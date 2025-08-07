local M = {}

-- Configuration
M.config = {
  worktree_dir = ".worktrees",
  change_directory_command = "cd",
  update_on_change = true,
  update_on_change_command = "e .",
  clearjumps_on_change = true,
  confirm_telescope_deletions = true,
}

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- Check if we're in a git repository
local function is_git_repo()
  local result = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
  return vim.v.shell_error == 0
end

-- Get git root directory
local function get_git_root()
  if not is_git_repo() then
    return nil
  end
  local result = vim.fn.system("git rev-parse --show-toplevel")
  return vim.trim(result)
end

-- Export get_git_root for telescope integration
M.get_git_root = get_git_root

-- Execute shell command and return output and success status
local function execute_command(cmd)
  local result = vim.fn.system(cmd)
  local success = vim.v.shell_error == 0
  return vim.trim(result), success
end

-- Create a new worktree in .worktrees directory
function M.create_worktree(branch)
  if not is_git_repo() then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return false
  end

  local git_root = get_git_root()
  if not git_root then
    vim.notify("Could not find git root", vim.log.levels.ERROR)
    return false
  end

  -- Always create in .worktrees directory
  local worktree_path = git_root .. "/" .. M.config.worktree_dir .. "/" .. branch

  -- Check if branch exists locally
  local branch_exists_cmd = string.format("git show-ref --verify --quiet refs/heads/%s", vim.fn.shellescape(branch))
  local _, branch_exists = execute_command(branch_exists_cmd)

  -- Check if branch exists remotely
  local remote_branch_cmd = string.format("git show-ref --verify --quiet refs/remotes/origin/%s", vim.fn.shellescape(branch))
  local _, remote_exists = execute_command(remote_branch_cmd)
  
  -- Also check upstream
  local upstream_branch_cmd = string.format("git show-ref --verify --quiet refs/remotes/upstream/%s", vim.fn.shellescape(branch))
  local _, upstream_exists = execute_command(upstream_branch_cmd)

  local cmd
  if branch_exists then
    -- Use existing local branch
    cmd = string.format("git worktree add %s %s", vim.fn.shellescape(worktree_path), vim.fn.shellescape(branch))
  elseif remote_exists then
    -- Create from remote origin branch
    cmd = string.format("git worktree add -b %s %s origin/%s", vim.fn.shellescape(branch), vim.fn.shellescape(worktree_path), vim.fn.shellescape(branch))
  elseif upstream_exists then
    -- Create from remote upstream branch
    cmd = string.format("git worktree add -b %s %s upstream/%s", vim.fn.shellescape(branch), vim.fn.shellescape(worktree_path), vim.fn.shellescape(branch))
  else
    -- Create new branch from HEAD
    cmd = string.format("git worktree add -b %s %s HEAD", vim.fn.shellescape(branch), vim.fn.shellescape(worktree_path))
  end

  local result, success = execute_command(cmd)
  
  if not success then
    vim.notify("Failed to create worktree: " .. result, vim.log.levels.ERROR)
    return false
  end

  vim.notify("Created worktree: " .. branch .. " -> " .. worktree_path, vim.log.levels.INFO)
  return worktree_path
end

-- Wrapper for backward compatibility
function M.create(branch_name)
  if not branch_name or branch_name == "" then
    branch_name = vim.fn.input("Branch name: ")
    if branch_name == "" then
      vim.notify("Branch name required", vim.log.levels.WARN)
      return
    end
  end
  
  local path = M.create_worktree(branch_name)
  if path and M.config.update_on_change then
    M.switch_worktree(path)
  end
  return path
end

-- Remove a worktree
function M.delete_worktree(path)
  if not is_git_repo() then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return false
  end

  local cmd = string.format("git worktree remove %s", vim.fn.shellescape(path))
  local result, success = execute_command(cmd)
  
  if not success then
    -- Try force removal if regular removal fails
    cmd = string.format("git worktree remove --force %s", vim.fn.shellescape(path))
    result, success = execute_command(cmd)
    
    if not success then
      vim.notify("Failed to remove worktree: " .. result, vim.log.levels.ERROR)
      return false
    end
  end

  vim.notify("Removed worktree: " .. path, vim.log.levels.INFO)
  return true
end

-- Wrapper for backward compatibility
function M.remove(branch_name)
  local worktrees = M.get_worktrees()
  for _, wt in ipairs(worktrees) do
    if wt.branch == branch_name then
      return M.delete_worktree(wt.path)
    end
  end
  vim.notify("Worktree not found: " .. branch_name, vim.log.levels.ERROR)
  return false
end

-- Get list of worktrees
function M.get_worktrees()
  if not is_git_repo() then
    return {}
  end

  local cmd = "git worktree list --porcelain"
  local result, success = execute_command(cmd)
  
  if not success or not result or result == "" then
    return {}
  end

  local worktrees = {}
  local current_wt = {}
  
  for line in result:gmatch("[^\r\n]+") do
    line = vim.trim(line)
    if line == "" then
      -- Empty line indicates end of worktree entry
      if current_wt.path then
        table.insert(worktrees, current_wt)
        current_wt = {}
      end
    elseif line:match("^worktree ") then
      -- Start of new worktree entry
      if current_wt.path then
        table.insert(worktrees, current_wt)
      end
      current_wt = { 
        path = line:match("^worktree (.+)"),
        bare = false,
        detached = false,
        locked = false
      }
    elseif line:match("^HEAD ") then
      current_wt.head = line:match("^HEAD (.+)")
    elseif line:match("^branch ") then
      local branch_ref = line:match("^branch (.+)")
      if branch_ref then
        current_wt.branch = branch_ref:gsub("^refs/heads/", "")
      end
    elseif line == "bare" then
      current_wt.bare = true
    elseif line == "detached" then
      current_wt.detached = true
    elseif line:match("^locked") then
      current_wt.locked = true
      current_wt.lock_reason = line:match("^locked (.*)") or ""
    end
  end
  
  -- Add the last worktree if exists
  if current_wt.path then
    table.insert(worktrees, current_wt)
  end

  -- Post-process worktrees
  local git_root = get_git_root()
  local managed_worktrees = {}
  
  for _, wt in ipairs(worktrees) do
    -- Set branch name for bare/detached worktrees
    if not wt.branch then
      if wt.bare then
        wt.branch = "(bare)"
      elseif wt.detached then
        wt.branch = "(detached)"
      else
        wt.branch = vim.fn.fnamemodify(wt.path, ":t")
      end
    end
    
    -- Determine if this is the current worktree
    local current_dir = vim.fn.getcwd()
    wt.is_current = vim.startswith(current_dir, wt.path)
    
    -- Check if this worktree is in our managed .worktrees directory
    if git_root then
      local worktree_pattern = git_root .. "/" .. M.config.worktree_dir .. "/"
      wt.is_managed = vim.startswith(wt.path, worktree_pattern)
      
      -- Only include managed worktrees (in .worktrees directory)
      if wt.is_managed then
        table.insert(managed_worktrees, wt)
      end
    end
  end

  return managed_worktrees
end

-- Switch to a worktree by path
function M.switch_worktree(path)
  if not path or path == "" then
    vim.notify("Invalid worktree path", vim.log.levels.ERROR)
    return false
  end

  if vim.fn.isdirectory(path) == 0 then
    vim.notify("Worktree directory does not exist: " .. path, vim.log.levels.ERROR)
    return false
  end

  -- Change directory
  vim.cmd(M.config.change_directory_command .. " " .. vim.fn.fnameescape(path))
  
  -- Clear jump list if configured
  if M.config.clearjumps_on_change then
    vim.cmd("clearjumps")
  end
  
  -- Update on change if configured
  if M.config.update_on_change then
    vim.cmd(M.config.update_on_change_command)
  end

  vim.notify("Switched to worktree: " .. path, vim.log.levels.INFO)
  return true
end

-- List all worktrees
function M.list()
  local worktrees = M.get_worktrees()
  
  if #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.INFO)
    return
  end

  print("Git Worktrees:")
  for _, wt in ipairs(worktrees) do
    local status = wt.is_current and " (current)" or ""
    local locked = wt.locked and " [LOCKED]" or ""
    print(string.format("  %s -> %s%s%s", wt.branch, wt.path, status, locked))
  end
end

-- Switch to a worktree (interactive)
function M.switch()
  local worktrees = M.get_worktrees()
  
  if #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  local choices = {}
  for i, wt in ipairs(worktrees) do
    local status = wt.is_current and " (current)" or ""
    table.insert(choices, string.format("%s -> %s%s", wt.branch, wt.path, status))
  end

  vim.ui.select(choices, {
    prompt = "Switch to worktree:",
  }, function(choice, idx)
    if choice and idx then
      M.switch_worktree(worktrees[idx].path)
    end
  end)
end

-- Backward compatibility wrapper
function M.switch_to(branch_name)
  local worktrees = M.get_worktrees()
  for _, wt in ipairs(worktrees) do
    if wt.branch == branch_name then
      return M.switch_worktree(wt.path)
    end
  end
  vim.notify("Worktree not found: " .. branch_name, vim.log.levels.ERROR)
  return false
end

-- Get current branch
local function get_current_branch()
  local cmd = "git branch --show-current"
  local result, success = execute_command(cmd)
  if success and result ~= "" then
    return vim.trim(result)
  end
  return nil
end

-- Get branches that are already used by worktrees
local function get_used_branches()
  local worktrees = M.get_worktrees()
  local used = {}
  
  -- Add current branch
  local current = get_current_branch()
  if current then
    used[current] = true
  end
  
  -- Add worktree branches
  for _, wt in ipairs(worktrees) do
    if wt.branch and wt.branch ~= "(bare)" and wt.branch ~= "(detached)" then
      used[wt.branch] = true
    end
  end
  
  return used
end

-- Get available branches for creating worktrees
function M.get_all_branches()
  local cmd = "git branch -a --format='%(refname:short)'"
  local result, success = execute_command(cmd)
  
  if not success then
    return {}
  end
  
  local branches = {}
  local seen = {}
  local used_branches = get_used_branches()
  
  for branch in result:gmatch("[^\r\n]+") do
    branch = vim.trim(branch)
    if branch ~= "" and not branch:match("HEAD") then
      -- Clean up remote branch names
      local clean_branch = branch:gsub("^origin/", ""):gsub("^upstream/", "")
      
      -- Only add if not already seen and not already used by a worktree
      if not seen[clean_branch] and not used_branches[clean_branch] then
        seen[clean_branch] = true
        table.insert(branches, clean_branch)
      end
    end
  end
  
  return branches
end

-- Export helper functions for telescope integration
M.execute_command = execute_command

return M