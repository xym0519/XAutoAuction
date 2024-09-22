XAutoAuction = {}
XAutoAuctionFrame = XAPI.CreateFrame('Frame')

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

-- OnUIUpdate callback
local uiUpdateCallback = {}
XAutoAuction.registerUIUpdateCallback = function(key, callback)
    uiUpdateCallback[key] = callback
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

-- UIUpdate callback
local lastUIUpdateTime = 0
local onUIUpdate = function()
    local currentTime = time()
    if currentTime - lastUIUpdateTime < 1 then
        return
    end
    lastUIUpdateTime = currentTime
    XAutoAuction.refreshUI()
    for _, callback in pairs(uiUpdateCallback) do
        if type(callback) == 'function' then
            callback()
        end
    end
end

-- Event listener
XAutoAuctionFrame:SetScript('OnUpdate', onUIUpdate)

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

-- Commands
SlashCmdList['XAUTOAUCTIONREFRESH'] = function()
    XInfo.reloadCount()
    XInfo.reloadTradeSkill()
    XAutoAuction.refreshUI()
end
SLASH_XAUTOAUCTIONREFRESH1 = '/xautoauction_refresh'

SlashCmdList['XAUTOAUCTIONUPDATE'] = onUpdate
SLASH_XAUTOAUCTIONUPDATE1 = '/xautoauction_update'
