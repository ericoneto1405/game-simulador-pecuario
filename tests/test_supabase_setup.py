import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class SupabaseSetupTest(unittest.TestCase):
    def test_database_enforces_slots_rls_and_atomic_revision(self):
        sql = (
            ROOT / "supabase/migrations/202608220001_cloud_accounts_and_saves.sql"
        ).read_text(encoding="utf-8").lower()

        self.assertIn("unique (user_id, slot)", sql)
        self.assertIn("check (slot between 1 and 3)", sql)
        self.assertIn("enable row level security", sql)
        self.assertIn("auth.uid()", sql)
        self.assertIn("for update", sql)
        self.assertIn("p_expected_revision", sql)
        self.assertNotIn("service_role", sql)

    def test_public_configuration_is_separated_from_real_configuration(self):
        example = ROOT / "config/supabase.example.json"
        gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
        export = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")

        self.assertTrue(example.is_file())
        self.assertIn("config/supabase.json", gitignore)
        self.assertIn('include_filter="config/supabase.json"', export)

    def test_game_uses_local_first_cloud_cache_without_legacy_import(self):
        manager = (ROOT / "scripts/user_manager.gd").read_text(encoding="utf-8")
        controller = (
            ROOT / "scripts/farm_setup_controller.gd"
        ).read_text(encoding="utf-8")

        self.assertIn('const CACHE_ROOT := "user://cloud_cache"', manager)
        self.assertIn("pending_sync", manager)
        self.assertIn("remote_revision", manager)
        self.assertIn("operation_id", manager)
        self.assertNotIn('"user://users.json"', manager)
        self.assertIn("UserManager.queue_slot_sync", controller)
        self.assertIn("const SAVE_VERSION := 20", controller)

    def test_environment_validator_checks_anonymous_access(self):
        validator = (
            ROOT / "tools/validate_supabase.py"
        ).read_text(encoding="utf-8")

        self.assertIn("game_saves expôs partidas para usuário anônimo", validator)
        self.assertIn("save_game_slot aceitou gravação anônima", validator)
        self.assertIn('"HTTP 401"', validator)


if __name__ == "__main__":
    unittest.main()
