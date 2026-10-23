#!/usr/bin/env python3
"""Cross-session collection evidence; bounds describe observations, not collision."""
import argparse,csv,glob,json
from pathlib import Path
from collections import defaultdict

def read(path):
 with open(path,encoding="utf-8-sig",newline="") as f:
  for row in csv.DictReader(f):
   if "source_csv" in row:
    name=Path(row["source_csv"]).name
    if name not in ("dribble_collection_zone_v2.csv","dribble_collection_zone_v3.csv"):continue
    keys=next(csv.reader([row["source_columns"]]))
    vals=next(csv.reader([row["source_values"]]))
    if len(keys)!=len(vals):continue
    yield name,dict(zip(keys,vals))
   else:yield path.name,row

def bounds(points):
 if not points:return None
 return dict(min_x=min(p[0] for p in points),max_x=max(p[0] for p in points),
             min_y=min(p[1] for p in points),max_y=max(p[1] for p in points))

def analyze(paths):
 positives={};negatives={};modes={}
 for path in paths:
  for source,row in read(path):
   try:
    sid=row["session"].strip();flag=int(row["flag"]);frame=int(row["frame"])
    if not sid or flag not in range(1,6):continue
    key=(sid,flag,frame);event=row.get("event")
    if source.endswith("_v3.csv") and event=="collection_transition":
     modes[(sid,flag)]=row.get("mode") or "UNKNOWN"
    elif source.endswith("_v2.csv") and event=="collection_transition":
     positives[key]=(float(row["pre_x"]),float(row["pre_y"]),float(row["post_x"]),float(row["post_y"]))
    elif source.endswith("_v2.csv") and event=="near_without_transition":
     negatives[key]=(float(row["pre_x"]),float(row["pre_y"]))
   except (KeyError,ValueError,TypeError):continue
 groups=defaultdict(lambda:dict(sessions=set(),pre=[],post=[],near=[]))
 for (sid,flag,frame),p in positives.items():
  g=groups[(flag,modes.get((sid,flag),"UNKNOWN"))]
  g["sessions"].add(sid);g["pre"].append(p[:2]);g["post"].append(p[2:])
 for (sid,flag,frame),p in negatives.items():
  g=groups[(flag,modes.get((sid,flag),"UNKNOWN"))]
  g["sessions"].add(sid);g["near"].append(p)
 entries=[]
 for (flag,mode),g in sorted(groups.items()):
  entries.append(dict(flag=flag,mode=mode,sessions=len(g["sessions"]),transitions=len(g["post"]),
   near_without_transition=len(g["near"]),pre_bbox=bounds(g["pre"]),
   post_bbox=bounds(g["post"]),no_transition_bbox=bounds(g["near"]),
   classification="observed_positions_only_not_collision_boundary"))
 return dict(groups=entries,unique_transitions=len(positives),unique_near_observations=len(negatives),
  limitations=["Counter transitions may lag actual contact.",
   "Near-without-transition is not evidence that a point is outside the physical collision zone.",
   "Observed bounding boxes do not establish collision geometry.",
   "UNKNOWN mode indicates missing mode evidence."])

def expand(inputs):
 result=set()
 for x in inputs:
  p=Path(x)
  if p.is_dir():
   for pattern in ("dribble_diagnostics_v2*.csv","dribble_collection_zone_v2*.csv","dribble_collection_zone_v3*.csv"):
    result.update(p.rglob(pattern))
  else:result.update(map(Path,glob.glob(x)))
 return sorted(x for x in result if x.is_file())

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument("inputs",nargs="+",help="CSV files, patterns or folders")
 ap.add_argument("--output",default="collection_zone_evidence_v5.json")
 a=ap.parse_args()
 files=expand(a.inputs)
 if not files:ap.error("No CSV inputs found")
 report=analyze(files);report["input_files"]=len(files)
 Path(a.output).write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding="utf-8")
 print("Processed",len(files),"files;",report["unique_transitions"],"unique collection transitions")
 for g in report["groups"]:
  print("flag",g["flag"],"mode",g["mode"],"sessions",g["sessions"],
        "collected",g["transitions"],"post_bbox",g["post_bbox"])
 print("Saved",a.output)
if __name__=="__main__":main()
