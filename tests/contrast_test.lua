-- Theme pass for the plugins base46 has no colours for (snacks, oil,
-- mini.diff) plus blink: every listed group stays readable (3:1 against what
-- it is drawn on) in wallbash (here the monochrome fixture palette), a dark
-- base46 theme and a light one.
local T = dofile "tests/helpers.lua"
T.settle()
require("lazy").load { plugins = { "blink.cmp", "oil.nvim", "mini.diff" }, wait = true }

local contrast = require("wallbash.palette").contrast

-- group -> the group whose background it is drawn on when it has none
local GROUPS = {
  SnacksPickerMatch = "NormalFloat",
  SnacksPickerDir = "NormalFloat",
  SnacksPickerFile = "NormalFloat",
  SnacksPickerPrompt = "NormalFloat",
  SnacksNotifierInfo = "NormalFloat",
  SnacksNotifierTitleInfo = "NormalFloat",
  OilDir = "NormalFloat",
  OilFile = "NormalFloat",
  BlinkCmpMenu = "NormalFloat",
  BlinkCmpLabelMatch = "BlinkCmpMenu",
  BlinkCmpMenuSelection = "BlinkCmpMenu",
  MiniDiffOverAdd = "Normal",
  MiniDiffOverDelete = "Normal",
  MiniDiffOverChange = "Normal",
}

local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function hex(n)
  return n and ("#%06x"):format(n)
end

local function colors(name)
  local own, under = hl(name), hl(GROUPS[name])
  local normal = hl "Normal"
  local fg = own.fg or under.fg or hl("NormalFloat").fg or normal.fg
  local bg = own.bg or under.bg or hl(GROUPS[under] or "NormalFloat").bg or normal.bg
  if own.reverse then
    fg, bg = bg, fg
  end
  return hex(fg), hex(bg)
end

for _, theme in ipairs { "wallbash", "ayu_dark", "one_light" } do
  require("nvconfig").base46.theme = theme
  require("theme_cache").load()
  for name in pairs(GROUPS) do
    local fg, bg = colors(name)
    if fg and bg then
      local ratio = contrast(fg, bg)
      T.ok(ratio >= 3.0, ("%s: %s %s on %s is %.2f:1"):format(theme, name, fg, bg, ratio))
    else
      T.ok(false, ("%s: %s has no resolvable colours"):format(theme, name))
    end
  end
end

T.done()
