XAutoBuy = {}
local moduleName = 'XAutoBuy'

-- Variable definition
local mainFrame = nil
local confirmFrame = nil

local dft_interval = 3
local dft_taskTimeout = 30
local dft_minPrice = 9999999

local dft_buttonWidth = 40
local dft_buttonGap = 1

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local isStarted = false

local isQuerying = false
local queryStartTime = 0
local queryIndex = 1
local queryPage = 0
local queryFound = nil
local queryResultProcessed = true
local queryRound = 1
local checkOnly = true
local manualBuy = true
local buyingItem = nil

-- Function definition
local initUI
local initUI_Confirm
local refreshUI
local getItem
local addItem
local startBuy
local stopBuy
local confirmBuy
local finishCurTask

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XAutoBuyMainFrame', 540, 425)
    mainFrame.title:SetText('自动购买')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()

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

    local resetButton = XUI.createButton(mainFrame, dft_buttonWidth, '清')
    resetButton:SetPoint('LEFT', startButton, 'RIGHT', dft_buttonGap, 0)
    resetButton:SetScript('OnClick', function()
        for _, item in ipairs(XAutoBuyList) do
            item.minprice = dft_minPrice
            item.minbuyoutprice = dft_minPrice
        end
        refreshUI()
    end)

    local refreshButton = XUI.createButton(mainFrame, dft_buttonWidth, '刷')
    refreshButton:SetPoint('LEFT', resetButton, 'RIGHT', dft_buttonGap, 0)
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

    local checkOnlyButton = XUI.createButton(mainFrame, dft_buttonWidth, '')
    checkOnlyButton:SetPoint('LEFT', settingButton, 'RIGHT', dft_buttonGap, 0)
    checkOnlyButton:SetScript('OnClick', function()
        checkOnly = not checkOnly
        refreshUI()
    end)
    mainFrame.checkOnlyButton = checkOnlyButton

    local manualBuyButton = XUI.createButton(mainFrame, dft_buttonWidth, '')
    manualBuyButton:SetPoint('LEFT', checkOnlyButton, 'RIGHT', dft_buttonGap, 0)
    manualBuyButton:SetScript('OnClick', function()
        manualBuy = not manualBuy
        refreshUI()
    end)
    mainFrame.manualBuyButton = manualBuyButton

    local hintLabel = XUI.createLabel(mainFrame, 170, '')
    hintLabel:SetPoint('LEFT', manualBuyButton, 'RIGHT', 10, 0)
    mainFrame.hintLabel = hintLabel

    local lastWidget = preButton
    for i = 1, displayPageSize do
        local frame = XAPI.CreateFrame('Frame', nil, mainFrame)
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

        local label = XUI.createLabel(frame, 50, '')
        label:SetPoint('LEFT', itemNameButton, 'RIGHT', 8, 0)
        frame.label = label

        local label2 = XUI.createLabel(frame, 55, '')
        label2:SetPoint('LEFT', label, 'RIGHT', 0, 0)
        frame.label2 = label2

        local label3 = XUI.createLabel(frame, 55, '')
        label3:SetPoint('LEFT', label2, 'RIGHT', 0, 0)
        frame.label3 = label3

        local label4 = XUI.createLabel(frame, 55, '')
        label4:SetPoint('LEFT', label3, 'RIGHT', 0, 0)
        frame.label4 = label4

        local deleteButton = XUI.createButton(frame, 32, '删')
        deleteButton:SetPoint('LEFT', label4, 'RIGHT', 3, 0)
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

        local setPriceButton = XUI.createButton(frame, 32, '>')
        setPriceButton:SetPoint('LEFT', enableButton, 'RIGHT', 1, 0)
        setPriceButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoBuyList[idx]
            if not item then return end
            XAuctionCenter.printItemsByName('*' .. item['itemname'])
            local price = item['minbuyoutprice'];
            XUIInputDialog.show(moduleName, function(data)
                    local basePrice = nil
                    local profitRate = nil
                    local isDealRate = nil
                    for _, titem in ipairs(data) do
                        if titem.Name == '基准价格' then basePrice = tonumber(titem.Value) end
                        if titem.Name == '利润率' then profitRate = tonumber(titem.Value) end
                        if titem.Name == '手续费' then isDealRate = tonumber(titem.Value) end
                    end
                    XAuctionCenter.setPriceByName('*' .. item['itemname'], basePrice, profitRate, isDealRate == 1, true)
                end,
                { {
                    Name = '基准价格',
                    Value = price,
                    OnEnterPressed = function(_, data)
                        local basePrice = nil
                        local profitRate = nil
                        local isDealRate = nil
                        for _, titem in ipairs(data) do
                            if titem.Name == '基准价格' then basePrice = tonumber(titem.Value) end
                            if titem.Name == '利润率' then profitRate = tonumber(titem.Value) end
                            if titem.Name == '手续费' then isDealRate = tonumber(titem.Value) end
                        end
                        XAuctionCenter.setPriceByName('*' .. item['itemname'], basePrice, profitRate, isDealRate == 1,
                            false)
                    end
                }, { Name = '利润率', Value = 0 },
                    { Name = '手续费', Value = 0 } },
                item['itemname'])

            refreshUI()
        end)

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    refreshUI()
end

initUI_Confirm = function()
    confirmFrame = XUI.createFrame('XAutoBuyMainFrame_Confirm', 200, 70)
    confirmFrame.title:SetText('自动购买')
    confirmFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    confirmFrame:Hide()

    local confirmButton = XUI.createButton(confirmFrame, 80, '购买')
    confirmButton:SetPoint('TOPLEFT', confirmFrame, 'TOPLEFT', 15, -30)
    confirmButton:SetScript('OnClick', function()
        confirmBuy()
    end)

    local cancelButton = XUI.createButton(confirmFrame, 80, '取消')
    cancelButton:SetPoint('LEFT', confirmButton, 'RIGHT', 12, 0)
    cancelButton:SetScript('OnClick', function()
        buyingItem = nil
        queryResultProcessed = true
        confirmFrame:Hide()
    end)
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end

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

    if checkOnly then
        mainFrame.checkOnlyButton:SetText('查')
    else
        mainFrame.checkOnlyButton:SetText('买')
    end

    if manualBuy then
        mainFrame.manualBuyButton:SetText('手')
    else
        mainFrame.manualBuyButton:SetText('自')
    end

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #XAutoBuyList then
            local item = XAutoBuyList[idx]
            local itemName = item['itemname']

            local price = item['price']
            local priceStr = XUI.White .. XUtils.priceToString(price)

            local minPrice = dft_minPrice
            if item['minprice'] then minPrice = item['minprice'] end
            local minPriceStr = XUI.White .. XUtils.priceToString(minPrice)
            if minPrice <= price then
                minPriceStr = XUI.White .. XUtils.priceToString(minPrice)
            elseif minPrice <= price * 1.2 then
                minPriceStr = XUI.Yellow .. XUtils.priceToString(minPrice)
            elseif minPrice <= price * 1.5 then
                minPriceStr = XUI.Orange .. XUtils.priceToString(minPrice)
            else
                minPriceStr = XUI.Red .. XUtils.priceToString(minPrice)
            end

            local minBuyoutPrice = dft_minPrice
            if item['minbuyoutprice'] then minBuyoutPrice = item['minbuyoutprice'] end
            local minBuyoutPriceStr = XUI.White .. XUtils.priceToString(minBuyoutPrice)
            if minBuyoutPrice <= price then
                minBuyoutPriceStr = XUI.White .. XUtils.priceToString(minBuyoutPrice)
            elseif minBuyoutPrice <= price * 1.2 then
                minBuyoutPriceStr = XUI.Yellow .. XUtils.priceToString(minBuyoutPrice)
            elseif minBuyoutPrice <= price * 1.5 then
                minBuyoutPriceStr = XUI.Orange .. XUtils.priceToString(minBuyoutPrice)
            else
                minBuyoutPriceStr = XUI.Red .. XUtils.priceToString(minBuyoutPrice)
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
            frame.label4:SetText(minBuyoutPriceStr)

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

getItem = function(itemName)
    for _, item in ipairs(XAutoBuyList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

addItem = function(itemName, price)
    if getItem(itemName) then return end
    local item = {
        itemname = itemName,
        price = price
    }
    table.insert(XAutoBuyList, item)
    refreshUI()
end

startBuy = function()
    isStarted = true
    isQuerying = false
    queryStartTime = 0
    queryPage = 0
    queryFound = nil
    queryResultProcessed = true
    buyingItem = nil
    refreshUI()
end

stopBuy = function()
    isStarted = false
    isQuerying = false
    queryStartTime = 0
    queryPage = 0
    queryFound = nil
    queryResultProcessed = true
    buyingItem = nil
    refreshUI()
    XUIConfirmDialog.close('XAutoBuy_Buy')
end

finishCurTask = function()
    isQuerying = false
    queryStartTime = 0
    queryIndex = queryIndex + 1
    queryPage = 0
    queryFound = nil
    queryResultProcessed = true
end

confirmBuy = function()
    if not confirmFrame then return end
    if buyingItem == nil then return end

    local index = 1
    local found = false
    local bought = false
    while true do
        local res = { XAPI.GetAuctionItemInfo('list', index) }
        local itemName = res[1]
        local stackCount = res[3]
        local bidStart = res[8]
        local bidIncrease = res[9]
        local buyoutPrice = res[10]
        local bidPrice = res[11]
        local isMine = res[12]
        local seller = res[14]
        local itemId = res[17]

        if not itemName then break end

        if itemName == buyingItem['itemname'] then
            local nextBidPrice = 0
            if bidPrice == 0 then
                nextBidPrice = bidStart
            else
                nextBidPrice = bidPrice + bidIncrease
            end

            local price = buyoutPrice / stackCount
            if price > 0 then
                if buyingItem.minbuyoutprice then
                    if price < buyingItem.minbuyoutprice then
                        buyingItem.minbuyoutprice = price
                    end
                else
                    buyingItem.minbuyoutprice = price
                end

                if nextBidPrice / stackCount < price then
                    price = nextBidPrice / stackCount
                end
            else
                price = nextBidPrice / stackCount
            end
            if buyingItem.minprice then
                if price < buyingItem.minprice then
                    buyingItem.minprice = price
                end
            else
                buyingItem.minprice = price
            end

            if nextBidPrice / stackCount <= buyingItem['price'] then
                found = true
            end

            if (not XInfo.isMe(seller)) and (not isMine) then
                if buyoutPrice / stackCount <= buyingItem['price'] and buyoutPrice > 0 then
                    xdebug.info('Buyout: ' .. itemName .. ' (' .. stackCount .. ')'
                        .. '    ' .. XUtils.priceToMoneyString(buyoutPrice / stackCount))
                    XAPI.PlaceAuctionBid('list', index, buyoutPrice)
                    break
                elseif nextBidPrice / stackCount <= buyingItem['price'] then
                    xdebug.info('Bid: ' .. itemName .. ' (' .. stackCount .. ')'
                        .. '    ' .. XUtils.priceToMoneyString(nextBidPrice / stackCount))
                    XAPI.PlaceAuctionBid('list', index, nextBidPrice)
                    break
                end
            end
        end
        index = index + 1
    end

    if not found then
        queryPage = queryPage - 1
        if queryPage < 0 then queryPage = 0 end
        confirmFrame:Hide()
        buyingItem = nil
        queryResultProcessed = true
    end
end

-- Event callback
local function onAuctionItemListUpdate()
    if not XAutoBuyList[queryIndex] then
        finishCurTask()
        return
    end

    local item = XAutoBuyList[queryIndex]

    local res = { XAPI.GetAuctionItemInfo('list', 1) }
    local itemName = res[1]

    if not itemName then
        queryFound = false
        isQuerying = false
        queryResultProcessed = false
        return
    end

    if itemName ~= item['itemname'] then return end

    queryFound = true
    queryResultProcessed = false
    isQuerying = false
end

local function onUpdate()
    if not confirmFrame then return end
    if XAutoAuction.XSellBuyFlag then return end
    if not isStarted then
        if not XAutoAuction.XSellBuyFlag then
            XAutoAuction.XSellBuyFlag = true
        end
        return
    end

    if isQuerying then
        if time() - queryStartTime > dft_taskTimeout then
            finishCurTask()
            refreshUI()
        end
        return
    end

    if queryFound == true then
        if not queryResultProcessed then
            local item = XAutoBuyList[queryIndex]
            local index = 1
            local lowerPriceFound = false
            while true do
                local res = { XAPI.GetAuctionItemInfo('list', index) }
                local itemName = res[1]
                local stackCount = res[3]
                local bidStart = res[8]
                local bidIncrease = res[9]
                local buyoutPrice = res[10]
                local bidPrice = res[11]
                local isMine = res[12]
                local seller = res[14]
                local itemId = res[17]

                if not itemName then break end

                XExternal.updateItemInfo(itemName, itemId)
                XExternal.addScanHistory(itemName, time(), buyoutPrice)

                local nextBidPrice = 0
                if bidPrice == 0 then
                    nextBidPrice = bidStart
                else
                    nextBidPrice = bidPrice + bidIncrease
                end

                local price = buyoutPrice / stackCount
                if price > 0 then
                    if item.minbuyoutprice then
                        if price < item.minbuyoutprice then
                            item.minbuyoutprice = price
                        end
                    else
                        item.minbuyoutprice = price
                    end

                    if nextBidPrice / stackCount < price then
                        price = nextBidPrice / stackCount
                    end
                else
                    price = nextBidPrice / stackCount
                end
                if item.minprice then
                    if price < item.minprice then
                        item.minprice = price
                    end
                else
                    item.minprice = price
                end

                if nextBidPrice / stackCount <= item['price'] then
                    lowerPriceFound = true
                end

                if (not checkOnly) and (not manualBuy) then
                    if (not XInfo.isMe(seller)) and (not isMine) then
                        if buyoutPrice / stackCount <= item['price'] and itemName == item['itemname'] and buyoutPrice > 0 then
                            xdebug.info('Buyout: ' .. itemName .. ' (' .. stackCount .. ')'
                                .. '    ' .. XUtils.priceToMoneyString(buyoutPrice / stackCount))
                            XAPI.PlaceAuctionBid('list', index, buyoutPrice)
                            break
                        elseif nextBidPrice / stackCount <= item['price'] and itemName == item['itemname'] then
                            xdebug.info('Bid: ' .. itemName .. ' (' .. stackCount .. ')'
                                .. '    ' .. XUtils.priceToMoneyString(nextBidPrice / stackCount))
                            XAPI.PlaceAuctionBid('list', index, nextBidPrice)
                            break
                        end
                    end
                end
                index = index + 1
            end

            if lowerPriceFound then
                if manualBuy then
                    if buyingItem == nil then
                        buyingItem = item
                        confirmFrame:Show()
                    end
                    return
                end
            else
                finishCurTask()
                return
            end

            if checkOnly then
                finishCurTask()
                return
            end

            queryResultProcessed = true
            return
        end

        if not XAPI.CanSendAuctionQuery() then return end

        queryStartTime = time()
        queryPage = queryPage + 1
        queryFound = nil
        isQuerying = true
        XAPI.QueryAuctionItems(XAutoBuyList[queryIndex]['itemname'], nil, nil, queryPage, nil, nil, nil, true)
        refreshUI()
        return
    end

    if queryFound == false then
        finishCurTask()
        refreshUI()
        return
    end

    if not XAPI.CanSendAuctionQuery() then return end

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
        item.minprice = dft_minPrice
        item.minbuyoutprice = dft_minPrice
        queryStartTime = time()
        queryPage = 0
        queryFound = nil
        isQuerying = true
        XAPI.QueryAuctionItems(item['itemname'], nil, nil, queryPage, nil, nil, nil, true)
        refreshUI()
        return
    end

    queryRound = queryRound + 1
    isQuerying = false
    queryStartTime = 0
    queryIndex = 1
    queryPage = 0
    queryFound = nil
    if not XAutoAuction.XSellBuyFlag then
        XAutoAuction.XSellBuyFlag = not XAutoAuction.XSellBuyFlag
    end
    refreshUI()
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    initUI_Confirm()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_ITEM_LIST_UPDATE', function()
    onAuctionItemListUpdate()
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    stopBuy()
    if mainFrame then mainFrame:Hide() end
end)

XAutoAuction.registerUpdateCallback(moduleName, onUpdate, dft_interval)

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

-- Interface
XAutoBuy.getItem = getItem
