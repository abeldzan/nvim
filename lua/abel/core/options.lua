vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false

-- search settings
opt.incsearch = true -- show search matches as you type
opt.hlsearch = true -- highlight all matches
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

opt.cursorline = true
opt.completeopt = "menuone,noselect,noinsert"
opt.termguicolors = true
opt.background = "dark" -- switch to "light" for GitHub light
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- In SSH/dev environments, use OSC52 so yanks reach local system clipboard.
if vim.env.SSH_TTY then
  local function osc52_copy(reg)
    local clipboard = reg == "+" and "c" or "p"
    return function(lines)
      local text = table.concat(lines, "\n")
      local b64 = vim.base64.encode(text)
      local seq = string.format("\27]52;%s;%s\27\\", clipboard, b64)

      -- tmux/screen require DCS passthrough for OSC52.
      if vim.env.TMUX then
        seq = "\27Ptmux;\27" .. seq:gsub("\27", "\27\27") .. "\27\\"
      elseif vim.env.STY then
        seq = "\27P" .. seq .. "\27\\"
      end

      vim.api.nvim_ui_send(seq)
    end
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52_copy("+"),
      ["*"] = osc52_copy("*"),
    },
    -- OSC52 paste is not consistently supported across terminals/tmux.
    -- Keep paste local to avoid hangs/timeouts.
    paste = {
      ["+"] = function()
        return vim.split(vim.fn.getreg("+"), "\n")
      end,
      ["*"] = function()
        return vim.split(vim.fn.getreg("*"), "\n")
      end,
    },
  }
end

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- undodir
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true
