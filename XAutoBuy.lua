XAutoBuy = {}
local moduleName = 'XAutoBuy'

-- Variable definition
local mainFrame = nil

local dft_minPrice = 9999999

local dft_buttonWidth = 40
local dft_buttonGap = 1

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

-- Function definition
local initUI
local refreshUI
local getItem
local getItemField
local addItem
local reset

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XAutoBuyMainFrame', 570, 425)
    mainFrame.title:SetText('自动购买')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

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

    local importButton = XUI.createButton(mainFrame, dft_buttonWidth, '导')
    importButton:SetPoint('LEFT', settingButton, 'RIGHT', dft_buttonGap, 0)
    importButton:SetScript('OnClick', function()
        XUIConfirmDialog.show(moduleName, '确认', '确认从Auctionator导入', function()
            for _, item in ipairs(XAutoBuyList) do
                if item['enabled'] then
                    local itemId = XInfo.getItemInfoField(item['itemname'], 'itemid')
                    local price = XAPI.Auctionator_GetAuctionPriceByItemId(itemId)
                    item['minbuyoutprice'] = price
                    item['updatetime'] = time()
                end
            end
            refreshUI()
        end)
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
            XUISortDialog.show('XAutoBuy_Sort', XAutoBuyList, idx, function()
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
            displaySettingItem = XAutoBuyList[idx]

            if IsLeftControlKeyDown() then
                XInfo.printBuyHistory(displaySettingItem['itemname'])
            else
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
            end
        end)
        itemNameButton:SetScript("OnEnter", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoBuyList[idx]
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

        local labelt = XUI.createLabel(frame, 50, '')
        labelt:SetPoint('LEFT', itemNameButton, 'RIGHT', 8, 0)
        frame.labelt = labelt

        local label = XUI.createLabel(frame, 50, '')
        label:SetPoint('LEFT', labelt, 'RIGHT', 0, 0)
        frame.label = label

        local label2 = XUI.createLabel(frame, 55, '')
        label2:SetPoint('LEFT', label, 'RIGHT', 0, 0)
        frame.label2 = label2

        local label4 = XUI.createLabel(frame, 55, '')
        label4:SetPoint('LEFT', label2, 'RIGHT', 0, 0)
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

    mainFrame.title:SetText('自动购买 (' .. (displayPageNo + 1) .. '/'
        .. (math.ceil(#XAutoBuyList / displayPageSize)) .. ')')

    XInfo.reloadBag()

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #XAutoBuyList then
            local item = XAutoBuyList[idx]
            local itemName = item['itemname']
            local itemId = XInfo.getItemId(itemName)

            local price = item['price']
            local priceStr = XUI.White .. XUtils.priceToString(price)

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

            local bagCount = XInfo.getBagItemCount(itemName)
            local bagCountStr = XUI.getColor_MaterialCount(bagCount) .. bagCount
            local bankCount = XInfo.getBankItemCount(itemName)
            local bankCountStr = XUI.getColor_MaterialCount(bankCount) .. bankCount

            local updateTimeStr = XUtils.formatTime(item['updatetime'])

            frame.indexButton:SetText(idx)
            frame.icon:SetTexture(XAPI.GetItemIcon(itemId))
            frame.itemNameButton:SetText(string.sub(itemName, 1, 18))
            frame.labelt:SetText(updateTimeStr)
            frame.label:SetText(bagCountStr .. XUI.White .. '/' .. bankCountStr)
            frame.label2:SetText(priceStr)
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

-- price / minbuyoutprice / minprice
getItemField = function(itemName, fieldName, defaultValue)
    local item = getItem(itemName)
    if not item then return defaultValue end
    if not item[fieldName] then return defaultValue end
    return item[fieldName]
end

addItem = function(itemName, price)
    if getItem(itemName) then return end
    local item = {
        itemname = itemName,
        price = price,
        minbuyoutprice = dft_minPrice,
        minprice = dft_minPrice,
        updatetime = 0
    }
    table.insert(XAutoBuyList, item)
    refreshUI()
end

reset = function()
    for _, item in ipairs(XAutoBuyList) do
        item['minbuyoutprice'] = dft_minPrice
        item['updatetime'] = 0
    end
    refreshUI()
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    if mainFrame then mainFrame:Hide() end
end)

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
XAutoBuy.getItemField = getItemField
XAutoBuy.reset = reset
