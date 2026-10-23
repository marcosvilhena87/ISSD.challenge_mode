import unittest
from tools.collection_zone_analysis_v6 import optimize
class EntryPointTest(unittest.TestCase):
 def group(self,flag,mode,x,y,n=2):
  return {"flag":flag,"mode":mode,"sessions":n,"transitions":n,"near_without_transition":1,
   "post_bbox":{"min_x":x,"max_x":x,"min_y":y,"max_y":y}}
 def test_rank_and_readiness(self):
  data={"groups":[self.group(1,"OFF",554,262,3),
                   self.group(2,"OFF",744,329,3),
                   self.group(2,"ABOVE",748,325,1)]}
  r=optimize(data)
  assert r["status"]=="experimental_ranking_only"
  assert len(r["candidates"])==2
  assert all(c["geometric_saving"]>0 for c in r["candidates"])
  assert next(c for c in r["candidates"] if c["mode"]=="ABOVE")["readiness"]=="insufficient_replication_or_mode"
  assert next(c for c in r["candidates"] if c["mode"]=="OFF")["readiness"]=="eligible_for_controlled_experiment"
 def test_missing_origin(self):
  assert optimize({"groups":[self.group(2,"OFF",744,329)]})["status"]=="insufficient_origin_evidence"
 def test_unknown_mode(self):
  r=optimize({"groups":[self.group(1,"OFF",554,262),self.group(2,"UNKNOWN",745,329,3)]})
  assert r["candidates"][0]["readiness"]=="insufficient_replication_or_mode"
if __name__=="__main__":unittest.main()
