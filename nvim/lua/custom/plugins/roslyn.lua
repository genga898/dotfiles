return {
  {
    'seblyng/roslyn.nvim',
    config = function()
      local csharp_lsp_path = vim.fn.expand '$MASON/packages/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll'
      local cmd = {
        'dotnet',
        csharp_lsp_path,
        '--stdio',
        '--logLevel=Information',
        '--extensionLogDirectory=' .. vim.fs.dirname(vim.lsp.log.get_filename()),
      }

      vim.lsp.config('roslyn', {
        cmd = cmd,
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
          ['csharp|formatting'] = {
            dotnet_organize_imports_on_format = true,
          },
          ['csharp|completion'] = {
            dotnet_show_completion_items_from_unimported_namespaces = true,
          },
        },
      })
      vim.lsp.enable 'roslyn'
    end,
    init = function()
      -- We add the Razor file types before the plugin loads.
      vim.filetype.add {
        extension = {
          razor = 'razor',
          cshtml = 'razor',
        },
      }
    end,
  },
}
