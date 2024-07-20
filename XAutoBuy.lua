XAutoBuy = {}
local moduleName = 'XAutoBuy'

-- Variable definition
local mainFrame = nil

local dft_taskInterval = 1
local dft_taskTimeout = 30

local dft_buttonWidth = 40
local dft_buttonGap = 1

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local isStarted = false
local lastTaskFinishTime = 0

local queryMode = 0 -- 0: 快速  1: 完整
local isQuerying = false
local queryStartTime = 0
local queryIndex = 1
local queryPage = 0
local queryFound = nil
local queryResultProcessed = true
local queryRound = 1

-- Function definition
local initUI
local refreshUI
local getBuyItem
local addItem
local startBuy
local stopBuy
local finishCurTask
local confirmBuy

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XAutoBuyMainFrame', 460, 425)
    mainFrame.title:SetText('自动购买')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    mainFrame = mainFrame

    local preButton = XUI.createButton(mainFrame, dft_buttonWidth, '上')
    preButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    preButton:SetScript('OnClick', function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, dft_buttonWidth, '下')
    nextButton:SetPoint('LEFT', preButton, 'RIGHT', dft_buttonGap, 0)
    nextButton:SetScript('OnClick', function()
        if displayPageNo < math.ceil(#XAutoBuyList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            refreshUI()
        end
    end)

    local startButton = XUI.createButton(mainFrame, dft_buttonWidth, '起')
    startButton:SetPoint('LEFT', nextButton, 'RIGHT', dft_buttonGap, 0)
    startButton:SetScript('OnClick', function()
        if isStarted then
            stopBuy()
        else
            startBuy()
        end
    end)
    mainFrame.startButton = startButton

    local modeButton = XUI.createButton(mainFrame, dft_buttonWidth, '快')
    modeButton:SetPoint('LEFT', startButton, 'RIGHT', dft_buttonGap, 0)
    modeButton:SetScript('OnClick', function()
        queryMode = (queryMode + 1) % 2
        refreshUI()
    end)
    mainFrame.modeButton = modeButton

    local refreshButton = XUI.createButton(mainFrame, dft_buttonWidth, '刷')
    refreshButton:SetPoint('LEFT', modeButton, 'RIGHT', dft_buttonGap, 0)
    refreshButton:SetScript('OnClick', function()
        refreshUI()
    end)

    local settingButton = XUI.createButton(mainFrame, dft_buttonWidth, '加')
    settingButton:SetPoint('LEFT', refreshButton, 'RIGHT', dft_buttonGap, 0)
    settingButton:SetScript('OnClick', function()
        displaySettingItem = nil
        XUIInputDialog.show(moduleName, function(data)
            local name = nil
            local price = nil
            for _, item in ipairs(data) do
                if item.Name == '物品' then name = item.Value end
                if item.Name == '价格' then price = tonumber(item.Value) end
            end
            if name and price then
                addItem(name, price)
                refreshUI()
            end
        end, { { Name = '物品' }, { Name = '价格' } }, '自动购买设置')
    end)

    local hintLabel = XUI.createLabel(mainFrame, 170, '')
    hintLabel:SetPoint('LEFT', settingButton, 'RIGHT', 10, 0)
    mainFrame.hintLabel = hintLabel

    local lastWidget = preButton
    for i = 1, displayPageSize do
        local frame = CreateFrame('Frame', nil, mainFrame)
        frame:SetSize(mainFrame:GetWidth(), 30)

        if i == 1 then
            frame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 0, -65)
        else
            frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -5)
        end

        frame:Hide()

        local indexButton = XUI.createButton(frame, 30, '')
        indexButton:SetPoint('LEFT', frame, 'LEFT', 15, 0)
        indexButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            XUISortDialog.show('XAutoBuy_Sort', XAutoBuyList, idx, function()
                refreshUI()
            end)
        end)
        frame.indexButton = indexButton

        local itemNameButton = XUI.createButton(frame, 160, '')
        itemNameButton:SetPoint('LEFT', indexButton, 'RIGHT', 3, 0)
        itemNameButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            displaySettingItem = XAutoBuyList[idx]

            XUIInputDialog.show(moduleName,
                function(data)
                    local name = nil
                    local price = nil
                    for _, item in ipairs(data) do
                        if item.Name == '物品' then name = item.Value end
                        if item.Name == '价格' then price = tonumber(item.Value) end
                    end
                    if name and price then
                        displaySettingItem['itemname'] = name
                        displaySettingItem['price'] = price
                        refreshUI()
                    end
                end,
                { { Name = '物品', Value = displaySettingItem['itemname'] }, { Name = '价格', Value = displaySettingItem['price'] } },
                '自动购买设置')
        end)
        frame.itemNameButton = itemNameButton

        local label = XUI.createLabel(frame, 60, '')
        label:SetPoint('LEFT', itemNameButton, 'RIGHT', 8, 0)
        frame.label = label

        local label2 = XUI.createLabel(frame, 40, '')
        label2:SetPoint('LEFT', label, 'RIGHT', 0, 0)
        frame.label2 = label2

        local label3 = XUI.createLabel(frame, 60, '')
        label3:SetPoint('LEFT', label2, 'RIGHT', 0, 0)
        frame.label3 = label3

        local deleteButton = XUI.createButton(frame, 32, '删')
        deleteButton:SetPoint('LEFT', label3, 'RIGHT', 3, 0)
        deleteButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #XAutoBuyList then
                XUIConfirmDialog.show(moduleName,
                    '确认删除',
                    '是否确认删除：' .. XAutoBuyList[idx]['itemname'],
                    function()
                        table.remove(XAutoBuyList, idx)
                        refreshUI()
                    end)
            end
        end)

        local enableButton = XUI.createButton(frame, 32, '')
        enableButton:SetPoint('LEFT', deleteButton, 'RIGHT', 1, 0)
        enableButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoBuyList[idx]
            if not item then return end
            item['enabled'] = not item['enabled']
            refreshUI()
        end)
        frame.enableButton = enableButton

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end

    mainFrame.title:SetText('自动购买 (' .. (displayPageNo + 1) .. '/'
        .. (math.ceil(#XAutoBuyList / displayPageSize)) .. ')    Querying: '
        .. queryIndex .. '    Round: ' .. queryRound)

    XInfo.reloadBag()
    if isStarted then
        mainFrame.startButton:SetText('停')
        if XAutoBuyList[queryIndex] then
            mainFrame.hintLabel:SetText(XAutoBuyList[queryIndex]['itemname'] .. '(' .. queryPage .. ')')
        end
    else
        mainFrame.startButton:SetText('起')
        mainFrame.hintLabel:SetText('等待')
    end

    if queryMode == 0 then
        mainFrame.modeButton:SetText('快')
    else
        mainFrame.modeButton:SetText('全')
    end

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #XAutoBuyList then
            local item = XAutoBuyList[idx]
            local itemName = item['itemname']

            local price = item['price'] / 10000
            local priceStr = XUI.White .. price

            local minPrice = 0
            if item['minprice'] then minPrice = item['minprice'] / 10000 end
            local minPriceStr = XUI.White .. minPrice
            if minPrice <= price then
                minPriceStr = XUI.White .. minPrice
            elseif minPrice <= price * 1.2 then
                minPriceStr = XUI.Yellow .. minPrice
            elseif minPrice <= price * 1.5 then
                minPriceStr = XUI.Orange .. minPrice
            else
                minPriceStr = XUI.Red .. minPrice
            end

            local bagCount = 0
            local bankCount = 0
            local itemBag = XInfo.getBagItem(itemName)
            if itemBag then
                bagCount = itemBag['count']
                bankCount = itemBag['bankcount']
            end
            local bagCountStr = XUtils.formatCount2(bagCount)
            local bankCountStr = XUtils.formatCount2(bankCount)

            frame.indexButton:SetText(idx)
            frame.itemNameButton:SetText(string.sub(itemName, 1, 18))
            frame.label:SetText(bagCountStr .. XUI.White .. '/' .. bankCountStr)
            frame.label2:SetText(priceStr)
            frame.label3:SetText(minPriceStr)

            if item['enabled'] ~= true then
                frame.enableButton:SetText(XUI.Red .. '停')
            else
                frame.enableButton:SetText(XUI.Green .. '起')
            end
            frame:Show()
        else
            frame:Hide()
        end
    end
end

getBuyItem = function(itemName)
    for _, item in ipairs(XAutoBuyList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

addItem = function(itemName, price)
    if getBuyItem(itemName) then return end
    local item = {
        itemname = itemName,
        price = price
    }
    table.insert(XAutoBuyList, item)
    refreshUI()
end

startBuy = function()
    isStarted = true
    lastTaskFinishTime = 0
    isQuerying = false
    queryStartTime = 0
    queryPage = 0
    queryFound = nil
    queryResultProcessed = true
    refreshUI()
end

stopBuy = function()
    isStarted = false
    lastTaskFinishTime = 0
    isQuerying = false
    queryStartTime = 0
    queryPage = 0
    queryFound = nil
    queryResultProcessed = true
    refreshUI()
    XUIConfirmDialog.close('XAutoBuy_Buy')
end

finishCurTask = function()
    lastTaskFinishTime = time()
    isQuerying = false
    queryStartTime = 0
    queryIndex = queryIndex + 1
    if queryIndex > #XAutoBuyList then
        queryIndex = 1
    end
    queryPage = 0
    queryFound = nil
    queryResultProcessed = true
end

confirmBuy = function()
    local tindex = 1
    while true do
        local itemName, _, stackCount, _, _, _, _, bidStart, bidIncrease, buyoutPrice, bidPrice, isMine, _, seller =
            GetAuctionItemInfo('list', tindex)
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
            PlaceAuctionBid('list', tindex, buyoutPrice)
        elseif (not XInfo.isMe(seller)) and (not isMine) and nextBidPrice / stackCount <= XAutoBuyList[queryIndex]['price'] and itemName == XAutoBuyList[queryIndex]['itemname'] then
            print('Bid: ' .. itemName .. ' (' .. stackCount .. ')'
                .. '    ' .. XUtils.priceToMoneyString(nextBidPrice / stackCount))
            PlaceAuctionBid('list', tindex, nextBidPrice)
        end
        tindex = tindex + 1
    end

    queryPage = queryPage - 1
    if queryPage < 0 then
        queryPage = 0
    end

    queryResultProcessed = true
    XUIConfirmDialog.close('XAutoBuy_Buy')
end

-- Event callback
local function onAuctionItemListUpdate()
    if not XAutoBuyList[queryIndex] then
        finishCurTask()
        return
    end

    local item = XAutoBuyList[queryIndex]

    local itemName, _, stackCount, _, _, _, _, bidStart, bidIncrease, buyoutPrice, bidPrice, isMine, _, seller =
        GetAuctionItemInfo('list', 1)

    if not itemName then
        queryFound = false
        isQuerying = false
        queryResultProcessed = false
        return
    end

    if itemName ~= item['itemname'] then return end

    local nextBidPrice = 0
    if bidPrice == 0 then
        nextBidPrice = bidStart
    else
        nextBidPrice = bidPrice + bidIncrease
    end

    local minPrice = buyoutPrice / stackCount
    if minPrice > 0 then
        if nextBidPrice / stackCount < minPrice then
            minPrice = nextBidPrice / stackCount
        end
    else
        minPrice = nextBidPrice / stackCount
    end
    if item.minprice then
        if minPrice < item.minprice then
            item.minprice = minPrice
        end
    else
        item.minprice = minPrice
    end

    if queryMode == 0 then -- 快速模式
        if nextBidPrice / stackCount <= item['price'] then
            queryFound = true
        else
            queryFound = false
        end
    else
        queryFound = true
    end

    queryResultProcessed = false
    isQuerying = false
end

local function onUpdate()
    if not isStarted then return end

    if isQuerying then
        if time() - queryStartTime > dft_taskTimeout then
            print('XAutoBuy query timeout')
            finishCurTask()
            refreshUI()
        end
        return
    end

    if queryFound == true then
        if not queryResultProcessed then
            local item = XAutoBuyList[queryIndex]
            local index = 1
            local totalPrice = 0
            local queryBuyoutCount = 0
            local queryBidCount = 0
            while true do
                local itemName, _, stackCount, _, _, _, _, bidStart, bidIncrease, buyoutPrice, bidPrice, isMine, _, seller, _, _, itemId =
                    GetAuctionItemInfo('list', index)

                if not itemName then break end

                XExternal.updateItemInfo(itemName, itemId)
                XExternal.addScanHistory(itemName, time(), buyoutPrice)

                local nextBidPrice = 0
                if bidPrice == 0 then
                    nextBidPrice = bidStart
                else
                    nextBidPrice = bidPrice + bidIncrease
                end

                if (not XInfo.isMe(seller)) and buyoutPrice / stackCount <= item['price'] and itemName == item['itemname'] and buyoutPrice > 0 then
                    queryBuyoutCount = queryBuyoutCount + stackCount
                    totalPrice = totalPrice + buyoutPrice
                elseif (not XInfo.isMe(seller)) and (not isMine) and nextBidPrice / stackCount <= XAutoBuyList[queryIndex]['price'] and itemName == item['itemname'] then
                    queryBidCount = queryBidCount + stackCount
                    totalPrice = totalPrice + nextBidPrice
                end
                index = index + 1
            end

            if queryBuyoutCount > 0 or queryBidCount > 0 then
                if not XUIConfirmDialog.isVisible('XAutoBuy_Buy') then
                    local queryAvgPrice = totalPrice / (queryBuyoutCount + queryBidCount)
                    local queryBuyoutCountStr = queryBuyoutCount .. ''
                    local queryBidCountStr = queryBidCount .. ''
                    if queryBuyoutCount > 0 then
                        queryBuyoutCountStr = XUI.Green .. queryBuyoutCountStr
                    end
                    if queryBidCount > 0 then
                        queryBidCountStr = XUI.Green .. queryBidCountStr
                    end

                    XUIConfirmDialog.show('XAutoBuy_Buy', XAutoBuyList[queryIndex]['itemname'],
                        { XUI.White .. 'Buyout:  ' .. queryBuyoutCountStr
                        .. XUI.White .. '       Bid:  ' .. queryBidCountStr,
                            'AvgPrice: ' .. XUtils.priceToMoneyString(queryAvgPrice) },
                        confirmBuy, finishCurTask)
                end
                refreshUI()
                return
            end

            queryResultProcessed = true
        end

        if time() - lastTaskFinishTime < dft_taskInterval then return end
        if not CanSendAuctionQuery() then return end

        queryStartTime = time()
        queryPage = queryPage + 1
        queryFound = nil
        isQuerying = true
        QueryAuctionItems(XAutoBuyList[queryIndex]['itemname'], nil, nil, queryPage, nil, nil, nil, true)
        refreshUI()
        return
    end

    if queryFound == false then
        finishCurTask()
        refreshUI()
        return
    end

    if time() - lastTaskFinishTime < dft_taskInterval then return end
    if not CanSendAuctionQuery() then return end

    local item = nil
    for i = queryIndex, #XAutoBuyList do
        local titem = XAutoBuyList[i]
        if titem and titem['enabled'] then
            queryIndex = i
            item = titem
            break
        end
    end

    if item then
        queryStartTime = time()
        queryPage = 0
        queryFound = nil
        isQuerying = true
        QueryAuctionItems(item['itemname'], nil, nil, queryPage, nil, nil, nil, true)
        refreshUI()
        return
    end

    isQuerying = false
    queryStartTime = 0
    queryIndex = 1
    queryPage = 0
    queryFound = nil
    queryRound = 1
    refreshUI()
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_ITEM_LIST_UPDATE', function()
    onAuctionItemListUpdate()
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    stopBuy()
    if mainFrame then mainFrame:Hide() end
end)

XAutoAuction.registerUpdateCallback(moduleName, onUpdate)

XAutoAuction.registerRefreshCallback(moduleName, refreshUI)

-- Commands
SlashCmdList['XAUTOBUY'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XAUTOBUY1 = '/xautobuy'

SlashCmdList['XAUTOBUYSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XAUTOBUYSHOW1 = '/xautobuy_show'

SlashCmdList['XAUTOBUYHIDE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XAUTOBUYHIDE1 = '/xautobuy_close'

SlashCmdList['XAUTOBUYCONFIRM'] = confirmBuy
SLASH_XAUTOBUYCONFIRM1 = '/xautobuy_confirm'

-- Interface
XAutoBuy.getBuyItem = getBuyItem
