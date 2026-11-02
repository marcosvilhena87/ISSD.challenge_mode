from pathlib import Path
import unittest
s=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class UniversalSupport(unittest.TestCase):
 def test_all_targets(self):
  self.assertIn('Ordered.next(nil,from,spatial.visited)',s)
  self.assertIn('"universal_support_planned"',s)
 def test_before_sidestep(self):
  self.assertLess(s.index('"universal_support_planned"'),s.index('long_710.sidestep_97_count=long_710.sidestep_97_count+1'))
 def test_cycle_guards(self):
  self.assertIn('universal_previous_holder',s)
  self.assertIn('support_count<2 and not loop_back',s)
  self.assertIn('"immediate_return"',s)
  self.assertIn('"universal_support_rejected"',s)
 def test_pass_safety(self):
  self.assertIn('carrier_gap(sample_for_auto,long_710.origin)',s)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',s)
if __name__=="__main__":unittest.main()
