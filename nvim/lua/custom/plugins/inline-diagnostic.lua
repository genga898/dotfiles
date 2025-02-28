return {
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    config = function()
      require('tiny-inline-diagnostic').setup {
        options = {
          multilines = {
            enabled = true,
            always_show = true,
          },
        },

        break_line = {
          enabled = true,
          after = 30,
        },
      }
    end,
  }
}
