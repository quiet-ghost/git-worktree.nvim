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

" Telescope integration commands (primary interface)
command! Worktrees Telescope worktree worktrees
command! WorktreeCreate Telescope worktree create_worktree

" Legacy telescope commands for backward compatibility  
command! WorktreeTelescope Telescope worktree worktrees
command! WorktreeTelescopeCreate Telescope worktree create_worktree