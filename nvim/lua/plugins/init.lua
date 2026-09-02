return {
  {
    "stevearc/conform.nvim",
    dependencies = {
      { "neovim/nvim-lspconfig" },
      { "nvim-lua/plenary.nvim" },
      { "williamboman/mason.nvim" },
    },
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          -- FormatDisable! will disable formatting just for this buffer
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })

      local conform_opts = require "configs.conform"
      conform_opts.format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 3000, lsp_format = "fallback" }
      end
      require("conform").setup(conform_opts)
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  {
    "williamboman/mason.nvim",
    opts = {
      PATH = "prepend", -- "skip" seems to cause the spawning error
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "clangd",
        "rust-analyzer",
        "gopls",
        "pyright",
      },
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
      -- Only use nvim-treesitter for parser/query management.
      -- Highlighting is driven by Neovim's native vim.treesitter.start()
      -- via the FileType autocmd in options.lua, which avoids the
      -- nvim-treesitter highlight module that is incompatible with Neovim 0.12.
      require("nvim-treesitter.configs").setup {
        ensure_installed = {
          "vim",
          "lua",
          "luadoc",
          "printf",
          "vimdoc",
          "rust",
          "go",
          "cpp",
          "python",
          "xml",
          "c_sharp",
          "html",
          "css",
          "typescript",
          "javascript",
        },
        highlight = { enable = false },
        indent = { enable = true },
      }
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    event = "VeryLazy",
    opts = function()
      return require "configs.null-ls"
    end,
  },
  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup()
    end,
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },
  {
    "saecki/crates.nvim",
    ft = { "rust", "toml" },
    config = function(_, opts)
      local crates = require "crates"
      crates.setup(opts)
      crates.show()
    end,
  },
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = {},
  },
  -- {
  --   "seblj/roslyn.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     local on_attach = require("nvchad.configs.lspconfig").on_attach
  --     local capabilities = require("nvchad.configs.lspconfig").capabilities
  --     require("roslyn").setup {
  --       broad_search = true,
  --       lock_target = true,
  --       -- Auto-prompt when multiple .sln files found (instead of requiring :Roslyn target)
  --       choose_target = function(targets)
  --         local choice
  --         vim.ui.select(targets, {
  --           prompt = "Select Roslyn target:",
  --           format_item = function(item)
  --             return vim.fs.basename(item)
  --           end,
  --         }, function(selected)
  --           choice = selected
  --         end)
  --         return choice
  --       end,
  --     }
  --     vim.lsp.config("roslyn", {
  --       on_attach = on_attach,
  --       capabilities = capabilities,
  --       settings = {
  --         ["csharp|inlay_hints"] = {
  --           csharp_enable_inlay_hints_for_implicit_object_creation = true,
  --           csharp_enable_inlay_hints_for_implicit_variable_types = false,
  --           csharp_enable_inlay_hints_for_lambda_parameter_types = true,
  --           csharp_enable_inlay_hints_for_types = true,
  --           dotnet_enable_inlay_hints_for_indexer_parameters = false,
  --           dotnet_enable_inlay_hints_for_literal_parameters = false,
  --           dotnet_enable_inlay_hints_for_object_creation_parameters = true,
  --           dotnet_enable_inlay_hints_for_other_parameters = true,
  --           dotnet_enable_inlay_hints_for_parameters = true,
  --           dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
  --           dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
  --           dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
  --         },
  --         ["csharp|code_lens"] = {
  --           dotnet_enable_references_code_lens = true,
  --         },
  --         ["csharp|formatting"] = {
  --           dotnet_organize_imports_on_format = true,
  --         },
  --       },
  --     })
  --   end,
  -- },
  -- render-markdown.nvim disabled: requires markdown treesitter injection
  -- which triggers neovim/neovim#39032 on Neovim 0.12.x. Re-enable once fixed.
  -- {
  --     "MeanderingProgrammer/render-markdown.nvim",
  --     dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  --     ft = { "markdown" },
  --     opts = {},
  -- },
  {
    "sphamba/smear-cursor.nvim",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.5,
      distance_stop_animating = 0.5,
    },
  },
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    config = function()
      require("lspsaga").setup {}
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- optional
      "nvim-tree/nvim-web-devicons", -- optional
    },
  },
  {
    "karb94/neoscroll.nvim",
    opts = {},
  },
  {
    "vhyrro/luarocks.nvim",
    priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
    config = true,
  },
  {
    "aznhe21/actions-preview.nvim",
    config = function()
      require("actions-preview").setup {
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.8,
            height = 0.9,
            prompt_position = "top",
            preview_cutoff = 20,
            preview_height = function(_, _, max_lines)
              return max_lines - 15
            end,
          },
        },
      }
    end,
  },
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "1.*",
    opts = {},
  },
  -- {
  --     "unblevable/quick-scope",
  --     event = "VeryLazy",
  --     config = function()
  --         vim.g.qs_highlight_on_keys = { 'f', 'F', 't', 'T' }
  --         vim.api.nvim_set_hl(0, 'QuickScopePrimary', { fg = '#4287f5', underline = true })
  --         vim.api.nvim_set_hl(0, 'QuickScopeSecondary', { fg = '#84659c', underline = true })
  --     end
  -- }
}
