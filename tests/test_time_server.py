import unittest
from datetime import datetime, timezone

from tools.time_server import build_time_payload


class TimeServerTest(unittest.TestCase):
    def test_returns_utc_and_bahia_time(self) -> None:
        payload = build_time_payload(datetime(2026, 8, 5, 15, 30, tzinfo=timezone.utc))

        self.assertEqual(payload["unix_utc"], 1785943800)
        self.assertEqual(payload["timezone"], "America/Bahia")
        self.assertEqual(payload["offset_seconds"], -10800)
        self.assertEqual(
            payload["local"],
            {"year": 2026, "month": 8, "day": 5, "hour": 12, "minute": 30, "second": 0},
        )


if __name__ == "__main__":
    unittest.main()
