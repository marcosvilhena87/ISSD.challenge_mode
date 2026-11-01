from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]

class ContinuousPassV086(unittest.TestCase):
 def test_chain_progress_and_limits(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  for token in ('pass_chain={active=false,passes=0,next_frame=0,limit=14,started=false}',
                'spatial.visited[spatial.holder]=true',
                'reason=="transfer_candidate_observed" and pass_chain.active',
                'pass_chain.next_frame=emu.framecount()+8',
                'pass_chain.passes>=pass_chain.limit','chain_complete_candidate','chain_limit_stop',
                'pass_chain.active=false;autopass.enabled=false;auto_finished=true'):
   self.assertIn(token,s)
 def test_control_and_safe_termination(self):
  s=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('buttons.B=true',s)
  self.assertIn('if not (buttons.Left or buttons.Right or buttons.Up or buttons.Down)',s)
  self.assertIn('t.tries=1',s)
  runner=(ROOT/"lua/pass_bot.lua").read_text()
  self.assertIn('pass_chain.active=false;record("stopped"',runner)
  self.assertNotIn('memory.write_',runner)

if __name__=="__main__":
 unittest.main()
