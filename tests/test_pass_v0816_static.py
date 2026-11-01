from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class Retarget(unittest.TestCase):
 def test_retry(self):
  auto=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  runner=(R/"lua/pass_bot.lua").read_text()
  relay=(R/"lua/challenge/pass_relay_v0810.lua").read_text()
  for k in ("max_retargets=3",'t.phase=="retarget_wait"','t.retarget_wait=frame+3','"retarget_limit_reached"'):
   self.assertIn(k,auto)
  for k in ('"retarget_requested"','"retarget_ready"','"retarget_limit_stop"'):
   self.assertIn(k,runner)
  self.assertIn('not (excluded and excluded[id])',relay)
if __name__=="__main__":unittest.main()
