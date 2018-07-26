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
    profile = { enable = true, shown = { ['*'] = false } },
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
  if not self.db.profile.enable then
    return
  end

  tsmpath = TSM_API.GetGroupPathByItem(slotData.link)
  shown = self.db.profile.shown[tsmpath]
  if tsmpath ~= nil and tsmpath ~= "" and shown ~= nil and shown then
      path, groupname = TSM_API.SplitGroupPath(tsmpath)
      return groupname
  end
end

function setFilter:GetOptions()
  local values = {}
  return {
    enable = {
      name = L['Enable TSM groups'],
      desc = L['Check this if you want to separate items in their TSM groups.'],
      type = 'toggle',
      order = 10,
    },
    shown = {
        name = L['TSM Groups to show'],
        desc = L["(Note: Different groups with the same name will be merged)"],
        type = 'multiselect',
        order = 20,
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
