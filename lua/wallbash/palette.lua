-- Turns HyDE's wallbash palette (wall.dcol) into a base46 theme table.
--
-- wall.dcol holds four colour groups. Each has a primary (dcol_pryN), a text
-- colour (dcol_txtN) and a nine-step accent ramp (dcol_Nxa1..9). The ramp runs
-- away from the background, so steps 7 and 8 are the high-contrast end in both
-- dark and light palettes.
local colors = require "base46.colors"

local M = {}

-- Theme used when there is no HyDE palette, and for the semantic slots (red,
-- green, yellow...) a wallpaper palette can't be trusted to provide.
local FALLBACK = "ayu_dark"

-- base_30 slots that are painted as backgrounds, not text
local BACKGROUNDS = {
  black = true,
  darker_black = true,
  black2 = true,
  one_bg = true,
  one_bg2 = true,
  one_bg3 = true,
  line = true,
  statusline_bg = true,
  lightbg = true,
}

local function fallback()
  return vim.deepcopy(require("base46.themes." .. FALLBACK))
end

function M.path()
  local dir = vim.env.HYDE_CACHE_HOME or ((vim.env.XDG_CACHE_HOME or (vim.env.HOME .. "/.cache")) .. "/hyde")
  return dir .. "/wall.dcol"
end

---@return table<string,string>|nil dcol_* keys to "#rrggbb", plus `mode`
function M.read(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local out = {}
  for line in file:lines() do
    local key, hex = line:match '^(dcol_%w+)="(%x%x%x%x%x%x)"$'
    if key then
      out[key] = "#" .. hex:lower()
    else
      out.mode = out.mode or line:match '^dcol_mode="(%a+)"$'
    end
  end
  file:close()
  return out.dcol_pry1 and out or nil
end

local function channel(c)
  c = c / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

--- WCAG contrast ratio between two "#rrggbb" colours, from 1 to 21.
function M.contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

-- Step `fg` in lightness away from `bg` until the pair reaches `floor`.
local function readable(fg, bg, floor)
  local step = luminance(bg) > 0.5 and -4 or 4
  for _ = 1, 30 do
    if M.contrast(fg, bg) >= floor then
      break
    end
    fg = colors.change_hex_lightness(fg, step)
  end
  return fg
end

function M.to_base46(dcol)
  local base = fallback()
  if not dcol then
    return base
  end

  local light = dcol.mode == "light" or (dcol.mode == nil and luminance(dcol.dcol_pry1) > 0.5)
  local sign = light and -1 or 1
  local bg = dcol.dcol_pry1

  -- background ramp: lighter steps on a dark theme, darker on a light one
  local function shade(percent)
    return colors.change_hex_lightness(bg, sign * percent)
  end

  local function accent(group, step, slot)
    return dcol[("dcol_%dxa%d"):format(group, step)] or base.base_30[slot]
  end

  local b30 = {
    black = bg,
    darker_black = shade(-3),
    black2 = shade(3),
    one_bg = shade(6),
    one_bg2 = shade(9),
    one_bg3 = shade(12),
    grey = shade(15),
    grey_fg = shade(19),
    grey_fg2 = shade(23),
    light_grey = shade(28),
    line = shade(9),
    statusline_bg = shade(2),
    lightbg = shade(9),
    white = dcol.dcol_txt1 or base.base_30.white,
    blue = accent(1, 8, "blue"),
    nord_blue = accent(1, 7, "nord_blue"),
    purple = accent(2, 8, "purple"),
    dark_purple = accent(2, 7, "dark_purple"),
    cyan = accent(3, 8, "cyan"),
    teal = accent(3, 7, "teal"),
    folder_bg = accent(4, 8, "folder_bg"),
    pmenu_bg = accent(4, 7, "pmenu_bg"),
  }
  for _, slot in ipairs { "red", "baby_pink", "pink", "green", "vibrant_green", "yellow", "sun", "orange" } do
    b30[slot] = base.base_30[slot]
  end

  -- every other slot is drawn as text on the background, or (pmenu_bg,
  -- folder_bg) carries `black` text itself: make each readable against it,
  -- the greys (comments, line numbers) a little softer
  for slot, value in pairs(b30) do
    if not BACKGROUNDS[slot] then
      b30[slot] = readable(value, bg, slot:match "^grey" and 3.0 or 4.5)
    end
  end

  local b16 = {
    base00 = bg,
    base01 = b30.one_bg,
    base02 = b30.one_bg2,
    base03 = b30.one_bg3,
    base04 = b30.grey,
    base05 = b30.white,
    base06 = b30.white,
    base07 = b30.white,
    base08 = b30.white,
    base09 = accent(3, 8, "cyan"),
    base0A = accent(2, 8, "purple"),
    base0B = accent(4, 8, "folder_bg"),
    base0C = accent(3, 7, "teal"),
    base0D = accent(1, 8, "blue"),
    base0E = accent(2, 7, "dark_purple"),
    base0F = accent(4, 7, "pmenu_bg"),
  }
  for slot, value in pairs(b16) do
    if slot ~= "base00" and slot ~= "base01" and slot ~= "base02" and slot ~= "base03" and slot ~= "base04" then
      b16[slot] = readable(value, bg, 4.5)
    end
  end

  return { base_30 = b30, base_16 = b16, type = light and "light" or "dark", polish_hl = {} }
end

return M
