require "nvchad.options"

-- add yours here!

vim.lsp.inlay_hint.enable()

local o = vim.o
vim.opt.scrolloff = 8
vim.opt.termguicolors = true
vim.opt.smartindent = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.fixeol = false
vim.opt.colorcolumn = "120"
vim.opt.wrap = false

o.number = true          -- Print the line number in front of each line
o.relativenumber = true  -- Show the line number relative to the line with the cursor in front of each line.
o.cursorlineopt = 'both' -- to enable cursorline!
o.cb = ''
o.autoindent = true      -- Copy indent from current line when starting a new line.
o.cursorline = true      -- Highlight the screen line of the cursor with CursorLine.
o.expandtab = true       -- In Insert mode: Use the appropriate number of spaces to insert a <Tab>.
o.shiftwidth = 4         -- Number of spaces to use for each step of (auto)indent.
o.tabstop = 4            -- Number of spaces that a <Tab> in the file counts for.
o.encoding = "utf-8"     -- Sets the character encoding used inside Vim.
o.fileencoding = "utf-8" -- Sets the character encoding for the file of this buffer.
o.ruler = true           -- Show the line and column number of the cursor position, separated by a comma.
o.mouse = "a"            -- Enable the use of the mouse. "a" you can use on all modes
o.title = true           -- When on, the title of the window will be set to the value of 'titlestring'
--o.hidden = true -- When on a buffer becomes hidden when it is |abandon|ed
o.ttimeoutlen = 0        -- The time in milliseconds that is waited for a key code or mapped key sequence to complete.
o.wildmenu = true        -- When 'wildmenu' is on, command-line completion operates in an enhanced mode.
o.showcmd = true         -- Show (partial) command in the last line of the screen. Set this option off if your terminal is slow.
o.showmatch = true       -- When a bracket is inserted, briefly jump to the matching one.
o.inccommand =
"split"                  -- When nonempty, shows the effects of :substitute, :smagic, :snomagic and user commands with the :command-preview flag as you type.

-- Use Neovim's native treesitter highlighting (bypasses nvim-treesitter's
-- highlight module, which is incompatible with Neovim 0.12).
-- Falls back to regex syntax if no parser is available.
-- Markdown is explicitly excluded — see workaround below.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("NativeTreesitterHighlight", { clear = true }),
    callback = function(ev)
        if vim.bo[ev.buf].filetype == "markdown" then return end
        if not pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].syntax = "on"
        end
    end,
})

-- WORKAROUND: Neovim 0.12.x has a treesitter regression where injected language
-- predicates call node:range() on a nil node — see neovim/neovim#39032. Markdown
-- with fenced code blocks triggers it on every redraw (including LSP hover, signature
-- help, and any other float that sets ft=markdown). Disable TS for markdown everywhere
-- by intercepting vim.treesitter.start itself — autocmds alone are insufficient because
-- vim.lsp.util calls treesitter.start() directly after the FileType event fires.
-- Remove once nvim ships a fix.
do
    local orig_ts_start = vim.treesitter.start
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.treesitter.start = function(bufnr, lang, ...)
        bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
        local ft = vim.bo[bufnr].filetype
        if ft == "markdown" or lang == "markdown" or lang == "markdown_inline" then
            return
        end
        return orig_ts_start(bufnr, lang, ...)
    end
end

local md_workaround_group = vim.api.nvim_create_augroup("MarkdownNoTreesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = md_workaround_group,
    pattern = "markdown",
    callback = function()
        pcall(vim.treesitter.stop, 0)
        vim.bo.syntax = "on"
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = md_workaround_group,
    callback = function(ev)
        if vim.bo[ev.buf].filetype == "markdown" then
            pcall(vim.treesitter.stop, ev.buf)
            vim.bo[ev.buf].syntax = "on"
        end
    end,
})
