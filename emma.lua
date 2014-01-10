------------------------------------------------------------------------------------------------------------------------
-- emma - Entity Multi-Managing Assistant
-- 
-- Simple Entity/Pooling Framework for Lua and Love2D
--
-- Usage:
-- local e = require 'emma'
-- 
------------------------------------------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2013 Robert Newton
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
------------------------------------------------------------------------------------------------------------------------
require 'middleclass'

local Emma = {}

--[[
Contains references to all the entity classes available to instantiate
@type table - string -> table (class)
--]]
local _entities = {}

--[[
Contains references to all the tags available to group classes
@type table - string (tag) -> table (class references)
--]]
local _tags = {}

--[[
Contains references to all the instances instantied, active and inactive
@type table - string -> table (active:bool,instance)
--]]
local _instances = {}

--[[
Private function to get the Class (table) from the name (string)
@param string name - name of the class
@return Class (table)
--]]
local _nameToClass = function(name)
	return _G[name]
end

--[[
Private function that checks if the class exists in the Entity Pool
@param string name - class name to check for
@returns bool - true if it exists in _entities, false otherwise
--]]
local _classExists = function(name)
	for _,v in pairs(_entities) do 
		if v.name == name then return true end
	end
	return false
end

--[[
Private function that checks if the class should use emma's recycling
@param string name - class name to check for
@returns bool - true if class recycles, false otherwise
--]]
local _classRecycles = function(name)
	if not _classExists(name) then error("emma: Class doesn't exist", 3) end
	for _,v in pairs(_entities) do 
		if v.name == name then return v.cleanup end
	end
end

--[[
Adds a class to the Entity pool with the given tags. The class can be instantiated after this.
@param string class - class name that is subclassed from Entity
@param table tags - list of string tags that categorize this class (required)
--]]
function Emma.addEntity(class, tags, cleanup)
	if class == nil then error("emma: Class is nil", 3) end
	if tags == nil or #tags == 0 then error("emma: No tags given", 3) end
	if _classExists(class) then error("emma: Class already exists in Entity Pool", 3) end

	local name = class
	class = _nameToClass(name)
	if not subclassOf(Entity, class) then error("emma: Class is not an Entity subclass", 3) end

	-- add entity to pool
	table.insert(_entities, {
		['name'] = name,
		['cleanup'] = cleanup or false
	})

	-- add tag references
	for _,tag in pairs(tags) do 
		assert(type(tag) == "string", "emma: Tags must be strings")
		if _tags[tag] == nil then
			_tags[tag] = {}
		end
		table.insert(_tags[tag], name)
	end
end

--[[
Instantiates and returns a new instance of the given class. The instance is cached and will be reused 
after Emma.destroy is called
@param string class - class name that is subclassed from Entity and has been added to the Entity Pool
@param ... - passthrough variables to class constructor
@return instance
]]
function Emma.instantiate(class, ...)
	if not _classExists(class) then error("emma: Class doesn't exist in Entity Pool", 3) end
	class = _nameToClass(class)

	-- loop over instances to see if we can recycle
	if _classRecycles(class.name) then
		for i,info in pairs(_instances) do 
			-- if inactive and of the right type
			if info.active == false and instanceOf(class, info.instance) then 
				-- reset and return
				_instances[i].instance:start()
				_instances[i].active = true
				return _instances[i].instance 
			end
		end
	end
	-- create a new instance
	table.insert(_instances, {['instance'] = class:new(unpack(arg)), ['active'] = true})
	_instances[#_instances].instance._uniq = #_instances
	_instances[#_instances].instance:start()
	return _instances[#_instances].instance
end

--[[
Returns a table with all instances with the given tags
@param table tags - list of string tags
@return table - list of active instances with those tags
--]]
function Emma.findAll(tags)
	local instances = {}

	-- if the tags are nil, then return all active instances
	if tags == nil or #tags == 0 then
		for _,info in pairs(_instances) do 
			if info.active == true then 
				table.insert(instances, info.instance)
			end
		end
	else -- gather classes, by tag
		local classes = {}

		for _,tag in pairs(tags) do 
			if _tags[tag] ~= nil then 
				for _,class in pairs(_tags[tag]) do 
					table.insert(classes, class)
				end
			end
		end

		-- gather instances by class
		for _,info in pairs(_instances) do 
			for _,class in pairs(classes) do 
				class = _nameToClass(class)
				if info.active == true and instanceOf(class, info.instance) then 
					table.insert(instances, info.instance)
				end
			end
		end
	end

	return instances
end

--[[
Given an instance, sets it to inactive
@param instance - instance to destroy
--]]
function Emma.destroy(instance)
	-- find correct instance to destroy
	for i,info in pairs(_instances) do 
		if info.active == true and info.instance._uniq == instance._uniq then
			if _classRecycles(instance.class.name) then
				_instances[i].active = false
			else
				_instances[i] = nil
			end
		end
	end
end

--[[
Calls update on the matching instances
@param number dt - delta time
@param table tags - list of string tags
--]]
function Emma.update(dt, tags)
	for _,instance in pairs(Emma.findAll(tags)) do
		instance:update(dt)
	end
end

--[[
Calls draw on the matching instances
@param table tags - list of string tags
--]]
function Emma.draw(tags)
	for _,instance in pairs(Emma.findAll(tags)) do 
		instance:draw()
	end
end

------------------------------------------------------------------------------------------------------------------------
-- Helper Classes
------------------------------------------------------------------------------------------------------------------------
--[[
Entity Class
------------------------
All objects drawn and updated should extend this class
--]]
Entity = class('Entity')

--[[
Called after instance is created. Use this function to reset your entity
--]]
function Entity:start() end
function Entity:update(dt) end
function Entity:draw() end

------------------------------------------------------------------------------------------------------------------------
-- end
------------------------------------------------------------------------------------------------------------------------
return Emma