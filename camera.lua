local Camera = {}
Camera.__index = Camera

setmetatable(Camera, {
    __call = function (cls, ...)
      return cls:new(...)
    end,
  })

function Camera:new(w, h)
    local self = setmetatable({}, Camera)
    self.w = w
    self.h = h
    local ww, wh = love.graphics.getDimensions()
    self.scale = {x=ww/w, y=wh/h}
    self.position = {x=0, y=0}
    return self
end

function Camera:setup()
    love.graphics.push()
    love.graphics.scale(self.scale.x, self.scale.y)
    love.graphics.translate(-self.position.x, -self.position.y)
end

function Camera:unset()
    love.graphics.pop()
end

function Camera:__tostring()
    return "w="..self.w.." h="..self.h.." sx="..self.scale.x.." sy="..self.scale.y
end

return Camera