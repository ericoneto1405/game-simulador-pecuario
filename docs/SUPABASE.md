# Configuração do Supabase

## 1. Criar o projeto

1. Entre no painel do Supabase e crie um projeto exclusivo para o jogo.
2. Escolha a região disponível mais próxima do Brasil.
3. Em **Authentication > Providers > Email**, mantenha e-mail e senha ativos e desative a confirmação obrigatória de e-mail.
4. No SQL Editor, execute `supabase/migrations/202608220001_cloud_accounts_and_saves.sql`.

A migração cria `profiles`, `game_saves`, as políticas RLS e as funções atômicas de salvar e apagar slots.

## 2. Configurar o jogo

1. Copie `config/supabase.example.json` para `config/supabase.json`.
2. Preencha `url` e `publishable_key` com os valores públicos do projeto.
3. Nunca coloque a chave `service_role` nesse arquivo.

`config/supabase.json` não entra no Git. Na exportação Web ele é incluído no pacote local do build. Como alternativa para execução nativa, use `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` no ambiente.

## 3. Validar antes da publicação

1. Execute `make check`.
2. Execute `make validate-supabase`. Para incluir login e leitura protegida, informe `SUPABASE_TEST_EMAIL` e `SUPABASE_TEST_PASSWORD` somente no ambiente local.
3. Cadastre duas contas de teste.
4. Confirme três slots isolados por conta.
5. Salve offline, reconecte e confirme a sincronização.
6. Edite o mesmo slot em dois navegadores e valide a escolha de conflito.
7. Limpe os dados de um navegador, entre novamente e confirme a recuperação.
8. Tente consultar ou alterar um save da outra conta e confirme o bloqueio por RLS.

O servidor atual de horário continua separado e a partida permanece no formato de conteúdo versão 20.
