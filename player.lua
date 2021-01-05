local Player = {}
Player.__index = Player

setmetatable(Player, {
    __call = function (cls, ...)
      return cls:new(...)
    end,
})

function Player:new()
    local self = setmetatable({}, Player)

    self.body = love.physics.newBody(world, cam.w/4, cam.h/2, "dynamic")
    self.body:setFixedRotation(true)
    if config.player.shape == "rectangle" then
        self.shape = love.physics.newRectangleShape(config.player.width, config.player.height)
    elseif config.player.shape == "circle" then
        self.shape = love.physics.newCircleShape(config.player.radius)
    end
    
    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setCategory(config.physicsgroups.player)
    self.body:setMass(config.player.mass)

    self.hit = false
    self.hittimer = 0

    return self
end

function Player:update(dt)
    if not(self.hit) then
        local x, y = 0, 0

        if love.keyboard.isDown("up") then
            y = -1
        end
        if love.keyboard.isDown("down") then
            y = y + 1
        end
        if love.keyboard.isDown("left") then
            x = -1
        end
        if love.keyboard.isDown("right") then
            x = x + 1
        end
        
        x = x * config.player.velocity
        y = y * config.player.velocity

        self.body:setLinearVelocity(x, y)
    else
        self.hittimer = self.hittimer + dt
        if self.hittimer >= config.player.hittimermax then
            self.hit = false
            self.hittimer = 0
        end
    end
end

function Player:draw()
    love.graphics.draw(getImage("player"), self.body:getX(), self.body:getY(), 0, 1, 1, getImage("player"):getWidth()/2,  getImage("player"):getHeight()/2)

    if debug then
        if self.shape:getType() == "circle" then
            love.graphics.circle("line", self.body:getX(), self.body:getY(), self.shape:getRadius())
        elseif self.shape:getType() == "polygon" then
            love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
        end
    end
end

return Player