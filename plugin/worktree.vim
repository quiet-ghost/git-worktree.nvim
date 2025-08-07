" worktree.nvim - Git worktree management for Neovim
" Maintainer: ghost-desktop

if exists('g:loaded_worktree')
  finish
endif
let g:loaded_worktree = 1

" Commands
command! -nargs=? WorktreeCreate lua require('worktree').create(<f-args>)
command! -nargs=? WorktreeRemove lua require('worktree').remove(<f-args>)
command! WorktreeList lua require('worktree').list()
command! WorktreeSwitch lua require('worktree').switch()

" Telescope integration commands
command! WorktreeTelescope lua require('telescope').extensions.worktree.worktrees()
command! WorktreeTelescopeCreate lua require('telescope').extensions.worktree.create_worktree()