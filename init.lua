dofile(minetest.get_modpath("boundarycraft") .. "/zones.lua")

print("Mod Loaded")

local playerList = {}

local boundaries = {
    x1 = -10,
    x2 = 10,
    z1 = -10,
    z2 = 10
}

local defaultSpawn = {
    x = 0,
    y = 0,
    z = 500
}

-- Player object
local aPlayer = {
    reference = nil,
    configuration = nil,
    initialised = false
}

-- Get http api to be able to fetch etc.
local http_api = minetest.request_http_api()
if not http_api then
    print("ERROR: in minetest.conf, this mod must be in secure.http_mods!")
end

-- Handle login form submission
minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "mymod:login" then
            if fields.token ~= nil then
                print("token: " .. fields.token)
                verifyToken(fields.token, player)
                return true
            else
                -- sends invalid token to enable handling of escape from form
                verifyToken("x", player)
            end
        end

        return false
    end
)

-- Sets up player configuration from server data
minetest.register_on_joinplayer(
    function(player)
        aPlayer.reference = player
        aPlayer.initialised = false
        -- Show Login Window
        minetest.show_formspec(
            player:get_player_name(),
            "mymod:login",
            "size[10,6]" ..
                "label[0,0;Hello, " ..
                    player:get_player_name() ..
                        "]" ..
                            "label[0,1;Please enter your login key to continue ]" ..
                                "field[1,3;3,1;token;Key;]" .. "button_exit[1,3.5;2,1;exit;Login]"
        )
    end
)

function verifyToken(token, player)
    http_api.fetch(
        {
            url = "http://localhost:3001/auth",
            post_data = '{ "Token" : "' .. token .. '"}'
        },
        function(res)
            print(dump(res.data))
            local fetchResult = minetest.parse_json(res.data)
            print("fetch result" .. dump(fetchResult))
            if fetchResult == "authenticated" then
                print("auth success")
                aPlayer.reference = player
                print("player name " .. player:get_player_name())
                -- get player data from api
                http_api.fetch(
                    {
                        url = "http://localhost:3001/player",
                        post_data = '{ "Message" : "blah-1234"}'
                    },
                    function(res)
                        print(res.data)
                        setPlayerConfiguration(res.data)
                    end
                )
            else
                print("auth failed")
                minetest.kick_player(player:get_player_name(), "Invalid Token")
            end
        end
    )
end

-- Set chat message commands
minetest.register_on_chat_message(
    function(name, message)
        if message == "generatearea" then
            minetest.chat_send_all("generating area")
            generateArea(-10, 10, 0, -10, 10)
        end
        if message == "cleararea" then
            minetest.chat_send_all("clearing area")
            local currentPos = aPlayer.reference:getpos()
            clearAreaSurface(currentPos.x, currentPos.x + 20, currentPos.y, currentPos.z, currentPos.z + 20)
        end
        if message == "home" then
            aPlayer.reference:setpos({x = 0, y = 5, z = 0})
        end
        if message == "empty" then
            minetest.chat_send_all("emptying world")
            emptyWorld()
        end
        if message == "generatehere" then
            local currentPos = aPlayer.reference:getpos()
            generateArea(currentPos.x, currentPos.x + 20, currentPos.y, currentPos.z, currentPos.z + 20)
        end
    end
)

-- Check boundary so that player cant walk outside designated area
minetest.register_globalstep(
    function(dtime)
        -- when player joins game hold them in the sky until they are initialised
        if aPlayer.reference ~= nil and aPlayer.initialised == false then
            aPlayer.reference:setpos({x = 0, y = 29000, z = 0})
        end
        -- -- Set player configuration once it is loaded in from fetch
        -- if aPlayer.configuration ~= nil and aPlayer.initialised == true then
        --     print("Group Boundary X2 = " .. aPlayer.configuration["Group"]["GroupBoundary"]["X2"])
        -- end

        -- for _, p in ipairs(minetest.get_connected_players()) do
        --     local currentPosition = p:getpos()
        --     if currentPosition.x < boundaries.x1 then
        --         p:setpos({x = currentPosition.x + 0.1, y = currentPosition.y, z = currentPosition.z})
        --     end
        --     if currentPosition.x > boundaries.x2 then
        --         p:setpos({x = currentPosition.x - 0.1, y = currentPosition.y, z = currentPosition.z})
        --     end
        --     if currentPosition.z < boundaries.z1 then
        --         p:setpos({x = currentPosition.x, y = currentPosition.y, z = currentPosition.z + 0.1})
        --     end
        --     if currentPosition.z > boundaries.z2 then
        --         p:setpos({x = currentPosition.x, y = currentPosition.y, z = currentPosition.z - 0.1})
        --     end
        -- end
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
    print("Group Boundary X1 = " .. aPlayer.configuration["Group"]["GroupBoundary"]["X1"])
    aPlayer.initialised = true
    print("Player Initialised")
    -- local xval = aPlayer.configuration["Group"]["SpawnPoint"]["X"]
    -- local yval = aPlayer.configuration["Group"]["SpawnPoint"]["Y"]
    -- local zval = aPlayer.configuration["Group"]["SpawnPoint"]["Z"]

    aPlayer.reference:setpos({x = 0, y = 15, z = 0})
end
