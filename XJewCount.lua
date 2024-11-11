XJewCount = {}
local moduleName = 'XJewCount'

-- Variable definition

local mainFrame = nil
local categoryButtons = {}
local labels = {}
local initData
local initUI
local refreshUI
local createLabel
local reloadLabels

local printPrice

local dft_defaultReceiver = '阿肌'
local receiverList = {
    {
        receiver = '默法',
        list = { '萨隆邪铁矿石', '血石', '茶晶石', '太阳水晶', '黑玉', '玉髓石', '暗影水晶', '永恒之土', '土之结晶', '钴矿石', '冰冻宝珠' }
    }
}

local categoryIndex = 3
local jewList = {
    {
        category = '全部',
        receiver = nil,
        issell = 0,
        list = { {}, {} }
    },
    {
        category = '起用',
        receiver = nil,
        issell = 0,
        list = { {}, {} }
    },
    {
        category = '常用',
        receiver = nil,
        issell = 0,
        list = { { '太阳水晶', '血石', '玉髓石', '萨隆邪铁矿石', '永恒之土', '土之结晶' }, { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石'} }
    },
    {
        category = '白龙',
        receiver = '小灬白龙',
        issell = 1,
        list = {
            { '太阳水晶', '血石', '玉髓石' }, { '萨隆邪铁矿石', '永恒之土', '土之结晶', '钴矿石' }
        }
    },
    {
        category = '九五',
        receiver = '编号九十五',
        issell = 1,
        list = {
            { '金苜蓿', '卷丹' }, { '死亡荨麻', '塔兰德拉的玫瑰' }
        }
    },
    {
        category = '咖喱',
        receiver = '咖喱贼',
        issell = 1,
        fixedprice = 100,
        list = { { '太阳水晶', '血石', '玉髓石', '萨隆邪铁矿石', '永恒之土', '土之结晶', '钴矿石', '损坏的项链' }, { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石', '冰冻宝珠' } }
    },
    {
        category = '原石',
        receiver = nil,
        issell = 0,
        list = {
            { '赤玉石', '紫黄晶', '王者琥珀', '祖尔之眼', '巨锆石', '恐惧石' },
            { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石' }
        }
    },
    {
        category = '炸矿',
        receiver = nil,
        issell = 0,
        list = {
            { '血石', '茶晶石', '太阳水晶', '黑玉', '玉髓石', '暗影水晶', '泰坦神铁矿石' },
            { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石', '萨隆邪铁矿石' }
        }
    }
}

-- Function implemention
initData = function()
    local list11 = {}
    local list12 = {}
    local list21 = {}
    local list22 = {}
    for _, buyItem in ipairs(XBuyItemList) do
        table.insert(list11, buyItem['itemname'])
        if buyItem['enabled'] then
            table.insert(list21, buyItem['itemname'])
        end
    end
    local startIndex = math.floor(#list11 / 2) + 1
    local endIndex = #list11
    for i = endIndex, startIndex, -1 do
        table.insert(list12, 1, list11[i])
        list11[i] = nil
    end
    jewList[1]['list'][1] = list11
    jewList[1]['list'][2] = list12

    startIndex = math.floor(#list21 / 2) + 1
    endIndex = #list21
    for i = endIndex, startIndex, -1 do
        table.insert(list22, 1, list21[i])
        list21[i] = nil
    end
    jewList[2]['list'][1] = list21
    jewList[2]['list'][2] = list22
end

createLabel = function(itemName)
    local itemId = XInfo.getItemId(itemName)

    local frame = XAPI.CreateFrame('Frame', nil, mainFrame)
    frame:SetSize(180, 30)
    frame.itemName = itemName
    frame.itemId = itemId

    local sendMailButton = XUI.createButton(frame, 30, 'U')
    sendMailButton:SetPoint('LEFT', frame, 'LEFT', 0, 0)
    sendMailButton:SetScript('OnClick', function(self)
        XInfo.reloadBag()
        local category = jewList[categoryIndex]
        local _itemName = self.frame.itemName
        local item = XInfo.getBagItem(_itemName)
        if not item then
            xdebug.error(_itemName .. '未找到')
            return
        end
        local count = 0
        if item then count = #item['positions'] end

        if category['issell'] and category['issell'] == 1 and IsLeftShiftKeyDown() then
            local receiver = category['receiver']
            local money = 'auto'
            if category['fixedprice'] then
                money = category['fixedprice']
            end
            XUtils.sendMail(_itemName, count, false, receiver, money)
        else
            local receiver = dft_defaultReceiver
            for _, receiverItem in ipairs(receiverList) do
                if XUtils.inArray(_itemName, receiverItem['list']) then
                    receiver = receiverItem['receiver']
                    break
                end
            end
            if IsLeftControlKeyDown() then
                XUtils.sendMail(_itemName, count, false, receiver)
            else
                XUtils.sendMail(_itemName, 1, true, receiver)
            end
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
    if not jewList[categoryIndex] then return end

    local col1 = jewList[categoryIndex]['list'][1]
    local col2 = jewList[categoryIndex]['list'][2]

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
    mainFrame:SetHeight(count * 30 + 55)
end

initUI = function()
    mainFrame = XUI.createFrame('XJewCountMainFrame', 580, 255)
    mainFrame.title:SetText('常用')
    mainFrame:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 60)
    mainFrame:Hide()
    XJewCount.mainFrame = mainFrame
    tinsert(UISpecialFrames, mainFrame:GetName())

    local fulfilStackButton = XUI.createButton(mainFrame, 60, '补全')
    fulfilStackButton:SetHeight(20)
    fulfilStackButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -30, -1)
    fulfilStackButton:SetScript('OnClick', function()
        XUtils.fulfilBag()
        xdebug.info('补充完成')
    end)

    local shrinkButton = XUI.createButton(mainFrame, 60, '整理')
    shrinkButton:SetHeight(20)
    shrinkButton:SetPoint('RIGHT', fulfilStackButton, 'LEFT', -3, 0)
    shrinkButton:SetScript('OnClick', function()
        XUtils.shrinkBag()
        xdebug.info('整理完成')
    end)

    local sortButton = XUI.createButton(mainFrame, 60, '排列')
    sortButton:SetHeight(20)
    sortButton:SetPoint('RIGHT', shrinkButton, 'LEFT', -3, 0)
    sortButton:SetScript('OnClick', function()
        XUtils.sortJewsInBag()
        xdebug.info('排列完成')
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

    local lastWidget = mainFrame
    for index, jewItem in ipairs(jewList) do
        local category = jewItem['category']
        local categoryButton = XUI.createButton(mainFrame, 60, XUI.Red .. category)
        if index == categoryIndex then
            categoryButton:SetText(XUI.Green .. category)
        end
        categoryButton:SetHeight(20)
        categoryButton.index = index
        if index == 1 then
            categoryButton:SetPoint('BOTTOMRIGHT', lastWidget, 'BOTTOMRIGHT', 0, 0)
        else
            categoryButton:SetPoint('RIGHT', lastWidget, 'LEFT', -3, 0)
        end
        categoryButton:SetScript('OnClick', function(self)
            for _, button in ipairs(categoryButtons) do
                button:SetText(XUI.Red .. jewList[button.index]['category'])
            end
            categoryIndex = self.index
            self:SetText(XUI.Green .. jewList[self.index]['category'])

            local title = jewList[self.index]['category']
            if jewList[self.index]['receiver'] then
                title = title .. ' (' .. jewList[self.index]['receiver'] .. ')'
            end
            mainFrame.title:SetText(title)
            reloadLabels()
            refreshUI()
        end)

        table.insert(categoryButtons, categoryButton)
        lastWidget = categoryButton
    end

    reloadLabels()

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end

    XInfo.reloadBag()

    for _, label in ipairs(labels) do
        label:Refresh()
    end
end

printPrice = function(isAll)
    local itemList = {}
    for _, itemName in ipairs(jewList[categoryIndex]['list'][1]) do
        table.insert(itemList, itemName)
    end
    for _, itemName in ipairs(jewList[categoryIndex]['list'][2]) do
        table.insert(itemList, itemName)
    end

    XInfo.reloadCount()
    local str = ''
    local total = 0
    for _, itemName in ipairs(itemList) do
        local price = XBuy.getItemField(itemName, 'price', 0) / 10000
        local count = 0
        if isAll then
            count = XInfo.getItemTotalCountAll(itemName)
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
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initData()
    initUI()
    refreshUI()
end)

XJewTool.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    if mainFrame then mainFrame:Hide() end
end)

XJewTool.registerRefreshCallback(moduleName, refreshUI)

XBuy.registerItemChangeCallback(moduleName, function()
    initData()
    reloadLabels()
    refreshUI()
end)

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
