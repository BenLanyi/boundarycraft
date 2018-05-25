print("Mod Loaded")

local boundaries = {
    x1 = 5,
    x2 = -5,
    z1 = 5,
    z2 = -5
}

local defaultSpawn = {
    x = 0,
    y = 0,
    z = 500
}

local aPlayer = {
    playerobj = nil,
    --boundaries = defaultBoundaries,
    spawn = defaultSpawn
}

local http_api = minetest.request_http_api()
if not http_api then
    print("ERROR: in minetest.conf, this mod must be in secure.http_mods!")
end

minetest.register_chatcommand(
    "foo",
    {
        privs = {
            interact = true
        },
        func = function(name, param)
            return true, "You said " .. param .. "!"
        end
    }
)

minetest.chat_send_all("This is a chat message to all players")

minetest.register_on_joinplayer(
    function(player)
        minetest.chat_send_all("Give a warm welcome to " .. player:get_player_name() .. "!")
        aPlayer.playerobj = player

        http_api.fetch(
            {
                url = "http://localhost:3001/test",
                post_data = '{ "Message" : "message from minetest"}'
            },
            function(res)
                print(res.data)
            end
        )
        -- get player data from api
        http_api.fetch(
            {
                url = "http://localhost:3001/player",
                post_data = '{ "Message" : "blah#1234"}'
            },
            function(res)
                print(res.data)
                local decoded = minetest.parse_json(res.data)
                print("Group Boundary X1 = " .. decoded["Group"]["GroupBoundary"]["X1"])
                -- aPlayer.spawn.x = res.data.Group.GroupSpawnPoint.X
                -- aPlayer.spawn.y = res.data.Group.GroupSpawnPoint.Y
                -- aPlayer.spawn.z = res.data.Group.GroupSpawnPoint.Z
                -- aPlayer.boundaries.x1 = res.data.Group.GroupBoundary.X1
                -- aPlayer.boundaries.x2 = res.data.Group.GroupBoundary.x2
                -- aPlayer.boundaries.z1 = res.data.Group.GroupBoundary.Z1
                -- aPlayer.boundaries.z2 = res.data.Group.GroupBoundary.Z2
            end
        )

        aPlayer.playerobj:setpos({x = 0, y = 10, z = 0})
    end
)

minetest.register_on_chat_message(
    function(name, message)
        if name == "singleplayer" and message == "home" then
            minetest.chat_send_all("setting position")
            aPlayer:setpos({x = 0, y = 10, z = 0})
            local currentPosition = aPlayer:getpos()
            print(currentPosition.x)
        end
    end
)

-- Check boundary so that player cant walk outside designated area
minetest.register_globalstep(
    function(dtime)
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
    end
)

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
