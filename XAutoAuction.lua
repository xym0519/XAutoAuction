XAutoAuction = CreateFrame("Frame")
XAuctionInfoList = {}
XAutoAuctionList = {}
XAutoBuyList = {}
XSpeakWordList = {}
XJewWordList = {}

XAutoAuction:RegisterEvent("ADDON_LOADED")
XAutoAuction:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
XAutoAuction:RegisterEvent("CHAT_MSG_SYSTEM")
XAutoAuction:RegisterEvent("AUCTION_HOUSE_CLOSED")
XAutoAuction:RegisterEvent("AUCTION_HOUSE_SHOW")
XAutoAuction:RegisterEvent("BAG_UPDATE")
XAutoAuction:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
XAutoAuction:RegisterEvent("UNIT_SPELLCAST_FAILED")
XAutoAuction:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
XAutoAuction:RegisterEvent("PLAYER_MONEY")

local updateCallback = {}
XAutoAuction.registerUpdateCallback = function(key, callback)
    updateCallback[key] = callback
end

local eventCallback = {}
XAutoAuction.registerEventCallback = function(key, event, callback)
    if not eventCallback[event] then
        eventCallback[event] = {}
    end
    eventCallback[event][key] = callback
end

local actionCallback = {}
XAutoAuction.registerActionCallback = function(key, callback)
    actionCallback[key] = callback
end

XAutoAuction.refreshUI = function()
    if XAuctionCenter ~= nil then XAuctionCenter.refreshUI() end
    if XAuctionBoard ~= nil then XAuctionBoard.refreshUI() end
    if XCraftQueue ~= nil then XCraftQueue.refreshUI() end
    if XAutoBuy ~= nil then XAutoBuy.refreshUI() end
    if XJewCount ~= nil then XJewCount.refreshUI() end
end

local lastUpdateTime = 0
local function onUpdate()
    for _, callback in pairs(updateCallback) do
        if type(callback) == "function" then
            callback()
        end
    end
end

XAutoAuction:SetScript('OnUpdate', function()
    local currentTime = time()
    if currentTime - lastUpdateTime < 1 then
        return
    end
    lastUpdateTime = currentTime
    onUpdate()
end)

XAutoAuction:SetScript("OnEvent", function(self, event, text, context)
    if event == 'ADDON_LOADED' then
        if text == "XAutoAuction" then
            if eventCallback[event] then
                for _, callback in pairs(eventCallback[event]) do
                    callback(self, event, text, context)
                end
            end
        end
    else
        if eventCallback[event] then
            for _, callback in pairs(eventCallback[event]) do
                callback(self, event, text, context)
            end
        end
    end
end)

SlashCmdList["XAUTOAUCTIONREFRESH"] = function()
    XInfo.reloadBag()
    XInfo.reloadAuction()
    XAutoAuction.refreshUI()
end
SLASH_XAUTOAUCTIONREFRESH1 = "/xautoauction_refresh"

SlashCmdList["XAUTOAUCTIONMODESELL"] = function()
    if XAuctionCenter.mainFrame then XAuctionCenter.mainFrame:Show() end
    if XAuctionBoard.mainFrame then XAuctionBoard.mainFrame:Show() end
    if XCraftQueue.mainFrame then XCraftQueue.mainFrame:Show() end
    if XAutoSpeak.mainFrame then XAutoSpeak.mainFrame:Show() end
    if XAutoBuy.mainFrame then XAutoBuy.mainFrame:Hide() end
    if XJewWords.mainFrame then XJewWords.mainFrame:Hide() end
    if XJewCount.mainFrame then XJewCount.mainFrame:Show() end
end
SLASH_XAUTOAUCTIONMODESELL1 = "/xautoauction_mode_sell"

SlashCmdList["XAUTOAUCTIONMODEBUY"] = function()
    if XAuctionCenter.mainFrame then XAuctionCenter.mainFrame:Hide() end
    if XAuctionBoard.mainFrame then XAuctionBoard.mainFrame:Hide() end
    if XCraftQueue.mainFrame then XCraftQueue.mainFrame:Hide() end
    if XAutoSpeak.mainFrame then XAutoSpeak.mainFrame:Hide() end
    if XAutoBuy.mainFrame then XAutoBuy.mainFrame:Show() end
    if XJewWords.mainFrame then XJewWords.mainFrame:Hide() end
    if XJewCount.mainFrame then XJewCount.mainFrame:Hide() end
end
SLASH_XAUTOAUCTIONMODEBUY1 = "/xautoauction_mode_buy"

SlashCmdList["XAUTOAUCTIONMODETRADE"] = function()
    if XAuctionCenter.mainFrame then XAuctionCenter.mainFrame:Hide() end
    if XAuctionBoard.mainFrame then XAuctionBoard.mainFrame:Hide() end
    if XCraftQueue.mainFrame then XCraftQueue.mainFrame:Hide() end
    if XAutoSpeak.mainFrame then XAutoSpeak.mainFrame:Hide() end
    if XAutoBuy.mainFrame then XAutoBuy.mainFrame:Hide() end
    if XJewWords.mainFrame then XJewWords.mainFrame:Show() end
    if XJewCount.mainFrame then XJewCount.mainFrame:Hide() end
end
SLASH_XAUTOAUCTIONMODETRADE1 = "/xautoauction_mode_trade"

SlashCmdList["XAUTOAUCTIONMODECLOSE"] = function()
    if XAuctionCenter.mainFrame then XAuctionCenter.mainFrame:Hide() end
    if XAuctionBoard.mainFrame then XAuctionBoard.mainFrame:Hide() end
    if XCraftQueue.mainFrame then XCraftQueue.mainFrame:Hide() end
    if XAutoSpeak.mainFrame then XAutoSpeak.mainFrame:Hide() end
    if XAutoBuy.mainFrame then XAutoBuy.mainFrame:Hide() end
    if XJewWords.mainFrame then XJewWords.mainFrame:Hide() end
    if XJewCount.mainFrame then XJewCount.mainFrame:Hide() end
end
SLASH_XAUTOAUCTIONMODECLOSE1 = "/xautoauction_mode_close"

SlashCmdList["XAUTOAUCTIONACTIONONE"] = function()
    if actionCallback then
        for key, callback in pairs(actionCallback) do
            callback(key)
        end
    end
end
SLASH_XAUTOAUCTIONACTIONONE1 = "/xautoauction_action_1"
