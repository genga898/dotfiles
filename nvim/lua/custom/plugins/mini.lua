return {
  {
    'echasnovski/mini.nvim',
    config = function()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
      require('mini.files').setup()
      require('mini.indentscope').setup()
      require('mini.comment').setup()
      require('mini.surround').setup()
      require('mini.indentscope').setup()
      require('mini.ai').setup({ n_lines = 500 })
    end,
  }
}
