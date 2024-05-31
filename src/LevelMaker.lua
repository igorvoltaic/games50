--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND

    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- locks and keys
    local isKeyAdded = false
    local isLockAdded = false
    local keyLockRange = math.floor(width * 0.3)
    local chance = 0

    -- insert blank tables into tiles for later access
    for _ = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        tileID = TILE_ID_EMPTY
        local isJumpBlockAdded = false
        chance = (chance + keyLockRange / 100)
        local chancePercent = math.floor(chance / keyLockRange * 100)

        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x < width - 5 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and x < width - 5 then
                blockHeight = 2

                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end

                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil

            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 and x < width - 5 then
                isJumpBlockAdded = true
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        width = TILE_SIZE,
                        height = TILE_SIZE,
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            GSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }

                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    GSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            GSounds['empty-block']:play()
                        end
                    }
                )
            end

            if math.random(100) <= chancePercent and x > width * 0.2 and not isKeyAdded and not isJumpBlockAdded then
                isKeyAdded = true
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'keys-and-locks',
                        width = TILE_SIZE,
                        height = TILE_SIZE,
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,

                        -- make it a random variant
                        frame = math.random(1,4),
                        collidable = false,
                        consumable = true,
                        solid = false,

                        -- gem has its own function to add to the player's score
                        onConsume = function(player, object)
                            GSounds['pickup']:play()
                            player.keyPicked = true
                        end
                    }
                )
            end

            if math.random(100) <= chancePercent and x > width * 0.5 and not isLockAdded and not isJumpBlockAdded then
                isLockAdded = true
                table.insert(objects,

                    -- lock block
                    GameObject {
                        isLock = true,
                        texture = 'keys-and-locks',
                        width = TILE_SIZE,
                        height = TILE_SIZE,
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,

                        -- make it a random variant
                        frame = math.random(5,8),
                        collidable = true,
                        solid = true,

                        onCollide = function(obj)
                            GSounds['empty-block']:play()
                            GSounds['powerup-reveal']:play()
                            GSounds['pickup']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles

    return GameLevel(entities, objects, map)
end
