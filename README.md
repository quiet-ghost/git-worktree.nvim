# worktree.nvim

A Neovim plugin for managing git worktrees with Telescope integration.

## Workflow

Creates and manages git worktrees in a `.worktrees/` directory within your repository. Provides a unified Telescope interface to switch between existing worktrees, create new ones from branches, or create entirely new branches as worktrees.

## How it works

- Lists existing worktrees and available branches in one Telescope picker
- Press Enter to switch to existing worktrees or create new ones
- Automatically detects if branches exist locally, remotely, or need to be created
- Stores all worktrees in `.worktrees/` directory for organization
- Supports deletion with confirmation prompts

## Installation

### lazy.nvim

```lua
{
  "quiet-ghost/git-worktree.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("worktree").setup()
    require("telescope").load_extension("worktree")
  end,
}
```

### packer.nvim

```lua
use {
  "quiet-ghost/git-worktree.nvim",
  requires = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("worktree").setup()
    require("telescope").load_extension("worktree")
  end,
}
```

## Usage

```vim
:Worktrees
```

- Enter: Switch to worktree or create from branch
- C-d/dd: Delete selected worktree
- Type new branch name and press Enter to create

Add `/.worktrees/` to your `.gitignore`.

## Keybinds configuration (place in keymaps.lua)

```vim
map("n", "<C-m>", ":Worktrees<CR>")
```

No default keybinds are provided.
