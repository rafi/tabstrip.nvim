-- Rafi's tabstrip - Unobtrusive tabline for Neovim
-- https://github.com/rafi/tabstrip.nvim

local M = {}

local strings = require('plenary.strings')

local api = vim.api

---@class TabstripConfig
local default_opts = {
	-- Limit maximum of chars per tab, 0 for no limit
	tab_max_chars = 18,
	-- Limit display of directories in path
	max_dirs = 1,
	-- Limit display of characters in each directory in path
	directory_max_chars = 5,

	icons = {
		modified = '+', -- + • ● ◎
		session = '',
	},

	colors = {
		modified = { fg = '#cf6a4c', ctermfg = 2 },
	},

	numeric_charset = { '⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹' },
	-- numeric_charset = {'₀','₁','₂','₃','₄','₅','₆','₇','₈','₉'},
}

---@type TabstripConfig
local opts = {}

-- Setup tabline
---@param user_opts TabstripConfig
function M.setup(user_opts)
	opts = vim.tbl_extend('force', default_opts, user_opts or {})

	api.nvim_create_autocmd('ColorScheme', {
		group = api.nvim_create_augroup('rafi_tabline', {}),
		callback = M.set_highlights,
	})

	M.set_highlights()

	vim.o.tabline = '%!v:lua.rafi_tabline()'
end

---@param number integer
---@param charset table
---@return string
local function numtr(number, charset)
	local result = ''
	for char in tostring(number):gmatch('.') do
		local char_num = tonumber(char)
		if char_num ~= nil then
			result = result .. charset[char_num + 1]
		end
	end
	return result
end

local ok, badge = pcall(require, 'rafi.lib.badge')
if not ok then
	badge = {
		---@return string
		project = function()
			return vim.fn.fnamemodify(vim.loop.cwd(), ':~:t')
		end,
		---@param bufnr integer
		---@return string
		filepath = function(bufnr, _, _, _)
			bufnr = bufnr or 0
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			return vim.fn.fnamemodify(bufname, ':~:t')
		end,
		---@param bufnr integer
		---@return string
		icon = function(bufnr)
			bufnr = bufnr or 0
			local buftype = vim.bo[bufnr].buftype
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
			if not has_devicons then
				return ''
			end
			if buftype == '' and bufname == '' then
				return devicons.get_default_icon().icon
			end
			local f_name = vim.fn.fnamemodify(bufname, ':t')
			local f_extension = vim.fn.fnamemodify(bufname, ':e')
			local icon, _ = devicons.get_icon(f_name, f_extension)
			if icon == '' or icon == nil then
				icon = devicons.get_default_icon().icon
			end
			return icon
		end,
	}
end

--- Return tab raw tab entry.
---@param tabnr integer
---@param current_tabpage integer
---@return string
local function make_tab(tabnr, current_tabpage)
	local line = ''

	-- Left-side of single tab
	if tabnr == current_tabpage then
		line = line .. '%#TabLineSelEdge#%#TabLineSel# '
	else
		line = line .. '%#TabLineEdge#%#TabLine# '
	end

	-- Get file-name with custom cutoff settings
	local winbuf = api.nvim_win_get_buf(api.nvim_tabpage_get_win(tabnr))
	local fpath =
		badge.filepath(winbuf, opts.max_dirs, opts.directory_max_chars, '_tab')

	-- File-type icon
	line = line .. badge.icon(winbuf) .. ' '

	-- Make tab
	local tab = fpath:gsub('%%', '%%%%')

	-- Count windows and look for modified buffers
	local modified = false
	local win_count = 0
	local tab_windows = api.nvim_tabpage_list_wins(tabnr)
	for _, winnr in ipairs(tab_windows) do
		local bufnr = api.nvim_win_get_buf(winnr)
		if vim.bo[bufnr].buftype == '' then
			win_count = win_count + 1
			if not modified and vim.bo[bufnr].modified then
				modified = true
			end
		end
	end

	-- Window count
	if win_count > 1 then
		tab = tab .. numtr(win_count, opts.numeric_charset)
	end

	-- Limit tab size
	if opts.tab_max_chars > 0 then
		if api.nvim_strwidth(tab) > opts.tab_max_chars then
			tab = strings.truncate(tab, opts.tab_max_chars, '…', -1)
		end

		local extra_space = 18 - api.nvim_strwidth(tab)
		if extra_space > 0 then
			local pad = ' '
			local side = extra_space / 2
			tab = pad:rep(math.floor(side)) .. tab .. pad:rep(math.ceil(side))
		end
	end

	line = line .. '%' .. tostring(tabnr) .. 'T' .. tab

	-- Add a symbol if one of the buffers in the tab page is modified
	if modified then
		if tabnr == current_tabpage then
			line = line .. '%#TabLineIconModifiedSel#'
		else
			line = line .. '%#TabLineIconModified#'
		end
		line = line .. opts.icons.modified .. '%*'
	end

	-- Right-side
	if tabnr == current_tabpage then
		if not modified then
			line = line .. '%#TabLineSel# '
		end
		line = line .. '%#TabLineSelEdge#'
	else
		line = line .. '%#TabLineEdge#'
		if not modified then
			line = line .. ' '
		end
	end

	return line
end

-- Main line display function.
---@return string
function _G.rafi_tabline()
	if vim.fn.exists('g:SessionLoad') == 1 then
		-- Skip tabline render during session loading
		return ''
	end

	-- Active project name
	local line = '%#TabLineProject# '
		.. badge.project()
		.. ' %#TabLineProjectEdge#'

	-- Iterate through all tabs and collect labels
	local current_tabpage = api.nvim_get_current_tabpage()
	for _, tabnr in ipairs(api.nvim_list_tabpages()) do
		line = line .. make_tab(tabnr, current_tabpage)
	end

	line = line .. '%#TabLineFill#%='

	-- Session indicator
	if vim.v['this_session'] ~= '' then
		local session_name = vim.fn.tr(vim.v['this_session'], '%', '/')
		line = line
			.. '%#TabLine#'
			.. vim.fn.fnamemodify(session_name, ':t:r')
			.. ' '
			.. opts.icons.session
			.. ' '
	end

	return line
end

-- Highlights
function M.set_highlights()
	if vim.fn.has('nvim-0.9') == 0 then
		M.set_highlights_pre9()
		return
	end

	local hi_tabline = api.nvim_get_hl(0, { name = 'TabLine' })
	local hi_tablinesel = api.nvim_get_hl(0, { name = 'TabLineSel' })

	-- Current project color
	api.nvim_set_hl(0, 'TabLineProject', { link = 'Pmenu', default = true })
	local hi_tablineproject = api.nvim_get_hl(0, { name = 'TabLineProject' })

	api.nvim_set_hl(0, 'TabLineProjectEdge', {
		fg = hi_tablineproject.bg,
		bg = hi_tabline.bg,
		ctermfg = hi_tablineproject.ctermbg,
		ctermbg = hi_tabline.ctermbg,
		default = true,
	})
	-- Non-selected tabline edge
	api.nvim_set_hl(0, 'TabLineEdge', {
		fg = hi_tabline.bg,
		bg = hi_tabline.bg,
		ctermfg = hi_tabline.ctermbg,
		ctermbg = hi_tabline.ctermbg,
		default = true,
	})
	-- Selected tab edge color
	api.nvim_set_hl(0, 'TabLineSelEdge', {
		fg = hi_tabline.bg,
		bg = hi_tablinesel.bg,
		ctermfg = hi_tabline.ctermbg,
		ctermbg = hi_tablinesel.ctermbg,
		default = true,
	})
	-- Modified icon color
	api.nvim_set_hl(0, 'TabLineIconModified', {
		fg = opts.colors.modified.fg,
		bg = hi_tabline.bg,
		ctermfg = opts.colors.modified.ctermfg,
		ctermbg = hi_tabline.ctermbg,
		default = true,
	})
	api.nvim_set_hl(0, 'TabLineIconModifiedSel', {
		fg = opts.colors.modified.fg,
		bg = hi_tablinesel.bg,
		ctermfg = opts.colors.modified.ctermfg,
		ctermbg = hi_tablinesel.ctermbg,
		default = true,
	})
end

---@deprecated
function M.set_highlights_pre9()
	local tabline_bg = api.nvim_get_hl_by_name('TabLine', true).background
	local tabline_ctermbg = api.nvim_get_hl_by_name('TabLine', false).background

	-- Current project color
	api.nvim_set_hl(0, 'TabLineProject', { link = 'Pmenu', default = true })
	api.nvim_set_hl(0, 'TabLineProjectEdge', {
		fg = api.nvim_get_hl_by_name('TabLineProject', true).background,
		bg = tabline_bg,
		ctermfg = api.nvim_get_hl_by_name('TabLineProject', false).background,
		ctermbg = tabline_ctermbg,
		default = true,
	})
	-- Non-selected tabline edge
	api.nvim_set_hl(0, 'TabLineEdge', {
		fg = tabline_bg,
		bg = tabline_bg,
		ctermfg = tabline_ctermbg,
		ctermbg = tabline_ctermbg,
		default = true,
	})
	-- Selected tab edge color
	api.nvim_set_hl(0, 'TabLineSelEdge', {
		fg = tabline_bg,
		bg = api.nvim_get_hl_by_name('TabLineSel', true).background,
		ctermfg = tabline_ctermbg,
		ctermbg = api.nvim_get_hl_by_name('TabLineSel', false).background,
		default = true,
	})
	-- Modified icon color
	api.nvim_set_hl(0, 'TabLineIconModified', {
		fg = opts.colors.modified.fg,
		bg = tabline_bg,
		ctermfg = 2,
		ctermbg = tabline_ctermbg,
		default = true,
	})
	api.nvim_set_hl(0, 'TabLineIconModifiedSel', {
		fg = opts.colors.modified.fg,
		bg = api.nvim_get_hl_by_name('TabLineSel', true).background,
		ctermfg = 2,
		ctermbg = api.nvim_get_hl_by_name('TabLineSel', false).background,
		default = true,
	})
end

return M
