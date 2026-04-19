return {
  "chipsenkbeil/distant.nvim",
  branch = "v0.3",
  config = function()
    require("distant"):setup({})

    local keymap = vim.keymap
    keymap.set("n", "<leader>dc", "<cmd>DistantConnect<cr>", { desc = "Distant connect" })
    keymap.set("n", "<leader>dl", "<cmd>DistantLaunch<cr>", { desc = "Distant launch" })
    keymap.set("n", "<leader>ds", "<cmd>DistantSessionSelect<cr>", { desc = "Distant sessions" })
    keymap.set("n", "<leader>de", "<cmd>DistantOpen<cr>", { desc = "Distant open file" })
  end,
}
