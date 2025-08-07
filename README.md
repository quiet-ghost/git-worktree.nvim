# worktree.nvim

A Neovim plugin for managing git worktrees with Telescope integration, inspired by ThePrimeagen's git-worktree.nvim.

## Features

- Create and manage git worktrees in a dedicated `.worktrees/` directory
- Full Telescope integration for fuzzy finding and management
- Fast switching between worktrees
- Easy worktree removal with confirmation
- Auto-switch to newly created worktrees
- Automatic branch detection (existing vs new)
- Clean project structure with organized worktrees

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "quiet-ghost/git-worktree.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- required for telescope integration
  },
  config = function()
    require("worktree").setup({
      worktree_dir = ".worktrees",              -- Directory name for worktrees
      change_directory_command = "cd",          -- Command to change directory (cd, tcd, lcd)
      update_on_change = true,                  -- Update after switching worktree
      update_on_change_command = "e .",         -- Command to run after switching
      clearjumps_on_change = true,              -- Clear jump list when switching
      confirm_telescope_deletions = true,       -- Confirm before deleting in telescope
    })

    -- Load telescope extension
    require("telescope").load_extension("worktree")
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "quiet-ghost/git-worktree.nvim",
  requires = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("worktree").setup()
    require("telescope").load_extension("worktree")
  end,
}
```

## Setup

Add `/.worktrees/` to your `.gitignore` file:

```gitignore
# Worktree directories
/.worktrees/
```

## Usage

### Primary Commands (Telescope)

The main interface is through Telescope:

```vim
:Worktrees              " List and manage existing worktrees
:WorktreeCreate         " Create new worktree from branch
```

### Telescope Key Mappings

**In `:Worktrees` picker:**

- `<Enter>` - Switch to selected worktree
- `<C-d>` - Delete selected worktree (insert mode)
- `dd` - Delete selected worktree (normal mode)

**In `:WorktreeCreate` picker:**

- `<Enter>` - Create worktree from selected existing branch
- `<C-n>` - Create worktree with new branch name

### Lua API

```lua
-- Telescope pickers (after loading extension)
require("telescope").load_extension("worktree")
require("telescope").extensions.worktree.worktrees()
require("telescope").extensions.worktree.create_worktree()

-- Direct API
local worktree = require("worktree")
worktree.create_worktree("feature-branch")  -- Creates .worktrees/feature-branch
worktree.switch_worktree("/path/to/worktree")
worktree.delete_worktree("/path/to/worktree")
worktree.get_worktrees()  -- Returns list of managed worktrees
```

### Legacy Commands

For backward compatibility:

- `:WorktreeCreate [branch]` - Create a new worktree
- `:WorktreeRemove [branch]` - Remove a worktree
- `:WorktreeList` - List all worktrees
- `:WorktreeSwitch` - Switch to a worktree

### Recommended Keymaps

Add these to your Neovim config:

```lua
-- Using commands
vim.keymap.set("n", "<leader>gw", "<cmd>Worktrees<cr>", { desc = "Git worktrees" })
vim.keymap.set("n", "<leader>gW", "<cmd>WorktreeCreate<cr>", { desc = "Create worktree" })

-- Or using Lua functions directly
vim.keymap.set("n", "<leader>gw", function()
  require("telescope").extensions.worktree.worktrees()
end, { desc = "Git worktrees" })

vim.keymap.set("n", "<leader>gW", function()
  require("telescope").extensions.worktree.create_worktree()
end, { desc = "Create worktree" })
```

### Common Keymap Issues

If your keymaps aren't working, make sure you:

1. **Load the telescope extension** in your config:

   ```lua
   require("telescope").load_extension("worktree")
   ```

2. **Set keymaps after plugin setup**:
   ```lua
   -- In your lazy.nvim config
   {
     "your-username/worktree.nvim",
     dependencies = { "nvim-telescope/telescope.nvim" },
     config = function()
       require("worktree").setup()
       require("telescope").load_extension("worktree")

       -- Set keymaps here
       vim.keymap.set("n", "<leader>gw", "<cmd>Worktrees<cr>")
       vim.keymap.set("n", "<leader>gW", "<cmd>WorktreeCreate<cr>")
     end,
   }
   ```

## Configuration

```lua
require("worktree").setup({
  worktree_dir = ".worktrees",              -- Directory name for worktrees (relative to git root)
  change_directory_command = "cd",          -- Command to change directory (cd, tcd, lcd)
  update_on_change = true,                  -- Update after switching worktree
  update_on_change_command = "e .",         -- Command to run after switching
  clearjumps_on_change = true,              -- Clear jump list when switching
  confirm_telescope_deletions = true,       -- Confirm before deleting in telescope
})
```

### Configuration Options

- **`worktree_dir`**: Directory name for worktrees (default: `.worktrees`)
- **`change_directory_command`**: Command used to change directory (`cd`, `tcd`, `lcd`)
- **`update_on_change`**: Whether to run update command after switching (default: `true`)
- **`update_on_change_command`**: Command to run after switching (default: `e .`)
- **`clearjumps_on_change`**: Clear jump list when switching worktrees (default: `true`)
- **`confirm_telescope_deletions`**: Show confirmation before deleting in telescope (default: `true`)

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

## Troubleshooting

### "No worktrees found in .worktrees directory"

This means you haven't created any worktrees yet, or they're not in the `.worktrees` directory. The plugin only shows worktrees that are managed in the `.worktrees` folder.

### "Branch 'master' is already used by worktree"

This happens when you try to create a worktree using a branch that's already checked out. The plugin now filters out branches that are already in use. If you see this error:

1. The branch filtering should prevent this, but if it still happens:
2. Create a new branch name instead
3. Or use `:WorktreeCreate` and press `<C-n>` to create a new branch

### "Extension doesn't exist or isn't installed"

Make sure you:

1. **Load the extension** in your config:
   ```lua
   require("telescope").load_extension("worktree")
   ```

2. **Have telescope installed** as a dependency

3. **Plugin is properly installed** in your plugin manager

### Keymaps not working

1. **Check if commands work first**:
   ```vim
   :Worktrees
   :WorktreeCreate
   ```

2. **Make sure extension is loaded** before setting keymaps:
   ```lua
   require("telescope").load_extension("worktree")
   vim.keymap.set("n", "<leader>gw", "<cmd>Worktrees<cr>")
   ```

3. **Try Lua functions directly**:
   ```lua
   vim.keymap.set("n", "<leader>gw", function()
     require("telescope").extensions.worktree.worktrees()
   end)
   ```

## License

MIT
