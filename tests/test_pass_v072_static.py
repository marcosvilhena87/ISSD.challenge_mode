from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassDirectionalV072(unittest.TestCase):
 def test_explicit_direction_and_one_attempt(self):
  run=(R/"lua/pass_bot.lua").read_text()
  ctrl=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('DIRECTION:',run)
  self.assertIn('pass_direction_v072.csv',run)
  self.assertIn('selected_direction',run)
  self.assertIn('autopass.direction=selected_direction',run)
  self.assertIn('direction=="AUTO"',ctrl)
  self.assertIn('direction~="NEUTRAL"',ctrl)
  self.assertIn('local buttons={B=true}',ctrl)
  self.assertIn('t.tries=1',ctrl)
  self.assertIn('t.enabled=false;t.phase="done"',ctrl)
  self.assertNotIn('memory.write_',run)
 def test_bonus_reset(self):
  s=(R/"lua/challenge/pass_bonus_validation_v051.lua").read_text()
  self.assertIn('bonus_abrupt_reset_candidate',s)
  self.assertIn('s.bonus==0 and p.bonus>=2',s)
if __name__=='__main__':unittest.main()
