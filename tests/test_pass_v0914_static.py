from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class ExclusiveV0914(unittest.TestCase):
 def test_priorities(self):
  self.assertIn('spatial.holder==6 and not spatial.visited[2]',S)
  self.assertIn('spatial.holder==5 and not spatial.visited[8]',S)
  self.assertIn('exclusive_receiver=to',S)
  self.assertIn('local receiver=exclusive_receiver or special or autopass.target',S)
 def test_bounded_alignment(self):
  for key in ['elapsed>=78','walked>155','frame-ctrl.last_progress>=14',
              'math.abs(geom.dy)>95 and geom.distance<=200',
              'geom.distance<=175 and math.abs(geom.dy)<=95','carrier>18']:
   self.assertIn(key,S)
 def test_time_gate(self):
  self.assertIn('if pass_chain.active and chain_visits>=10 and completion_frame then',S)
  self.assertIn('chain_complete_out_of_time',S)
 def test_preserve_score_and_finish(self):
  self.assertIn('pass_score_wram_correlated',S)
  self.assertIn('finish_x_verified_output',S)
if __name__=="__main__":unittest.main()
