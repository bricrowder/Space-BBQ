local bbq = {}
bbq.__index = bbq

setmetatable(bbq, {
    __call = function (cls, ...)
      return cls:new(...)
    end,
  })

function bbq:new()
    local self = setmetatable({}, bbq)

    -- the grills
    self.grills = {}

    -- load the grills

    for i, v in ipairs(config.bbq.grills) do
        -- position
        local x, y, w, h, vx, vy, cw, ch = 0, 0, 0, 0, 0, 0, 0, 0
        local image = nil
        if v.position == "top" then
            x = cam.w/2
            y = v.height/2
            w = v.width
            h = v.height
            vx = v.velocity
            vy = 0
            cw = w
            ch = h
            r = 0
            fr = r + math.pi/2
        elseif v.position == "bottom" then
            x = cam.w/2
            y = cam.h - v.height/2
            w = v.width
            h = v.height
            vx = v.velocity
            vy = 0
            cw = w
            ch = h
            r = math.pi
            fr = r - math.pi/2
        elseif v.position == "left" then
            x = v.width/2
            y = cam.h/2
            w = v.width
            h = v.height
            vx = 0
            vy = v.velocity
            cw = h
            ch = w
            r = (math.pi*3)/2
            fr = r + math.pi
        elseif v.position == "right" then
            x = cam.w - v.width/2
            y = cam.h/2
            w = v.width
            h = v.height
            vx = 0
            vy = v.velocity
            cw = h
            ch = w
            r = math.pi/2
            fr = r
        end

        local images = {}
        local parts = cw/8-2
        local partsperhealth = math.floor(parts/config.bbq.health)
        -- flags for the parts
        local partsindex = {}
        for i=1, parts, 1 do
            partsindex[i] = true
        end

        for i=config.bbq.health, 1, -1 do
            -- grill canvas
            images[i] = love.graphics.newCanvas(cw, ch)
            love.graphics.setCanvas(images[i])
            -- grill ends
            love.graphics.draw(getImage("grill-end"), 0, 0)
            love.graphics.draw(getImage("grill-end"), cw-8, 0)
            -- see if we need to remove any parts?
            if i < config.bbq.health then
                for i=1, partsperhealth, 1 do
                    local found = false
                    while not(found) do
                        local p = math.random(1, parts)
                        if partsindex[p] then
                            partsindex[p] = false
                            found = true
                        end
                    end
                end
            end

            -- grill parts
            for i=1, #partsindex, 1 do
                if partsindex[i] then
                    love.graphics.draw(getImage("grill-part"), i*8, 4)
                end
            end
            love.graphics.setCanvas()            
        end

        -- grill fire
        local fire = love.graphics.newParticleSystem(getImage("particle-fire"), 512)
        fire:setDirection(fr)
        fire:setEmissionArea("uniform", cw/2 - getImage("particle-fire"):getWidth()/2, 0)
        fire:setEmissionRate(256)
        fire:setParticleLifetime(0.5,0.75)
        fire:setSpeed(32,64)
        fire:setSizes(1,0.25)
        fire:setColors(
            -- {1,1,0,0.5},
            -- {0,1,0,0.5},
            -- {0.5,0.5,0.5,0.5},
            -- {0.5,0.5,0.5,0}
            {1,1,0,0.5},
            {1,0.5,0,0.5},
            {0.5,0.5,0.5,0.5},
            {0.5,0.5,0.5,0}
        )

        -- setup parthit table
        local parthit = {}
        for i=1, partsperhealth, 1 do
            table.insert(parthit, 
                {
                    x=0,
                    y=0,
                    a=0,
                    s=0,
                    spinspeed=0
                }
            )
        end
        local endhit = {}
        for i=1, 2, 1 do
            table.insert(endhit, 
                {
                    x=0,
                    y=0,
                    a=0,
                    s=0,
                    spinspeed=0
                }
            )
        end

        table.insert(self.grills, 
            {
                type = v.position,
                health = config.bbq.health,
                state = "active",       -- makeinactive, inactive
                w = w,
                h = h,
                images = images,
                r = r,
                fr = fr,
                vx = vx,
                vy = vy,
                body = love.physics.newBody(world, x, y, "static"),
                shape = love.physics.newRectangleShape(w, h),
                fire = fire,
                parthit = parthit,
                endhit = endhit,
                hit = false,
                hittimer = 0
            }
        )
        self.grills[#self.grills].fixture = love.physics.newFixture(self.grills[#self.grills].body, self.grills[#self.grills].shape)
        self.grills[#self.grills].fixture:setCategory(config.physicsgroups.bbq)
        self.grills[#self.grills].fixture:setMask(config.physicsgroups.rightbounds)
    end

    return self
end

function bbq:update(dt)
    for i, v in ipairs(self.grills) do
        if v.state == "makeinactive" then
            v.state = "inactive"
            v.body:setActive(false)
        end
    end

    for i, v in ipairs(self.grills) do
        if v.state == "active" then
            local x, y = v.body:getPosition()
            if v.type == "top" or v.type == "bottom" then
                x = x + v.vx * dt
                if x - v.w/2 <= 0 or x + v.w/2 >= cam.w then
                    v.vx = -v.vx
                end
            elseif v.type == "left" or v.type == "right" then
                y = y + v.vy * dt    
                if y - v.h/2 <= 0 or y + v.h/2 >= cam.h then
                    v.vy = -v.vy
                end
            end
            v.body:setPosition(x, y)
            v.fire:update(dt)
        end
        if v.hit then
            v.hittimer = v.hittimer + dt
            if v.hittimer >= config.bbq.hittimermax then
                v.hittimer = 0
                v.hit = false
            else
                for j, k in ipairs(v.parthit) do
                    k.x = k.x + config.bbq.hitspeed * math.cos(k.a) * dt
                    k.y = k.y + config.bbq.hitspeed * math.sin(k.a) * dt
                    k.s = k.s + k.spinspeed * dt
                end
                if v.health <= 0 then
                    for j, k in ipairs(v.endhit) do
                        k.x = k.x + config.bbq.hitspeed * math.cos(k.a) * dt
                        k.y = k.y + config.bbq.hitspeed * math.sin(k.a) * dt
                        k.s = k.s + k.spinspeed * dt
                    end
                end
            end
        end
    end
end

function bbq:draw()
    for i, v in ipairs(self.grills) do
        if v.hit then
            for j, k in ipairs(v.parthit) do
                love.graphics.draw(getImage("grill-part"), k.x, k.y, k.s, 1, 1, getImage("grill-part"):getWidth()/2, getImage("grill-part"):getHeight()/2)
            end
            if v.health <= 0 then
                for j, k in ipairs(v.endhit) do
                    love.graphics.draw(getImage("grill-end"), k.x, k.y, k.s, 1, 1,  getImage("grill-end"):getWidth()/2, getImage("grill-end"):getHeight()/2)
                end
            end
        end
        if v.state == "active" then
            love.graphics.draw(v.fire, v.body:getX(), v.body:getY(), v.r)
            love.graphics.draw(v.images[v.health], v.body:getX(), v.body:getY(), v.r, 1, 1, v.images[v.health]:getWidth()/2, v.images[v.health]:getHeight()/2)
            if debug then
                love.graphics.polygon("line", v.body:getWorldPoints(v.shape:getPoints()))
            end
        end
    end
end

return bbq