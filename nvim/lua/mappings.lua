require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

map("n", "<leader>w", vim.cmd.w)
map("n", "<leader>q", vim.cmd.q)
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
map("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
map({ "n", "v" }, "<leader>y", [["+y]])
map("n", "<leader>Y", [["+Y]])
map({ "n", "v" }, "<leader>p", [["+p]])
map("n", "<leader>P", [["+P]])
map("n", "<leader><leader>", function()
    vim.cmd "so"
end)
map("n", "<C-a>", "ggVG")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
map("n", "d", '"_d')
map("n", "<leader>rcu", function()
    require("crates").upgrade_all_crates()
end)
map("n", "<C-c>", "")
map("n", "<leader>b", "<C-v>")
map("n", "<leader>d", function()
    vim.diagnostic.open_float({ scope = "line" })
end)

map("n", "<leader>cl", vim.lsp.codelens.refresh)
map("n", "<leader>cc", vim.lsp.codelens.clear)
map("n", "<leader>a", vim.lsp.buf.code_action)
map({ "v", "n" }, "<leader>gf", require("actions-preview").code_actions)
map("v", "<", "<gv")
map("v", ">", ">gv")
map("n", "qj", "@q")

