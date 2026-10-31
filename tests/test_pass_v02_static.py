from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class PassV02StaticTests(unittest.TestCase):
    def test_tracker_requires_exactly_ten_players(self):
        code = (ROOT / "lua/challenge/pass_tracking_v02.lua").read_text()
        self.assertIn("#config.players~=10", code)
        self.assertIn('duplicate_or_invalid_possession_value', code)
        self.assertIn('no_possession_collides_with_player', code)

    def test_route_is_dynamic_programming(self):
        code = (ROOT / "lua/challenge/pass_tracking_v02.lua").read_text()
        self.assertIn('2^n-1', code)
        self.assertIn('euclidean_held_karp', code)
        self.assertIn('self.streak<self.stability', code)

    def test_no_automated_passing_or_memory_writes(self):
        runner = (ROOT / "lua/pass_bot.lua").read_text()
        self.assertIn('pass_ram_map_v02.lua', runner)
        self.assertIn('pass_lv1_tracking_v02.csv', runner)
        self.assertIn('joypad.set({},1)', runner)
        self.assertNotIn('memory.write_', runner)

if __name__ == "__main__":
    unittest.main()
