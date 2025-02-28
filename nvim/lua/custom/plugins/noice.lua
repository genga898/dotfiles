return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  opts = {
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
    -- your other opts
  },
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
}
