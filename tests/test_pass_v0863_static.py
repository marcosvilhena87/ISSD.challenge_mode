from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
OBS=(ROOT/"lua/challenge/pass_reach_v0863.lua").read_text()
BOT=(ROOT/"lua/pass_bot.lua").read_text()
ORD=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text()
class TestReachV0863(unittest.TestCase):
 def test_measurements(self):
  for word in ('ball_path','ball_max','walk=p.walk','initial=p.initial','function M.finish','st.flight=nil'):
   self.assertIn(word,OBS)
 def test_wiring(self):
  self.assertIn('Reach.observe(reach,emu.framecount()',BOT)
  self.assertIn('Reach.finish(reach,emu.framecount()',BOT)
  self.assertIn('pass_reach_v0863.csv',BOT)
  self.assertIn('reach=Reach.new()',BOT)
 def test_previous_logic(self):
  self.assertIn('VERSION="0.8.63"',ORD)
  self.assertIn('primary_9_to_7',ORD)
  self.assertIn('CONTINUOUS_HOLD_710=24',ORD)
  self.assertIn('GoalEvidence.step(goal_monitor,g)',BOT)
if __name__=="__main__":unittest.main()
