XJewCount = {}
local moduleName = 'XJewCount'

-- Variable definition
local dft_receiver1 = '阿肌'
local dft_receiver2 = '默法'
local dft_receiverItemList2 = { '萨隆邪铁矿石', '太阳水晶', '永恒之土', '钴矿石' }
local dft_receiverSell = '小灬白龙'
-- local dft_receiverSell = '咖喱骑士'

local mainFrame = nil
local labels = {}
local initUI
local refreshUI
local createLabel
local reloadLabels

local printPrice

local categories = { '默认', '出售', '原石', '炸矿' }
local categoryIndex = 1
local categoryItemList = {
    {
        { '太阳水晶', '萨隆邪铁矿石', '永恒之土', '钴矿石' },
        { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石' }
    },
    {
        { '太阳水晶', '萨隆邪铁矿石' },
        { '永恒之土', '钴矿石' }
    },
    {
        { '赤玉石', '紫黄晶', '王者琥珀', '祖尔之眼', '巨锆石', '恐惧石' },
        { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石' }
    },
    {
        { '血石', '茶晶石', '太阳水晶', '黑玉', '玉髓石', '暗影水晶', '泰坦神铁矿石' },
        { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石', '萨隆邪铁矿石' }
    }
}

-- Function implemention
createLabel = function(itemName)
    local itemId = XInfo.getItemId(itemName)

    local frame = XAPI.CreateFrame('Frame', nil, mainFrame)
    frame:SetSize(180, 30)
    frame.itemName = itemName
    frame.itemId = itemId

    local sendMailButton = XUI.createButton(frame, 30, 'U')
    sendMailButton:SetPoint('LEFT', frame, 'LEFT', 0, 0)
    sendMailButton:SetScript('OnClick', function(self)
        local category = categories[categoryIndex]
        if category == '出售' then
            XInfo.reloadBag()
            local item = XInfo.getBagItem(self.frame.itemName)
            if item then
                XUtils.sendMail(self.frame.itemName, #item['positions'], false, dft_receiverSell, 'auto')
            end
        else
            local count = 1
            local fullStack = true
            if IsLeftControlKeyDown() then
                fullStack = false
                if IsShiftKeyDown() then
                    XInfo.reloadBag()
                    local item = XInfo.getBagItem(self.frame.itemName)
                    if item then count = #item['positions'] end
                end
            else
                if IsShiftKeyDown() then
                    XInfo.reloadBag()
                    local item = XInfo.getBagItem(self.frame.itemName)
                    if item then count = #item['positions'] - 1 end
                end
            end
            local receiver = dft_receiver1
            if XUtils.inArray(self.frame.itemName, dft_receiverItemList2) then
                receiver = dft_receiver2
            end
            XUtils.sendMail(self.frame.itemName, count, fullStack, receiver)
        end
        refreshUI()
    end)
    sendMailButton.frame = frame

    local receiveMailButton = XUI.createButton(frame, 30, 'R')
    receiveMailButton:SetPoint('LEFT', sendMailButton, 'RIGHT', 0, 0)
    receiveMailButton:SetScript('OnClick', function(self)
        if IsLeftShiftKeyDown() then
            if IsLeftControlKeyDown() then
                XUtils.receiveMail(self.frame.itemName, true)
            else
                XUtils.receiveMail(self.frame.itemName, true, true)
            end
        else
            XUtils.receiveMail(self.frame.itemName)
        end
        refreshUI()
    end)
    receiveMailButton.frame = frame

    local toBankButton = XUI.createButton(frame, 30, 'O')
    toBankButton:SetPoint('LEFT', receiveMailButton, 'RIGHT', 0, 0)
    toBankButton:SetScript('OnClick', function(self)
        if IsShiftKeyDown() then
            XUtils.moveToBank(self.frame.itemName, nil, nil, false)
        else
            XUtils.moveToBank(self.frame.itemName, 1)
        end
        refreshUI()
    end)
    toBankButton.frame = frame

    local toBagButton = XUI.createButton(frame, 30, 'I')
    toBagButton:SetPoint('LEFT', toBankButton, 'RIGHT', 0, 0)
    toBagButton:SetScript('OnClick', function(self)
        if IsShiftKeyDown() then
            XUtils.moveToBag(self.frame.itemName, nil, nil, false)
        else
            XUtils.moveToBag(self.frame.itemName, 1)
        end
        refreshUI()
    end)
    toBagButton.frame = frame

    local itemFrame = XAPI.CreateFrame('Frame', nil, frame)
    itemFrame:SetSize(110, 30)
    itemFrame:SetPoint('LEFT', toBagButton, 'RIGHT', 3, 0)

    local icon = XUI.createItemIcon(itemFrame, 25, 25, itemName)
    icon:SetPoint('LEFT', itemFrame, 'LEFT', 0, 0)

    local label = XUI.createLabel(itemFrame, 120)
    label:SetPoint('LEFT', icon, 'RIGHT', 10, 0)
    label:SetHeight(18)

    itemFrame:SetScript("OnEnter", function(self)
        if self.frame.itemId > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.frame.itemId) -- 显示物品信息
        end
    end)
    itemFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    itemFrame:SetScript('OnMouseDown', function(self)
        if IsLeftAltKeyDown() then
            XAPI.Auctionator_SearchExact(self.frame.itemName)
        elseif IsLeftShiftKeyDown() then
            XAuctionCenter.addMaterialQueryTaskByItemName(self.frame.itemName)
            refreshUI()
        elseif IsLeftControlKeyDown() then
            XInfo.printBuyHistory(self.frame.itemName)
        end
    end)
    itemFrame.frame = frame
    frame.label = label

    frame.Refresh = function(self)
        local bagCount = XInfo.getBagItemCount(self.itemName)
        local bagCountStr = XUI.getColor_MaterialCount(bagCount) .. bagCount
        local mailCount = XInfo.getMailItemCount(self.itemName)
        local mailCountStr = XUI.getColor_MaterialTotalCount(mailCount) .. mailCount
        local totalCount = XInfo.getItemTotalCountAll(self.itemName)
        local totalCountStr = XUI.getColor_MaterialTotalCount(totalCount) .. totalCount

        local content = bagCountStr
            .. XUI.White .. ' / ' .. mailCountStr
            .. XUI.White .. ' / ' .. totalCountStr

        self.label:SetText(content)
    end
    return frame
end

reloadLabels = function()
    if mainFrame == nil then return end
    if not categoryItemList[categoryIndex] then return end

    local col1 = categoryItemList[categoryIndex][1]
    local col2 = categoryItemList[categoryIndex][2]

    for _, item in ipairs(labels) do
        item:Hide()
    end
    labels = {}

    local lastWidget = mainFrame
    for index, itemName in ipairs(col1) do
        local label = createLabel(itemName)
        if index == 1 then
            label:SetPoint('TOPLEFT', lastWidget, 'TOPLEFT', 8, -30)
        else
            label:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, 0)
        end
        table.insert(labels, label)
        lastWidget = label
    end

    lastWidget = mainFrame
    for index, itemName in ipairs(col2) do
        local label = createLabel(itemName)
        if index == 1 then
            label:SetPoint('TOPLEFT', lastWidget, 'TOPLEFT', 292, -30)
        else
            label:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, 0)
        end
        table.insert(labels, label)
        lastWidget = label
    end

    local count = #col1
    if #col2 > count then count = #col2 end
    mainFrame:SetHeight(count * 30 + 50)
end

initUI = function()
    mainFrame = XUI.createFrame('XJewCountMainFrame', 580, 250)
    mainFrame.title:SetText('默认')
    mainFrame:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 60)
    mainFrame:Hide()
    XJewCount.mainFrame = mainFrame
    tinsert(UISpecialFrames, mainFrame:GetName())

    local fulfilStackButton = XUI.createButton(mainFrame, 60, '补全')
    fulfilStackButton:SetHeight(20)
    fulfilStackButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -30, -1)
    fulfilStackButton:SetScript('OnClick', function()
        if not XAPI.IsBankOpen() then
            xdebug.error('银行未打开')
            return
        end

        for i = 0, XAPI.NUM_BAG_SLOTS do
            local bagSlotCount = XAPI.C_Container_GetContainerNumSlots(i)
            for j = 1, bagSlotCount do
                local itemBag = XAPI.C_Container_GetContainerItemInfo(i, j)
                if itemBag then
                    local itemName = itemBag.itemName
                    local count = itemBag.stackCount
                    local stackCount = XInfo.getStackCount(itemName)
                    if XUtils.inArray(itemName, XInfo.materialList) then
                        if count < stackCount then
                            local subCount = stackCount - count
                            for x = -1, XAPI.NUM_BAG_SLOTS + XAPI.NUM_BANKBAGSLOTS do
                                if count < stackCount then
                                    if x < 0 or x > XAPI.NUM_BAG_SLOTS then
                                        local bankSlotCount = XAPI.C_Container_GetContainerNumSlots(x)
                                        for y = 1, bankSlotCount do
                                            local itemBank = XAPI.C_Container_GetContainerItemInfo(x, y)
                                            if itemBank then
                                                local itemName2 = itemBank.itemName
                                                local count2 = itemBank.stackCount
                                                if itemName2 == itemName then
                                                    if count2 <= subCount then
                                                        XAPI.C_Container_PickupContainerItem(x, y)
                                                        count = count + count2
                                                    else
                                                        XAPI.C_Container_SplitContainerItem(x, y, subCount)
                                                        count = count + subCount
                                                    end
                                                    XAPI.C_Container_PickupContainerItem(i, j)
                                                    if count >= stackCount then
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                else
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        xdebug.info('补充完成')
    end)

    local shrinkButton = XUI.createButton(mainFrame, 60, '整理')
    shrinkButton:SetHeight(20)
    shrinkButton:SetPoint('RIGHT', fulfilStackButton, 'LEFT', -3, 0)
    shrinkButton:SetScript('OnClick', function()
        XAutoAuction.registerUIUpdateCallback(moduleName .. '_sort', function()
            local list = {}
            local found = false
            for i = 0, XAPI.NUM_BAG_SLOTS do
                local bagSlotCount = XAPI.C_Container_GetContainerNumSlots(i)
                for j = 1, bagSlotCount do
                    if not XInfo.isItemFullStack(i, j) then
                        local itemBag = XAPI.C_Container_GetContainerItemInfo(i, j)
                        if itemBag then
                            local itemName = itemBag.itemName
                            if list[itemName] then
                                XAPI.C_Container_PickupContainerItem(i, j)
                                XAPI.C_Container_PickupContainerItem(list[itemName]['x'], list[itemName]['y'])
                                list[itemName] = nil
                                found = true
                            else
                                list[itemName] = { x = i, y = j }
                            end
                        end
                    end
                end
            end
            if not found then
                XAutoAuction.unRegisterUIUpdateCallback(moduleName .. '_sort')
                xdebug.info('整理完成')
            end
        end, 0.2)
    end)

    local bagPriceButton = XUI.createButton(mainFrame, 60, '包价')
    bagPriceButton:SetHeight(20)
    bagPriceButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 5, -1)
    bagPriceButton:SetScript('OnClick', function()
        printPrice(false)
    end)

    local totalPriceButton = XUI.createButton(mainFrame, 60, '总价')
    totalPriceButton:SetHeight(20)
    totalPriceButton:SetPoint('LEFT', bagPriceButton, 'RIGHT', 3, 0)
    totalPriceButton:SetScript('OnClick', function(self)
        printPrice(true)
    end)

    local categoryButton = XUI.createButton(mainFrame, 60, categories[categoryIndex])
    categoryButton:SetHeight(20)
    categoryButton:SetPoint('BOTTOMRIGHT', mainFrame, 'BOTTOMRIGHT', 0, 0)
    categoryButton:SetScript('OnClick', function(self)
        categoryIndex = (categoryIndex % #categories) + 1
        self:SetText(categories[categoryIndex])
        reloadLabels()
        refreshUI()
    end)


    reloadLabels()

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end

    XInfo.reloadBag()

    mainFrame.title:SetText(categories[categoryIndex])
    for _, label in ipairs(labels) do
        label:Refresh()
    end
end

printPrice = function(isAll)
    local itemList = {}
    for _, itemName in ipairs(categoryItemList[categoryIndex][1]) do
        table.insert(itemList, itemName)
    end
    for _, itemName in ipairs(categoryItemList[categoryIndex][2]) do
        table.insert(itemList, itemName)
    end

    XInfo.reloadCount()
    local str = ''
    local total = 0
    for _, itemName in ipairs(itemList) do
        local price = XAutoBuy.getItemField(itemName, 'price', 0) / 10000
        local count = 0
        if isAll then
            count = XInfo.getItemTotalCount(itemName)
        else
            count = XInfo.getBagItemCount(itemName)
        end
        if count > 0 and price > 0 then
            str = str .. string.sub(itemName, 1, 3) .. price .. '*' .. count .. '+'
            total = total + price * count
        end
    end
    total = math.floor(total)
    if XUtils.stringEndsWith(str, '+') then
        str = string.sub(str, 1, string.len(str) - 1)
        str = str .. '=' .. total .. ' (' .. math.floor(total * XAPI.ProfitRate) .. ')'
        xdebug.info(str)
    end
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
SlashCmdList['XJEWCOUNT'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XJEWCOUNT1 = '/xjewcount'

SlashCmdList['XJEWCOUNTSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XJEWCOUNTSHOW1 = '/xjewcount_show'

SlashCmdList['XJEWCOUNTCLOSE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XJEWCOUNTCLOSE1 = '/xjewcount_close'

-- Interface
XJewCount.toggle = function() XUI.toggleVisible(mainFrame) end
