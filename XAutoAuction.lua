XAutoAuction = {}
XAutoAuctionFrame = XAPI.CreateFrame('Frame')
local moduleName = 'XAutoAuction'

-- Global variables definition
XAutoAuctionList = {}
XAutoBuyList = {}
XSpeakWordList = {}
XJewWordList = {}
XJewWordSetting = {}
XAuctionBoardList = {}
XFrameLevel = 10

-- Register system events
XAutoAuctionFrame:RegisterEvent('ADDON_LOADED')

XAutoAuctionFrame:RegisterEvent('AUCTION_HOUSE_CLOSED')
XAutoAuctionFrame:RegisterEvent('AUCTION_HOUSE_SHOW')
XAutoAuctionFrame:RegisterEvent('AUCTION_ITEM_LIST_UPDATE')

XAutoAuctionFrame:RegisterEvent('CHAT_MSG_SYSTEM')
XAutoAuctionFrame:RegisterEvent('CHAT_MSG_WHISPER')

XAutoAuctionFrame:RegisterEvent('BAG_UPDATE')
XAutoAuctionFrame:RegisterEvent('GET_ITEM_INFO_RECEIVED')

XAutoAuctionFrame:RegisterEvent('UNIT_SPELLCAST_START')
XAutoAuctionFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
XAutoAuctionFrame:RegisterEvent('UNIT_SPELLCAST_FAILED')
XAutoAuctionFrame:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')

XAutoAuctionFrame:RegisterEvent('PLAYER_MONEY')

-- Event registion interface
-- OnUpdate callback
local updateCallback = {}
XAutoAuction.registerUpdateCallback = function(key, callback, interval)
    if interval == nil then interval = 1 end
    updateCallback[key] = { callback = callback, interval = interval, lastUpdateTime = 0 }
end

-- OnFastUpdate callback
local fastUpdateCallback = {}
XAutoAuction.registerFastUpdateCallback = function(key, callback)
    fastUpdateCallback[key] = callback
end

-- onUIUpdate callback
local uiUpdateCallback = {}
XAutoAuction.registerUIUpdateCallback = function(key, callback, interval)
    if interval == nil then interval = 1 end
    uiUpdateCallback[key] = { callback = callback, interval = interval, lastUpdateTime = 0 }
end
XAutoAuction.unRegisterUIUpdateCallback = function(key)
    uiUpdateCallback[key] = nil
end

-- Refresh callback
local refreshCallback = {}
XAutoAuction.registerRefreshCallback = function(key, callback)
    refreshCallback[key] = callback
end

-- Other events callback
local eventCallback = {}
XAutoAuction.registerEventCallback = function(key, event, callback)
    if not eventCallback[event] then
        eventCallback[event] = {}
    end
    eventCallback[event][key] = callback
end

-- Event callback
-- Update callback
local lastUpdateTime = 0
local onUpdate = function()
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
XAutoAuctionFrame:SetScript('OnUpdate', function()
    local time = time()
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

XAutoAuctionFrame:SetScript('OnEvent', function(...)
    local event, text = select(2, ...)
    if event == 'ADDON_LOADED' then
        if text == 'XAutoAuction' then
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
XAutoAuction.refreshUI = function()
    for _, callback in pairs(refreshCallback) do
        if type(callback) == 'function' then
            callback()
        end
    end
end

XAutoAuction.registerUIUpdateCallback(moduleName, XAutoAuction.refreshUI, 1)

-- Commands
SlashCmdList['XAUTOAUCTIONREFRESH'] = function()
    XInfo.reloadCount()
    XInfo.reloadTradeSkill()
    XAutoAuction.refreshUI()
end
SLASH_XAUTOAUCTIONREFRESH1 = '/xautoauction_refresh'

SlashCmdList['XAUTOAUCTIONUPDATE'] = onUpdate
SLASH_XAUTOAUCTIONUPDATE1 = '/xautoauction_update'
