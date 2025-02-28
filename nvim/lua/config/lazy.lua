-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out,                            'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Setup lazy.nvim
require('lazy').setup {
  spec = {
    {
      'https://github.com/rebelot/kanagawa.nvim',
      lazy = false,
      priority = 1000, -- Make sure to load this before all the other start plugins.
      config = function()
        vim.cmd.colorscheme 'kanagawa'
      end,
    },

    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

    -- Highlight todo, notes, etc in comments
    {
      'folke/todo-comments.nvim',
      event = 'VimEnter',
      dependencies = { 'nvim-lua/plenary.nvim' },
      opts = { signs = false },
    },

    { -- Adds git related signs to the gutter, as well as utilities for managing changes
      'lewis6991/gitsigns.nvim',
      opts = {
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
      },
    },
    {
      'lewis6991/hover.nvim',
      config = function()
        require('hover').setup {
          init = function()
            require 'hover.providers.lsp'
          end,

          preview_opts = {
            border = 'rounded',
          },
        }

        vim.keymap.set('n', 'K', require('hover').hover, { desc = 'hover.nvim' })
      end,
      dependencies = {
        'nvim-treesitter/nvim-treesitter', -- optional
        'nvim-tree/nvim-web-devicons',     -- optional
      },
    },
    -- import your plugins
    { import = 'custom.plugins' },
  },
}
