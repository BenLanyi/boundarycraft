print("Mod Loaded")

local boundaries = {
    x1 = 10,
    x2 = -10,
    z1 = 10,
    z2 = -10
}

local defaultSpawn = {
    x = 0,
    y = 0,
    z = 500
}

local aPlayer = {
    reference = nil,
    configuration = nil,
    initialised = false
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
        aPlayer.reference = player
        aPlayer.initialised = false
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
                setPlayerConfiguration(res.data)
            end
        )
    end
)

minetest.register_on_chat_message(
    function(name, message)
        if message == "generatearea" then
            minetest.chat_send_all("generating area")
            generateArea()
            aPlayer.reference:setpos({x = 0, y = 10, z = 0})
        end
    end
)

-- Check boundary so that player cant walk outside designated area
minetest.register_globalstep(
    function(dtime)
        if aPlayer.configuration ~= nil and aPlayer.initialised == false then
            print("Group Boundary X2 = " .. aPlayer.configuration["Group"]["GroupBoundary"]["X2"])
            aPlayer.reference:setpos({x = 0, y = 10, z = 0})
            aPlayer.initialised = true
            print("Player Initialised")
        end

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

function setPlayerConfiguration(data)
    aPlayer.configuration = minetest.parse_json(data)
    print("Group Boundary X2 = " .. aPlayer.configuration["Group"]["GroupBoundary"]["X2"])
end

function generateArea()
    local firstLayer = true
    local blockToGenerate = "default:dirt_with_grass"
    for xval = -10, 10, 1 do
        for yval = -5, 0, 1 do
            for zval = -10, 10, 1 do
                minetest.set_node({x = xval, y = yval, z = zval}, {name = blockToGenerate})
            end
        end
    end

    local firstLayer = true
    local blockToGenerate = "default:dirt_with_grass"
    for xval = 12, 22, 1 do
        for yval = -5, 0, 1 do
            for zval = -10, 10, 1 do
                minetest.set_node({x = xval, y = yval, z = zval}, {name = blockToGenerate})
            end
        end
    end
end
