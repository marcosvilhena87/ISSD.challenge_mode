from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class ProgressApproach(unittest.TestCase):
 def test_switch_and_progress(self):
  s=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for word in ('STALL_WINDOW=6','state.best_distance','state.previous_distance','"axis_switched"','state.axis=axis'):
   self.assertIn(word,s)
 def test_runner_logging_and_adaptation(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  for word in ('"approach_progress"','"approach_axis_switched"','cause=approach_stall','Feet.set_level(autopass.relax_level)','Ordered.observe(pass_chain.approach_state,measurement)'):
   self.assertIn(word,s)
  self.assertIn('approach_state={}',s)
 def test_sequence_preserved(self):
  s=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text()
  self.assertIn('ROUTE={6,2,3,4,5,8,9,7,10,11}',s)
if __name__=="__main__": unittest.main()
