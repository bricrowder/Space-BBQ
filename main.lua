-- load stuff
Json = require "json"
Camera = require "camera"
Player = require "player"
Item = require "item"
Bounds = require "bounds"
bbq = require "bbq"

function love.load()
    -- Setup the randomizer
    math.randomseed(os.time())
    -- need to pop a few... wierd thing
    math.random()
    math.random()
    math.random()    

    -- setup graphics environment
    love.graphics.setDefaultFilter("nearest","nearest")

    -- load config
    config = Json.opendecode("config.json")

    -- makes lists of food items, asteroid items, etc
    foods = {}
    asteroids = {}
    health = {}
    powerups = {}
    for i, v in ipairs(config.items) do
        if v.type == config.item.food then
            table.insert(foods, v)
        elseif v.type == config.item.asteroid then
            table.insert(asteroids, v)
        elseif v.type == config.item.health then
            table.insert(health, v)
        elseif v.type == config.item.powerup then
            table.insert(powerups, v)
        end
    end

    -- load assets
    images = {}
    for i, v in ipairs(config.images) do
        table.insert(images,
            {
                name = v.name,
                image = love.graphics.newImage(v.file)
            }
        )
    end
    img_particle = love.graphics.newImage("assets/particle.png")

    -- load physics environment - no gravity and objects can sleep
    world = love.physics.newWorld()
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    -- debug flag - draws physics shapes & debug text
    debug = true

    -- load camera
    cam = Camera(config.camera.width, config.camera.height)

    -- create background1
    background = love.graphics.newCanvas(config.camera.width, config.camera.height)
    love.graphics.setCanvas(background)
    for i=1, config.background.starcount, 1 do
        local r = math.random(1,2)
        local a = math.random()
        love.graphics.setColor(1,1,1,a)
        love.graphics.circle("fill",math.random(1, cam.w), math.random(1, cam.h), r)
    end
    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1,1)

    -- background 2
    background2 = love.graphics.newCanvas(config.camera.width, config.camera.height)
    love.graphics.setCanvas(background2)
    for i=1, config.background.starcount, 1 do
        local a = math.random() - 0.5
        love.graphics.setColor(1,1,1,a)
        love.graphics.circle("fill",math.random(1, cam.w), math.random(1, cam.h), 1)
    end
    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1,1)

    -- background position
    bgoffset = 0
    bgoffset2 = 2

    -- load boundaries
    b = Bounds()

    -- load player
    p = Player()

    -- init item list
    items = {}
    -- spawn counter
    itemcounter = 0
    itemcountermax = math.random(config.item.itemcountermin,config.item.itemcountermax)

    -- create the space BBQ!
    spacebbq = bbq()

    print(cam)
end

function love.update(dt)
    -- update world, player
    world:update(dt)
    p:update(dt)

    -- update items (checks if they should be removed because they are leaving the play area)
    for i=#items, 1, -1 do
        items[i]:update(dt)
        -- something is not working iwth this??
        if items[i].death and items[i].removaleffect:getCount() <= 0 and items[i].traileffect:getCount() <= 0 then
            items[i].remove = true
        end 
        if items[i].remove then
            table.remove(items, i)
        end
    end

    -- add to item list
    itemcounter = itemcounter + dt
    if itemcounter >= itemcountermax then
        -- reset counter and max
        itemcounter = 0
        itemcountermax = math.random(config.item.itemcountermin,config.item.itemcountermax)
        -- create a new item
        table.insert(items, Item())
    end

    -- update background position
    bgoffset = bgoffset - dt * config.background.velocity
    if bgoffset <= -cam.w then
        bgoffset = 0
    end
    bgoffset2 = bgoffset2 - dt * config.background.velocity2
    if bgoffset2 <= -cam.w then
        bgoffset2 = 0
    end

    -- update bbq!
    spacebbq:update(dt)
end

function love.draw()

    -- draw scaled
    cam:setup()
    -- draw background
    love.graphics.draw(background, bgoffset, 0)
    love.graphics.draw(background, cam.w + bgoffset, 0)
    love.graphics.draw(background2, bgoffset2, 0)
    love.graphics.draw(background2, cam.w + bgoffset2, 0)
    -- boundary
    b:draw()
    -- player
    p:draw()
    -- bbq
    spacebbq:draw()
    -- items
    for i, v in ipairs(items) do
        v:draw()
    end
    -- draw normal
    cam:unset()

    if debug then
        love.graphics.print("Items:" .. #items, 10, 10)
    end
end

function beginContact(a, b, coll)
    -- references for the items
    local t = nil
    local t2 = nil

    -- flags for types of collisions
    local food_bbq = false
    local food_asteroid_player = false
    local asteroid_bbq = false

    -- figure out what collision it is
    if (a:getCategory() == config.physicsgroups.item and b:getCategory() == config.physicsgroups.bbq) or (a:getCategory() == config.physicsgroups.bbq and b:getCategory() == config.physicsgroups.item)then
        food_bbq = true
        if a:getCategory() == config.physicsgroups.item then
            t = a
        else
            t = b
        end
    elseif a:getCategory() == config.physicsgroups.item and b:getCategory() == config.physicsgroups.asteroid then
        food_asteroid_player = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.item and b:getCategory() == config.physicsgroups.item then
        food_asteroid_player = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.item and b:getCategory() == config.physicsgroups.player then
        food_asteroid_player = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.asteroid and b:getCategory() == config.physicsgroups.asteroid then
        food_asteroid_player = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.asteroid and b:getCategory() == config.physicsgroups.item then
        food_asteroid_player = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.asteroid and b:getCategory() == config.physicsgroups.player then
        food_asteroid_player = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.asteroid and b:getCategory() == config.physicsgroups.bbq then
        food_asteroid_player = true
        asteroid_bbq = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.bbq and b:getCategory() == config.physicsgroups.asteroid then
        food_asteroid_player = true
        asteroid_bbq = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.player and b:getCategory() == config.physicsgroups.asteroid then
        food_asteroid_player = true
        t = a
        t2 = b
    elseif a:getCategory() == config.physicsgroups.player and b:getCategory() == config.physicsgroups.item then
        food_asteroid_player = true
        t = a
        t2 = b
    end

    -- we have an item!
    if food_bbq then
        -- check against item fixtures and remove it!
        for i=#items, 1, -1 do
            if items[i].fixture == t then
                if not(items[i].death) then
                    items[i].body:setLinearVelocity(0, 0)
                    items[i].fixture:setMask(1,2,3,4,5,6)
                    items[i].death = true
                    items[i].removaleffect:emit(64)
                    items[i].traileffect:stop()
                    break
                end
            end 
        end
    end

    -- we have an item!
    if food_asteroid_player then
        for i, v in ipairs(items) do
            if v.fixture == t or v.fixture == t2 then
                v.traileffect:start()
                v.touches = v.touches + 1
            end
        end
    end

    if asteroid_bbq then
        for i, v in ipairs(spacebbq.grills) do
            if v.state == "active" then
                if v.fixture == t or v.fixture == t2 then
                    if v.fixture:getCategory() == config.physicsgroups.bbq then
                        v.health = v.health - 1
                        v.hit = true
                        for j, k in ipairs(v.parthit) do
                            k.x = math.random(v.body:getX() - v.w/2, v.body:getX() + v.w/2)
                            k.y = math.random(v.body:getY() - v.h/2, v.body:getY() + v.h/2)
                            local tr = v.r + math.pi/2
                            k.a = math.random(tr - math.pi/8, tr + math.pi/8)
                            k.spinspeed = math.random() * math.pi*2
                            k.s = math.random() * math.pi*2
                        end
                        if v.health <= 0 then
                            for j, k in ipairs(v.endhit) do
                                k.x = math.random(v.body:getX() - v.w/2, v.body:getX() + v.w/2)
                                k.y = math.random(v.body:getY() - v.h/2, v.body:getY() + v.h/2)
                                local tr = v.r + math.pi/2
                                k.a = math.random(tr - math.pi/8, tr + math.pi/8)
                                k.spinspeed = math.random() * math.pi*2
                                k.s = math.random() * math.pi*2
                            end    
                            v.state = "makeinactive"
                        end
                    end
                end
            end
        end
    end
end

function getImage(name)
    for i, v in ipairs(images) do
        if v.name == name then
            return v.image
        end
    end
    -- default in case name isn't found
    return images[1].image
end

function love.keypressed(key)
    if key == "d" then
        debug = not(debug)
    end
    if key == "b" then
        for i, v in ipairs(spacebbq.grills) do
            if v.state == "inactive" then
                v.body:setActive(true)
                v.state = "active"
                v.health = config.bbq.health
            end
        end
    end    
end

-- these callbacks aren't used
function endContact(a, b, coll)
end
function preSolve(a, b, coll)
end
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end
