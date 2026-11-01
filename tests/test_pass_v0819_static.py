from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class AdaptiveLimits(unittest.TestCase):
 def test_limits(self):
  s=(R/"lua/challenge/pass_feet_v0815.lua").read_text()
  for k in ("BASE_RANGE=190","BASE_LATERAL=72","RANGE_STEP=25","LATERAL_STEP=12","MAX_LEVEL=4","function M.set_level(level)"):
   self.assertIn(k,s)
 def test_exhaustion_and_logging(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for k in ('selector_reason=="no_reachable_target"','"limits_expanded"','"limits_exhausted"','Feet.set_level(autopass.relax_level or 0)'):
   self.assertIn(k,s)
 def test_relay_and_reset(self):
  self.assertIn("first<=Feet.MAX_RANGE",(R/"lua/challenge/pass_relay_v0810.lua").read_text())
  self.assertIn("relax_level=0",(R/"lua/challenge/pass_auto_v071.lua").read_text())
if __name__=="__main__":unittest.main()
