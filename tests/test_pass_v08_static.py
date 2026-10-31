from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV08(unittest.TestCase):
 def test_selector(self):
  s=(R/"lua/challenge/pass_alignment_v08.lua").read_text()
  self.assertIn('p.id>=2 and p.id<=11',s)
  self.assertIn('not (visited and visited[p.id])',s)
  self.assertIn('alignment_weight',s)
  self.assertIn('distance+alignment_weight',s)
 def test_bounded_alignment_and_single_pass(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('align_frames=2',s)
  self.assertIn('alignment_correction',s)
  self.assertIn('local buttons={B=true}',s)
  self.assertIn('t.tries=1',s)
  runner=(R/"lua/pass_bot.lua").read_text()
  self.assertIn('Alignment.choose(',runner)
  self.assertIn('receiver_selected',runner)
  self.assertIn('alignment_correction',runner)
  self.assertNotIn('memory.write_',runner)
if __name__=="__main__": unittest.main()
