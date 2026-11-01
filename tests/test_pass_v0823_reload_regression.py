from pathlib import Path
import unittest
root=Path(__file__).resolve().parents[1]
class ReloadRegression(unittest.TestCase):
 def test_forced_reload_precedes_require(self):
  s=(root/"lua/pass_bot.lua").read_text()
  self.assertLess(s.index('package.loaded["challenge.pass_ordered_v0820"]=nil'),s.index('local Ordered=require("challenge.pass_ordered_v0820")'))
  self.assertIn('assert(type(Ordered.observe)=="function"',s)
 def test_module_exports_observe(self):
  s=(root/"lua/challenge/pass_ordered_v0820.lua").read_text()
  self.assertIn("function M.observe(state,metrics)",s)
if __name__=="__main__":unittest.main()
