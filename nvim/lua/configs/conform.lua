local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    cpp = { "clang-format" },
    python = { "flake8" },
    xml = { "lemminx" },
    markdown = { "mdformat" },
    json = { "prettier" },
    html = { "prettier" },
    cs = { "csharpier" },
    -- css = { "prettier" },
  },

  format_after_save = {
    lsp_format = "fallback",
  },
  notify_on_error = true,
  notify_no_formatters = true,
}

return options
