#!/usr/bin/env python3
"""Rank experimental flag-2 entry targets from v5 evidence; never change bot."""
import argparse,json,math
from pathlib import Path

WAYPOINTS={1:(555,261),2:(760,330),3:(974,356),4:(1228,293),5:(1460,360)}
def midpoint(b):
 if not isinstance(b,dict):return None
 try:return ((float(b["min_x"])+float(b["max_x"]))/2,(float(b["min_y"])+float(b["max_y"]))/2)
 except (KeyError,TypeError,ValueError):return None
def dist(a,b):return math.hypot(a[0]-b[0],a[1]-b[1])
def optimize(report,flag=2,min_sessions=2):
 """Geometric rankings only; latency, trajectory and collision remain unknown."""
 if flag<2 or flag>5:raise ValueError("flag must be 2..5")
 groups=report.get("groups",[])
 origins=[g for g in groups if g.get("flag")==flag-1 and g.get("transitions",0)>0 and midpoint(g.get("post_bbox"))]
 # Origin is inferred only from preceding flag's observed post-collection boxes.
 # Multiple origin modes/sessions are pooled as an envelope (not a measured start).
 if not origins:
  return {"flag":flag,"status":"insufficient_origin_evidence","candidates":[],
          "limitations":["Missing observed previous-flag collection positions."]}
 origin_box={"min_x":min(g["post_bbox"]["min_x"] for g in origins),
             "max_x":max(g["post_bbox"]["max_x"] for g in origins),
             "min_y":min(g["post_bbox"]["min_y"] for g in origins),
             "max_y":max(g["post_bbox"]["max_y"] for g in origins)}
 origin=midpoint(origin_box)
 wp=WAYPOINTS[flag]
 baseline=dist(origin,wp)
 candidates=[]
 seen=set()
 for g in groups:
  if g.get("flag")!=flag or g.get("transitions",0)<1:continue
  target=midpoint(g.get("post_bbox"))
  if target is None:continue
  key=(g.get("mode","UNKNOWN"),target)
  if key in seen:continue
  seen.add(key)
  distance=dist(origin,target)
  sessions=int(g.get("sessions",0))
  known=g.get("mode","UNKNOWN")!="UNKNOWN"
  candidates.append({"mode":g.get("mode","UNKNOWN"),"target":{"x":target[0],"y":target[1]},
    "origin":{"x":origin[0],"y":origin[1]},"straight_line_distance":round(distance,3),
    "waypoint_distance":round(baseline,3),"geometric_saving":round(baseline-distance,3),
    "sessions":sessions,"transitions":int(g.get("transitions",0)),
    "near_without_transition":int(g.get("near_without_transition",0)),
    "readiness":"eligible_for_controlled_experiment" if known and sessions>=min_sessions
       else "insufficient_replication_or_mode",
    "evidence":"post_collection_observation_not_verified_entry_point"})
 candidates.sort(key=lambda x:(-x["geometric_saving"],-x["sessions"],x["mode"]))
 return {"flag":flag,"status":"experimental_ranking_only","origin_observed_bbox":origin_box,
  "origin_estimate":{"x":origin[0],"y":origin[1]},"reference_waypoint":{"x":wp[0],"y":wp[1]},
  "minimum_sessions":min_sessions,"candidates":candidates,
  "limitations":["Bounding-box centers are NOT verified collision entry points.",
   "Origin envelopes combine sessions, which may have different starts.",
   "Straight-line distance is a geometric lower bound, not observed travel or elapsed time.",
   "Delayed counter updates and near-without-transition observations cannot establish collision boundaries.",
   "No routes, waypoints, Dash or controls are modified automatically."]}
def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument("input",help="v5 evidence JSON")
 p.add_argument("--flag",type=int,default=2)
 p.add_argument("--min-sessions",type=int,default=2)
 p.add_argument("--output",default="collection_zone_candidates_v6.json")
 a=p.parse_args()
 if a.min_sessions<1:p.error("--min-sessions must be >=1")
 result=optimize(json.loads(Path(a.input).read_text(encoding="utf-8")),a.flag,a.min_sessions)
 Path(a.output).write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
 print("Status:",result["status"],"| candidates:",len(result["candidates"]))
 for c in result["candidates"]:
  print(c["mode"],c["target"],"saving",c["geometric_saving"],"status",c["readiness"])
 print("Saved:",a.output)
if __name__=="__main__":main()
