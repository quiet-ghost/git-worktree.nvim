local M = {}

-- Configuration
M.config = {
  worktree_dir = ".worktrees",
  auto_switch = true,
  telescope_integration = true,
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

-- Execute shell command and return output
local function execute_command(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return nil, "Failed to execute command"
  end
  local result = handle:read("*a")
  local success = handle:close()
  return result, success and nil or "Command failed"
end

-- Create a new worktree
function M.create(branch_name)
  if not is_git_repo() then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  if not branch_name or branch_name == "" then
    branch_name = vim.fn.input("Branch name: ")
    if branch_name == "" then
      vim.notify("Branch name required", vim.log.levels.WARN)
      return
    end
  end

  local git_root = get_git_root()
  if not git_root then
    vim.notify("Could not find git root", vim.log.levels.ERROR)
    return
  end

  -- Use the git wt alias we created
  local cmd = string.format("cd %s && echo 'y' | git wt %s", git_root, branch_name)
  local result, err = execute_command(cmd)
  
  if err then
    vim.notify("Failed to create worktree: " .. (result or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  vim.notify("Worktree created: " .. branch_name, vim.log.levels.INFO)
  
  -- Auto-switch if enabled
  if M.config.auto_switch then
    M.switch_to(branch_name)
  end
end

-- Remove a worktree
function M.remove(branch_name)
  if not is_git_repo() then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  if not branch_name or branch_name == "" then
    -- Show interactive removal
    M.remove_interactive()
    return
  end

  local git_root = get_git_root()
  if not git_root then
    vim.notify("Could not find git root", vim.log.levels.ERROR)
    return
  end

  -- Use the git wtr alias we created
  local cmd = string.format("cd %s && git wtr %s", git_root, branch_name)
  local result, err = execute_command(cmd)
  
  if err then
    vim.notify("Failed to remove worktree: " .. (result or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  vim.notify("Worktree removed: " .. branch_name, vim.log.levels.INFO)
end

-- Interactive worktree removal
function M.remove_interactive()
  local worktrees = M.get_worktrees()
  if #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  local choices = {}
  for i, wt in ipairs(worktrees) do
    table.insert(choices, string.format("%d. %s", i, wt.branch))
  end

  vim.ui.select(choices, {
    prompt = "Select worktree to remove:",
  }, function(choice, idx)
    if choice and idx then
      local confirm = vim.fn.confirm("Remove worktree '" .. worktrees[idx].branch .. "'?", "&Yes\n&No", 1)
      if confirm == 1 then
        M.remove(worktrees[idx].branch)
      end
    end
  end)
end

-- Get list of worktrees
function M.get_worktrees()
  if not is_git_repo() then
    return {}
  end

  local git_root = get_git_root()
  if not git_root then
    return {}
  end

  local cmd = "git worktree list --porcelain"
  local result, err = execute_command(cmd)
  
  if err or not result then
    return {}
  end

  local worktrees = {}
  local current_wt = {}
  
  for line in result:gmatch("[^\r\n]+") do
    if line:match("^worktree ") then
      if current_wt.path then
        table.insert(worktrees, current_wt)
      end
      current_wt = { path = line:match("^worktree (.+)") }
    elseif line:match("^branch ") then
      current_wt.branch = line:match("^branch refs/heads/(.+)")
    elseif line:match("^HEAD ") then
      current_wt.head = line:match("^HEAD (.+)")
    end
  end
  
  if current_wt.path then
    table.insert(worktrees, current_wt)
  end

  -- Filter for .worktrees directory
  local filtered = {}
  for _, wt in ipairs(worktrees) do
    if wt.path:match("/" .. M.config.worktree_dir .. "/") then
      wt.branch = wt.branch or vim.fn.fnamemodify(wt.path, ":t")
      table.insert(filtered, wt)
    end
  end

  return filtered
end

-- List all worktrees
function M.list()
  local worktrees = M.get_worktrees()
  
  if #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.INFO)
    return
  end

  print("Worktrees:")
  for _, wt in ipairs(worktrees) do
    print(string.format("  %s -> %s", wt.branch, wt.path))
  end
end

-- Switch to a worktree
function M.switch()
  local worktrees = M.get_worktrees()
  
  if #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  local choices = {}
  for i, wt in ipairs(worktrees) do
    table.insert(choices, string.format("%s (%s)", wt.branch, wt.path))
  end

  vim.ui.select(choices, {
    prompt = "Switch to worktree:",
  }, function(choice, idx)
    if choice and idx then
      M.switch_to(worktrees[idx].branch)
    end
  end)
end

-- Switch to specific worktree
function M.switch_to(branch_name)
  local git_root = get_git_root()
  if not git_root then
    vim.notify("Could not find git root", vim.log.levels.ERROR)
    return
  end

  local worktree_path = git_root .. "/" .. M.config.worktree_dir .. "/" .. branch_name
  
  if vim.fn.isdirectory(worktree_path) == 0 then
    vim.notify("Worktree not found: " .. branch_name, vim.log.levels.ERROR)
    return
  end

  vim.cmd("cd " .. worktree_path)
  vim.notify("Switched to worktree: " .. branch_name, vim.log.levels.INFO)
end

return M