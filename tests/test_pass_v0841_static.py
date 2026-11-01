from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV0841(unittest.TestCase):
 def test_pair_specific_sequence(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  for token in ('t.origin==6 and t.target==3','t.phase=="pre_up"','t.pre_up_frames>=2','{Up=true},"pre_up_step"','t.phase="hold";return empty,"pre_up_release"','if t.origin==6 and t.target==3 then buttons={} end'):
   self.assertIn(token,s)
 def test_preserved_other_pairs(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('t.phase=="pre_down"',s)
  self.assertIn('return {Down=true},"pre_down_step"',s)
  self.assertIn('not (t.origin==6 and t.target==3)',s)
  bot=(R/"lua/pass_bot.lua").read_text()
  for token in ('pre_up=2|release=1|pass=B_only','pre_up_step','approach_right_followup','local desired_burst=','approach_diagonal_started'):
   self.assertIn(token,bot)
if __name__=="__main__":unittest.main()
