XJewTool = {}
XJewToolFrame = XAPI.CreateFrame('Frame')
local moduleName = 'XJewTool'

-- Global variables definition
XItemList = {}
XBuyItemList = {}
XSpeakWordList = {}
XJewWordList = {}
XJewWordSetting = {}
XAuctionBoardList = {}
XFrameLevel = 10

-- ui
local hintShowDelay = 3
local lastActionTime = time()
local isRunning = false
local hintFrame = XAPI.CreateFrame('Frame', nil, UIParent)
hintFrame:SetSize(300, 100)
hintFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
hintFrame:SetFrameStrata('DIALOG')
hintFrame:Hide()
hintFrame.text = hintFrame:CreateFontString(nil, 'ARTWORK')
hintFrame.text:SetJustifyH('CENTER')
hintFrame.text:SetAllPoints()
hintFrame.text:SetFontObject(ChatFontNormal)
hintFrame.text:SetText('已停止')
hintFrame.hintBg = hintFrame:CreateTexture(nil, 'BACKGROUND')
hintFrame.hintBg:SetAllPoints(hintFrame)
hintFrame.hintBg:SetColorTexture(1, 1, 0, 0.9)
hintFrame:SetScript('OnMouseDown', function(self) self:Hide() end)

-- Register system events
XJewToolFrame:RegisterEvent('ADDON_LOADED')

XJewToolFrame:RegisterEvent('AUCTION_HOUSE_CLOSED')
XJewToolFrame:RegisterEvent('AUCTION_HOUSE_SHOW')
XJewToolFrame:RegisterEvent('AUCTION_ITEM_LIST_UPDATE')

XJewToolFrame:RegisterEvent('CHAT_MSG_SYSTEM')
XJewToolFrame:RegisterEvent('CHAT_MSG_WHISPER')

XJewToolFrame:RegisterEvent('BAG_UPDATE')
XJewToolFrame:RegisterEvent('GET_ITEM_INFO_RECEIVED')

XJewToolFrame:RegisterEvent('UNIT_SPELLCAST_START')
XJewToolFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
XJewToolFrame:RegisterEvent('UNIT_SPELLCAST_FAILED')
XJewToolFrame:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')

XJewToolFrame:RegisterEvent('UI_ERROR_MESSAGE')

XJewToolFrame:RegisterEvent('PLAYER_MONEY')

-- Event registion interface
-- OnUpdate callback
local updateCallback = {}
XJewTool.registerUpdateCallback = function(key, callback, interval)
    if interval == nil then interval = 1 end
    updateCallback[key] = { callback = callback, interval = interval, lastUpdateTime = 0 }
end

-- OnFastUpdate callback
local fastUpdateCallback = {}
XJewTool.registerFastUpdateCallback = function(key, callback)
    fastUpdateCallback[key] = callback
end

-- onUIUpdate callback
local uiUpdateCallback = {}
XJewTool.registerUIUpdateCallback = function(key, callback, interval)
    if interval == nil then interval = 1 end
    uiUpdateCallback[key] = { callback = callback, interval = interval, lastUpdateTime = 0 }
end
XJewTool.unRegisterUIUpdateCallback = function(key)
    uiUpdateCallback[key] = nil
end

-- Refresh callback
local refreshCallback = {}
XJewTool.registerRefreshCallback = function(key, callback)
    refreshCallback[key] = callback
end

-- Other events callback
local eventCallback = {}
XJewTool.registerEventCallback = function(key, event, callback)
    if not eventCallback[event] then
        eventCallback[event] = {}
    end
    eventCallback[event][key] = callback
end

-- Event callback
-- Update callback
local lastUpdateTime = 0
local onUpdate = function()
    isRunning = true
    lastActionTime = time()

    for _, callback in pairs(fastUpdateCallback) do
        if type(callback) == 'function' then
            callback()
        end
    end

    local currentTime = time()
    if currentTime - lastUpdateTime < 1 then
        return
    end
    lastUpdateTime = currentTime
    for _, item in pairs(updateCallback) do
        if item.lastUpdateTime + item.interval < time() then
            if type(item.callback) == 'function' then
                item.callback()
                item.lastUpdateTime = time()
            end
        end
    end
end

-- Event listener
local uiUpdateTimeList = {}
local uiUpdateTimeItem = nil
local deltaTime = 1
XJewToolFrame:SetScript('OnUpdate', function()
    local time = time()

    if isRunning and lastActionTime + hintShowDelay < time then
        if not hintFrame:IsVisible() then
            hintFrame.text:SetText('已停止  ' .. XUtils.formatTime(lastActionTime + hintShowDelay))
            hintFrame:Show()
        end
        isRunning = false
    end

    if uiUpdateTimeItem == nil then
        uiUpdateTimeItem = { time = time, count = 0 }
    end
    if time ~= uiUpdateTimeItem['time'] then
        table.insert(uiUpdateTimeList, 1, uiUpdateTimeItem['count'])
        uiUpdateTimeItem['time'] = time
        uiUpdateTimeItem['count'] = 1
        local totalCount = 0
        for i = 1, #uiUpdateTimeList do
            if i <= 5 then
                totalCount = totalCount + uiUpdateTimeList[i]
            else
                uiUpdateTimeList[i] = nil
            end
        end
        deltaTime = #uiUpdateTimeList / totalCount
    else
        uiUpdateTimeItem['count'] = uiUpdateTimeItem['count'] + 1
    end
    if #uiUpdateTimeList >= 5 then
        local curMilTime = time + deltaTime * uiUpdateTimeItem['count']
        for _, item in pairs(uiUpdateCallback) do
            if item.lastUpdateTime + item.interval < curMilTime then
                if type(item.callback) == 'function' then
                    item.callback()
                    item.lastUpdateTime = curMilTime
                end
            end
        end
    end
end)

XJewToolFrame:SetScript('OnEvent', function(...)
    local event, text = select(2, ...)
    if event == 'ADDON_LOADED' then
        if text == 'XJewTool' then
            if eventCallback[event] then
                for _, callback in pairs(eventCallback[event]) do
                    if type(callback) == 'function' then
                        callback(...)
                    end
                end
            end
        end
    else
        if eventCallback[event] then
            for _, callback in pairs(eventCallback[event]) do
                if type(callback) == 'function' then
                    callback(...)
                end
            end
        end
    end
end)

-- Global functions
XJewTool.refreshUI = function()
    for _, callback in pairs(refreshCallback) do
        if type(callback) == 'function' then
            callback()
        end
    end
end

XJewTool.registerUIUpdateCallback(moduleName, XJewTool.refreshUI, 1)


-- Commands
SlashCmdList['XJEWTOOLREFRESH'] = function()
    XInfo.reloadCount()
    XInfo.reloadTradeSkill()
    XJewTool.refreshUI()
end
SLASH_XJEWTOOLREFRESH1 = '/xjewtool_refresh'

SlashCmdList['XJEWTOOLUPDATE'] = onUpdate
SLASH_XJEWTOOLUPDATE1 = '/xjewtool_update'

SlashCmdList['XJEWTOOLSKILL'] = onUpdate
SLASH_XJEWTOOLSKILL1 = '/xjewtool_skill'

SlashCmdList['XJEWTOOLCAST'] = onUpdate
SLASH_XJEWTOOLCAST1 = '/xjewtool_cast'

SlashCmdList['XJEWTOOLMAGIC'] = onUpdate
SLASH_XJEWTOOLMAGIC1 = '/xjewtool_magic'

SlashCmdList['XJEWTOOLFANG'] = onUpdate
SLASH_XJEWTOOLFANG1 = '/xjewtool_fang'

SlashCmdList['XJEWTOOLFANG'] = onUpdate
SLASH_XJEWTOOLFANG1 = '/xjewtool_fang'