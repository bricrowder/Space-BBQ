local Bounds = {}
Bounds.__index = Bounds

setmetatable(Bounds, {
    __call = function (cls, ...)
      return cls:new(...)
    end,
  })

function Bounds:new()
    local self = setmetatable({}, Bounds)

    self.body = love.physics.newBody(world, 0, 0)
    self.top = {}
    self.top.shape = love.physics.newEdgeShape(0, 0, cam.w, 0)
    self.top.fixture = love.physics.newFixture(self.body, self.top.shape)
    self.top.fixture:setCategory(config.physicsgroups.playerboundary)
    self.bottom = {}
    self.bottom.shape = love.physics.newEdgeShape(0, cam.h, cam.w, cam.h)
    self.bottom.fixture = love.physics.newFixture(self.body, self.bottom.shape)
    self.bottom.fixture:setCategory(config.physicsgroups.playerboundary)
    self.left = {}
    self.left.shape = love.physics.newEdgeShape(0, 0, 0, cam.h)
    self.left.fixture = love.physics.newFixture(self.body, self.left.shape)
    self.left.fixture:setCategory(config.physicsgroups.playerboundary)
    self.right = {}
    self.right.shape = love.physics.newEdgeShape(cam.w, 0, cam.w, cam.h)
    self.right.fixture = love.physics.newFixture(self.body, self.right.shape)
    self.right.fixture:setCategory(config.physicsgroups.playerboundary)
    self.rightbounds = {}
    self.rightbounds.shape = love.physics.newEdgeShape(cam.w - config.bounds.rightboundoffset, 0, cam.w - config.bounds.rightboundoffset, cam.h)
    self.rightbounds.fixture = love.physics.newFixture(self.body, self.rightbounds.shape)
    self.rightbounds.fixture:setCategory(config.physicsgroups.rightbounds)
    return self
end

function Bounds:draw()
    if debug then
        love.graphics.line(self.body:getWorldPoints(self.top.shape:getPoints()))        
        love.graphics.line(self.body:getWorldPoints(self.bottom.shape:getPoints()))        
        love.graphics.line(self.body:getWorldPoints(self.left.shape:getPoints()))        
        love.graphics.line(self.body:getWorldPoints(self.right.shape:getPoints()))        
        love.graphics.line(self.body:getWorldPoints(self.rightbounds.shape:getPoints()))        
    end
end

return Bounds