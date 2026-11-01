from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
class TestPass084(unittest.TestCase):
 def test_transition_diagnostics(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  for token in ('pass_runtime_gates_v084.csv','if signature==previous_gate then return end',
                'gate_reason="auto_disabled"','gate_reason="missing_spatial_sample"',
                'gate_reason="no_stable_holder"','gate_write(emu.framecount()'):
   self.assertIn(token,s)
 def test_receiver_metrics_from_audit_report(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  self.assertIn('for _,candidate in ipairs(report and report.candidates or {})',s)
  self.assertIn('if candidate.id==receiver.id then c=candidate',s)
  self.assertNotIn('receiver.distance,receiver.misalignment,receiver.cost',s)
 def test_input_safety_preserved(self):
  auto=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('buttons.B=true',auto)
  self.assertIn('buttons.Left or buttons.Right or buttons.Up or buttons.Down',auto)
  self.assertIn('t.tries=1',auto)
if __name__=="__main__": unittest.main()
