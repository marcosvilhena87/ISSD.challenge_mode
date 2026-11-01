from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
B=(R/"lua/pass_bot.lua").read_text()
class V0855(unittest.TestCase):
 def test_primary_and_fallback(self):
  self.assertIn('VERSION="0.8.55"',O)
  self.assertIn('if holder==9 and not visited[7] then return 7,"primary_9_to_7"',O)
  self.assertIn('if holder==6 and visited[9] and not visited[7] then return 7,"fallback_6_to_7"',O)
 def test_physical_input(self):
  self.assertIn('approach_7_joypad_commit',B)
  self.assertIn('joypad.set(buttons,1)',B)
  self.assertIn('geometry_reason=',B)
  self.assertIn('(holder==8 and target==9 or holder==6 and target==7) and buttons.Up and buttons.Right',B)
 def test_regressions(self):
  self.assertIn('approach_89_relative_feedback',B)
  self.assertIn('route_67_continuity',B)
  self.assertIn('approach_67_diagonal_feedback',B)
if __name__=="__main__": unittest.main()
