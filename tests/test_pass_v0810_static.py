from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class RelayV0810(unittest.TestCase):
 def test_relays_limited_and_penalized(self):
  s=(R/"lua/challenge/pass_relay_v0810.lua").read_text()
  for token in ('RELAY_PENALTY=100','MAX_CONSECUTIVE=2','id~=previous',
                'visited[id]','first<=200 and second<=200',
                'math.max(0,direct-180)*2','stage="penultimate_11"','stage="last_10"'):
   self.assertIn(token,s)
 def test_visited_snapshot_actual_receiver(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for token in ('visited_before_pass','visited_before_pass[holder]',
                'relay_outcome','consecutive_relays','limit=18','package.loaded["challenge.pass_priority_v087"]=nil'):
   self.assertIn(token,s)
 def test_no_extra_button_pulse(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('buttons.B=true',s)
  self.assertIn('t.hold_count>=t.hold_frames',s)
if __name__=="__main__": unittest.main()
