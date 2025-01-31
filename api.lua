-[[ MIT LICENSE HEADER

  Copyright © 2017 Jordan Irwin (AntumDeluge)

  See: LICENSE.txt

  For: https://github.com/AntumMT/mod-hidename
--]]

--- Hide Name API
--
--  @topic api


local S = core.get_translator(prophunt.modname)


-- START: compatibility with mods that provide "invisibility"

local msupport = {
	invisibility = invisibility,
	invisible = invisible,
}

if msupport.invisible and msupport.invisible.toggle then
	local invis_toggle_orig = msupport.invisible.toggle
	msupport.invisible.toggle = function(user, ...)
		if prophunt.hidden(user:get_nametag_attributes(), user:get_player_name()) then
			-- don't unhide player nametag
			return
		end

		return invis_toggle_orig(user, ...)
	end
end

-- END:


--- Checks if player's nametag is hidden.
--
--  @tparam table nametag_data Nametag data retrieved by *player:get_nametag_attributes()*.
--  @tparam[opt] string pname Player name.
--  @treturn bool `true` if player's nametag is hidden
function prophunt.hidden(nametag_data, pname)
	if prophunt.use_alpha then
		return nametag_data.color.a == 0
	end

	-- check "invisibility" mod
	if msupport.invisibility and msupport.invisibility[pname] then
		return true
	end

	if nametag_data.text then
		return nametag_data.text:len() > 0 and nametag_data.text:trim() == ""
	end

	return false
end


--- Messages info to player about nametag text & visibility.
--
--  @tparam string name Name of player to check & message
function prophunt.tellStatus(name)
	local player = core.get_player_by_name(name)
	local nametag = player:get_nametag_attributes()

	local status = "Status: @1"
	if prophunt.hidden(nametag, name) then
		status = S(status, S("hidden"))
	else
		status = S(status, S("visible"))
	end

	-- Use stored text or name parameter value if nametag.text is empty
	if not nametag.text or nametag.text:trim() == "" then
		nametag.text = player:get_meta():get_string("nametag_stored_text")
		if nametag.text:trim() == "" then
			nametag.text = name
		end
	end

	core.chat_send_player(name, S("Nametag: @1", nametag.text))
	core.chat_send_player(name, status)
end


--- Hides a player's nametag.
--
--  @tparam string name Name of player whose nametag should be made hidden
--  @treturn bool `true` if player's nametag is hidden
function prophunt.hide(name)
	local player = core.get_player_by_name(name)
	local nametag = player:get_nametag_attributes()

	if prophunt.hidden(nametag, name) then
		core.chat_send_player(name, S("Nametag is already hidden"))
		return true
	end

	local pmeta = player:get_meta()
	if prophunt.use_alpha then
		-- Preserve nametag alpha level
		pmeta:set_int("nametag_stored_alpha", nametag.color.a)

		-- Set nametag alpha level to 0
		nametag.color.a = 0
		player:set_nametag_attributes(nametag)
	else
		-- preserve original nametag text (might be different than player name)
		pmeta:set_string("nametag_stored_text", nametag.text)
		-- preserve original nametag bg color (we store entire color
		-- because bgcolor attribute can be boolean)
		pmeta:set_string("nametag_stored_bgcolor", core.serialize(nametag.bgcolor))

		-- remove text from nametag
		nametag.text = " " -- HACK: empty nametag triggers using player name
		nametag.bgcolor = {a=0, r=255, g=255, b=255} -- can't just set alpha because may be a boolean value

		player:set_nametag_attributes(nametag)
	end

	if prophunt.hidden(player:get_nametag_attributes(), name) then
		core.chat_send_player(name, S("Nametag is now hidden"))
	else
		core.chat_send_player(name, S("ERROR: Could not hide nametag"))
		core.log("error", "Could not set nametag to \"hidden\" for player " .. name)
		core.log("error", "Please submit an error report to the \"prophunt\" mod developer")
	end
end


--- Makes a player's nametag visible.
--
--  @tparam string name Name of player whose nametag should be made visible
--  @treturn bool `true` if player's nametag is visible
function prophunt.show(name)
	if msupport.invisibility and msupport.invisibility[name] then
		core.chat_send_player(name, S("Cannot make nametag visible while you are invisible"))
		return true
	end

	local player = core.get_player_by_name(name)
	local nametag = player:get_nametag_attributes()

	if not prophunt.hidden(nametag, name) then
		core.chat_send_player(name, S("Nametag is already visible"))
		return true
	end

	local pmeta = player:get_meta()
	if prophunt.use_alpha then
		-- restore nametag alpha level
		nametag.color.a = pmeta:get_int("nametag_stored_alpha")
		player:set_nametag_attributes(nametag)

		-- clean meta info
		player:get_meta():set_string("nametag_stored_alpha", nil)
	else
		-- restore nametag text & bg color
		nametag.text = pmeta:get_string("nametag_stored_text")
		if nametag.text:trim() == "" then
			nametag.text = nil
		end
		nametag.bgcolor = core.deserialize(pmeta:get_string("nametag_stored_bgcolor"))

		player:set_nametag_attributes(nametag)

		-- clean meta info
		pmeta:set_string("nametag_stored_text", nil)
		pmeta:set_string("nametag_stored_bgcolor", nil)
	end

	if not prophunt.hidden(player:get_nametag_attributes(), name) then
		core.chat_send_player(name, S("Nametag is now visible"))
	else
		core.chat_send_player(name, S("ERROR: Could not show nametag"))
		core.log("error", "Could not set nametag to \"visible\" for player " .. name)
		core.log("error", "Please submit an error report to the \"prophunt\" mod developer")
	end
end
