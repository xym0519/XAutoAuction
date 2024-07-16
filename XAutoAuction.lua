XAutoAuction = {}
XAutoAuctionFrame = CreateFrame('Frame')

-- Global variables definition
XAuctionInfoList = {}
XAutoAuctionList = {}
XAutoBuyList = {}
XSpeakWordList = {}
XJewWordList = {}
XJewWordSetting = {}
XFrameLevel = 10

-- Register system events
XAutoAuctionFrame:RegisterEvent('ADDON_LOADED')
XAutoAuctionFrame:RegisterEvent('AUCTION_ITEM_LIST_UPDATE')
XAutoAuctionFrame:RegisterEvent('CHAT_MSG_SYSTEM')
XAutoAuctionFrame:RegisterEvent('AUCTION_HOUSE_CLOSED')
XAutoAuctionFrame:RegisterEvent('AUCTION_HOUSE_SHOW')
XAutoAuctionFrame:RegisterEvent('BAG_UPDATE')
XAutoAuctionFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
XAutoAuctionFrame:RegisterEvent('UNIT_SPELLCAST_FAILED')
XAutoAuctionFrame:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
XAutoAuctionFrame:RegisterEvent('PLAYER_MONEY')

-- Event registion interface
-- OnUpdate callback
local updateCallback = {}
XAutoAuction.registerUpdateCallback = function(key, callback)
    updateCallback[key] = callback
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

-- Update cycle per second
local lastUpdateTime = 0
XAutoAuctionFrame:SetScript('OnUpdate', function()
    local currentTime = time()
    if currentTime - lastUpdateTime < 1 then
        return
    end
    lastUpdateTime = currentTime
    for _, callback in pairs(updateCallback) do
        if type(callback) == 'function' then
            callback()
        end
    end
end)

-- Event listener
XAutoAuctionFrame:SetScript('OnEvent', function(self, event, text, context)
    if event == 'ADDON_LOADED' then
        if text == 'XAutoAuction' then
            if eventCallback[event] then
                for _, callback in pairs(eventCallback[event]) do
                    if type(callback) == 'function' then
                        callback(self, event, text, context)
                    end
                end
            end
        end
    else
        if eventCallback[event] then
            for _, callback in pairs(eventCallback[event]) do
                if type(callback) == 'function' then
                    callback(self, event, text, context)
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
    XAutoAuction.refreshUI()
end
SLASH_XAUTOAUCTIONREFRESH1 = '/xautoauction_refresh'

