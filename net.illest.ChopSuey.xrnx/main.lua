--
-- chop suey
-- 2010 william light
-- will@illest.net
--
-- holla back
--


--
-- registration
--

renoise.tool():add_keybinding {
	name   = "Sample Editor:Chop Suey:Selection to New Sample",
	invoke = function ()
		selection_to_new_sample()
	end
}

renoise.tool():add_menu_entry {
	name = "Sample Editor:Chop Suey:Selection to New Sample",
	invoke = function ()
		selection_to_new_sample()
	end
}


--
-- things
--

function selection_to_new_sample()
	local s = renoise.song()

	local ins = s.selected_instrument
	local smp = s.selected_sample
	local smpidx = s.selected_sample_index

	local buf = smp.sample_buffer
	local sel = buf.selection_range

	-- I really dislike this 1-indexed bullshit
	local slen = sel[2] - sel[1] + 1

	if( slen == buf.number_of_frames ) then
		renoise.app():show_status("Nothing selected!")
		return
	end

	local new = ins.insert_sample_at(ins, smpidx + 1)
	local nbuf = new.sample_buffer

	if( not nbuf:create_sample_data(buf.sample_rate, buf.bit_depth,
	                                buf.number_of_channels, slen) ) then
		renoise.app():show_error("Couldn't create sample!")
		return
	end

	local ch, fr

	-- copy data to new sample
	for fr = 1, nbuf.number_of_frames do
		for ch = 1, buf.number_of_channels do
			nbuf:set_sample_data(ch, fr,
				buf:sample_data(ch, sel[1] - 1 + fr))
		end
	end

	local to_copy = {"loop_mode", "base_note", "fine_tune", "autoseek"}
	local i

	for _,i in pairs(to_copy) do new[i] = smp[i] end

	-- TODO: what
	new["name"] = ("chopped #%d"):format(smpidx)
	nbuf:finalize_sample_data_changes()

	-- create a new, truncated sample
	local new = ins.insert_sample_at(ins, smpidx + 1)
	local nbuf = new.sample_buffer

	if( not nbuf:create_sample_data(buf.sample_rate, buf.bit_depth,
	                                buf.number_of_channels, buf.number_of_frames - slen) ) then
		renoise.app():show_error("Couldn't create sample!")
		renoise.app():undo()
		return
	end

	for ch = 1, buf.number_of_channels do
		for fr = 1, sel[1] - 1 do
			nbuf:set_sample_data(ch, fr,
				buf:sample_data(ch, fr))
		end

		for fr = sel[1], buf.number_of_frames - slen do
			nbuf:set_sample_data(ch, fr,
				buf:sample_data(ch, fr + slen))
		end
	end

	table.insert(to_copy, "name")
	for _,i in pairs(to_copy) do new[i] = smp[i] end

	nbuf:finalize_sample_data_changes()

	ins:delete_sample_at(smpidx)
	s.selected_sample_index = smpidx + 1
end
