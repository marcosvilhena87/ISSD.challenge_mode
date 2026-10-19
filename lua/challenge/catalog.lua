local M = {}
local root = _G.ISSD_PROJECT_ROOT or "."
local entries = dofile(root .. "/data/challenges.lua")
local lookup = {}
for _, item in ipairs(entries) do lookup[item.id] = item end
function M.get(id) return lookup[id] end
function M.all() return entries end
function M.valid_level(level) return type(level) == "number" and level >= 1 and level <= 4 and level % 1 == 0 end
function M.count_scenarios() return #entries * 4 end
return M
