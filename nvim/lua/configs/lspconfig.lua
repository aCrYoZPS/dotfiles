require("nvchad.configs.lspconfig").defaults()

vim.lsp.enable { "rust_analyzer" }

local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local util = require "lspconfig/util"

vim.lsp.config("tinymist", {
  settings = {
    formatterMode = "typstyle",
  },
})
vim.lsp.enable "tinymist"

vim.lsp.config("gopls", {
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/codeLens" then
      vim.lsp.codelens.refresh() -- Initial refresh
      -- Auto-refresh on events (e.g., saving, cursor hold)
      vim.api.nvim_create_autocmd({ "BufWritePost", "CursorHold" }, {
        buffer = bufnr,
        callback = vim.lsp.codelens.refresh,
      })
    end
    on_attach(client, bufnr)
  end,
  capabilities = capabilities,
  on_init = on_init,
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = util.root_pattern("go.work", "go.mod", ".git"),
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        unusedparams = true,
      },
    },
  },
})
vim.lsp.enable "gopls"

vim.lsp.enable "clangd"
-- vim.lsp.config("clangd",
--     {
--         capabilities = capabilities,
--         on_attach = on_attach,
--         on_init = on_init,
--         root_dir = util.root_pattern ".clangd",
--         cmd = {
--             "clangd",
--             "--background-index",
--             "--clang-tidy",
--             "--completion-style=detailed",
--             "--header-insertion=iwyu",
--             "--query-driver=clang++"
--         },
--         filetypes = { "cpp", "c" },
--     }
-- )

vim.lsp.config("rust_analyzer", {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_dir = util.root_pattern("Cargo.toml", "rust-project.json", ".git"),
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
    },
  },
})

vim.lsp.enable { "rust_analyzer" }

vim.lsp.config("lua_ls", {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          -- Depending on the usage, you might want to add additional paths here.
          -- "${3rd}/luv/library"
          -- "${3rd}/busted/library",
        },
        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
        -- library = vim.api.nvim_get_runtime_file("", true)
      },
    })
  end,
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/codeLens" then
      vim.lsp.codelens.refresh() -- Initial refresh
      -- Auto-refresh on events (e.g., saving, cursor hold)
      vim.api.nvim_create_autocmd({ "BufWritePost", "CursorHold" }, {
        buffer = bufnr,
        callback = vim.lsp.codelens.refresh,
      })
    end
    on_attach(client, bufnr)
  end,
  capabilities = capabilities,
  filetypes = { "lua" },
  settings = {
    Lua = {},
  },
})
vim.lsp.enable "lua_ls"

vim.lsp.config("csharp_ls", {
  on_attach = on_attach,
  capabilities = capabilities,
  on_init = on_init,
  filetypes = { "cs" },
})
vim.lsp.enable "csharp_ls"

vim.lsp.config("pylsp", {
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/codeLens" then
      vim.lsp.codelens.refresh() -- Initial refresh
      -- Auto-refresh on events (e.g., saving, cursor hold)
      vim.api.nvim_create_autocmd({ "BufWritePost", "CursorHold" }, {
        buffer = bufnr,
        callback = vim.lsp.codelens.refresh,
      })
    end
    on_attach(client, bufnr)
  end,
  capabilities = capabilities,
  on_init = on_init,
  filetypes = { "python" },
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = {
          maxLineLength = 120,
        },
        flake8 = {
          enabled = true,
          maxLineLength = 120,
        },
      },
    },
  },
})

vim.lsp.enable "pylsp"

vim.lsp.config("markdown_oxide", {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  root_dir = function(fname)
    return util.root_pattern(".git", ".obsidian", ".marksman.toml")(fname) or vim.fn.getcwd()
  end,
  filetypes = { "markdown" },
})
vim.lsp.enable "markdown_oxide"

-- lspconfig.prettier.setup {
--     on_attach = on_attach,
--     on_init = on_init,
--     capabilities = capabilities,
--     filetypes = { "json" },
-- }

vim.lsp.enable "postgres_lsp"
-- lspconfig.postgres_lsp.setup {
--     on_attach = on_attach,
--     on_init = on_init,
--     capabilities = capabilities,
--     filetypes = { "sql" },
-- }

vim.lsp.config("zls", {
  -- https://zigtools.org/zls/configure/
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "zig" },
  settings = {
    zls = {
      semantic_tokens = "partial",
    },
  },
})
vim.lsp.enable "zls"

vim.lsp.config("cssls", {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "css" },
})
vim.lsp.enable "cssls"

vim.lsp.enable "ts_ls"

vim.lsp.config("hls", {
  filetypes = { "haskell", "lhaskell", "cabal" },
})
vim.lsp.enable "hls"

local function get_angularls_cmd()
  local mason_path = vim.fn.stdpath "data" .. "/mason/packages/angular-language-server"
  if vim.fn.isdirectory(mason_path) == 0 then
    return { "ngserver", "--stdio" }
  end
  local project_node_modules = vim.fn.getcwd() .. "/node_modules"
  local probe_locations =
    "C:\\Users\\aCrYoZ\\AppData\\Local\\nvim-data\\mason\\packages\\angular-language-server\\node_modules\\@angular\\language-server"
  if vim.fn.isdirectory(project_node_modules) == 1 then
    probe_locations = probe_locations .. "," .. project_node_modules
  end
  return {
    "node",
    mason_path .. "/node_modules/@angular/language-server/bin/ngserver",
    "--stdio",
    "--tsProbeLocations",
    probe_locations,
    "--ngProbeLocations",
    probe_locations,
  }
end

vim.lsp.config("html", {
  filetypes = { "html", "htmlangular" },
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
})
vim.lsp.enable "html"

vim.lsp.config("angularls", {
  cmd = get_angularls_cmd(),
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
})
vim.lsp.enable "angularls"
