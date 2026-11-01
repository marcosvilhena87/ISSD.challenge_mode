from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class GateV0812(unittest.TestCase):
 def test_stability_gate(self):
  s=(R/"lua/challenge/pass_possession_gate_v0812.lua").read_text()
  for token in ('required=4','max_distance=18','max_delta=3','t.streak>=t.required','missing_observation','too_far'):
   self.assertIn(token,s)
 def test_controller_guards(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  for token in ('t.phase=="possession_gate"','return empty,"possession_gate_wait"','return empty,"possession_gate_timeout"','t.phase="possession_gate";t.gate_start=frame','buttons.B=true'):
   self.assertIn(token,s)
 def test_rearm_and_telemetry(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for token in ('cmd=="ARM" or cmd=="REARM"','armed and auto_finished and selected_pass_button=="B"',
                '"possession_gate_timeout"','pass_trigger_v0811.csv','autopass.phase=="possession_gate"'):
   self.assertIn(token,s)
if __name__=="__main__": unittest.main()
