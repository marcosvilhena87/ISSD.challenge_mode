import csv,tempfile,unittest
from pathlib import Path
from tools.collection_zone_analysis_v5 import analyze
class CrossSessionTest(unittest.TestCase):
 def test_overlap_and_modes(self):
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/"dribble_diagnostics_v2.csv"
   rows=[
    ["s1","12","dribble_collection_zone_v2.csv","collection_transition",
     "session,frame,flag,event,pre_x,pre_y,post_x,post_y","s1,12,2,collection_transition,742,329,744,329"],
    ["s1","12","dribble_collection_zone_v3.csv","collection_transition",
     "session,frame,flag,mode,event","s1,12,2,OFF,collection_transition"],
    ["s1","11","dribble_collection_zone_v2.csv","near_without_transition",
     "session,frame,flag,event,pre_x,pre_y","s1,11,2,near_without_transition,732,323"]]
   with path.open("w",newline="") as f:
    writer=csv.writer(f);writer.writerow(["session","frame","source_csv","record_type","source_columns","source_values"]);writer.writerows(rows+rows)
   data=analyze([path,path])
   assert data["unique_transitions"]==1
   assert data["unique_near_observations"]==1
   assert data["groups"][0]["mode"]=="OFF"
   assert data["groups"][0]["post_bbox"]["min_x"]==744
if __name__=="__main__":unittest.main()
