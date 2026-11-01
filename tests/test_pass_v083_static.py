from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class TestPass083(unittest.TestCase):
 def test_bridge_lua_integration(self):
  s=(R/"lua/challenge/pass_bridge_v083.lua").read_text()
  for snippet in ('function M.selftest(selector,auto)','info.report.eligible==9','state=="target_selected"',
                  'keys.B and (keys.Up or keys.Down or keys.Left or keys.Right)','t.tries==1'):
   self.assertIn(snippet,s)
 def test_runner_handoff_and_module_reload(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for snippet in ('package.loaded["challenge.pass_alignment_v08"]=nil',
                  'Bridge.selftest','Bridge.resolve','handoff_diagnostic','integration_selftest=PASS'):
   self.assertIn(snippet,s)
  self.assertNotIn('memory.write_',s)
 def test_version_and_failure_closed(self):
  s=(R/"lua/challenge/pass_alignment_v08.lua").read_text()
  self.assertIn('VERSION="0.8.3",API=3',s)
  b=(R/"lua/challenge/pass_bridge_v083.lua").read_text()
  self.assertIn('selector_api_mismatch',b)
  self.assertIn('selected_without_receiver',b)
if __name__=="__main__": unittest.main()
