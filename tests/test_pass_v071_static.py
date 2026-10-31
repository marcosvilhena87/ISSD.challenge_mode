from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class SinglePass(unittest.TestCase):
 def test_only_one_attempt_and_simultaneous_input(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn("local buttons={B=true}",s)
  self.assertIn('t.tries=1',s)
  self.assertIn('t.enabled=false;t.phase="done"',s)
  self.assertIn('ball_moved_without_transfer',s)
  self.assertIn('no_ball_motion_detected',s)
 def test_runner_and_no_finish(self):
  s=(R/"lua/pass_bot.lua").read_text()
  self.assertIn('require("challenge.pass_auto_v071")',s)
  self.assertIn('finish.enabled=false;auto_finish_queued=false',s)
  self.assertIn('max_ball_displacement=',s)
  self.assertNotIn('memory.write_',s)
if __name__=="__main__":unittest.main()
