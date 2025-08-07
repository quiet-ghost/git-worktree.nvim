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

-- Telescope picker for worktrees (switch/delete)
function M.worktrees(opts)
  opts = opts or {}
  
  local worktrees = worktree.get_worktrees()
  
  if #worktrees == 0 then
    vim.notify("No worktrees found in .worktrees directory", vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = "Git Worktrees",
    finder = finders.new_table({
      results = worktrees,
      entry_maker = function(entry)
        local display_text = entry.branch
        local path_display = utils.transform_path(opts, entry.path)
        
        -- Add status indicators
        if entry.is_current then
          display_text = display_text .. " (current)"
        end
        if entry.locked then
          display_text = display_text .. " [LOCKED]"
        end
        if entry.bare then
          display_text = display_text .. " [BARE]"
        end
        
        return {
          value = entry,
          display = string.format("%-20s %s", display_text, path_display),
          ordinal = entry.branch .. " " .. entry.path,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and not selection.value.is_current then
          worktree.switch_worktree(selection.value.path)
        end
      end)

      -- Delete worktree with <C-d>
      map("i", "<C-d>", function()
        local selection = action_state.get_selected_entry()
        if selection then
          local wt = selection.value
          if wt.is_current then
            vim.notify("Cannot delete current worktree", vim.log.levels.WARN)
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
        end
      end)

      map("n", "dd", function()
        local selection = action_state.get_selected_entry()
        if selection then
          local wt = selection.value
          if wt.is_current then
            vim.notify("Cannot delete current worktree", vim.log.levels.WARN)
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
        end
      end)

      return true
    end,
  }):find()
end

-- Telescope picker for creating worktrees
function M.create_worktree(opts)
  opts = opts or {}
  
  local branches = worktree.get_all_branches()
  
  if #branches == 0 then
    vim.notify("No branches found", vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = "Create Worktree from Branch",
    finder = finders.new_table({
      results = branches,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local branch = selection.value
          local path = worktree.create_worktree(branch)
          if path then
            -- Switch to the new worktree
            worktree.switch_worktree(path)
          end
        end
      end)

      -- Create new branch with <C-n>
      map("i", "<C-n>", function()
        actions.close(prompt_bufnr)
        local branch_name = vim.fn.input("New branch name: ")
        if branch_name ~= "" then
          local path = worktree.create_worktree(branch_name)
          if path then
            -- Switch to the new worktree
            worktree.switch_worktree(path)
          end
        end
      end)

      return true
    end,
  }):find()
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