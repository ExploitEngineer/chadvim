-- Colour codes are painted by nvim-highlight-colors; nvim-colorizer is gone.
local T = dofile "tests/helpers.lua"
T.settle()

T.eq(require("lazy.core.config").plugins["nvim-colorizer.lua"], nil, "nvim-colorizer is gone")

local file = vim.fn.tempname() .. ".css"
vim.fn.writefile({ "a { color: #ff0000; background: rgb(0, 128, 255); }" }, file)
vim.cmd.edit(file)

local function painted()
  local count = 0
  for name, ns in pairs(vim.api.nvim_get_namespaces()) do
    if name:find("highlight", 1, true) and name:find("color", 1, true) then
      count = count + #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
    end
  end
  return count
end
T.ok(
  vim.wait(3000, function()
    return painted() >= 2
  end, 50),
  "the hex and the rgb() colour are both painted"
)

-- ...and by nothing else: NvChad's Colorify and Neovim's LSP document colour
-- would each paint the same value again (two swatches plus a background fill)
vim.wait(5000, function()
  return #vim.lsp.get_clients { bufnr = 0 } > 0
end, 50)
vim.wait(2000) -- give the LSP colour request time to come back
local swatches, fills = 0, 0
for _, ns in pairs(vim.api.nvim_get_namespaces()) do
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
    local details = mark[4]
    if details.virt_text and details.virt_text[1][1]:find("󱓻", 1, true) then
      swatches = swatches + 1
    end
    if details.hl_group and tostring(details.hl_group):find "^LspDocumentColor" then
      fills = fills + 1
    end
  end
end
T.eq(swatches, 2, "one swatch per colour (two colours)")
T.eq(fills, 0, "no LSP document colour fill")

T.done()
