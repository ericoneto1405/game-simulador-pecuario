begin;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 2 and 60),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.game_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  slot smallint not null check (slot between 1 and 3),
  save_version integer not null check (save_version > 0),
  revision bigint not null default 1 check (revision > 0),
  payload jsonb not null,
  client_saved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, slot)
);

alter table public.profiles enable row level security;
alter table public.game_saves enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select to authenticated
using ((select auth.uid()) = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert to authenticated
with check ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists "game_saves_select_own" on public.game_saves;
create policy "game_saves_select_own"
on public.game_saves for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "game_saves_insert_own" on public.game_saves;
create policy "game_saves_insert_own"
on public.game_saves for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "game_saves_update_own" on public.game_saves;
create policy "game_saves_update_own"
on public.game_saves for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "game_saves_delete_own" on public.game_saves;
create policy "game_saves_delete_own"
on public.game_saves for delete to authenticated
using ((select auth.uid()) = user_id);

create or replace function public.create_own_profile(p_display_name text)
returns public.profiles
language plpgsql
security invoker
set search_path = public
as $$
declare
  result public.profiles;
begin
  insert into public.profiles (id, display_name)
  values ((select auth.uid()), trim(p_display_name))
  on conflict (id) do update
    set display_name = excluded.display_name,
        updated_at = now()
  returning * into result;
  return result;
end;
$$;

create or replace function public.save_game_slot(
  p_slot smallint,
  p_expected_revision bigint,
  p_save_version integer,
  p_payload jsonb,
  p_client_saved_at timestamptz default null
)
returns table (
  success boolean,
  conflict boolean,
  new_revision bigint,
  server_payload jsonb,
  server_updated_at timestamptz
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  owner_id uuid := (select auth.uid());
  current_save public.game_saves;
begin
  if owner_id is null then
    raise exception 'authentication required';
  end if;
  if p_slot not between 1 and 3 then
    raise exception 'invalid slot';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(owner_id::text || ':' || p_slot::text, 0)
  );

  select * into current_save
  from public.game_saves
  where user_id = owner_id and slot = p_slot
  for update;

  if not found then
    if p_expected_revision <> 0 then
      return query select false, true, 0::bigint, null::jsonb, null::timestamptz;
      return;
    end if;
    insert into public.game_saves (
      user_id, slot, save_version, revision, payload, client_saved_at
    ) values (
      owner_id, p_slot, p_save_version, 1, p_payload, p_client_saved_at
    ) returning revision, payload, updated_at
      into current_save.revision, current_save.payload, current_save.updated_at;
    return query select true, false, current_save.revision,
      current_save.payload, current_save.updated_at;
    return;
  end if;

  if current_save.revision <> p_expected_revision then
    return query select false, true, current_save.revision,
      current_save.payload, current_save.updated_at;
    return;
  end if;

  update public.game_saves
  set save_version = p_save_version,
      revision = revision + 1,
      payload = p_payload,
      client_saved_at = p_client_saved_at,
      updated_at = now()
  where id = current_save.id
  returning revision, payload, updated_at
    into current_save.revision, current_save.payload, current_save.updated_at;

  return query select true, false, current_save.revision,
    current_save.payload, current_save.updated_at;
end;
$$;

create or replace function public.delete_game_slot(
  p_slot smallint,
  p_expected_revision bigint
)
returns table (
  success boolean,
  conflict boolean,
  server_revision bigint,
  server_payload jsonb,
  server_updated_at timestamptz
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  owner_id uuid := (select auth.uid());
  current_save public.game_saves;
begin
  if owner_id is null then
    raise exception 'authentication required';
  end if;
  perform pg_advisory_xact_lock(
    hashtextextended(owner_id::text || ':' || p_slot::text, 0)
  );
  select * into current_save
  from public.game_saves
  where user_id = owner_id and slot = p_slot
  for update;
  if not found then
    return query select true, false, 0::bigint, null::jsonb, null::timestamptz;
    return;
  end if;
  if current_save.revision <> p_expected_revision then
    return query select false, true, current_save.revision,
      current_save.payload, current_save.updated_at;
    return;
  end if;
  delete from public.game_saves
  where id = current_save.id;
  return query select true, false, current_save.revision,
    null::jsonb, now();
end;
$$;

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.game_saves to authenticated;
revoke all on function public.create_own_profile(text) from public, anon;
revoke all on function public.save_game_slot(smallint, bigint, integer, jsonb, timestamptz) from public, anon;
revoke all on function public.delete_game_slot(smallint, bigint) from public, anon;
grant execute on function public.create_own_profile(text) to authenticated;
grant execute on function public.save_game_slot(smallint, bigint, integer, jsonb, timestamptz) to authenticated;
grant execute on function public.delete_game_slot(smallint, bigint) to authenticated;

commit;
