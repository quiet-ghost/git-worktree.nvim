local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  return
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local worktree = require("worktree")

local M = {}

-- Telescope picker for worktrees
function M.worktrees(opts)
  opts = opts or {}
  
  local worktrees = worktree.get_worktrees()
  
  if #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = "Git Worktrees",
    finder = finders.new_table({
      results = worktrees,
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format("%s (%s)", entry.branch, entry.path),
          ordinal = entry.branch,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          worktree.switch_to(selection.value.branch)
        end
      end)

      map("i", "<C-d>", function()
        local selection = action_state.get_selected_entry()
        if selection then
          actions.close(prompt_bufnr)
          local confirm = vim.fn.confirm(
            "Remove worktree '" .. selection.value.branch .. "'?", 
            "&Yes\n&No", 
            2
          )
          if confirm == 1 then
            worktree.remove(selection.value.branch)
          end
        end
      end)

      return true
    end,
  }):find()
end

-- Telescope picker for creating worktrees
function M.create_worktree(opts)
  opts = opts or {}
  
  -- Get available branches
  local cmd = "git branch -a --format='%(refname:short)' | grep -v HEAD | sort -u"
  local handle = io.popen(cmd)
  if not handle then
    vim.notify("Failed to get branches", vim.log.levels.ERROR)
    return
  end
  
  local result = handle:read("*a")
  handle:close()
  
  local branches = {}
  for branch in result:gmatch("[^\r\n]+") do
    -- Remove origin/ prefix for remote branches
    local clean_branch = branch:gsub("^origin/", "")
    if not vim.tbl_contains(branches, clean_branch) then
      table.insert(branches, clean_branch)
    end
  end

  pickers.new(opts, {
    prompt_title = "Create Worktree from Branch",
    finder = finders.new_table({
      results = branches,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          worktree.create(selection[1])
        end
      end)

      -- Allow creating new branch
      map("i", "<C-n>", function()
        actions.close(prompt_bufnr)
        local branch_name = vim.fn.input("New branch name: ")
        if branch_name ~= "" then
          worktree.create(branch_name)
        end
      end)

      return true
    end,
  }):find()
end

-- Register telescope extensions
return telescope.register_extension({
  setup = function(ext_config, config)
    -- Extension setup
  end,
  exports = {
    worktrees = M.worktrees,
    create_worktree = M.create_worktree,
  },
})