local M = {}
local namespace = vim.api.nvim_create_namespace("curb_extmarks")

local uv = vim.uv or vim.loop
local timer
local loading_extmark_id
local loading_group

---@param buf number
---@param start_row number
---@param start_col number
---@param end_row number
---@param end_col number
---@return number
function M.create_extmark(buf, start_row, start_col, end_row, end_col)
	local line_count = vim.api.nvim_buf_line_count(buf)
	if end_row >= line_count then
		end_row = line_count - 1
	end
	local line = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or ""
	if end_col > #line then
		end_col = #line
	end

	return vim.api.nvim_buf_set_extmark(buf, namespace, start_row, start_col, {
		end_row = end_row,
		end_col = end_col,
		hl_group = "Comment",
	})
end

---@param buf number
---@param extmark_id number
function M.clear_extmark(buf, extmark_id)
	if extmark_id and vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.api.nvim_buf_del_extmark, buf, namespace, extmark_id)
	end
end

---@param buf number
---@param extmark_id number
---@return number|nil, number|nil
function M.get_extmark_rows(buf, extmark_id)
	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
	if not mark or #mark == 0 then
		return nil, nil
	end
	return mark[1], mark[3].end_row
end

---@param buf number
---@param extmark_id number
function M.start_loading(buf, extmark_id)
	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
	if not mark or #mark == 0 then
		return
	end

	local s_row, e_row = mark[1], mark[3].end_row
	local original_lines = vim.api.nvim_buf_get_lines(buf, s_row, e_row + 1, false)
	local expected_str = table.concat(original_lines, "\n")

	local spinner_frames = { "𜱩", "𜱪", "◌", "○" }
	local frame = 1

	local function update_spinner()
		loading_extmark_id = vim.api.nvim_buf_set_extmark(buf, namespace, s_row, 0, {
			id = loading_extmark_id,
			virt_lines = { { { " " .. spinner_frames[frame] .. " Curb is processing...", "DiagnosticInfo" } } },
			virt_lines_above = true,
		})
	end

	update_spinner()
	timer = uv.new_timer()
	timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			if not vim.api.nvim_buf_is_valid(buf) then
				M.stop_loading(buf)
				return
			end
			frame = frame % #spinner_frames + 1
			update_spinner()
		end)
	)

	loading_group = vim.api.nvim_create_augroup("CurbLoading_" .. extmark_id, { clear = true })
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = loading_group,
		buffer = buf,
		callback = function()
			local m = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
			if not m or #m or m[1] > m[3].end_row then
				return
			end
			local current_lines = vim.api.nvim_buf_get_lines(buf, m[1], m[3].end_row + 1, false)
			if table.concat(current_lines, "\n") ~= expected_str then
				local cursor = vim.api.nvim_win_get_cursor(0)
				vim.api.nvim_buf_set_lines(buf, m[1], m[3].end_row + 1, false, original_lines)
				pcall(vim.api.nvim_win_set_cursor, 0, cursor)
				vim.notify("Curb: Selection is locked during processing", vim.log.levels.WARN)
			end
		end,
	})
end

---@param buf number
function M.stop_loading(buf)
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
	if loading_extmark_id then
		M.clear_extmark(buf, loading_extmark_id)
		loading_extmark_id = nil
	end
	if loading_group then
		pcall(vim.api.nvim_del_augroup_by_id, loading_group)
		loading_group = nil
	end
end

---@param buf number
---@param extmark_id number
---@param new_lines string|table
---@param reprompt_cb function
function M.replace_interactive(buf, extmark_id, new_lines, reprompt_cb)
	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
	if not mark or #mark == 0 then
		return
	end

	local s_row, e_row = mark[1], mark[3].end_row
	local original_lines = vim.api.nvim_buf_get_lines(buf, s_row, e_row + 1, false)

	local cs = vim.bo[buf].commentstring
	if cs == "" or not cs:find("%%s") then
		cs = "-- %s"
	end
	local accept_str = cs:format("Accept (delete line to apply)")
	local reject_str = cs:format("Reject (delete line to cancel)")
	local reprompt_str = cs:format("Reprompt (delete line to retry)")

	if type(new_lines) == "string" then
		new_lines = vim.split(new_lines, "\n")
	end
	local display_lines = vim.deepcopy(new_lines)
	table.insert(display_lines, accept_str)
	table.insert(display_lines, reject_str)
	table.insert(display_lines, reprompt_str)

	vim.api.nvim_buf_set_lines(buf, s_row, e_row + 1, false, display_lines)
	M.clear_extmark(buf, extmark_id)

	local interactive_id = vim.api.nvim_buf_set_extmark(buf, namespace, s_row, 0, {
		end_row = s_row + #display_lines - 1,
		end_col = 0,
		hl_group = "DiffAdd",
	})

	local base_str = table.concat(display_lines, "\n")
	local group = vim.api.nvim_create_augroup("CurbInteractive_" .. interactive_id, { clear = true })

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		buffer = buf,
		callback = function()
			local m = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, interactive_id, { details = true })
			-- Safety: check if extmark is valid and not collapsed inversely
			if not m or #m == 0 then
				return
			end
			local cur_s, cur_e = m[1], m[3].end_row
			if cur_s > cur_e then
				return
			end

			local current = vim.api.nvim_buf_get_lines(buf, cur_s, cur_e + 1, false)
			local current_str = table.concat(current, "\n")
			if current_str == base_str then
				return
			end

			local has_a = current_str:find(accept_str, 1, true)
			local has_r = current_str:find(reject_str, 1, true)
			local has_p = current_str:find(reprompt_str, 1, true)

			if
				(not has_a and has_r and has_p)
				or (has_a and not has_r and has_p)
				or (has_a and has_r and not has_p)
			then
				vim.api.nvim_del_augroup_by_id(group)
				if not has_a then
					vim.api.nvim_buf_set_lines(buf, cur_s, cur_e + 1, false, new_lines)
					vim.notify("Curb: Applied", vim.log.levels.INFO)
				elseif not has_r then
					vim.api.nvim_buf_set_lines(buf, cur_s, cur_e + 1, false, original_lines)
					vim.notify("Curb: Cancelled", vim.log.levels.WARN)
				elseif not has_p then
					vim.api.nvim_buf_set_lines(buf, cur_s, cur_e + 1, false, original_lines)
					local new_mark = M.create_extmark(buf, cur_s, 0, cur_s + #original_lines - 1, 0)
					vim.schedule(function()
						reprompt_cb(new_mark)
					end)
				end
				M.clear_extmark(buf, interactive_id)
			else
				local cursor = vim.api.nvim_win_get_cursor(0)
				vim.api.nvim_buf_set_lines(buf, cur_s, cur_e + 1, false, display_lines)
				pcall(vim.api.nvim_win_set_cursor, 0, cursor)
				vim.notify("Curb: Locked. Delete an action line to proceed.", vim.log.levels.WARN)
			end
		end,
	})
end

return M
