-- display
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.colorcolumn = "80"
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true

-- indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- editing
vim.opt.undofile = true
vim.opt.splitbelow = true
vim.opt.splitright = true

-- tell neovim's built-in SQL syntax to use the PostgreSQL dialect
vim.g.sql_type_default = "pgsql"

-- psql opens temp files named "psql.edit.N.sql" — ensure they get SQL filetype
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "psql.edit.*" },
  command = "setfiletype sql",
})

-- SQL-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "sql",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
    -- proper comment formatting for -- and /* */ styles
    vim.opt_local.comments = "s1:/*,mb: *,ex:*/,:--"
    vim.opt_local.commentstring = "-- %s"
    vim.opt_local.formatoptions:remove("r")
    vim.opt_local.formatoptions:remove("o")

    -- <leader>u  → uppercase the current word (SQL keyword convention)
    vim.keymap.set("n", "<leader>u", "gUiw", { buffer = true, desc = "Uppercase word" })
    -- <leader>l  → lowercase the current word
    vim.keymap.set("n", "<leader>l", "guiw", { buffer = true, desc = "Lowercase word" })
  end,
})
