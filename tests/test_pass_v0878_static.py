from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class RecentClosure(unittest.TestCase):
 def test_bounded_recent_extension(self):
  self.assertIn('function M.recent_closure_710',O)
  self.assertIn('frames>=M.MAX_APPROACH_ABSOLUTE',O)
  self.assertIn('(state.pair_710_recent_extensions or 0)>=2',O)
  self.assertIn('total>=6 and positives>=4',O)
  self.assertIn('sum/total>=0.35',O)
 def test_integration(self):
  self.assertIn('Ordered.recent_closure_710',B)
  self.assertIn('approach_710_recent_closure_extension',B)
  self.assertIn('movement.pair_710_recent_extensions=',B)
  self.assertIn('movement.pair_710_closure_samples',B)
 def test_existing_features(self):
  self.assertIn('VERSION="0.8.78"',O)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('repeat_710_started',B)
  self.assertIn('approach_710_actual_input',B)
if __name__=="__main__":unittest.main()
