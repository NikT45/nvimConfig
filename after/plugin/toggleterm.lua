-- Removed exec-based system in favor of count-based system below

local Terminal = require("toggleterm.terminal").Terminal

--[[

local function get_buf_size()
  local cbuf = vim.api.nvim_get_current_buf()
  local bufinfo = vim.tbl_filter(function(buf)
    return buf.bufnr == cbuf
  end, vim.fn.getwininfo(vim.api.nvim_get_current_win()))[1]
  if not bufinfo then return { width = -1, height = -1 } end
  return { width = bufinfo.width, height = bufinfo.height }
end
local function get_dynamic_terminal_size(direction, size)
  if direction ~= "float" and type(size) == "number" and size > 0 and size < 1 then
    local buf_sizes = get_buf_size()
    local base = (direction == "horizontal") and buf_sizes.height or buf_sizes.width
    return math.floor(base * size)
  end
  return size
end

]]
local function get_buf_size()
    local cbuf = vim.api.nvim_get_current_buf()
    local bufinfo = vim.tbl_filter(function(buf)
        return buf.bufnr == cbuf
    end, vim.fn.getwininfo(vim.api.nvim_get_current_win()))[1]
    if bufinfo == nil then
        return { width = -1, height = -1 }
    end
    return { width = bufinfo.width, height = bufinfo.height }
end


local function get_dynamic_terminal_size(direction, size)
    size = size
    if direction ~= "float" and tostring(size):find(".", 1, true) then
        size = math.min(size, 1.0)
        local buf_sizes = get_buf_size()
        local buf_size = direction == "horizontal" and buf_sizes.height or buf_sizes.width
        return buf_size * size
    else
        return size
    end
end
-- One cache per direction+count so toggling reuses the same instance
local term_cache = {} -- key: "h:101", "v:201", etc.

local function toggle_term(direction, size_ratio, base_offset)
  local n = vim.v.count1 -- defaults to 1 when no count is given
  local count = base_offset + n
  local key = string.format("%s:%d", direction, count)

  if not term_cache[key] then
    term_cache[key] = Terminal:new({
      cmd = vim.o.shell,
      direction = direction,
      count = count,
    })
  end

  local size = get_dynamic_terminal_size(direction, size_ratio)
  term_cache[key]:toggle(size, direction)
end
-- Count-based terminal toggles: use 1<C-x>, 2<C-x>, 3<C-x>, etc. for multiple instances
vim.keymap.set({ "n", "t" }, "<C-x>", function()
  toggle_term("horizontal", 0.30, 100) -- 101, 102, 103...
end, { desc = "Toggle horizontal terminal (countable)", silent = true })

vim.keymap.set({ "n", "t" }, "<C-v>", function()
  toggle_term("vertical", 0.50, 200) -- 201, 202, 203...
end, { desc = "Toggle vertical terminal (countable)", silent = true })

vim.keymap.set({ "n", "t" }, "<C-f>", function()
  toggle_term("float", nil, 300) -- 301, 302, ...
end, { desc = "Toggle floating terminal (countable)", silent = true })


require("toggleterm").setup {
  size = 20,
  open_mapping = [[<c-t>]],
  hide_numbers = false, -- hide the number column in toggleterm buffers
  shade_filetypes = {},
  shade_terminals = true,
  shading_factor = 2, -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
  start_in_insert = true,
  insert_mappings = true, -- whether or not the open mapping applies in insert mode
  persist_size = false,
  direction = "float",
  close_on_exit = true, -- close the terminal window when the process exits
  shell = nil, -- change the default shell
  float_opts = {
    border = "rounded",
    winblend = 0,
    highlights = {
      border = "Normal",
      background = "Normal",
    },
  },
  winbar = {
    enabled = true,
    name_formatter = function(term) --  term: Terminal
      return term.count
    end,
  },
}

vim.cmd [[
augroup terminal_setup | au!
autocmd TermOpen * nnoremap <buffer><LeftRelease> <LeftRelease>i
autocmd TermEnter * startinsert!
augroup end
]]

vim.api.nvim_create_autocmd({ "TermEnter" }, {
  pattern = { "*" },
  callback = function()
    vim.cmd "startinsert"
    _G.set_terminal_keymaps()
  end,
})

local opts = { noremap = true, silent = true }
function _G.set_terminal_keymaps()
  vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
end
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true })


-- Resize windows
vim.keymap.set("n", "<leader><Left>",  ":vertical resize -5<CR>", { silent = true })
vim.keymap.set("n", "<leader><Right>", ":vertical resize +5<CR>", { silent = true })
vim.keymap.set("n", "<leader><Up>",    ":resize +3<CR>",          { silent = true })
vim.keymap.set("n", "<leader><Down>",  ":resize -3<CR>",          { silent = true })
local opts = { noremap = true, silent = true }

-- Terminal resize with Alt+arrows (leader key passes through to shell)
vim.keymap.set("t", "<M-Left>",  [[<C-\><C-n>:vertical resize -5<CR>i]], opts)
vim.keymap.set("t", "<M-Right>", [[<C-\><C-n>:vertical resize +5<CR>i]], opts)
vim.keymap.set("t", "<M-Up>",    [[<C-\><C-n>:resize +3<CR>i]],          opts)
vim.keymap.set("t", "<M-Down>",  [[<C-\><C-n>:resize -3<CR>i]],          opts)

-- Custom terminals
local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new {
  cmd = "lazygit",
  dir = "git_dir",
  direction = "float",
  float_opts = {
    border = "rounded",
  },
  -- function to run on opening the terminal
  on_open = function(term)
    vim.cmd "startinsert!"
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  end,
  -- function to run on closing the terminal
  on_close = function(term)
    vim.cmd "startinsert!"
  end,
}

local bun_outdated = Terminal:new {
  cmd = "bunx npm-check-updates@latest -ui --format group --packageManager bun",
  dir = "git_dir",
  direction = "float",
  float_opts = {
    border = "rounded",
  },
  -- function to run on opening the terminal
  on_open = function(term)
    vim.cmd "startinsert!"
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  end,
  -- function to run on closing the terminal
  on_close = function(term)
    vim.cmd "startinsert!"
  end,
}

local cargo_run = Terminal:new {
  cmd = "cargo run -q",
  dir = "git_dir",
  direction = "float",
  float_opts = {
    border = "rounded",
  },
  -- function to run on opening the terminal
  on_open = function(term)
    vim.cmd "startinsert!"
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  end,
  -- function to run on closing the terminal
  on_close = function(term)
    vim.cmd "startinsert!"
  end,
}

--function _lazygit_toggle()
--  lazygit:toggle()
--end

--function _bun_outdated()
  --bun_outdated:toggle()
--end
--
--function _cargo_run()
  --cargo_run:toggle()
--end

-- Uncomment these lines if you want to use these keybindings
--vim.api.nvim_set_keymap("n", "<leader>gz", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap("n", "<leader>co", "<cmd>lua _bun_outdated()<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap("n", "<leader>cr", "<cmd>lua _cargo_run()<CR>", { noremap = true, silent = true })
