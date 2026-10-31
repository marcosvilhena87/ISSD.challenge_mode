from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class PassV05Static(unittest.TestCase):
 def test_addresses_and_bcd(self):
  s=(ROOT/"lua/challenge/pass_timers_v05.lua").read_text()
  for addr in ("0x014F0","0x014F2","0x014F4","0x014F6"):
   self.assertIn(addr,s)
  self.assertIn('lo>9 or hi>9',s)
  self.assertIn('bonus_zero_to_positive_candidate',s)
 def test_integration_read_only(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  self.assertIn("pass_timers_v05.csv",s)
  self.assertIn("Timers.read(memory.read_u8,memory.read_u16_le)",s)
  self.assertNotIn("memory.write_",s)
if __name__=="__main__": unittest.main()
