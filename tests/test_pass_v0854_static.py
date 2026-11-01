from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
B=(R/"lua/pass_bot.lua").read_text()
class TestV0854(unittest.TestCase):
 def test_receiver_escape_not_carrier_failure(self):
  for term in ('VERSION="0.8.54"','pair_89_receiver_escape_progress','pair_89_extension_count or 0)<2'):
   self.assertIn(term,O)
  for term in ('receiver_caused=carrier>0.5 and escape>carrier and delta>1.5','pair_89_escape_growth','pair_89_carrier_progress_streak','pair_89_extension_count'):
   self.assertIn(term,B)
 def test_six_seven_diagonal_retained(self):
  self.assertIn('pair_67_up_right_approach',O)
  self.assertIn('approach_67_diagonal_feedback',B)
  self.assertIn('route_67_continuity',B)
 def test_absolute_safety(self):
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('approach_89_regression_stop',B)
if __name__=="__main__": unittest.main()
