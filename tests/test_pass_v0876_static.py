from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class TestV0876(unittest.TestCase):
 def test_ab_probe(self):
  self.assertIn('approach_710_ab_probe',B)
  self.assertIn('RIGHT_ONLY',B)
  self.assertIn('RIGHT_Y',B)
  self.assertIn('math.floor((pass_chain.approach_frames or 0)/8)%2==1',B)
  self.assertIn('ball_gap_710(sample_for_auto) or math.huge)<=12',B)
 def test_one_repeat_after_visited(self):
  self.assertIn('spatial.visited[10] and not spatial.visited[11]',B)
  self.assertIn('not pass_chain.repeat_710_used',B)
  self.assertIn('repeat_710_pass_authorized',B)
  self.assertIn('repeat_710_result',B)
  self.assertIn('count_additional_visit=false',B)
 def test_safe_limits(self):
  self.assertIn('VERSION="0.8.76"',O)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('m.distance<=Early.MAX_DISTANCE',B)
  self.assertIn('m.lateral<=Early.MAX_LATERAL',B)
if __name__=="__main__": unittest.main()
