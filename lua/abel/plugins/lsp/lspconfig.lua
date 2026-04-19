return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    -- import lspconfig utilities
    local root_pattern = require("lspconfig.util").root_pattern

    local function legacy_root_dir(pattern_fn)
      return function(bufnr, on_dir)
        local path = vim.api.nvim_buf_get_name(bufnr)
        local root = pattern_fn(path)
        if root then
          on_dir(root)
        end
      end
    end

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- for conciseness

    -- Neovim 0.11+ compatibility shims for plugins still using old LSP call patterns.
    do
      local make_position_params = vim.lsp.util.make_position_params
      vim.lsp.util.make_position_params = function(window, position_encoding)
        if position_encoding then
          return make_position_params(window, position_encoding)
        end

        local win = window or 0
        local buf = vim.api.nvim_win_get_buf(win)
        local clients = vim.lsp.get_clients({ bufnr = buf })
        local encoding = (clients[1] and clients[1].offset_encoding) or "utf-16"
        return make_position_params(win, encoding)
      end

      local function patch_supports_method(client)
        if client and not client._patched_supports_method then
          client._patched_supports_method = true
          local original_supports_method = client.supports_method
          client.supports_method = function(a, b, c)
            local method, opts

            -- Support both call styles:
            --   client:supports_method(method, opts)
            --   client.supports_method(method, opts)
            if type(a) == "table" and a == client then
              method, opts = b, c
            else
              method, opts = a, b
            end

            local bufnr = nil
            if type(opts) == "table" then
              bufnr = opts.bufnr
            elseif type(opts) == "number" then
              bufnr = opts
            end

            if type(bufnr) ~= "number" then
              bufnr = nil
            end

            if type(method) ~= "string" then
              return false
            end

            return original_supports_method(client, method, bufnr)
          end
        end
      end

      for _, client in ipairs(vim.lsp.get_clients()) do
        patch_supports_method(client)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspCompat", { clear = true }),
        callback = function(ev)
          patch_supports_method(vim.lsp.get_client_by_id(ev.data.client_id))
        end,
      })
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show Hover Information"
        keymap.set("n", "gh", vim.lsp.buf.hover, opts) -- go to declaration

        local function goto_definition()
          local method = vim.lsp.protocol.Methods.textDocument_definition
          local clients = vim.lsp.get_clients({ bufnr = ev.buf })
          local supports_definition = false

          for _, client in ipairs(clients) do
            if client:supports_method(method, ev.buf) then
              supports_definition = true
              break
            end
          end

          if not supports_definition then
            vim.notify("No attached LSP server supports textDocument/definition for this buffer", vim.log.levels.WARN)
            return
          end

          -- Use built-in definition UI to avoid telescope popup theme mismatch.
          vim.lsp.buf.definition()
        end

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", goto_definition, opts) -- show lsp definitions

        opts.desc = "Show LSP definitions"
        keymap.set("n", "<leader>gd", goto_definition, opts)

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = "󰠠 ",
          [vim.diagnostic.severity.INFO] = " ",
        },
      },
    })

    vim.lsp.config("svelte", {
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = { "*.js", "*.ts", "*.svelte", "*.html" },
          callback = function(ctx)
            client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
          end,
        })
      end,
    })

    -- GraphQL
    vim.lsp.config("graphql", {
      capabilities = capabilities,
      filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
    })

    -- Emmet
    vim.lsp.config("emmet_ls", {
      capabilities = capabilities,
      filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
    })

    -- Zig
    vim.lsp.config("zls", {
      capabilities = capabilities,
      cmd = { "zls" },
      filetypes = { "zig" },
      root_dir = legacy_root_dir(root_pattern("build.zig")),
      settings = {},
    })

    -- Lua
    vim.lsp.config("lua_ls", {
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
          completion = {
            callSnippet = "Replace",
          },
        },
      },
    })

    -- Go
    vim.lsp.config("gopls", {
      capabilities = capabilities,
      cmd = { "gopls" },
      filetypes = { "go", "gomod", "gowork", "gotmpl" },
      root_dir = legacy_root_dir(root_pattern("go.work", "go.mod", ".git")),
      single_file_support = true,
    })

    -- Python Pyright
    vim.lsp.config("pyright", {
      capabilities = capabilities,
      cmd = { "pyright-langserver", "--stdio" },
      filetypes = { "python" },
      single_file_support = true,
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = "workspace",
          },
        },
      },
    })

    -- Diable other lsp to prevent conflict
    vim.lsp.config("pylsp", {
      autostart = false,
    })

    vim.lsp.config("jedi_language_server", {
      autostart = false,
    })

    -- Default setup for all other servers
    -- List here or loop through manually installed servers if needed
    vim.lsp.config("ts_ls", {
      capabilities = capabilities,
    })

    -- Explicitly enable configured servers with the Neovim 0.11 API.
    vim.lsp.enable({
      "svelte",
      "graphql",
      "emmet_ls",
      "zls",
      "lua_ls",
      "gopls",
      "pyright",
      "ts_ls",
    })
  end,
}
