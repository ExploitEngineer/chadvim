-- Loads the compiled base46 highlights at startup, recompiling first when the
-- cache no longer matches what chadrc.lua asks for.
--
-- base46 only compiles when something tells it to (the theme picker, saving
-- chadrc.lua inside Neovim). Anything that happens while Neovim is closed (a
-- HyDE theme switch rewriting wall.dcol, editing chadrc.lua elsewhere, a git
-- switch) would otherwise leave the old colours in the cache. A stamp file
-- beside the compiled files records what they were built from.
local M = {}

local function stamp_file()
  return vim.g.base46_cache .. "chadvim_stamp"
end

local function read(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local text = file:read "*a"
  file:close()
  return text
end

local function write(path, text)
  local file = io.open(path, "w")
  if file then
    file:write(text)
    file:close()
  end
end

--- What the compiled cache must have been built from for `theme`.
function M.stamp(theme)
  if theme ~= "wallbash" then
    return theme
  end
  -- HyDE's wall.dcol is a symlink into dcols/, repointed per wallpaper: the
  -- target path tells two cached palettes apart even at equal size and mtime
  local path = require("wallbash.palette").path()
  local real, stat = vim.uv.fs_realpath(path), vim.uv.fs_stat(path)
  if not (real and stat) then
    return theme .. ":no-palette"
  end
  return ("%s:%s:%d:%d.%d"):format(theme, real, stat.size, stat.mtime.sec, stat.mtime.nsec)
end

--- Recompile every integration and apply it, then record the stamp.
function M.compile()
  package.loaded["themes.wallbash"] = nil -- re-read wall.dcol
  require("base46").load_all_highlights()
  write(stamp_file(), M.stamp(require("nvconfig").base46.theme))
end

local link_watcher, target_watcher, target_dir, debounce

--- Live follow: repaint when HyDE changes the palette, while the active theme
--- is wallbash.
---
--- HyDE changes it two ways: repointing the wall.dcol symlink with `ln -fs`
--- (unlink, then symlink: a watch on the file itself would die), and rewriting
--- the linked dcols/<hash>.dcol in place (colour shuffle). So this watches the
--- link's directory, and the directory of whatever the link points at.
function M.watch()
  if link_watcher then
    return
  end
  local palette = require "wallbash.palette"
  local path = palette.path()
  local dir, name = vim.fs.dirname(path), vim.fs.basename(path)
  if not vim.uv.fs_stat(dir) then
    return -- no HyDE on this machine
  end
  debounce = assert(vim.uv.new_timer())

  local follow_target

  local function changed()
    -- one HyDE switch touches the files more than once
    debounce:start(200, 0, function()
      vim.schedule(function()
        follow_target()
        if require("nvconfig").base46.theme ~= "wallbash" or palette.read(path) == nil then
          return -- another theme, or mid-write: keep the current colours
        end
        M.compile()
        -- what NvChad's picker does after a reload, for its own UI
        pcall(function()
          require("plenary.reload").reload_module "volt.highlights"
          require "volt.highlights"
        end)
      end)
    end)
  end

  follow_target = function()
    local real = vim.uv.fs_realpath(path)
    local tdir = real and vim.fs.dirname(real)
    if not tdir or tdir == dir or tdir == target_dir then
      return
    end
    if target_watcher then
      target_watcher:stop()
    else
      target_watcher = assert(vim.uv.new_fs_event())
    end
    target_dir = tdir
    target_watcher:start(tdir, {}, function(err, filename)
      local current = vim.uv.fs_realpath(path)
      if not err and current and filename == vim.fs.basename(current) then
        changed()
      end
    end)
  end

  link_watcher = assert(vim.uv.new_fs_event())
  link_watcher:start(dir, {}, function(err, filename)
    if not err and filename == name then
      changed()
    end
  end)
  follow_target()
end

--- Startup entry point: replaces NvChad's plain dofile of the cache.
function M.load()
  local want = M.stamp(require("nvconfig").base46.theme)
  if read(stamp_file()) ~= want or not vim.uv.fs_stat(vim.g.base46_cache .. "defaults") then
    M.compile()
    return
  end
  dofile(vim.g.base46_cache .. "defaults")
  dofile(vim.g.base46_cache .. "statusline")
end

return M
