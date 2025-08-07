" worktree.nvim - Git worktree management for Neovim
" Maintainer: ghost-desktop

if exists('g:loaded_worktree')
  finish
endif
let g:loaded_worktree = 1

" Core commands
command! -nargs=? WorktreeCreate lua require('worktree').create(<f-args>)
command! -nargs=? WorktreeRemove lua require('worktree').remove(<f-args>)
command! WorktreeList lua require('worktree').list()
command! WorktreeSwitch lua require('worktree').switch()

" Primary telescope interface (unified)
command! Worktrees lua require('telescope').extensions.worktree.worktrees()

" Legacy commands (all redirect to unified interface)
command! WorktreeCreate lua require('telescope').extensions.worktree.worktrees()
command! WorktreeTelescope lua require('telescope').extensions.worktree.worktrees()
command! WorktreeTelescopeCreate lua require('telescope').extensions.worktree.worktrees()