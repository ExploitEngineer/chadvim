local dap = require "dap"
local dapui = require "dapui"
local mason = vim.fn.stdpath "data" .. "/mason"

dapui.setup()

dap.listeners.after.event_initialized["dapui"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui"] = function()
  dapui.close()
end

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })

-- C/C++ — rust debugging goes through rustaceanvim's own codelldb wiring
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    -- if the mason shim misbehaves, fall back to
    -- mason/packages/codelldb/extension/adapter/codelldb
    command = mason .. "/bin/codelldb",
    args = { "--port", "${port}" },
  },
}

dap.configurations.c = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}
dap.configurations.cpp = dap.configurations.c

-- Python
require("dap-python").setup(mason .. "/packages/debugpy/venv/bin/python")

-- JS/TS — mason's js-debug-adapter ships a pwa-node server
dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = mason .. "/bin/js-debug-adapter",
    args = { "${port}" },
  },
}

for _, ft in ipairs { "javascript", "typescript", "javascriptreact", "typescriptreact" } do
  dap.configurations[ft] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }
end

-- project-local .vscode/launch.json files are picked up automatically by nvim-dap
