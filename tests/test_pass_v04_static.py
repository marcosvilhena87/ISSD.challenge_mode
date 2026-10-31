from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
class SpatialV04Tests(unittest.TestCase):
 def test_known_coordinates_and_goalkeeper_exclusion(self):
  s=(ROOT/"lua/challenge/pass_spatial_v04.lua").read_text()
  self.assertIn("x=0x042A,y=0x042C",s)
  self.assertIn("id=1,x=0x052A,y=0x052C",s)
  self.assertIn("for id=2,11 do",s)
  self.assertIn("sample.goalkeeper.distance>nearest.distance",s)
 def test_stable_candidate_not_confirmed(self):
  s=(ROOT/"lua/challenge/pass_spatial_v04.lua").read_text()
  self.assertIn("self.streak<self.stable",s)
  self.assertIn("spatial_proximity_only",s)
 def test_runner_is_read_only(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  self.assertIn("pass_spatial_v04.csv",s)
  self.assertIn("Spatial.read(memory.read_s16_le)",s)
  self.assertNotIn("memory.write_",s)
if __name__=="__main__":
 unittest.main()
