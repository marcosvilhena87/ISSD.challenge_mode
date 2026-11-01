from pathlib import Path
import unittest
root=Path(__file__).resolve().parents[1]
class SmoothMovement(unittest.TestCase):
 def test_burst(self):
  driver=(root/"lua/pass_bot.lua").read_text()
  ordered=(root/"lua/challenge/pass_ordered_v0820.lua").read_text()
  self.assertIn("BURST_FRAMES=4",ordered)
  self.assertIn("movement.burst_remaining=movement.burst_remaining-1",driver)
  self.assertIn("pass_chain.approach_neutral=movement.burst_remaining==0",driver)
  self.assertIn('"approach_burst_started"',driver)
  self.assertIn('Ordered.observe(pass_chain.approach_state,measurement)',driver)
  self.assertIn('movement.burst_buttons=buttons',driver)
if __name__=="__main__":unittest.main()
