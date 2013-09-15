local e = require 'emma'

------------------------------------------------------------------------------------------------------------------------
-- Player Class
------------------------------------------------------------------------------------------------------------------------
Player = class('Player', Entity)
function Player:initialize(x, y)
	self.startX = x
	self.startY = y
	self.x = x
	self.y = y
end

function Player:start()
	self.x = self.startX
	self.y = self.startY
end

function Player:update(dt)
	self.x = love.mouse.getX()
	self.y = love.mouse.getY()
end

function Player:draw()
	love.graphics.setColor({255,255,255})
	love.mouse.setVisible(false)
	love.graphics.rectangle('fill', self.x, self.y, 10, 10)
end

------------------------------------------------------------------------------------------------------------------------
-- end Player Class
------------------------------------------------------------------------------------------------------------------------

e.addEntity('Player', {'players'})
local p = e.instantiate('Player', 0, 0)

------------------------------------------------------------------------------------------------------------------------
-- Pickup Class
------------------------------------------------------------------------------------------------------------------------
Pickup = class('Pickup', Entity)
function Pickup:initialize()
	self.x = 0
	self.y = 0
end

function Pickup:start() 
	self.x = math.random(0,300)
	self.y = math.random(0,300)
end

function Pickup:update(dt) 
	if math.sqrt( (self.x - p.x)^2 + (self.y - p.y)^2 ) < 10 then 
		e.destroy(self)
		pickupCount = pickupCount - 1
	end
end

function Pickup:draw()
	love.graphics.setColor({255,0,0})
	love.graphics.rectangle('fill', self.x, self.y, 10, 10)
end

------------------------------------------------------------------------------------------------------------------------
-- end Pickup Class
------------------------------------------------------------------------------------------------------------------------

e.addEntity('Pickup', {'powerups'})
local pickups = {}
local nextPickup = 0
pickupCount = 0
local maxPickups = 6

function love.draw()
	love.graphics.setBackgroundColor({95,95,95})
	e.draw()
end

function love.update(dt)
	e.update(dt, {'players', 'pickups'})

	nextPickup = nextPickup + dt
	if nextPickup > 1 and pickupCount < maxPickups then
		nextPickup = 0
		pickupCount = pickupCount + 1
		table.insert(pickups, e.instantiate('Pickup'))
	end
end