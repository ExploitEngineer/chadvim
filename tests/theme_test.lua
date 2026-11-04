-- The wallbash base46 theme, and the startup cache logic that keeps whatever
-- chadrc names from being overridden or served stale.
local T = dofile "tests/helpers.lua"
T.settle()

local fixtures = vim.fn.getcwd() .. "/tests/fixtures/dcol/"
local wall = vim.env.HYDE_CACHE_HOME .. "/wall.dcol"
local dcols = vim.env.HYDE_CACHE_HOME .. "/dcols/"

local function hl_bg(name)
  local bg = vim.api.nvim_get_hl(0, { name = name, link = false }).bg
  return bg and ("#%06x"):format(bg)
end

local function read(path)
  local file = assert(io.open(path, "rb"))
  local data = file:read "*a"
  file:close()
  return data
end

local function write(path, data)
  local file = assert(io.open(path, "wb"))
  file:write(data)
  file:close()
end

local function use_theme(name)
  require("nvconfig").base46.theme = name
  require("theme_cache").load()
end

local function wait_for(want)
  return vim.wait(3000, function()
    return hl_bg "Normal" == want
  end, 50)
end

-- HyDE's layout: wall.dcol is a symlink into dcols/<hash>.dcol, repointed
-- with `ln -fs` (wallpaper/core.sh), which unlinks and then symlinks
vim.fn.mkdir(dcols, "p")
write(dcols .. "dark.dcol", read(fixtures .. "dark.dcol"))
write(dcols .. "light.dcol", read(fixtures .. "light.dcol"))
-- same size and mtime as dark.dcol, one colour different
local twin = read(fixtures .. "dark.dcol"):gsub('dcol_pry1="000000"', 'dcol_pry1="101010"')
write(dcols .. "twin.dcol", twin)
local stat = vim.uv.fs_stat(dcols .. "dark.dcol")
vim.uv.fs_utime(dcols .. "twin.dcol", stat.atime.sec, stat.mtime.sec)
vim.uv.fs_utime(dcols .. "dark.dcol", stat.atime.sec, stat.mtime.sec)

local function link(target)
  vim.uv.fs_unlink(wall)
  assert(vim.uv.fs_symlink(dcols .. target, wall))
end

-- palette parsing ------------------------------------------------------------
local P = require "wallbash.palette"
local dark = P.read(fixtures .. "dark.dcol")
T.eq(dark.dcol_pry1, "#000000", "reads pry1")
T.eq(dark.dcol_txt1, "#ffffff", "reads txt1")
T.eq(dark.mode, "dark", "reads mode")
T.eq(dark.dcol_pry1_rgba, nil, "skips rgba keys")
T.eq(P.read(fixtures .. "missing.dcol"), nil, "missing file is nil")
T.eq(P.path(), wall, "path follows HYDE_CACHE_HOME")

-- palette to base46 tables ---------------------------------------------------
for _, name in ipairs { "dark", "light", "truncated" } do
  local t = P.to_base46(P.read(fixtures .. name .. ".dcol"))
  T.ok(vim.tbl_count(t.base_30) >= 30, name .. ": full base_30")
  T.eq(vim.tbl_count(t.base_16), 16, name .. ": full base_16")
  for _, slot in ipairs { "base05", "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F" } do
    T.ok(P.contrast(t.base_16[slot], t.base_16.base00) >= 4.5, name .. ": " .. slot .. " readable")
  end
  -- base46 paints Comment and @comment with base_30.grey_fg (integrations/defaults.lua:15)
  T.ok(P.contrast(t.base_30.grey_fg, t.base_16.base00) >= 3.0, name .. ": comments readable")
end
T.eq(P.to_base46(P.read(fixtures .. "light.dcol")).type, "light", "light palette gives a light theme")
T.eq(P.to_base46(P.read(fixtures .. "dark.dcol")).base_16.base00, "#000000", "background is pry1")
T.eq(P.to_base46(nil).base_30.black, "#0B0E14", "no HyDE: ayu_dark fallback")

-- the reported bug: a theme picked in the picker is never overridden ---------
use_theme "ayu_dark"
T.eq(hl_bg "Normal", "#0b0e14", "ayu_dark Normal survives a wall.dcol being present")
T.eq(hl_bg "St_NormalMode", "#43b0e6", "statusline is ayu_dark too")

-- stale cache: palette changes while Neovim was closed are picked up --------
link "dark.dcol"
use_theme "wallbash"
T.eq(hl_bg "Normal", "#000000", "wallbash Normal is the HyDE background")
link "light.dcol"
require("theme_cache").load()
T.eq(hl_bg "Normal", "#9be9f7", "repointed link picked up at load")
link "dark.dcol"
require("theme_cache").load()
link "twin.dcol"
require("theme_cache").load()
T.eq(hl_bg "Normal", "#101010", "a target with the same size and mtime still counts as a change")

-- a wiped cache dir (fresh install, cleared ~/.local/share) compiles instead
-- of crashing init.lua on a missing file
link "light.dcol"
vim.fn.delete(vim.g.base46_cache, "rf")
require("theme_cache").load()
T.ok(vim.uv.fs_stat(vim.g.base46_cache .. "defaults") ~= nil, "empty cache gets compiled")
T.eq(hl_bg "Normal", "#9be9f7", "and loads the right colors")

-- live follow, no restart. No watch() call here: lua/autocmds.lua must have
-- started it at startup.
for i, target in ipairs { "dark.dcol", "light.dcol", "dark.dcol" } do
  link(target)
  T.ok(wait_for(target == "dark.dcol" and "#000000" or "#9be9f7"), ("live follow %d: %s applied"):format(i, target))
end
-- HyDE's color shuffle rewrites the linked file in place, inside dcols/
write(dcols .. "dark.dcol", twin)
T.ok(wait_for "#101010", "live follow: in-place rewrite of the linked file applied")

use_theme "ayu_dark"
link "light.dcol"
vim.wait(800)
T.eq(hl_bg "Normal", "#0b0e14", "watcher leaves other themes alone")

-- any other base46 setting in chadrc.lua changed while Neovim was closed
-- (integrations, hl_add, hl_override...) also invalidates the compiled cache
local conf = require("nvconfig").base46
use_theme "ayu_dark"
table.insert(conf.integrations, "notify")
-- base46 copies the integration list when its module loads, which at a real
-- startup is always after chadrc.lua changed; reload it to match
require("plenary.reload").reload_module "base46"
require("theme_cache").load()
T.ok(vim.uv.fs_stat(vim.g.base46_cache .. "notify") ~= nil, "a newly listed integration gets compiled")
conf.hl_add.ChadvimStampProbe = { fg = "red" }
require("theme_cache").load()
T.ok(next(vim.api.nvim_get_hl(0, { name = "ChadvimStampProbe" })) ~= nil, "a new hl_add group gets compiled")

-- NvChad's picker renames the theme with a file-wide gsub over chadrc.lua, so
-- no theme name may appear there except the active one, once
local chadrc = read(vim.fn.stdpath "config" .. "/lua/chadrc.lua")
local active = require("chadrc").base46.theme
T.eq(active, "wallbash", "wallbash is the default theme")
for _, theme in ipairs(require("nvchad.utils").list_themes()) do
  local _, count = chadrc:gsub(vim.pesc(theme), "")
  T.eq(count, theme == active and 1 or 0, "chadrc.lua mentions theme " .. theme)
end

T.done()
