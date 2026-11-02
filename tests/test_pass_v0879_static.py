from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
B=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class V0879(unittest.TestCase):
 def test_limits(self):
  self.assertIn('MAX_APPROACH_ABSOLUTE=210,MAX_APPROACH_710_ABSOLUTE=480',O)
  self.assertIn('local approach_absolute=(holder==7 and target==10) and Ordered.MAX_APPROACH_710_ABSOLUTE or Ordered.MAX_APPROACH_ABSOLUTE',B)
  self.assertIn('(movement.pair_710_progressive_extensions or 0)<8',B)
 def test_vertical(self):
  self.assertIn('pair_710_vertical_correction',O)
  self.assertIn('math.abs(lateral)>=32',O)
  self.assertIn('pair_710_vertical_cooldown',O)
 def test_progress_and_safety(self):
  self.assertIn('approach_710_progressive_extension',B)
  self.assertIn('positions.hx-last.hx>=12 or last.distance-measurement.distance>=8',B)
  self.assertIn('repeat_710_started',B)
  self.assertIn('VERSION="0.8.79"',O)
if __name__=="__main__":unittest.main()
