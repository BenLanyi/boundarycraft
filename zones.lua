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
