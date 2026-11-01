from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class PassV088(unittest.TestCase):
 def test_bounded_extra_wait(self):
  s=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('extra_wait_frames=90',s)
  self.assertIn('if not t.extended and t.ball_max_displacement>=8 then',s)
  self.assertIn('return empty,"flight_wait_extended"',s)
  self.assertIn('t.first_motion_frame=frame',s)
  self.assertIn('frame%10==0',s)
  self.assertIn('buttons.B=true',s)
 def test_logs_and_strategy_preserved(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  for t in ("flight_wait_extended","flight_sample","flight_summary","receiver_mismatch","completed_displacement","Priority.resolve(Bridge,Alignment"):
   self.assertIn(t,s)
  p=(ROOT/"lua/challenge/pass_priority_v087.lua").read_text()
  self.assertIn('penultimate_11',p)
  self.assertIn('last_10',p)
if __name__=="__main__": unittest.main()
