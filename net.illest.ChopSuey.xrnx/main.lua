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

function copy_attributes(from, to, attrs)
	for _,i in pairs(attrs) do
		to[i] = from[i]
	end
end

function selection_to_new_sample()
	local s = renoise.song()

	local ins = s.selected_instrument
	local smp = s.selected_sample
	local smpidx = s.selected_sample_index
	local buf = smp.sample_buffer

	if( not buf.has_sample_data ) then
		renoise.app():show_status("No sample!")
		return
	end

	local sel = buf.selection_range
	local slen = sel[2] - sel[1] + 1

	if( slen == buf.number_of_frames ) then
		renoise.app():show_status("Nothing selected!")
		return
	end

	-- first, let's create the sample that will consist of
	-- the current selection

	local new = ins:insert_sample_at(smpidx + 1)
	local nbuf = new.sample_buffer

	if( not nbuf:create_sample_data(buf.sample_rate, buf.bit_depth,
	                                buf.number_of_channels, slen) ) then
		renoise.app():show_error("Couldn't create sample!")
		return
	end

	-- copy data to new sample
	for fr = 1, nbuf.number_of_frames do
		for ch = 1, buf.number_of_channels do
			nbuf:set_sample_data(ch, fr,
				buf:sample_data(ch, sel[1] - 1 + fr))
		end
	end

	copy_attributes(smp, new, {"loop_mode", "base_note", "fine_tune", "autoseek"})

	-- TODO: what
	new["name"] = ("chopped #%d"):format(smpidx)
	nbuf:finalize_sample_data_changes()

	-- now we'll create a replacement sample for the original one
	-- this will have the audio data on either side of the selection
	-- (i.e. just like if you had pressed "cut" or "delete")

	local new = ins:insert_sample_at(smpidx + 1)
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

	copy_attributes(smp, new, {"name", "loop_mode", "base_note", "fine_tune", "autoseek"})

	nbuf:finalize_sample_data_changes()

	-- remove the original sample now that we've got a replacement
	ins:delete_sample_at(smpidx)

	-- and select the new, chopped sample
	s.selected_sample_index = smpidx + 1
end
