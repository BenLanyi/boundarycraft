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

-- Sets up player configuration from server data
minetest.register_on_joinplayer(
    function(player)
        minetest.chat_send_all("Give a warm welcome to " .. player:get_player_name() .. "!")

        aPlayer.reference = player
        print("player name " .. player:get_player_name())
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
                post_data = '{ "Message" : "blah-1234"}'
            },
            function(res)
                print(res.data)
                setPlayerConfiguration(res.data)
            end
        )
    end
)

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
        -- Set player configuration once it is loaded in from fetch
        if aPlayer.configuration ~= nil and aPlayer.initialised == false then
            print("Group Boundary X2 = " .. aPlayer.configuration["Group"]["GroupBoundary"]["X2"])
            aPlayer.reference:setpos({x = 0, y = 10, z = 0})
            aPlayer.initialised = true
            print("Player Initialised")
        end

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
    print("Group Boundary X2 = " .. aPlayer.configuration["Group"]["GroupBoundary"]["X2"])
end

-- Generates landmass with trees etc.
function generateArea(x1, x2, y, z1, z2)
    clearAreaSurface(x1, x2, y, z1, z2)

    generateLand(x1, x2, y, z1, z2)
    default.grow_new_pine_tree({x = x1 + 1, y = y + 1, z = z1 + 1})
    default.grow_new_apple_tree({x = x1 + 2, y = y + 1, z = z1 + 7})
    default.grow_new_apple_tree({x = x1 + 5, y = y + 1, z = z1 + 7})
    default.grow_new_apple_tree({x = z1 + 4, y = y + 1, z = z1 + 4})
    default.grow_new_apple_tree({x = x1 + 6, y = y + 1, z = z1 + 1})

    generateLake(x2 - 4, x2 - 1, y, z2 - 5, z2 - 1)
    generateGrass(x1, x2, y, z1, z2)

    --generateLand(x2 + 2, x2 + 12, y, z1, z2)
end

-- Clears surface of land mass, anything above level 0
function clearAreaSurface(x1, x2, y, z1, z2)
    local blockToGenerate = "air"
    for xval = x1, x2, 1 do
        for yval = y + 0.5, y + 100, 1 do
            for zval = z1, z2, 1 do
                minetest.set_node({x = xval, y = yval, z = zval}, {name = blockToGenerate})
            end
        end
    end
end

-- Generates land mass
function generateLand(x1, x2, y, z1, z2)
    -- Top layer with grass
    local blockToGenerate = "default:dirt_with_grass"
    for xval = x1, x2, 1 do
        for zval = z1, z2, 1 do
            minetest.set_node({x = xval, y = y, z = zval}, {name = blockToGenerate})
        end
    end
    -- Middle layer of dirt
    local blockToGenerate = "default:dirt"
    for xval = x1, x2, 1 do
        for yval = y - 5, y - 1, 1 do
            for zval = z1, z2, 1 do
                minetest.set_node({x = xval, y = yval, z = zval}, {name = blockToGenerate})
            end
        end
    end
    -- bedrock of obsidian, may need to make indestructable
    local blockToGenerate = "default:obsidian"
    for xval = x1, x2, 1 do
        for zval = z1, z2, 1 do
            minetest.set_node({x = xval, y = y - 6, z = zval}, {name = blockToGenerate})
        end
    end
end

-- Destroys land mass
function emptyWorld()
    local blockToGenerate = "air"
    for xval = -10, 10, 1 do
        for yval = -10, 20, 1 do
            for zval = -10, 10, 1 do
                minetest.set_node({x = xval, y = yval, z = zval}, {name = blockToGenerate})
            end
        end
    end
end

-- Generates grass in random spots within area.
-- Checks nothing already exists in position and dirt with grass is below
function generateGrass(x1, x2, y, z1, z2)
    local xval = nil
    local zval = nil
    for passes = 1, 10, 1 do
        xval = math.random(x1, x2)
        zval = math.random(z1, z2)
        currentNode = minetest.get_node({x = xval, y = y + 1, z = zval})
        nodeBelow = minetest.get_node({x = xval, y = y, z = zval})
        print(nodeBelow.name)
        if currentNode.name == "air" and nodeBelow.name == "default:dirt_with_grass" then
            print("grass generated")
            minetest.set_node({x = xval, y = y + 1, z = zval}, {name = "default:grass_1"})
        end
    end
end

function generateLake(x1, x2, y, z1, z2)
    for xval = x1, x2, 1 do
        for zval = z1, z2, 1 do
            minetest.set_node({x = xval, y = y, z = zval}, {name = "default:water_source"})
        end
    end
end
