from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class ActiveAlignment(unittest.TestCase):
 def test_b_only_after_alignment(self):
  auto=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text()
  for token in ('t.phase=="active_align"','active_alignment_started','alignment_acquired','t.phase="hold"','retarget_requested_'):
   self.assertIn(token,auto)
  self.assertLess(auto.index('if t.phase=="active_align"'),auto.index('if t.phase=="hold"'))
 def test_bounded_directional_inputs(self):
  s=(ROOT/"lua/challenge/pass_active_alignment_v0818.lua").read_text()
  for token in ('MAX_STEP_FRAMES=2','alignment_regressed','ball_not_at_feet','return {[dir]=true}'):
   self.assertIn(token,s)
if __name__=="__main__":unittest.main()
