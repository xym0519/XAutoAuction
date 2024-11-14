XBuy = {}
local moduleName = 'XBuy'

-- Variable definition
local mainFrame = nil

local dft_mineCraftRateS = {
    { itemname = '血玉石', rate = 0.83 },
    { itemname = '帝黄晶', rate = 0.93 },
    { itemname = '秋色石', rate = 1.07 },
    { itemname = '森林翡翠', rate = 0.79 },
    { itemname = '天蓝石', rate = 0.79 },
    { itemname = '曙光猫眼石', rate = 0.7 },
    { itemname = '血石', rate = 3.34 },
    { itemname = '茶晶石', rate = 3.55 },
    { itemname = '太阳水晶', rate = 3.95 },
    { itemname = '黑玉', rate = 3.75 },
    { itemname = '玉髓石', rate = 3.75 },
    { itemname = '暗影水晶', rate = 3.69 },
}
local dft_mineCraftPerfectRate = 0.2
local dft_mineCraftProfitRate = 0.1

local dft_minPrice = 9999999

local dft_buttonWidth = 40
local dft_buttonGap = 1

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local mineCrafting = false
local jewCrafting = false
local onMineCrafingUpdate
local onJewCrafingUpdate

-- Function definition
local initUI
local refreshUI
local getItem
local getItemField
local addItem
local reset
local itemChanged
local getMineSmallPrice

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XBuyMainFrame', 655, 425)
    mainFrame.title:SetText('自动购买')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local normalModeButton = XUI.createButton(mainFrame, dft_buttonWidth, '普通')
    normalModeButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, 0)
    normalModeButton:SetScript('OnClick', function(self)
        XAPI.PutItemInBackpack()
        XAPI.PickupMacro('法1')
        XAPI.PlaceAction(1)
        XAPI.PickupMacro('法2')
        XAPI.PlaceAction(2)
        XAPI.PickupMacro('法3')
        XAPI.PlaceAction(3)
        XAPI.PickupMacro('法4')
        XAPI.PlaceAction(4)
        XAPI.PickupMacro('法5')
        XAPI.PlaceAction(5)
        XAPI.PickupMacro('选矿')
        XAPI.PlaceAction(6)
        XAPI.PutItemInBackpack()
    end)

    local mineCraftModeButton = XUI.createButton(mainFrame, dft_buttonWidth, '炸矿')
    mineCraftModeButton:SetPoint('LEFT', normalModeButton, 'RIGHT', dft_buttonGap, 0)
    mineCraftModeButton:SetScript('OnClick', function(self)
        XAPI.PutItemInBackpack()
        XAPI.PickupMacro('选矿')
        XAPI.PlaceAction(1)
        XAPI.PickupMacro('选矿')
        XAPI.PlaceAction(2)
        XAPI.PickupMacro('选矿')
        XAPI.PlaceAction(3)
        XAPI.PickupMacro('选矿')
        XAPI.PlaceAction(4)
        XAPI.PickupMacro('选矿')
        XAPI.PlaceAction(5)
        XAPI.PickupMacro('法1')
        XAPI.PlaceAction(6)
        XAPI.PutItemInBackpack()
    end)

    local jewCraftModeButton = XUI.createButton(mainFrame, dft_buttonWidth, '垃圾')
    jewCraftModeButton:SetPoint('LEFT', mineCraftModeButton, 'RIGHT', dft_buttonGap, 0)
    jewCraftModeButton:SetScript('OnClick', function(self)
        XAPI.PutItemInBackpack()
        XAPI.PickupMacro('拆土1')
        XAPI.PlaceAction(1)
        XAPI.PickupMacro('拆土2')
        XAPI.PlaceAction(2)
        XAPI.PickupMacro('拆土3')
        XAPI.PlaceAction(3)
        XAPI.PickupMacro('拆土4')
        XAPI.PlaceAction(4)
        XAPI.PickupMacro('拆土5')
        XAPI.PlaceAction(5)
        XAPI.PickupMacro('拆土1')
        XAPI.PlaceAction(6)
        XAPI.PutItemInBackpack()
    end)

    local mineCraftStartButton = XUI.createButton(mainFrame, dft_buttonWidth, XUI.Red .. '炸矿')
    mineCraftStartButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -30, 0)
    mineCraftStartButton:SetScript('OnClick', function(self)
        mineCrafting = not mineCrafting
        refreshUI()
    end)
    mainFrame.mineCraftStartButton = mineCraftStartButton

    local jewCraftStartButton = XUI.createButton(mainFrame, dft_buttonWidth, XUI.Red .. '垃圾')
    jewCraftStartButton:SetPoint('RIGHT', mineCraftStartButton, 'LEFT', dft_buttonGap, 0)
    jewCraftStartButton:SetScript('OnClick', function(self)
        XCraftQueue.start(true, 5)
        if XCraftQueue.isRunning() then
            jewCrafting = true
            refreshUI()
        else
            jewCrafting = false
            refreshUI()
        end
    end)
    mainFrame.jewCraftStartButton = jewCraftStartButton

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
        if displayPageNo < math.ceil(#XBuyItemList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            refreshUI()
        end
    end)

    local resetButton = XUI.createButton(mainFrame, dft_buttonWidth, '清')
    resetButton:SetPoint('LEFT', nextButton, 'RIGHT', dft_buttonGap, 0)
    resetButton:SetScript('OnClick', function()
        reset()
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
            local sellPrice = nil
            for _, item in ipairs(data) do
                if item.Name == '物品' then name = item.Value end
                if item.Name == '收购价格' then price = tonumber(item.Value) end
                if item.Name == '出售价格' then sellPrice = tonumber(item.Value) end
            end
            if name and price and sellPrice then
                addItem(name, price, sellPrice)
                refreshUI()
            end
        end, { { Name = '物品' }, { Name = '收购价格' }, { Name = '出售价格' } }, '购买设置')
    end)


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
            XUISortDialog.show('XBuy_Sort', XBuyItemList, idx, function()
                refreshUI()
            end)
        end)
        frame.indexButton = indexButton

        local icon = XUI.createIcon(frame, 25, 25)
        icon:SetPoint('LEFT', indexButton, 'RIGHT', 3, 0)
        frame.icon = icon

        local itemNameButton = XUI.createButton(frame, 160, '')
        itemNameButton:SetPoint('LEFT', icon, 'RIGHT', 3, 0)
        itemNameButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            displaySettingItem = XBuyItemList[idx]

            if IsLeftControlKeyDown() then
                XInfo.printBuyHistory(displaySettingItem['itemname'])
            else
                XUIInputDialog.show(moduleName,
                    function(data)
                        local name = nil
                        local price = nil
                        local sellPrice = nil
                        for _, item in ipairs(data) do
                            if item.Name == '物品' then name = item.Value end
                            if item.Name == '收购价格' then price = tonumber(item.Value) end
                            if item.Name == '出售价格' then sellPrice = tonumber(item.Value) end
                        end
                        if name and price and sellPrice then
                            displaySettingItem['itemname'] = name
                            displaySettingItem['price'] = price
                            displaySettingItem['sellprice'] = sellPrice
                            refreshUI()
                        end
                    end,
                    {
                        { Name = '物品', Value = displaySettingItem['itemname'] },
                        { Name = '收购价格', Value = displaySettingItem['price'] },
                        { Name = '出售价格', Value = displaySettingItem['sellprice'] }
                    },
                    '自动购买设置')
            end
        end)
        itemNameButton:SetScript("OnEnter", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XBuyItemList[idx]
            if not item then return end
            local itemid = XInfo.getItemId(item['itemname'])
            if itemid > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. itemid) -- 显示物品信息
            end
        end)
        itemNameButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        frame.itemNameButton = itemNameButton

        local labelTime = XUI.createLabel(frame, 50, '')
        labelTime:SetPoint('LEFT', itemNameButton, 'RIGHT', 8, 0)
        frame.labelTime = labelTime

        local labelCount = XUI.createLabel(frame, 65, '')
        labelCount:SetPoint('LEFT', labelTime, 'RIGHT', 0, 0)
        frame.labelCount = labelCount

        local labelPrice = XUI.createLabel(frame, 60, '')
        labelPrice:SetPoint('LEFT', labelCount, 'RIGHT', 0, 0)
        frame.labelPrice = labelPrice

        local labelSellPrice = XUI.createLabel(frame, 60, '')
        labelSellPrice:SetPoint('LEFT', labelPrice, 'RIGHT', 0, 0)
        frame.labelSellPrice = labelSellPrice

        local labelCurPrice = XUI.createLabel(frame, 60, '')
        labelCurPrice:SetPoint('LEFT', labelSellPrice, 'RIGHT', 0, 0)
        frame.labelCurPrice = labelCurPrice

        local deleteButton = XUI.createButton(frame, 32, '删')
        deleteButton:SetPoint('LEFT', labelCurPrice, 'RIGHT', 3, 0)
        deleteButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #XBuyItemList then
                XUIConfirmDialog.show(moduleName,
                    '确认删除',
                    '是否确认删除：' .. XBuyItemList[idx]['itemname'],
                    function()
                        table.remove(XBuyItemList, idx)
                        refreshUI()
                        itemChanged()
                    end)
            end
        end)

        local enableButton = XUI.createButton(frame, 32, '')
        enableButton:SetPoint('LEFT', deleteButton, 'RIGHT', 1, 0)
        enableButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XBuyItemList[idx]
            if not item then return end
            item['enabled'] = not item['enabled']
            refreshUI()
            itemChanged()
        end)
        frame.enableButton = enableButton

        local setPriceButton = XUI.createButton(frame, 32, '>')
        setPriceButton:SetPoint('LEFT', enableButton, 'RIGHT', 1, 0)
        setPriceButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XBuyItemList[idx]
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
                }, { Name = '利润率', Value = 0.1 },
                    { Name = '手续费', Value = 1 } },
                item['itemname'])

            refreshUI()
        end)

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end

    local mineSmallPrice = getMineSmallPrice()
    mainFrame.title:SetText('购买清单 (' .. (displayPageNo + 1) .. '/'
        .. (math.ceil(#XBuyItemList / displayPageSize)) .. ')'
        .. '    邪铁: ' .. math.floor(mineSmallPrice * (1 - dft_mineCraftProfitRate) / 100)
        .. '(' .. math.floor(mineSmallPrice / 100) .. ')')

    if mineCrafting then
        mainFrame.mineCraftStartButton:SetText(XUI.Green .. '炸矿')
    else
        mainFrame.mineCraftStartButton:SetText(XUI.Red .. '炸矿')
    end
    if jewCrafting then
        mainFrame.jewCraftStartButton:SetText(XUI.Green .. '垃圾')
    else
        mainFrame.jewCraftStartButton:SetText(XUI.Red .. '垃圾')
    end

    XInfo.reloadBag()

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #XBuyItemList then
            local item = XBuyItemList[idx]
            local itemName = item['itemname']
            local itemId = XInfo.getItemId(itemName)

            local price = item['price']
            local priceStr = 'B' .. XUtils.priceToString(price)

            local sellPrice = item['sellprice']
            local sellPriceStr = 'S' .. XUtils.priceToString(sellPrice)

            local minBuyoutPrice = dft_minPrice
            if item['minbuyoutprice'] then minBuyoutPrice = item['minbuyoutprice'] end
            local minBuyoutPriceStr = 'C' .. XUtils.priceToString(minBuyoutPrice)
            if minBuyoutPrice <= price then
                minBuyoutPriceStr = XUI.White .. minBuyoutPriceStr
            elseif minBuyoutPrice <= price * 1.2 then
                minBuyoutPriceStr = XUI.Yellow .. minBuyoutPriceStr
            elseif minBuyoutPrice <= price * 1.5 then
                minBuyoutPriceStr = XUI.Orange .. minBuyoutPriceStr
            else
                minBuyoutPriceStr = XUI.Red .. minBuyoutPriceStr
            end

            local bagCount = XInfo.getBagItemCount(itemName)
            local bagCountStr = XUI.getColor_MaterialCount(bagCount) .. bagCount
            local totalCount = XInfo.getItemTotalCountAll(itemName)
            local totalCountStr = XUI.getColor_MaterialTotalCount(totalCount) .. totalCount

            local updateTimeStr = XUtils.formatTime(item['updatetime'])

            frame.indexButton:SetText(idx)
            frame.icon:SetTexture(XAPI.GetItemIcon(itemId))
            frame.itemNameButton:SetText(string.sub(itemName, 1, 18))
            frame.labelTime:SetText(updateTimeStr)
            frame.labelCount:SetText(bagCountStr .. XUI.White .. ' / ' .. totalCountStr)
            frame.labelPrice:SetText(priceStr)
            frame.labelSellPrice:SetText(sellPriceStr)
            frame.labelCurPrice:SetText(minBuyoutPriceStr)

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
    for _, item in ipairs(XBuyItemList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

-- price / minbuyoutprice / minprice
getItemField = function(itemName, fieldName, defaultValue)
    local item = getItem(itemName)
    if not item then return defaultValue end
    if not item[fieldName] then return defaultValue end
    return item[fieldName]
end

addItem = function(itemName, price, sellPrice)
    if getItem(itemName) then return end
    local item = {
        itemname = itemName,
        price = price,
        sellprice = sellPrice,
        minbuyoutprice = dft_minPrice,
        minprice = dft_minPrice,
        updatetime = 0
    }
    table.insert(XBuyItemList, item)
    refreshUI()
    itemChanged()
end

reset = function()
    for _, item in ipairs(XBuyItemList) do
        item['minbuyoutprice'] = dft_minPrice
        item['updatetime'] = 0
    end
    refreshUI()
end

getMineSmallPrice = function()
    local jewPrice = 31478
    local tuPrice = XBuy.getItemField('土之结晶', 'sellprice', 0)
    local r1m = dft_mineCraftRateS[1]['rate'] * XBuy.getItemField(dft_mineCraftRateS[1]['itemname'], 'sellprice', 0)
    local o1m = dft_mineCraftRateS[2]['rate'] * XBuy.getItemField(dft_mineCraftRateS[2]['itemname'], 'sellprice', 0)
    local y1m = dft_mineCraftRateS[3]['rate'] * XBuy.getItemField(dft_mineCraftRateS[3]['itemname'], 'sellprice', 0)
    local g1m = dft_mineCraftRateS[4]['rate'] * XBuy.getItemField(dft_mineCraftRateS[4]['itemname'], 'sellprice', 0)
    local b1m = dft_mineCraftRateS[5]['rate'] * XBuy.getItemField(dft_mineCraftRateS[5]['itemname'], 'sellprice', 0)
    local p1m = dft_mineCraftRateS[6]['rate'] * XBuy.getItemField(dft_mineCraftRateS[6]['itemname'], 'sellprice', 0)

    local r0m = dft_mineCraftRateS[7]['rate'] * (jewPrice - tuPrice * 2)
    local o0m = dft_mineCraftRateS[8]['rate'] * (jewPrice - tuPrice * 2)
    local y0m = dft_mineCraftRateS[9]['rate'] * (jewPrice - tuPrice * 2)
    local g0m = dft_mineCraftRateS[10]['rate'] * (1 * dft_mineCraftPerfectRate + 0.5 * (1 - dft_mineCraftPerfectRate))
    local b0m = dft_mineCraftRateS[11]['rate'] * (jewPrice - tuPrice * 2)
    local p0m = dft_mineCraftRateS[12]['rate'] * (1 * dft_mineCraftPerfectRate + 0.5 * (1 - dft_mineCraftPerfectRate))

    local total = r1m + o1m + y1m + g1m + b1m + p1m + r0m + o0m + y0m + g0m + b0m + p0m
    return math.floor(total / 100)
end

onMineCrafingUpdate = function()
    if not mineCrafting then return end
    XInfo.reloadBag()

    if XInfo.getBagItemCount('萨隆邪铁矿石') < 20 and XInfo.getMailItemCount('萨隆邪铁矿石') > 0 then
        XUtils.receiveMail('萨隆邪铁矿石')
        return
    end

    for _, item in ipairs(dft_mineCraftRateS) do
        if XInfo.getBagItemCount(item['itemname']) >= 60 then
            XUtils.sendMail(item['itemname'], 3)
            return
        end
    end

    XUtils.shrinkBag()
    XUtils.sortJewsInBag()
end

onJewCrafingUpdate = function()
    if not jewCrafting then return end
    XInfo.reloadBag()

    local rubbishList = XCraftQueue.getRubbishList()
    for _, item in ipairs(rubbishList) do
        if XInfo.getBagItemCount(item['itemname']) >= 5 then
            XUtils.sendMail(item['itemname'], 5)
            return
        end
        if XInfo.getBagItemCount('完美' .. item['itemname']) >= 5 then
            XUtils.sendMail('完美' .. item['itemname'], 5)
            return
        end
    end
    for _, item in ipairs(rubbishList) do
        local materialName = XInfo.getMaterialName(item['itemname'])
        if XInfo.getBagItemCount(materialName) < 20 and XInfo.getMailItemCount(materialName) > 0 then
            XUtils.receiveMail(materialName)
            return
        end
    end
    if XInfo.getBagItemCount('永恒之土') <= 0 and XInfo.getBagItemCount('土之结晶') < 10 and XInfo.getMailItemCount('永恒之土') > 0 then
        XUtils.receiveMail('永恒之土')
        return
    end

    XUtils.shrinkBag()
    XUtils.sortJewsInBag()
end

-- Observes
local itemChangeCallbacks = {}
XBuy.registerItemChangeCallback = function(key, callback)
    itemChangeCallbacks[key] = callback
end

itemChanged = function()
    for _, callback in pairs(itemChangeCallbacks) do
        if type(callback) == 'function' then
            callback()
        end
    end
end

-- Events
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XJewTool.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    if mainFrame then mainFrame:Hide() end
end)

XJewTool.registerRefreshCallback(moduleName, refreshUI)

XJewTool.registerFastUpdateCallback(moduleName .. '_mine', onMineCrafingUpdate)
XJewTool.registerUpdateCallback(moduleName .. '_jew', onJewCrafingUpdate)

-- Commands
SlashCmdList['XBUY'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XBUY1 = '/xbuy'

SlashCmdList['XBUYSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XBUYSHOW1 = '/xbuy_show'

SlashCmdList['XBUYHIDE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XBUYHIDE1 = '/xbuy_close'

-- Interface
XBuy.getItem = getItem
XBuy.getItemField = getItemField
XBuy.reset = reset
