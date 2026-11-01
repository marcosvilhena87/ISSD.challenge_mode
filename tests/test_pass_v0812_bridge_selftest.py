from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class BridgeSelftestV0812(unittest.TestCase):
 def test_wait_for_gate_before_pulse(self):
  s=(ROOT/"lua/challenge/pass_bridge_v083.lua").read_text()
  self.assertIn('last_state=="possession_gate_ready"',s)
  self.assertIn('pulses==3',s)
  self.assertIn('last_state=="pass_pulse"',s)
  self.assertNotIn('last_last_state',s)
  self.assertNotIn('for frame=2,4 do',s)
 def test_gate_still_required(self):
  s=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('t.phase="possession_gate";t.gate_start=frame',s)
  self.assertIn('return empty,"possession_gate_ready"',s)
if __name__=="__main__": unittest.main()
