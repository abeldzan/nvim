return {
  "zbirenbaum/copilot.lua",
  event = "VeryLazy",
  config = function()
    local function current_project_root()
      local bufname = vim.api.nvim_buf_get_name(0)
      local start = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
      local git_dir = vim.fs.find(".git", { path = start, upward = true })[1]
      return git_dir and vim.fs.dirname(git_dir) or vim.uv.cwd()
    end

    require("copilot").setup({
      root_dir = current_project_root,
      should_attach = function(bufnr, bufname)
        if not vim.bo[bufnr].buflisted or vim.bo[bufnr].buftype ~= "" then
          return false
        end
        if bufname == "" or vim.fn.filereadable(bufname) == 0 then
          return false
        end
        return true
      end,
      suggestion = {
        auto_trigger = true,
        keymap = {
          -- accept = "<Tab>",
        },
      },
    })
  end,
}
