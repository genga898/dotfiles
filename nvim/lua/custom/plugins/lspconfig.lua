return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      inlay_hints = { enabled = true },
    },
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'saghen/blink.cmp',
      {
        'seblyng/roslyn.nvim',
        ft = { 'cs', 'razor' },
      },
    },
    config = function()
      local enable = vim.lsp.enable

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = { 'vim' },
            },
          },
        },
      })

      vim.lsp.config('nixd', {
        cmd = { 'nixd' },
        settings = {
          nixd = {
            nixpkgs = {
              expr = 'import <nixpkgs> {}',
            },
            formatting = {
              command = { 'nixfmt' },
            },
          },
        },
      })
      -- Vue language server config
      local vue_language_server_path = vim.fn.stdpath 'data' .. 'mason/packages/vue-language-server/node_modules/@vue/language-server'
      local tsserver_filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' }
      local vue_plugin = {
        name = '@vue/typescript-plugin',
        location = vue_language_server_path,
        languages = { 'vue' },
        configNamespace = 'typescript',
      }
      local vtsls_config = {
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                vue_plugin,
              },
            },
          },
        },
        filetypes = tsserver_filetypes,
      }

      vim.lsp.config('vtsls', vtsls_config)

      enable { 'lua_ls', 'rust_analyzer', 'nixd', 'gleam', 'biome', 'qmlls', 'vue-ls', 'vtsls', 'html', 'tailwindcss', 'zls', 'roslyn', 'cssls' }

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if not client then
            return
          end

          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = args.buf, desc = 'LSP: ' .. desc })
          end
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- Find references for the word under your cursor.
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute lsp code actions
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          if client:supports_method 'textDocument/formatting' then
            -- Format buffer on save
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format { bufnr = args.buf, id = client.id }
              end,
            })
          end
        end,
      })

      ---@diagnostic disable-next-line: missing-fields
      require('mason').setup {
        registries = {
          'github:mason-org/mason-registry',
          'github:crashdummyy/mason-registry',
        },
        ui = {
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
        },
      }

      local ensure_installed = {
        'stylua', -- Used to format Lua code
        'vue_ls',
        'html',
        'emmet_language_server',
      }
      require('mason-lspconfig').setup { ensure_installed = ensure_installed }
    end,
  },
}
