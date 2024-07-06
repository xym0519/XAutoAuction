XAutoBuy = CreateFrame("Frame")

local dft_taskInterval = 1
local dft_taskTimeout = 30

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local isStarted = false
local lastTaskFinishTime = 0

local isQuerying = false
local queryStartTime = 0
local queryIndex = 0
local queryPage = 0
local queryLastCount = nil
local queryFound = false
local queryRound = 1

XAutoBuy.getBuyItem = function(itemName)
    for _, item in ipairs(XAutoBuyList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

XAutoBuy.refreshUI = function()
    if not XAutoBuy.mainFrame then return end
    XAutoBuy.mainFrame.title:SetText('自动购买 (' .. (displayPageNo + 1) .. '/'
        .. (math.ceil(#XAutoBuyList / displayPageSize)) .. ')    Querying: '
        .. queryIndex .. '    Round: ' .. queryRound)

    XInfo.reloadBag()
    if isStarted then
        XAutoBuy.mainFrame.startButton:SetText('停')
        if XAutoBuyList[queryIndex] ~= nil then
            XAutoBuy.mainFrame.hintLabel:SetText(XAutoBuyList[queryIndex]['itemname'] .. '(' .. queryPage .. ')')
        end
    else
        XAutoBuy.mainFrame.startButton:SetText('起')
        XAutoBuy.mainFrame.hintLabel:SetText('等待')
    end

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #XAutoBuyList then
            local item = XAutoBuyList[idx]
            local itemName = item['itemname']
            local priceStr = '|cFFFFFFFF' .. XUtils.priceToMoneyString(item['price'])
            local bagCount = 0
            local bankCount = 0
            local itemBag = XInfo.getBagItem(itemName)
            if itemBag ~= nil then
                bagCount = itemBag['count']
                bankCount = itemBag['bankcount']
            end
            local bagCountStr = XUtils.formatCount2(bagCount)
            local bankCountStr = XUtils.formatCount2(bankCount)

            frame.indexButton:SetText(idx)
            frame.itemNameButton:SetText(string.sub(itemName, 1, 18))
            frame.label:SetText(bagCountStr .. '|cFFFFFFFF/' .. bankCountStr .. '|cFFFFFFFF  ' .. priceStr)

            if item['enabled'] ~= true then
                frame.enableButton:SetText('|cFFFF0000停')
            else
                frame.enableButton:SetText('|cFF00FF00起')
            end
            frame:Show()
        else
            frame:Hide()
        end
    end
end

local function startBuy()
    isStarted = true
    lastTaskFinishTime = -1
    isQuerying = false
    queryStartTime = -1
    queryIndex = 0
    queryPage = -1
    queryLastCount = nil
    queryFound = false
    XAutoBuy.refreshUI()
end

local function stopBuy()
    isStarted = false
    lastTaskFinishTime = 0
    isQuerying = false
    queryStartTime = 0
    queryIndex = 0
    queryPage = 0
    queryLastCount = nil
    queryFound = false
    XAutoBuy.refreshUI()
    XUIConfirmDialog.close('XAutoBuy_Buy')
end

local function addItem(itemName, price)
    if XAutoBuy.getBuyItem(itemName) then return end
    local item = {
        itemname = itemName,
        price = price
    }
    table.insert(XAutoBuyList, item)
    XAutoBuy.refreshUI()
end

local function confirmBuy()
    local tindex = 1
    while true do
        local itemName, _, stackCount, _, _, _, bidStart, bidIncrease, buyoutPrice, bidPrice, isMine, seller =
            GetAuctionItemInfo("list", tindex)
        if not itemName then break end
        local nextBidPrice = 0
        if bidPrice == 0 then
            nextBidPrice = bidStart
        else
            nextBidPrice = bidPrice + bidIncrease
        end
        if (not XInfo.isMe(seller)) and buyoutPrice / stackCount <= XAutoBuyList[queryIndex]['price'] and itemName == XAutoBuyList[queryIndex]['itemname'] and buyoutPrice > 0 then
            print('Buyout: ' .. itemName .. ' (' .. stackCount .. ')'
                .. '    ' .. XUtils.priceToMoneyString(buyoutPrice / stackCount))
            PlaceAuctionBid("list", tindex, buyoutPrice)
        elseif (not XInfo.isMe(seller)) and (not isMine) and nextBidPrice / stackCount <= XAutoBuyList[queryIndex]['price'] and itemName == XAutoBuyList[queryIndex]['itemname'] then
            print('Bid: ' .. itemName .. ' (' .. stackCount .. ')'
                .. '    ' .. XUtils.priceToMoneyString(nextBidPrice / stackCount))
            PlaceAuctionBid("list", tindex, nextBidPrice)
        end
        tindex = tindex + 1
    end

    queryFound = false
    queryPage = queryPage - 1
    if queryPage < 0 then
        queryPage = 0
    end

    XUIConfirmDialog.close('XAutoBuy_Buy')
end

local function finishCurTask()
    lastTaskFinishTime = time()
    queryIndex = queryIndex + 1
    queryPage = 0
    queryLastCount = nil
    isQuerying = false
end

local function initUI_Setting()
    local settingFrame = XUI.createFrame('XAutoBuySettingFrame', 220, 100, 'DIALOG')
    settingFrame.title:SetText("自动购买设置")
    settingFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    settingFrame:Hide()
    XAutoBuy.mainFrame.settingFrame = settingFrame

    local itemNameLabel = XUI.createLabel(settingFrame, 40, '物品')
    itemNameLabel:SetPoint("TOPLEFT", settingFrame, "TOPLEFT", 15, -30)

    local itemNameEditBox = XUI.createEditbox(settingFrame, 150, true)
    itemNameEditBox:SetPoint("LEFT", itemNameLabel, "RIGHT", 5, 0)
    itemNameEditBox:SetScript("OnEscapePressed", function() XAutoBuy.mainFrame.settingFrame:Hide() end)
    itemNameEditBox:SetScript("OnTabPressed", function()
        XAutoBuy.mainFrame.settingFrame.priceEditBox:SetFocus()
    end)
    settingFrame.itemNameEditBox = itemNameEditBox

    local priceLabel = XUI.createLabel(settingFrame, 40, '价格')
    priceLabel:SetPoint("TOP", itemNameLabel, "BOTTOM", 0, 0)

    local priceEditBox = XUI.createEditbox(settingFrame, 150, false)
    priceEditBox:SetPoint("LEFT", priceLabel, "RIGHT", 5, 0)
    priceEditBox:SetScript("OnEscapePressed", function() XAutoBuy.mainFrame.settingFrame:Hide() end)
    priceEditBox:SetScript("OnEnterPressed", function()
        local name = XAutoBuy.mainFrame.settingFrame.itemNameEditBox:GetText()
        local price = tonumber(XAutoBuy.mainFrame.settingFrame.priceEditBox:GetText())
        if not displaySettingItem then
            addItem(name, price)
        else
            displaySettingItem['itemname'] = name
            displaySettingItem['price'] = price
        end
        XAutoBuy.mainFrame.settingFrame:Hide()
        XAutoBuy.refreshUI()
    end)
    settingFrame.priceEditBox = priceEditBox
end

local function initUI()
    local mainFrame = XUI.createFrame("XAutoBuyMainFrame", 460, 430)
    mainFrame.title:SetText("自动购买")
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", -50, 0)
    mainFrame:Hide()
    XAutoBuy.mainFrame = mainFrame

    local preButton = XUI.createButton(mainFrame, 45, '上')
    preButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -30)
    preButton:SetScript("OnClick", function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            XAutoBuy.refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, 45, '下')
    nextButton:SetPoint("LEFT", preButton, "RIGHT", 5, 0)
    nextButton:SetScript("OnClick", function()
        if displayPageNo < math.ceil(#XAutoBuyList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            XAutoBuy.refreshUI()
        end
    end)

    local startButton = XUI.createButton(mainFrame, 45, '起')
    startButton:SetPoint("LEFT", nextButton, "RIGHT", 5, 0)
    startButton:SetScript("OnClick", function()
        if isStarted then
            stopBuy()
        else
            startBuy()
        end
    end)
    mainFrame.startButton = startButton

    local refreshButton = XUI.createButton(mainFrame, 45, '刷')
    refreshButton:SetPoint("LEFT", startButton, "RIGHT", 5, 0)
    refreshButton:SetScript("OnClick", function()
        XAutoAuction.refreshUI()
    end)

    local settingButton = XUI.createButton(mainFrame, 45, '加')
    settingButton:SetPoint("LEFT", refreshButton, "RIGHT", 5, 0)
    settingButton:SetScript("OnClick", function()
        if XAutoBuy.mainFrame.settingFrame ~= nil then
            displaySettingItem = nil
            XAutoBuy.mainFrame.settingFrame.itemNameEditBox:SetText('')
            XAutoBuy.mainFrame.settingFrame.priceEditBox:SetText('')
            XAutoBuy.mainFrame.settingFrame:Show()
        end
    end)

    local hintLabel = XUI.createLabel(mainFrame, 200, '')
    hintLabel:SetPoint("LEFT", settingButton, "RIGHT", 15, 0)
    mainFrame.hintLabel = hintLabel

    local lastWidget = preButton
    for i = 1, displayPageSize do
        local frame = CreateFrame("Frame", nil, mainFrame)
        frame:SetSize(460, 30)

        if i == 1 then
            frame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -65)
        else
            frame:SetPoint("TOPLEFT", lastWidget, "BOTTOMLEFT", 0, -5)
        end

        frame:Hide()

        local indexButton = XUI.createButton(frame, 30, '')
        indexButton:SetPoint("LEFT", frame, "LEFT", 15, 0)
        indexButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            XUISortDialog.show('XAutoBuy_Sort', XAutoBuyList, idx, function()
                XAutoBuy.refreshUI()
            end)
        end)
        frame.indexButton = indexButton

        local itemNameButton = XUI.createButton(frame, 160, '')
        itemNameButton:SetPoint("LEFT", indexButton, "RIGHT", 3, 0)
        itemNameButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            displaySettingItem = XAutoBuyList[idx]
            if not displaySettingItem then return end
            if not XAutoBuy.mainFrame.settingFrame then return end
            XAutoBuy.mainFrame.settingFrame.itemNameEditBox:SetText(displaySettingItem['itemname'])
            XAutoBuy.mainFrame.settingFrame.priceEditBox:SetText(displaySettingItem['price'])
            XAutoBuy.mainFrame.settingFrame:Show()
        end)
        frame.itemNameButton = itemNameButton

        local label = XUI.createLabel(frame, 160, '')
        label:SetPoint("LEFT", itemNameButton, "RIGHT", 10, 0)
        frame.label = label

        local deleteButton = XUI.createButton(frame, 30, '删')
        deleteButton:SetPoint("LEFT", label, "RIGHT", 3, 0)
        deleteButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #XAutoBuyList then
                table.remove(XAutoBuyList, idx)
                XAutoBuy.refreshUI()
            end
        end)

        local enableButton = XUI.createButton(frame, 30, '')
        enableButton:SetPoint("LEFT", deleteButton, "RIGHT", 5, 0)
        enableButton:SetScript("OnClick", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoBuyList[idx]
            if not item then return end
            item['enabled'] = not item['enabled']
            XAutoBuy.refreshUI()
        end)
        frame.enableButton = enableButton

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    initUI_Setting()

    XAutoBuy.refreshUI()
end

local function onAuctionItemListUpdate()
    if not XAutoBuyList[queryIndex] then
        finishCurTask()
        return
    end

    local item = XAutoBuyList[queryIndex]

    local index = 1
    while true do
        local itemName, _, stackCount, _, _, _, bidStart, bidIncrease, buyoutPrice, bidPrice, isMine, seller =
            GetAuctionItemInfo("list", index)
        if not itemName then break end
        local nextBidPrice = 0
        if bidPrice == 0 then
            nextBidPrice = bidStart
        else
            nextBidPrice = bidPrice + bidIncrease
        end
        if (not XInfo.isMe(seller)) and buyoutPrice / stackCount <= item['price'] and itemName == item['itemname'] and buyoutPrice > 0 then
            queryFound = true
        elseif (not XInfo.isMe(seller)) and (not isMine) and nextBidPrice / stackCount <= XAutoBuyList[queryIndex]['price'] and itemName == XAutoBuyList[queryIndex]['itemname'] then
            queryFound = true
        end
        index = index + 1
    end
    queryLastCount = index - 1
    isQuerying = false
end

local function onUpdate()
    if not isStarted then return end

    XAutoBuy.refreshUI()

    if isQuerying then
        if time() - queryStartTime > dft_taskTimeout then
            finishCurTask()
        end
        return
    end

    if queryFound then
        if not XUIConfirmDialog.isVisible('XAutoBuy_Buy') then
            local queryBuyoutCount = 0
            local queryBidCount = 0
            local querySumPrice = 0
            local tindex = 1
            while true do
                local itemName, _, stackCount, _, _, _, bidStart, bidIncrease, buyoutPrice, bidPrice, isMine, seller =
                    GetAuctionItemInfo("list", tindex)
                if itemName == nil then
                    break
                end
                local nextBidPrice = 0
                if bidPrice == 0 then
                    nextBidPrice = bidStart
                else
                    nextBidPrice = bidPrice + bidIncrease
                end
                if (not XInfo.isMe(seller)) and buyoutPrice / stackCount <= XAutoBuyList[queryIndex]['price'] and itemName == XAutoBuyList[queryIndex]['itemname'] and buyoutPrice > 0 then
                    queryBuyoutCount = queryBuyoutCount + stackCount
                    querySumPrice = querySumPrice + buyoutPrice
                elseif (not XInfo.isMe(seller)) and (not isMine) and nextBidPrice / stackCount <= XAutoBuyList[queryIndex]['price'] and itemName == XAutoBuyList[queryIndex]['itemname'] then
                    queryBidCount = queryBidCount + stackCount
                    querySumPrice = querySumPrice + nextBidPrice
                end
                tindex = tindex + 1
            end
            if queryBuyoutCount > 0 or queryBidCount > 0 then
                local queryBuyoutCountStr = queryBuyoutCount
                local queryBidCountStr = queryBidCount
                if queryBuyoutCount > 0 then
                    queryBuyoutCountStr = '|cFF00FF00' .. queryBuyoutCountStr
                end
                if queryBidCount > 0 then
                    queryBidCountStr = '|cFF00FF00' .. queryBidCountStr
                end

                XUIConfirmDialog.show('XAutoBuy_Buy', XAutoBuyList[queryIndex]['itemname'],
                    { '|cFFFFFFFFBuyout:  ' .. queryBuyoutCountStr
                    .. '       |cFFFFFFFFBid:  ' .. queryBidCountStr,
                        'AvgPrice: ' .. XUtils.priceToMoneyString(querySumPrice / (queryBuyoutCount + queryBidCount)) },
                    confirmBuy, stopBuy)
            else
                queryFound = false
            end
        end
        return
    end

    if queryIndex > #XAutoBuyList then
        queryRound = queryRound + 1
        startBuy()
        return
    end

    if time() - lastTaskFinishTime < dft_taskInterval then return end
    if not CanSendAuctionQuery() then return end

    local item = XAutoBuyList[queryIndex]
    if not item then
        finishCurTask()
        return
    end

    if not item['enabled'] then
        finishCurTask()
        return
    end

    if not queryLastCount then
        isQuerying = true
        queryStartTime = time()
        QueryAuctionItems(item['itemname'], nil, nil, nil, 0, 0, queryPage)
        return
    elseif queryLastCount > 0 then
        queryPage = queryPage + 1
        isQuerying = true
        queryStartTime = time()
        QueryAuctionItems(item['itemname'], nil, nil, nil, 0, 0, queryPage)
        return
    end
    finishCurTask()
end

XAutoAuction.registerEventCallback('XAutoBuy', 'ADDON_LOADED', function()
    initUI()
    XAutoBuy.refreshUI()
end)

XAutoAuction.registerEventCallback('XAutoBuy', 'AUCTION_ITEM_LIST_UPDATE', function()
    onAuctionItemListUpdate()
end)

XAutoAuction.registerEventCallback('XAutoBuy', 'AUCTION_HOUSE_CLOSED', function()
    stopBuy()
    if XAutoBuy.mainFrame then
        XAutoBuy.mainFrame:Hide()
    end
end)

XAutoAuction.registerUpdateCallback('XAutoBuy', onUpdate)

XAutoAuction.registerActionCallback('XAutoBuy', function()
    confirmBuy()
end)

SlashCmdList["XAUTOBUY"] = function()
    if XAutoBuy.mainFrame then
        if XAutoBuy.mainFrame:IsVisible() then
            XAutoBuy.mainFrame:Hide()
        else
            XAutoBuy.mainFrame:Show()
        end
    end
end
SLASH_XAUTOBUY1 = "/xautobuy"

SlashCmdList["XAUTOBUYCONFIRM"] = function()
    confirmBuy()
end
SLASH_XAUTOBUYCONFIRM1 = "/xautobuy_confirm"
