from pathlib import Path
import unittest

SOURCE=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")

class PassFirstSyntaxRegression(unittest.TestCase):
    def test_outer_candidate_loop_closed_before_fallback(self):
        section=SOURCE.split("local function pass_first_target(sample,from,visited)",1)[1].split("-- Diagonal travel",1)[0]
        self.assertIn("for id=2,11 do",section)
        self.assertIn("   end\n end\n end\n -- Conservative fallback:",section)

if __name__=="__main__":
    unittest.main()
