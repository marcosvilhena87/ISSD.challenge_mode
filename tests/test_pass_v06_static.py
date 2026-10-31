from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class ExperimentalPassV06(unittest.TestCase):
    def test_explicit_opt_in_and_limits(self):
        s=(ROOT/"lua/pass_bot.lua").read_text()
        a=(ROOT/"lua/challenge/pass_auto_v06.lua").read_text()
        for token in ("AUTO:ON","AUTO:OFF","PASSBTN:","opt_in_required"):
            self.assertIn(token,s)
        self.assertIn("frame-t.start_frame>3600",a)
        self.assertIn("t.tries>=15",a)
        self.assertIn("cooldown",a)
        self.assertIn("pass_pulse",a)
    def test_no_ram_writes(self):
        for p in ("lua/pass_bot.lua","lua/challenge/pass_auto_v06.lua"):
            self.assertNotIn("memory.write_", (ROOT/p).read_text())
if __name__=="__main__":unittest.main()
