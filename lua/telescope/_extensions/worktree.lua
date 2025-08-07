local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope.utils")

local worktree = require("worktree")

local M = {}

-- Unified telescope picker for all worktree operations
function M.worktrees(opts)
  opts = opts or {}
  
  local worktrees = worktree.get_worktrees()
  local all_branches = worktree.get_all_branches()
  
  -- Combine existing worktrees with available branches for creation
  local results = {}
  
  -- Add existing worktrees first
  for _, wt in ipairs(worktrees) do
    table.insert(results, {
      type = "worktree",
      branch = wt.branch,
      path = wt.path,
      is_current = wt.is_current,
      is_main = wt.is_main,
      locked = wt.locked,
      bare = wt.bare,
    })
  end
  
  -- Add available branches that don't have worktrees yet
  for _, branch in ipairs(all_branches) do
    table.insert(results, {
      type = "branch",
      branch = branch,
      path = nil,
      is_current = false,
      is_main = false,
      locked = false,
      bare = false,
    })
  end

  pickers.new(opts, {
    prompt_title = "Git Worktrees (Enter: switch/create, C-d/dd: delete)",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local display_text = entry.branch
        local path_display = ""
        
        if entry.type == "worktree" then
          path_display = utils.transform_path(opts, entry.path)
          
          -- Add status indicators for existing worktrees
          if entry.is_current then
            display_text = display_text .. " (current)"
          end
          if entry.is_main then
            display_text = display_text .. " (main)"
          end
          if entry.locked then
            display_text = display_text .. " [LOCKED]"
          end
          if entry.bare then
            display_text = display_text .. " [BARE]"
          end
        else
          -- Available branch for creation
          display_text = display_text .. " (create)"
          path_display = "→ will create in .worktrees/"
        end
        
        return {
          value = entry,
          display = string.format("%-30s %s", display_text, path_display),
          ordinal = entry.branch,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      -- Handle dynamic creation when typing
      local function handle_selection()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        
        if selection then
          if selection.value.type == "worktree" then
            -- Switch to existing worktree
            if not selection.value.is_current then
              actions.close(prompt_bufnr)
              worktree.switch_worktree(selection.value.path)
            end
          else
            -- Create new worktree from branch
            actions.close(prompt_bufnr)
            local path = worktree.create_worktree(selection.value.branch)
            if path then
              worktree.switch_worktree(path)
            end
          end
        else
          -- No selection - check if user typed a new branch name
          local current_line = action_state.get_current_line()
          if current_line and current_line ~= "" then
            actions.close(prompt_bufnr)
            local path = worktree.create_worktree(current_line)
            if path then
              worktree.switch_worktree(path)
            end
          end
        end
      end
      
      actions.select_default:replace(handle_selection)

      -- Delete worktree with <C-d> (insert mode)
      map("i", "<C-d>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.type == "worktree" then
          local wt = selection.value
          if wt.is_current then
            vim.notify("Cannot delete current worktree", vim.log.levels.WARN)
            return
          end
          if wt.is_main then
            vim.notify("Cannot delete main repository", vim.log.levels.WARN)
            return
          end
          
          local should_delete = true
          if worktree.config.confirm_telescope_deletions then
            local confirm = vim.fn.confirm(
              "Delete worktree '" .. wt.branch .. "'?\n" .. wt.path, 
              "&Yes\n&No", 
              2
            )
            should_delete = confirm == 1
          end
          
          if should_delete then
            actions.close(prompt_bufnr)
            if worktree.delete_worktree(wt.path) then
              -- Refresh the picker
              vim.schedule(function()
                M.worktrees(opts)
              end)
            end
          end
        else
          vim.notify("Cannot delete branch that hasn't been created as worktree", vim.log.levels.WARN)
        end
      end)

      -- Delete worktree with dd (normal mode)
      map("n", "dd", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.type == "worktree" then
          local wt = selection.value
          if wt.is_current then
            vim.notify("Cannot delete current worktree", vim.log.levels.WARN)
            return
          end
          if wt.is_main then
            vim.notify("Cannot delete main repository", vim.log.levels.WARN)
            return
          end
          
          local should_delete = true
          if worktree.config.confirm_telescope_deletions then
            local confirm = vim.fn.confirm(
              "Delete worktree '" .. wt.branch .. "'?\n" .. wt.path, 
              "&Yes\n&No", 
              2
            )
            should_delete = confirm == 1
          end
          
          if should_delete then
            actions.close(prompt_bufnr)
            if worktree.delete_worktree(wt.path) then
              -- Refresh the picker
              vim.schedule(function()
                M.worktrees(opts)
              end)
            end
          end
        else
          vim.notify("Cannot delete branch that hasn't been created as worktree", vim.log.levels.WARN)
        end
      end)

      return true
    end,
  }):find()
end

-- Keep create_worktree for backward compatibility, but redirect to main interface
function M.create_worktree(opts)
  M.worktrees(opts)
end

-- Register telescope extension
return telescope.register_extension({
  setup = function(ext_config, config)
    -- Extension setup
  end,
  exports = {
    worktrees = M.worktrees,
    create_worktree = M.create_worktree,
  },
})