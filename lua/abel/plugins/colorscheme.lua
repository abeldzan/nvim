return {
  "projekt0n/github-nvim-theme",
  name = "github-theme",
  lazy = false,
  priority = 1000,
  config = function()
    require("github-theme").setup({
      options = {
        transparent = false,
      },
    })

    local function apply_github_theme()
      if vim.o.background == "light" then
        vim.cmd.colorscheme("github_light")
      else
        vim.cmd.colorscheme("github_dark")
      end

      -- Keep statusline plain/minimal.
      vim.api.nvim_set_hl(0, "StatusLine", { fg = "NONE", bg = "NONE", bold = false })
      vim.api.nvim_set_hl(0, "StatusLineNC", { fg = "NONE", bg = "NONE", bold = false })
    end

    apply_github_theme()

    vim.api.nvim_create_user_command("LoadTheme", function()
      apply_github_theme()
      vim.notify("Loaded GitHub " .. vim.o.background .. " theme", vim.log.levels.INFO)
    end, {})
  end,
}
