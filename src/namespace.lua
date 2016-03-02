require("lib.utils")
require("ops.random")
require("experimentSetup")
local pretty = require 'pl.pretty'

local Experiment = require "experiment"
local Assignment = require "assignment"

DefaultExperiment = Experiment:new()

function DefaultExperiment:configureLogger()
  return
end

function DefaultExperiment:setup()
  self.name = 'test_name'
end

function DefaultExperiment:log(data)
  return
end

function DefaultExperiment:getParamNames()
  return self:getDefaultParamNames()
end

function DefaultExperiment:previouslyLogged()
  return true
end

function DefaultExperiment:assign(params, args)
  return
end


Namespace = {}

function Namespace:new(args)
  return _new_(self, {}):init(args)
end

function Namespace:init(args) return self end

function Namespace:addExperiment(name, obj, segments)
  error "addExperiment Not implemented"
end

function Namespace:removeExperiment(name)
  error "removeExperiment Not implemented"
end

function Namespace:setAutoExposureLogging(value)
  error "setAutoExposureLogging Not implemented"
end

function Namespace:inExperiment()
  error "inExperiment Not implemented"
end

function Namespace:get(name, defaultVal)
  error "get Not implemented"
end

function Namespace:logExposure(extras)
  error "logExposure Not implemented"
end

function Namespace:logEvent(eventType, extras)
  error "logEvent Not implemented"
end

function Namespace:requireExperiment()
  if self._experiment == nil then
    self:_assignExperiment()
  end
end

function Namespace:requireDefaultExperiment()
  if not self._defaultExperiment then
    self:_assignDefaultExperiment()
  end
end


SimpleNamespace = Namespace:new()

function SimpleNamespace:init(args)
  if args ~= nil then
    self.name = self:getDefaultNamespaceName()
    self.inputs = args or {}
    self.numSegments = 1
    self.segmentAllocations = {}
    self.currentExperiments = {}

    self._experiment = nil
    self._defaultExperiment = nil
    self.defaultExperimentClass = DefaultExperiment
    self._inExperiment = false

    self:setupDefaults();
    self:setup();
    self.availableSegments = range(self.numSegments);
    self:setupExperiments();
  end
  return self
end

function SimpleNamespace:setupDefaults()
  return
end

function SimpleNamespace:setup()
  error "setup Not implemented"
end

function SimpleNamespace:setupExperiments()
  error "setupExperiments Not implemented"
end

function SimpleNamespace:getPrimaryUnit()
  return self._primaryUnit
end

function SimpleNamespace:allowedOverride()
  return false
end

function SimpleNamespace:getOverrides()
  return {}
end

function SimpleNamespace:setPrimaryUnit(value)
  self._primaryUnit = value
end

function SimpleNamespace:addExperiment(name, expObject, segments)
  local numberAvailable = #self.availableSegments;

  if numberAvailable < segments or self.currentExperiments[name] ~= nil
  then return false end

  local a = Assignment:new(self.name);
  a:set('sampled_segments', Sample:new({
    ['choices'] = self.availableSegments,
    ['draws'] = segments,
    ['unit'] = name
  }))
  local sample = a:get('sampled_segments')

  for i, v in ipairs(sample) do
    self.segmentAllocations[v] = name
    local currentIndex = table.indexOf(self.availableSegments, v)
    table.remove(self.availableSegments, currentIndex)
  end

  self.currentExperiments[name] = expObject
end

function SimpleNamespace:removeExperiment(name)
  if self.currentExperiments[name] == nil then return false end
  local currentIndex = table.indexOf(self.segmentAllocations, name)
  while currentIndex ~= -1 do
    self.segmentAllocations[currentIndex] = currentIndex
    table.insert(self.availableSegments, currentIndex)
    self.currentExperiments[name] = nil
    currentIndex = table.indexOf(self.segmentAllocations, name)
  end

  return true
end

function SimpleNamespace:getSegment()
  local a = Assignment:new(self.name)
  local segment = RandomInteger:new({
    ['min'] = 0,
    ['max'] = self.numSegments - 1,
    ['unit'] = self.inputs[self:getPrimaryUnit()] or ''
  })
  a:set('segment', segment);
  return a:get('segment') + 1;
end

function SimpleNamespace:getDefaultNamespaceName()
  return "GenericNamespace"
end

function SimpleNamespace:_assignExperiment()
  self.inputs = table.merge(self.inputs or {}, getExperimentInputs(self:getName()))
  local segment = self:getSegment()
  if type(self.segmentAllocations[segment]) == "string" then
    self:_assignExperimentObject(self.segmentAllocations[segment])
  end
end

function SimpleNamespace:_assignExperimentObject(experimentName)
  local experiment = self.currentExperiments[experimentName]:new(self.inputs)
  experiment:setName(self:getName() .. "-" .. experimentName)
  experiment:setSalt(self:getName() .. "-" .. experimentName)
  self._experiment = experiment
  self._inExperiment = experiment:inExperiment()
  if self._inExperiment then self:_assignDefaultExperiment() end
end

function SimpleNamespace:_assignDefaultExperiment()
  self._defaultExperiment = self.defaultExperimentClass:new(self.inputs);
end

function SimpleNamespace:defaultGet(name, default_val)
  Namespace.requireDefaultExperiment(self)
  return self._defaultExperiment:get(name, default_val)
end

function SimpleNamespace:getName()
  return self.name;
end

function SimpleNamespace:setName(name)
  self.name = name;
end

function SimpleNamespace:previouslyLogged()
  if self._experiment ~= nil then return self._experiment:previouslyLogged() end
  return nil;
end

function SimpleNamespace:inExperiment()
  Namespace.requireExperiment(self)
  return self._inExperiment
end

function SimpleNamespace:setAutoExposureLogging(value)
  self._autoExposureLogging = value
  if self._defaultExperiment ~= nil then self._defaultExperiment:setAutoExposureLogging(value) end
  if self._experiment ~= nil then self._experiment:setAutoExposureLogging(value) end
end

function SimpleNamespace:setGlobalOverride(name)
  local globalOverrides = self:getOverrides()
  if globalOverrides ~= nil and globalOverrides[name] ~= nil then
    local overrides = globalOverrides[name]
    if self.currentExperiments[overrides.experimentName] ~= nil then
      self:_assignExperimentObject(overrides.experimentName)
      self._experiment:addOverride(name, overrides.value)
    end
  end
end

function SimpleNamespace:getParams(experimentName)
  Namespace.requireExperiment(self)
  if self._experiment ~= nil and self:getOriginalExperimentName() == experimentName then return self._experiment:getParams() end
  return nil
end

function SimpleNamespace:getOriginalExperimentName()
  if self._experiment ~= nil then return self._experiment:getName() end
  return nil
end

function SimpleNamespace:get(name, defaultVal)
  Namespace.requireExperiment(self)
  if self:allowedOverride() then self:setGlobalOverride(name) end

  if self._experiment == nil then return self:defaultGet(name, defaultVal) end

  if self._autoExposureLogging ~= nil then self._experiment:setAutoExposureLogging(self._autoExposureLogging) end

  return self._experiment:get(name, self:defaultGet(name, defaultVal))
end

function SimpleNamespace:logExposure(extras)
  Namespace.requireExperiment(self)
  if self._experiment ~= nil then return self:logExposure(extras) end
  return nil
end

function SimpleNamespace:logEvent(eventType, extras)
  Namespace.requireExperiment(self)
  if self._experiment ~= nil then return self:logEvent(eventType, extras) end
  return nil
end
