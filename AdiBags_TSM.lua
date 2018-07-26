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

  itemstring = TSMAPI_FOUR.Item.ToItemString(slotData.link)
  if itemstring == nil then
    return
  end

  tsmpath = TSMAPI_FOUR.Groups.GetPathByItem(itemstring)
  shown = self.db.profile.shown[tsmpath]
  if tsmpath ~= nil and tsmpath ~= "" and shown ~= nil and shown then
      path, groupname = TSMAPI_FOUR.Groups.SplitPath(tsmpath)
      return groupname
  end
end

function setFilter:GetTSMGroupList()
    -- Horrible hack to get the list of groups from the TSM database.
    -- There is a function Groups:GetSortedGroupPathList in
    -- Core/Libs/Groups.lua but it's not accessible in TSMAPI, so I'm using
    -- this hack in the meantime.
    local res = {}
    local db = TradeSkillMasterDB
    local char = strjoin(' - ', UnitName("player"), GetRealmName())
    local profile = db['_currentProfile'][char] or 'Default'
    for k, v in pairs(db["p@" .. profile .. "@userData@groups"]) do
        tinsert(res, k)
    end
    return res
end

--[[ Get all the TSM group strings ]]
function setFilter:TSMGroupList()
  local v = {}
  for i, name in ipairs(setFilter:GetTSMGroupList()) do
    if name ~= "" then
        display_name, count = string.gsub(name, "`", " / ")
        v[name] = display_name
    end
  end
  return v
end

function setFilter:GetOptions()
  local options = {
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
        values = setFilter:TSMGroupList,
        width = 'double',
    },
    enableAll = {
      name = L['Enable All Groups'],
      desc = L['Click the button to check all TSM groups.']
      type = 'execute',
      func = function()
        for i, name in setFilter:TSMGroupList() do
          options.shown.set(i) = true
        end
      end
    },
    disableAll = {
      name = L['Disable All Groups'],
      desc = L['Click the button to uncheck all TSM groups.']
      type = 'execute',
      func = function()
        for i, name in setFilter:TSMGroupList() do
          options.shown.set(i) = false
        end
      end
    }
  }
  return options, addon:GetOptionHandler(self, false, function() return self:Update() end)
end
