-- base46 theme that follows HyDE: colours come from ~/.cache/hyde/wall.dcol,
-- the palette HyDE generates for kitty, waybar, rofi and the rest. Without
-- HyDE it falls back to a fixed theme (see lua/wallbash/palette.lua).
--
-- Re-read on every compile: lua/theme_cache.lua drops this module from
-- package.loaded first, and recompiles when wall.dcol changes.
local palette = require "wallbash.palette"

local M = palette.to_base46(palette.read(palette.path()))

return require("base46").override_theme(M, "wallbash")
