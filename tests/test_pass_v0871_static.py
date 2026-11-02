from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
class V0871(unittest.TestCase):
 def test_receiver_reconciliation(self):
  self.assertIn('"route_unexpected_receiver_reconcile"',B)
  self.assertIn('Ordered.next(pass_chain.route_index,holder,spatial.visited)',B)
  self.assertIn('visited_actual=',B)
 def test_711_target_and_guard(self):
  self.assertIn('VERSION="0.8.71"',O)
  self.assertIn('pair_711_coordinate_retarget',O)
  self.assertIn('pair_711_net_regression_stop',O)
  self.assertIn('metrics.distance>state.best_distance+28',O)
  self.assertIn('movement.approach_frames=pass_chain.approach_frames or 0',B)
 def test_prior_safety(self):
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('Early.TARGET_DISTANCE==160',B)
if __name__=="__main__":unittest.main()
