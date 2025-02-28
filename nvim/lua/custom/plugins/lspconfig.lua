return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'saghen/blink.cmp',
      {
        'folke/lazydev.nvim',
        ft = 'lua',
        opts = {
          library = {
            -- Load luvit types when the `vim.uv` word is found
            { path = 'luvit-meta/library', words = { 'vim%.uv' } },
          },
        },
      },
      { 'j-hui/fidget.nvim',       opts = {} },
      {
        'seblyng/roslyn.nvim',
        ft = { 'cs', 'razor' },
        opts = {
          exe = 'Microsoft.CodeAnalysis.LanguageServer',
        },
        dependencies = {
          'tris203/rzls.nvim',
        },
      },
    },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      require('lspconfig').lua_ls.setup { capabilities = capabilities }
      require('lspconfig').tailwindcss.setup { capabilities = capabilities }
      require('rzls').setup {
        capabilities = capabilities,
        on_attach = require('blink.cmp').on_attach,
        path = 'rzls',
      }

      require('roslyn').setup {
        args = {
          '--stdio',
          '--logLevel=Information',
          '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.get_log_path()),
          '--razorSourceGenerator=/etc/profiles/per-user/genga/lib/roslyn-ls/Microsoft.CodeAnalysis.Razor.Compiler.dll',
          '--razorDesignTimePath=/etc/profiles/per-user/genga/lib/rzls/Targets/Microsoft.NET.Sdk.Razor.DesignTime.targets',
        },
        ---@diagnostic disable-next-line: missing-fields
        config = {
          capabilities = capabilities,
          on_attach = require('blink.cmp').on_attach,
          handlers = require 'rzls.roslyn_handlers',
          settings = {
            ['csharp|inlay_hints'] = {
              csharp_enable_inlay_hints_for_implicit_object_creation = true,
              csharp_enable_inlay_hints_for_implicit_variable_types = true,

              csharp_enable_inlay_hints_for_lambda_parameter_types = true,
              csharp_enable_inlay_hints_for_types = true,
              dotnet_enable_inlay_hints_for_indexer_parameters = true,
              dotnet_enable_inlay_hints_for_literal_parameters = true,
              dotnet_enable_inlay_hints_for_object_creation_parameters = true,
              dotnet_enable_inlay_hints_for_other_parameters = true,
              dotnet_enable_inlay_hints_for_parameters = true,
              dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
              dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
            },
            ['csharp|code_lens'] = {
              dotnet_enable_references_code_lens = true,
            },
          },
        },
        init = function()
          -- we add the razor filetypes before the plugin loads
          vim.filetype.add {
            extension = {
              razor = 'razor',
              cshtml = 'razor',
            },
          }
        end,
      }
      require('lspconfig').nixd.setup {
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
        capabilities = capabilities,
      }
      require('lspconfig').gleam.setup { capabilities = capabilities }
      require('lspconfig').biome.setup { capabilities = capabilities }

      -- Vue language server config
      local mason_registry = require 'mason-registry'
      local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() ..
      '/node_modules/@vue/language-server'
      require('lspconfig').ts_ls.setup {
        init_options = {
          plugins = {
            {
              name = '@vue/typescript-plugin',
              location = vue_language_server_path,
              languages = { 'vue' },
            },
          },
        },
        capabilities = capabilities,
      }
      require('lspconfig').volar.setup {
        filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
        init_options = {
          vue = {
            hybridMode = false,
          },
        },
        capabilities = capabilities,
      }

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

          if client.supports_method 'textDocument/formatting' then
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

      -- Define default servers to be installed
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
      }

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

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
        'vue-language-server',
        'html-lsp',
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      ---@diagnostic disable-next-line missing-fields
      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
}
