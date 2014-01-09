# emma #

Simple Lua Entity Framework using tags. emma is a way to organize objects (as classes using middleclass) and perform operations on them without having to manually keep track of instantiated objects. This is intended for use in a game engine. 

See main.lua for a full example that will run in löve. This framework should technically work in an lua environment, but I happen to like löve. 

### Usage: ###

	-- place wherever you need it
	local emma = require 'path.to.emma'

(You may have to change/remove the require to 'middleclass' in emma.lua if you are using the library already and have another place/version.)

All entities that you create and wish to use with emma must extend the included 'Entity' class.
e.g.: Person = class('Person', Entity)

Entity includes 3 functions that aren't required, but are helpful.
	start() -- called once on instantiation of the object
	update(dt) -- intended to be used with Emma.update
	draw() -- intended to be used with Emma.draw
By default, these functions don't do anything. 

### Mixins: ###

middle class also enables the use of mixins. See their documentation (or main.lua) for example usage. 

### Available functions: ###

	--[[
	Adds a class to the Entity pool with the given tags. The class can be instantiated after this.
	@param string class - class name that is subclassed from Entity
	@param table tags - list of string tags that categorize this class (required)
	--]]
	Emma.addEntity(class, tags)

	--[[
	Instantiates and returns a new instance of the given class. The instance is cached and will be reused 
	after Emma.destroy is called
	@param string class - class name that is subclassed from Entity and has been added to the Entity Pool
	@param ... - passthrough variables to class constructor
	@return instance
	]]
	Emma.instantiate(class, ...)

	--[[
	Returns a table with all instances with the given tags
	@param table tags - list of string tags
	@return table - list of active instances with those tags
	--]]
	Emma.findAll(tags)

	--[[
	Given an instance, sets it to inactive
	@param instance - instance to destroy
	--]]
	function Emma.destroy(instance)

	--[[
	Calls update on the matching instances
	@param number dt - delta time
	@param table tags - list of string tags
	--]]
	function Emma.update(dt, tags)

	--[[
	Calls draw on the matching instances
	@param table tags - list of string tags
	--]]
	function Emma.draw(tags)