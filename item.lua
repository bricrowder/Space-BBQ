local Item = {}
Item.__index = Item

setmetatable(Item, {
    __call = function (cls, ...)
      return cls:new(...)
    end,
})

function Item:new()
    local self = setmetatable({}, Item)

    -- type of item (food, asteroid, etc)
    local list = nil
    -- if math.random() <= config.item.powerupchance then
    --     list = powerups
    -- end
    -- if not(list) and math.random() <= config.item.healthchance then
    --     list = health
    -- end
    if not(list) and math.random() <= config.item.foodchance then
        list = foods
    end
    if not(list) and math.random() <= config.item.asteroidchance then
        list = asteroids
    end

    


    local i = list[math.random(1,#list)]
    -- local i = config.items[math.random(1,#config.items)]
    self.type = i.type
    self.touches = 0

    self.body = love.physics.newBody(world, cam.w + 32, math.random(config.item.spawnoffset, cam.h - config.item.spawnoffset), "dynamic")

    self.image = getImage(i.image)

    if i.shape == "rectangle" then
        self.shape = love.physics.newRectangleShape(i.width, i.height)
    elseif i.shape == "circle" then
        self.shape = love.physics.newCircleShape(i.radius)
    end
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.body:setMass(i.mass)
    -- set category and mask against left/right walls
    if self.type == 1 then
        self.fixture:setCategory(config.physicsgroups.item)
    else
        self.fixture:setCategory(config.physicsgroups.asteroid)
    end

    self.fixture:setMask(config.physicsgroups.playerboundary, config.physicsgroups.rightbounds)
    self.fixture:setRestitution(i.bounce)
    self.body:setLinearVelocity(math.random(i.velocitymin, i.velocitymax), 0)
    self.body:setAngularVelocity(math.random(i.rotatemin, i.rotatemax))
    
    -- removal & death states
    self.remove = false
    self.death = false

    -- particle emitter on removal
    self.removaleffect = love.graphics.newParticleSystem(getImage("particle"), 64)
    self.removaleffect:setParticleLifetime(0.5,0.5)
    self.removaleffect:setSpeed(64,64)
    self.removaleffect:setSpread(math.pi*2)
    self.removaleffect:setColors({1,0,0,1},{1,0,0,0})

    -- particle emitter for trail
    self.traileffect = love.graphics.newParticleSystem(getImage("particle"), 192)
    self.traileffect:setParticleLifetime(3,3)
    self.traileffect:setSizes(1,0)
    self.traileffect:setEmissionRate(64)
    self.traileffect:setColors({1,0,0,1},{0,1,0,1},{0,0,1,1})
    self.traileffect:stop()

    return self
end

function Item:update(dt)
    -- flag for removal if out of camera
    if self.body:getX() <= -32 or self.body:getX() >= cam.w + 32 or self.body:getY() <= -32 or self.body:getY() >= cam.h + 32 then
        self.death = true
        self.traileffect:stop()
    end
    -- update particle systems
    self.removaleffect:update(dt)
    self.traileffect:setPosition(self.body:getX(), self.body:getY())
    self.traileffect:update(dt)
end

function Item:draw()
    -- draw particles
    love.graphics.draw(self.removaleffect, self.body:getX(), self.body:getY())
    love.graphics.draw(self.traileffect, 0, 0)

    -- draw item
    if not(self.death) then
        love.graphics.draw(self.image, self.body:getX(), self.body:getY(), self.body:getAngle(), 1, 1, self.image:getWidth()/2, self.image:getHeight()/2)
        love.graphics.print(self.touches, self.body:getX(), self.body:getY())
        if debug then
            if self.shape:getType() == "circle" then
                love.graphics.circle("line", self.body:getX(), self.body:getY(), self.shape:getRadius())
            elseif self.shape:getType() == "polygon" then
                love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
            end
        end
    end
end

return Item