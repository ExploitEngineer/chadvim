-- compiler-explorer compiles on godbolt.org, and uploads only the current
-- buffer to do it. Any `#include "local.h"` therefore fails with
-- 'types.h' file not found, whichever compiler is chosen, because the header
-- never leaves this machine.
--
-- godbolt's compile API takes a `files` array alongside `source` and resolves
-- quoted includes against it, but the plugin never fills that field in. So
-- walk the quoted includes out of the buffer, resolve them the way the
-- preprocessor does, and attach them.
--
-- Angle-bracket includes are deliberately skipped: <stdio.h> and friends are
-- the toolchain's own headers and godbolt already has them.
--
-- NOTE this widens what gets uploaded: not just the buffer now, but every
-- project header it reaches, transitively.

local M = {}

-- Bounds, so a buffer at the top of a deep include tree cannot quietly push a
-- whole source tree over the wire.
M.max_files = 32
M.max_bytes = 256 * 1024

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local contents = fd:read "*a"
  fd:close()
  return contents
end

local function quoted_includes(text)
  local names = {}
  for line in text:gmatch "[^\r\n]+" do
    -- only `#include "..."`; the spacing is loose because `#  include` is legal
    local name = line:match '^%s*#%s*include%s*"([^"]+)"'
    if name then
      table.insert(names, name)
    end
  end
  return names
end

--- Collect the local headers `source` pulls in, following headers that include
--- further headers, and return them in godbolt's `files` shape.
--- @param source string contents of the buffer being compiled
--- @param dir string directory the buffer lives in
function M.collect(source, dir)
  local files, seen, total = {}, {}, 0
  local queue = { { text = source, dir = dir } }

  while #queue > 0 and #files < M.max_files do
    local item = table.remove(queue, 1)

    for _, name in ipairs(quoted_includes(item.text)) do
      if not seen[name] then
        seen[name] = true

        -- quoted includes resolve against the directory of the file doing the
        -- including, so a header in a subdir can include its own siblings
        local path = vim.fs.normalize(item.dir .. "/" .. name)
        local contents = read_file(path)

        if contents and total + #contents <= M.max_bytes then
          total = total + #contents

          -- filename must be the include string verbatim: that is the key
          -- godbolt matches the #include against, not the path on disk
          table.insert(files, { filename = name, contents = contents })
          table.insert(queue, { text = contents, dir = vim.fs.dirname(path) })
        end
      end
    end
  end

  return files
end

function M.setup(opts)
  require("compiler-explorer").setup(opts)

  local rest = require "compiler-explorer.rest"
  local build_body = rest.create_compile_body

  rest.create_compile_body = function(args)
    local body = build_body(args)

    -- runs before the asm window is created, so the current buffer is still
    -- the source being compiled
    local files = M.collect(args.source or body.source or "", vim.fn.expand "%:p:h")
    if #files > 0 then
      body.files = files
    end

    return body
  end
end

return M
