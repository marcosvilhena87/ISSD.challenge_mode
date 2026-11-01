from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV087(unittest.TestCase):
 def test_late_attackers(self):
  s=(R/"lua/challenge/pass_priority_v087.lua").read_text()
  self.assertIn('for id=2,9 do',s)
  self.assertIn('return allow,"penultimate_11"',s)
  self.assertIn('return allow,"last_10"',s)
  self.assertIn('filtered[id]=true',s)
 def test_adaptive_window(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('range<=150 and 90 or (range<=300 and 150 or 210)',s)
  self.assertIn('buttons.B=true',s)
 def test_continuous_wiring(self):
  s=(R/"lua/pass_bot.lua").read_text()
  self.assertIn('Priority.resolve(Bridge,Alignment',s)
  self.assertIn('priority_stage=',s)
  self.assertIn('pass_chain.passes=pass_chain.passes+1',s)
  self.assertNotIn('memory.write_',s)
if __name__=="__main__": unittest.main()
