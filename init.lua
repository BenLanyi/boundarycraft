dofile(minetest.get_modpath("boundarycraft") .. "/zones.lua")

print("Mod Loaded")

local playerList = {}

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

-- Show login window when player connects
minetest.register_on_joinplayer(
    function(player)
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

-- Clear player from player list array when leaving
minetest.register_on_leaveplayer(
    function(player)
        playerList[player:get_player_name()] = nil
    end
)

function verifyToken(token, player)
    http_api.fetch(
        {
            url = "http://localhost:3001/auth",
            post_data = '{ "Token" : "' .. token .. '"}'
        },
        function(res)
            local fetchResult = minetest.parse_json(res.data)
            print(dump(fetchResult))
            if fetchResult.Response == "authenticated" then
                -- get player data from api
                -- http_api.fetch(
                --     {
                --         url = "http://localhost:3001/player",
                --         post_data = '{ "Message" : "blah-1234"}'
                --     },
                --     function(res)
                --         setPlayerConfiguration(res.data, player)
                --     end
                -- )
                minetest.log("action", player:get_player_name() .. " connected with valid token")
                setPlayerConfiguration(fetchResult.PlayerData, player)
            else
                minetest.log("action", player:get_player_name() .. " was kicked due to invalid token")
                minetest.kick_player(player:get_player_name(), "Invalid Token")
            end
        end
    )
end

-- Runs every server tick
minetest.register_globalstep(
    function(dtime)
        for _, p in ipairs(minetest.get_connected_players()) do
            -- if player has not initialised set their position to waiting area in the sky
            if playerList[p:get_player_name()] == nil then
                p:setpos({x = 0, y = 29000, z = 0})
            else
                -- keep player inside boundaries
                local currentPosition = p:getpos()
                if currentPosition.x < playerList[p:get_player_name()].configuration.Group.GroupBoundary.X1 then
                    p:setpos(
                        {
                            x = playerList[p:get_player_name()].configuration.Group.GroupBoundary.X1,
                            y = currentPosition.y,
                            z = currentPosition.z
                        }
                    )
                elseif currentPosition.x > playerList[p:get_player_name()].configuration.Group.GroupBoundary.X2 then
                    p:setpos(
                        {
                            x = playerList[p:get_player_name()].configuration.Group.GroupBoundary.X2,
                            y = currentPosition.y,
                            z = currentPosition.z
                        }
                    )
                elseif currentPosition.z < playerList[p:get_player_name()].configuration.Group.GroupBoundary.Z1 then
                    p:setpos(
                        {
                            x = currentPosition.x,
                            y = currentPosition.y,
                            z = playerList[p:get_player_name()].configuration.Group.GroupBoundary.Z1
                        }
                    )
                elseif currentPosition.z > playerList[p:get_player_name()].configuration.Group.GroupBoundary.Z2 then
                    p:setpos(
                        {
                            x = currentPosition.x,
                            y = currentPosition.y,
                            z = playerList[p:get_player_name()].configuration.Group.GroupBoundary.Z2
                        }
                    )
                end
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

function setPlayerConfiguration(data, player)
    local thisPlayer = {
        reference = player,
        configuration = data,
        initialised = true
    }
    playerList[player:get_player_name()] = thisPlayer

    player:setpos(
        {
            x = thisPlayer.configuration.Group.GroupSpawnPoint.X,
            y = 15,
            z = thisPlayer.configuration.Group.GroupSpawnPoint.Z
        }
    )
    --generate area
    generateArea(
        thisPlayer.configuration.Group.GroupBoundary.X1,
        thisPlayer.configuration.Group.GroupBoundary.X2,
        8,
        thisPlayer.configuration.Group.GroupBoundary.Z1,
        thisPlayer.configuration.Group.GroupBoundary.Z2
    )
    --end generate area
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
            local currentPos = playerList[name].reference:getpos()
            clearAreaSurface(currentPos.x, currentPos.x + 20, currentPos.y, currentPos.z, currentPos.z + 20)
        end
        if message == "home" then
            playerList[name].reference:setpos({x = 0, y = 20, z = 0})
        end
        if message == "generatehere" then
            local currentPos = playerList[name].reference:getpos()
            generateArea(currentPos.x, currentPos.x + 20, currentPos.y, currentPos.z, currentPos.z + 20)
        end
    end
)
