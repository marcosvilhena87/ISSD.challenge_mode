from pathlib import Path
import unittest
SRC=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text()
class ArmStateRegression(unittest.TestCase):
 def test_arm_reinitializes_ordered_state(self):
  self.assertIn("pass_chain={active=autopass.enabled,passes=0,next_frame=0,limit=18,started=false,previous=nil,consecutive_relays=0,route_index=1,approach_frames=0,approach_neutral=false}",SRC)
 def test_nil_safe_maximum(self):
  self.assertIn("(pass_chain.approach_frames or 0)>=Ordered.MAX_APPROACH",SRC)
if __name__=="__main__":unittest.main()
