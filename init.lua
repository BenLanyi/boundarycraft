print("Mod Loaded")


local aPlayer = nil
local boundaries = {
    x1 = 5,
    x2 = -5,
    z1 = 5,
    z2 = -5
}

minetest.register_chatcommand("foo", {
    privs = {
        interact = true
    },
    func = function(name, param)
        return true, "You said " .. param .. "!"
    end
})

minetest.chat_send_all("This is a chat message to all players")


minetest.register_on_joinplayer(function(player)
    minetest.chat_send_all("Give a warm welcome to "..player:get_player_name().."!")
    aPlayer = player
    aPlayer:setpos({x = 0, y = 10, z = 0})
end)

minetest.register_on_chat_message(function(name, message)
	if name == "singleplayer"
	and message == "home" then
		minetest.chat_send_all("setting position")
        aPlayer:setpos({x = 0, y = 10, z = 0})
        local currentPosition = aPlayer:getpos()
        print(currentPosition.x)
	end
end)

-- Check boundary so that player cant walk outside designated area
minetest.register_globalstep(function(dtime)
    for _, p in ipairs(minetest.get_connected_players()) do
        local currentPosition = p:getpos()
        if currentPosition.x > boundaries.x1 then
            p:setpos({x = currentPosition.x - 0.1, y = currentPosition.y, z = currentPosition.z})
        end
        if currentPosition.x < boundaries.x2 then
            p:setpos({x = currentPosition.x + 0.1, y = currentPosition.y, z = currentPosition.z})
        end
        if currentPosition.z > boundaries.z1 then
            p:setpos({x = currentPosition.x, y = currentPosition.y, z = currentPosition.z - 0.1})
        end
        if currentPosition.z < boundaries.z2 then
            p:setpos({x = currentPosition.x, y = currentPosition.y, z = currentPosition.z + 0.1})
        end
    end
  end)

-- Prevent player from destroying nodes outside of their boundary
local old_node_dig = minetest.node_dig
function minetest.node_dig(pos, node, digger)
	-- if pos. then
	-- 	return	
    -- else
        print(pos.x)
		return old_node_dig(pos, node, digger)
	-- end
end