-- File references for agent prompts: `path#L12` or `path#L12-L20` (relative
-- to the cwd when the file is under it), and fenced code blocks whose info
-- string carries the same reference. Paste either into Claude to point it at
-- exact lines. Keys: <leader>yf / <leader>yp / <leader>yc in lua/mappings.lua.
local M = {}

local function file_path(bufnr, absolute)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or vim.bo[bufnr].buftype ~= "" then
    return nil
  end
  name = vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
  if absolute then
    return name
  end
  return vim.fs.relpath(vim.fn.getcwd(), name) or name
end

local function line_suffix(l1, l2)
  if not l2 or l1 == l2 then
    return "#L" .. l1
  end
  if l2 < l1 then
    l1, l2 = l2, l1
  end
  return ("#L%d-L%d"):format(l1, l2)
end

---@return string|nil reference, nil when the buffer is not a file
function M.relative_ref(bufnr, l1, l2)
  local path = file_path(bufnr, false)
  return path and path .. line_suffix(l1, l2)
end

---@return string|nil reference, nil when the buffer is not a file
function M.absolute_ref(bufnr, l1, l2)
  local path = file_path(bufnr, true)
  return path and path .. line_suffix(l1, l2)
end

---@return string|nil fenced block, nil when the buffer is not a file
function M.code_block(bufnr, l1, l2)
  if l2 < l1 then
    l1, l2 = l2, l1
  end
  local ref = M.relative_ref(bufnr, l1, l2)
  if not ref then
    return nil
  end
  local out = { ("```%s %s"):format(vim.bo[bufnr].filetype, ref) }
  vim.list_extend(out, vim.api.nvim_buf_get_lines(bufnr, l1 - 1, l2, false))
  table.insert(out, "```")
  return table.concat(out, "\n")
end

return M
