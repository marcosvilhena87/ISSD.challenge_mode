from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text()
class MovementScope(unittest.TestCase):
 def test_variable_precedes_both_branches(self):
  start=S.index('if autopass.phase=="idle" and not plan and selector_reason=="approach_required"')
  region=S[start:S.index('elseif integration_ok and (autopass.phase~="idle" or plan)',start)]
  self.assertEqual(region.count('local movement=pass_chain.approach_state'),1)
  self.assertLess(region.index('local movement=pass_chain.approach_state'),region.index('elseif pass_chain.approach_neutral'))
  self.assertIn('movement.last_expansion_step',region)
if __name__=="__main__":unittest.main()
