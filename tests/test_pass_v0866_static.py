from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
MAP=(ROOT/"lua/challenge/pass_goal_stadium_v0866.lua").read_text()
FIN=(ROOT/"lua/challenge/pass_finish_v07.lua").read_text()
BOT=(ROOT/"lua/pass_bot.lua").read_text()
class TestStadiumGoalV0866(unittest.TestCase):
 def test_wram_sources(self):
  for address in ("0x0086","0x12A2","0x12A4","0x12F2","0x12D8"):
   self.assertIn(address,MAP)
  self.assertIn("cx+len/2",MAP)
  self.assertIn("left_x=cx-len/2",MAP)
  self.assertIn("calibrated=false",MAP)
 def test_no_ghost_keeper(self):
  self.assertIn("sample.goal_reference",FIN)
  self.assertNotIn("sample.goalkeeper",FIN)
  self.assertIn("stadium_goal_coordinate_mismatch",FIN)
  self.assertIn("GoalStadium.read(memory.read_s16_le,memory.read_u16_le)",BOT)
  self.assertIn("finish_stadium_goal_audit",BOT)
if __name__=="__main__": unittest.main()
