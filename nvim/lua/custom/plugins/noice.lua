return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  opts = {
    presets = {
      lsp_doc_border = true,
    },
    routes = {
      {
        filter = {
          event = 'notify',
          find = 'No information available',
        },
        opts = {
          skip = true,
        },
      },
    },
    lsp = {
      progress = {
        enabled = false,
      },
      hover = {
        enabled = true,
        opts = {
          vim.keymap.set({ 'n', 'i', 's' }, '<c-f>', function()
            if not require('noice.lsp').scroll(4) then
              return '<c-f>'
            end
          end),

          vim.keymap.set({ 'n', 'i', 's' }, '<c-b>', function()
            if not require('noice.lsp').scroll(-4) then
              return '<c-b>'
            end
          end),
        },
      },
      signature = {
        enabled = true,
      },
    },
  },
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
}
