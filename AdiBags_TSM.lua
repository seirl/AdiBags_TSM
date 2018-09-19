--[[
AdiBags_TSM - Adds TSM groups to AdiBags.

Copyright (c) 2018 Antoine Pietri <antoine.pietri1@gmail.com>
SPDX-License-Identifier: GPL-3.0
--]]

local _, ns = ...

local addon = LibStub('AceAddon-3.0'):GetAddon('AdiBags')
local L = setmetatable({}, {__index = addon.L})

-- The filter itself

local setFilter = addon:RegisterFilter("TSM", 93, 'ABEvent-1.0')
setFilter.uiName = L['TSM']
setFilter.uiDesc = L['Separate items in their TSM groups']

function setFilter:OnInitialize()
  self.db = addon.db:RegisterNamespace('TSM', {
    profile = { shown = { ['*'] = false } },
    char = {  },
  })
end

function setFilter:Update()
  self:SendMessage('AdiBags_FiltersChanged')
end

function setFilter:OnEnable()
  addon:UpdateFilters()
end

function setFilter:OnDisable()
  addon:UpdateFilters()
end

local groups = {}
function setFilter:Filter(slotData)
  local item_string = TSM_API.ToItemString(slotData.link)
  local item_link = item_string and TSM_API.GetItemLink(item_string)
  if not item_link then
      return
  end

  tsmpath = TSM_API.GetGroupPathByItem(item_link)

  -- Get the lowest parent group of the item present in the whitelist.
  while (tsmpath ~= nil and tsmpath ~= "") do
    shown = self.db.profile.shown[tsmpath]
    parent_path, groupname = TSM_API.SplitGroupPath(tsmpath)
    if shown ~= nil and shown then
      return groupname
    end
    tsmpath = parent_path
  end
end

function setFilter:SetAllOptions(setTo)
  assert(type(setTo) == 'boolean')

  for i, name in ipairs(TSM_API.GetGroupPaths({})) do
    self.db.profile.shown[name] = setTo
  end
end

function setFilter:GetOptions()
  local values = {}
  return {
    enableAll = {
      name = L['Check all Groups'],
      desc = L['Click to check all TSM groups.'],
      type = 'execute',
      order = 20,
      func = function()
        setFilter:SetAllOptions(true)
      end
    },
    disableAll = {
      name = L['Uncheck all Groups'],
      desc = L['Click to uncheck all TSM groups.'],
      type = 'execute',
      order = 30,
      func = function()
        setFilter:SetAllOptions(false)
      end
    },
    shown = {
        name = L['TSM Groups to show'],
        desc = L["(Note: Different groups with the same name will be merged)"],
        type = 'multiselect',
        order = 40,
        values = function()
            wipe(values)
            for i, name in ipairs(TSM_API.GetGroupPaths({})) do
                if name ~= "" then
                    display_name, count = string.gsub(name, "`", " > ")
                    if count > 0 then
                        display_name = (string.rep(" ", count * 4) ..
                                        display_name)
                    end
                    values[name] = display_name
                end
            end
            return values
        end,
        width = 'double',
    },
  }, addon:GetOptionHandler(self, false, function() return self:Update() end)
end
