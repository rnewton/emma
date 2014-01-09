local e = require 'emma'

------------------------------------------------------------------------------------------------------------------------
-- Player Class
------------------------------------------------------------------------------------------------------------------------
Player = class('Player', Entity)
function Player:initialize(x, y)
	self.shockwaveCooldown = 0
	self.shockwaveReset = 3
end

function Player:start()
	self:initCollidable(0, 0, 20, 20, "dynamic")
end

function Player:update(dt)
	self.collidable_body:setPosition(love.mouse.getX(), love.mouse.getY())

	self.shockwaveCooldown = self.shockwaveCooldown - dt

	if love.mouse.isDown('l') and self.shockwaveCooldown <= 0 then
		self:makeShockwave()
		self.shockwaveCooldown = self.shockwaveReset
	end
end

function Player:draw()
	self:drawCollidable({255,255,255})
end

------------------------------------------------------------------------------------------------------------------------
-- end Player Class
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- Pickup Class
------------------------------------------------------------------------------------------------------------------------
Pickup = class('Pickup', Entity)
function Pickup:initialize()
	self:initCollidable(0, 0, 10, 10, "dynamic")
end

function Pickup:start() 
	local x = math.random(0,love.window.getWidth())
	local y = math.random(0,love.window.getHeight())

	self.collidable_body:setPosition(x, y)
end

function Pickup:update(dt) 
	world:setCallbacks(self.checkCollect)

	if math.random(1,100) == 50 then
		self.collidable_body:applyForce(math.random(-10,10),math.random(-10,10))
	end
end

function Pickup:draw()
	self:drawCollidable({255,0,0})
end

------------------------------------------------------------------------------------------------------------------------
-- end Pickup Class
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Add mixins
-- Note: These are messy, but show how to use tags, physics, etc
------------------------------------------------------------------------------------------------------------------------
Collectable = {
	checkCollect = function(self, other, col)
		if self:getUserData() == nil or other:getUserData() == nil then return end

		if other:getUserData().class.name == 'Player' then 
			e.destroy(self:getUserData())
			pickupCount = pickupCount - 1
		elseif self:getUserData().class.name == 'Player' then 
			e.destroy(other:getUserData())
			pickupCount = pickupCount - 1
		end
	end
}
Pickup:include(Collectable)

Collidable = {
	initCollidable = function(self, x, y, width, height, type)
		self.collidable_body = love.physics.newBody(world, width, height, type)
		self.collidable_body:setPosition(x, y)
		self.collidable_shape = love.physics.newRectangleShape(width, height)
		self.collidable_fixture = love.physics.newFixture(self.collidable_body, self.collidable_shape)
		self.collidable_fixture:setRestitution(0.4)
		self.collidable_fixture:setUserData(self)
	end,

	drawCollidable = function(self, color)
		love.graphics.setColor(color)
		love.graphics.polygon('fill', self.collidable_body:getWorldPoints(self.collidable_shape:getPoints()))
	end,

	isCollidable = function(self)
		return true
	end
}
Player:include(Collidable)
Pickup:include(Collidable)

Shockwave = {
	makeShockwave = function(self)
		assert(type(self.isCollidable) == "function", "This entity must be collidable.")
		local others = e.findAll({'pickups'})
		for _,pickup in pairs(others) do
			local x, y = pickup.collidable_body:getPosition()
			local force = (1/self:distance(x, y)) * 100
			local angle, xcomp, ycomp = self:angle(x, y)
			pickup.collidable_body:applyForce(xcomp * force, ycomp * force)
		end
	end,

	angle = function(self, x, y)
		local mx, my = self.collidable_body:getPosition()
		local dx, dy = x - mx, y - my
		return math.atan2(dy, dx) * 180 / math.pi, dx, dy
	end,

	distance = function(self, x, y)
		assert(type(self.isCollidable) == "function", "This entity must be collidable.")
		local mx, my = self.collidable_body:getPosition()
		return math.sqrt(math.pow((mx - x), 2) + math.pow((my - y), 2))
	end
}
Player:include(Shockwave)

------------------------------------------------------------------------------------------------------------------------
-- Instantiate Entities
------------------------------------------------------------------------------------------------------------------------
e.addEntity('Player', {'players'})
e.addEntity('Pickup', {'pickups'})

------------------------------------------------------------------------------------------------------------------------
-- Löve specific demo below
------------------------------------------------------------------------------------------------------------------------
pickups = {}
nextPickup = 0
pickupCount = 0
maxPickups = 6000

meter = 64
world = {}

math.randomseed(os.time())

function love.load()
	love.mouse.setVisible(false)
	love.graphics.setBackgroundColor({95,95,95})

	love.physics.setMeter(meter)
	world = love.physics.newWorld(0, 0, true)
	p = e.instantiate('Player', 0, 0)

	local w = love.window.getWidth()
	local h = love.window.getHeight()

	-- could make the walls into entities easily
	wallTop = {}
	wallTop.body = love.physics.newBody(world, w, 5)
	wallTop.shape = love.physics.newRectangleShape(w, 5)
	wallTop.fixture = love.physics.newFixture(wallTop.body, wallTop.shape)
	wallTop.body:setPosition(w/2, 0)
	wallBottom = {}
	wallBottom.body = love.physics.newBody(world, w, 5)
	wallBottom.shape = love.physics.newRectangleShape(w, 5)
	wallBottom.fixture = love.physics.newFixture(wallBottom.body, wallBottom.shape)
	wallBottom.body:setPosition(w/2, h)
	wallLeft = {}
	wallLeft.body = love.physics.newBody(world, 5, h)
	wallLeft.shape = love.physics.newRectangleShape(5, h)
	wallLeft.fixture = love.physics.newFixture(wallLeft.body, wallLeft.shape)
	wallLeft.body:setPosition(0, h/2)
	wallRight = {}
	wallRight.body = love.physics.newBody(world, 5, h)
	wallRight.shape = love.physics.newRectangleShape(5, h)
	wallRight.fixture = love.physics.newFixture(wallRight.body, wallRight.shape)
	wallRight.body:setPosition(w, h/2)
end

function love.draw()
	e.draw()

	love.graphics.setColor(0,0,0)
	love.graphics.print("fps: "..love.timer.getFPS(), 0, 0)
	love.graphics.print("pickup count: "..pickupCount, 0, 15)
	love.graphics.print("click to make a shockwave", 0, 30)

	love.graphics.polygon("fill", wallTop.body:getWorldPoints(wallTop.shape:getPoints()))
	love.graphics.polygon("fill", wallBottom.body:getWorldPoints(wallBottom.shape:getPoints()))
	love.graphics.polygon("fill", wallLeft.body:getWorldPoints(wallLeft.shape:getPoints()))
	love.graphics.polygon("fill", wallRight.body:getWorldPoints(wallRight.shape:getPoints()))
end

function love.update(dt)
	world:update(dt)
	e.update(dt, {'players', 'pickups'})

	nextPickup = nextPickup + dt
	if nextPickup > 0.1 and pickupCount < maxPickups then
		nextPickup = 0
		pickupCount = pickupCount + 1
		table.insert(pickups, e.instantiate('Pickup'))
	end
end