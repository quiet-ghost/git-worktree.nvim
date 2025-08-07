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

### Unified Interface

Everything is done through one command:

```vim
:Worktrees              " View, create, switch, and delete worktrees
```

### How It Works

The `:Worktrees` command shows:
- **Existing worktrees** - switch to them with `<Enter>`
- **Available branches** - create worktree with `<Enter>`
- **Type new branch name** - creates new worktree if no match found

### Key Mappings

- `<Enter>` - Switch to worktree OR create worktree from branch OR create new branch
- `<C-d>` - Delete selected worktree (insert mode)
- `dd` - Delete selected worktree (normal mode)

### Workflow Examples

1. **Switch to existing worktree**: `:Worktrees` → select worktree → `<Enter>`
2. **Create from existing branch**: `:Worktrees` → select branch (create) → `<Enter>`
3. **Create new branch**: `:Worktrees` → type "new-feature" → `<Enter>`
4. **Delete worktree**: `:Worktrees` → select worktree → `<C-d>` or `dd`

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

For backward compatibility (all redirect to unified interface):

- `:WorktreeCreate` - Opens unified worktree interface
- `:WorktreeRemove [branch]` - Remove a worktree  
- `:WorktreeList` - List all worktrees
- `:WorktreeSwitch` - Switch to a worktree
### Recommended Keymaps

Add this to your Neovim config:

```lua
-- Single keymap for everything
vim.keymap.set("n", "<leader>gw", "<cmd>Worktrees<cr>", { desc = "Git worktrees" })

-- Or using Lua function directly
vim.keymap.set("n", "<leader>gw", function()
  require("telescope").extensions.worktree.worktrees()
end, { desc = "Git worktrees" })
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
