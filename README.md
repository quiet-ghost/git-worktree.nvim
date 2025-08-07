# worktree.nvim

A Neovim plugin for managing git worktrees with a clean `.worktrees/` directory structure.

## Features

- Create and manage git worktrees in a dedicated `.worktrees/` directory
- Interactive branch creation and switching
- Easy worktree removal with confirmation
- Telescope integration for fuzzy finding
- Uses your existing `git wt` and `git wtr` aliases
- Auto-switch to newly created worktrees

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "quiet-ghost/worktree.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    require("worktree").setup({
      worktree_dir = ".worktrees",     -- Directory name for worktrees
      auto_switch = true,              -- Auto-switch to new worktrees
      telescope_integration = true,    -- Enable telescope integration
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "quier-ghost/worktree.nvim",
  requires = {
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    require("worktree").setup()
  end,
}
```

## Prerequisites

This plugin requires the `git wt` and `git wtr` aliases to be configured. Run these commands to set them up:

```bash
# Create worktree alias
git config --global alias.wt '!f() {
  if [ -z "$1" ]; then
    echo "Available branches:";
    git branch -a | grep -v HEAD;
    echo "";
    echo "Usage: git wt <branch-name>";
    return;
  fi;
  if git show-ref --verify --quiet refs/heads/$1; then
    echo "Using existing branch: $1";
    git worktree add ./.worktrees/$1 $1;
  else
    echo "Branch $1 does not exist.";
    echo "Available branches:";
    git branch -a | grep -v HEAD;
    echo "";
    read -p "Create new branch $1? (Y/n): " -n 1 -r;
    echo "";
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Cancelled.";
    else
      git worktree add -b $1 ./.worktrees/$1 HEAD;
    fi;
  fi;
}; f'

# Remove worktree alias
git config --global alias.wtr '!f() {
  if [ -n "$1" ]; then
    if [ -d ".worktrees/$1" ]; then
      echo "Removing worktree: $1";
      git worktree remove .worktrees/$1;
      echo "Worktree $1 removed.";
    else
      echo "Worktree $1 not found in .worktrees/";
    fi;
    return;
  fi;

  echo "Current worktrees:";
  git worktree list | grep "\.worktrees" | while read line; do
    path=$(echo "$line" | awk "{print \$1}");
    branch=$(basename "$path");
    echo "  $branch";
  done;

  if ! git worktree list | grep -q "\.worktrees"; then
    echo "  No worktrees found.";
    return;
  fi;

  echo "";
  read -p "Enter worktree name to remove (or press Enter to cancel): " worktree_name;

  if [ -z "$worktree_name" ]; then
    echo "Cancelled.";
    return;
  fi;

  if [ -d ".worktrees/$worktree_name" ]; then
    read -p "Remove worktree $worktree_name? (Y/n): " -n 1 -r;
    echo "";
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Cancelled.";
    else
      git worktree remove .worktrees/$worktree_name;
      echo "Worktree $worktree_name removed.";
    fi;
  else
    echo "Worktree $worktree_name not found.";
  fi;
}; f'
```

Also add `/.worktrees/` to your `.gitignore` file:

```gitignore
# Worktree directories
/.worktrees/
```

## Usage

### Commands

- `:WorktreeCreate [branch]` - Create a new worktree (prompts for branch name if not provided)
- `:WorktreeRemove [branch]` - Remove a worktree (interactive selection if not provided)
- `:WorktreeList` - List all worktrees
- `:WorktreeSwitch` - Switch to a worktree (interactive selection)

### Telescope Integration

If you have Telescope installed, you can use:

```vim
:Telescope worktrees
:Telescope create_worktree
```

Or in Lua:

```lua
require("telescope").extensions.worktrees.worktrees()
require("telescope").extensions.worktrees.create_worktree()
```

### Key Mappings (Telescope)

In the worktree picker:

- `<CR>` - Switch to selected worktree
- `<C-d>` - Delete selected worktree

In the create worktree picker:

- `<CR>` - Create worktree from selected branch
- `<C-n>` - Create worktree with new branch name

## Configuration

```lua
require("worktree").setup({
  worktree_dir = ".worktrees",     -- Directory name for worktrees
  auto_switch = true,              -- Auto-switch to new worktrees
  telescope_integration = true,    -- Enable telescope integration
})
```

## Project Structure

Your project will look like this:

```
my-project/
├── .git/
├── .gitignore              # Contains /.worktrees/
├── main-project-files...
└── .worktrees/
    ├── feature-branch/     # Worktree for feature-branch
    ├── hotfix/            # Worktree for hotfix
    └── dev/               # Worktree for dev
```

## License

MIT
