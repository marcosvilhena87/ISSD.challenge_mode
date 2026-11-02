from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
class PredictiveChase(unittest.TestCase):
 def test_prediction(self):
  for key in ('VERSION="0.8.72"','function M.observe_710','function M.predict_710','pair_710_predictive_chase','frame-v.frame>8','math.min(24,'):
   self.assertIn(key,O)
 def test_runtime(self):
  self.assertIn('Ordered.observe_710(movement,sample_for_auto,emu.framecount())',B)
  self.assertIn('approach_710_receiver_velocity',B)
  self.assertIn('Early.MAX_DISTANCE',B)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
if __name__=="__main__":unittest.main()
