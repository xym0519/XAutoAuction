XMineCenter = {}
local moduleName = 'XMineCenter'

-- Variable definition
local mainFrame = nil

local dft_buttonWidth = 60
local dft_buttonGap = 1

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local successCount = 0
local productList = {}

local mode = 'normal'
local onUpdate

-- Function definition
local initUI
local refreshUI
local addItem
local reset
local getPrice
local getMineSmallPrice
local getRedJewSmallPrice

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame(moduleName .. 'MainFrame', 655, 425)
    mainFrame.title:SetText('炸矿中心')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local normalModeButton = XUI.createButton(mainFrame, dft_buttonWidth, '普通')
    normalModeButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    normalModeButton:SetScript('OnClick', function(self)
        mode = 'normal'
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

        refreshUI()
    end)
    mainFrame.normalModeButton = normalModeButton

    local mineCraftModeButton = XUI.createButton(mainFrame, dft_buttonWidth, '炸矿')
    mineCraftModeButton:SetPoint('LEFT', normalModeButton, 'RIGHT', dft_buttonGap, 0)
    mineCraftModeButton:SetScript('OnClick', function(self)
        XCraftQueue.start(true, 5, true)
        if not XCraftQueue.isRunning() then return end
        mode = 'mine'
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

        refreshUI()
    end)
    mainFrame.mineCraftStartButton = mineCraftModeButton

    local jewCraftModeButton = XUI.createButton(mainFrame, dft_buttonWidth, '垃圾')
    jewCraftModeButton:SetPoint('LEFT', mineCraftModeButton, 'RIGHT', dft_buttonGap, 0)
    jewCraftModeButton:SetScript('OnClick', function(self)
        mode = 'rubbish'
        self:SetFocus(true)
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

        refreshUI()
    end)
    mainFrame.jewCraftStartButton = jewCraftModeButton

    local preButton = XUI.createButton(mainFrame, dft_buttonWidth, '上页')
    preButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 280, -30)
    preButton:SetScript('OnClick', function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, dft_buttonWidth, '下页')
    nextButton:SetPoint('LEFT', preButton, 'RIGHT', dft_buttonGap, 0)
    nextButton:SetScript('OnClick', function()
        if displayPageNo < math.ceil(#XBuyItemList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            refreshUI()
        end
    end)

    local resetButton = XUI.createButton(mainFrame, dft_buttonWidth, '清理')
    resetButton:SetPoint('LEFT', nextButton, 'RIGHT', dft_buttonGap, 0)
    resetButton:SetScript('OnClick', function()
        reset()
    end)

    local refreshButton = XUI.createButton(mainFrame, dft_buttonWidth, '刷新')
    refreshButton:SetPoint('LEFT', resetButton, 'RIGHT', dft_buttonGap, 0)
    refreshButton:SetScript('OnClick', function()
        refreshUI()
    end)

    local label11 = XUI.createLabel(mainFrame, 80, '邪铁价格：', 'LEFT')
    label11:SetPoint('TOPLEFT', normalModeButton, 'BOTTOMLEFT', 5, -10)
    local label12 = XUI.createLabel(mainFrame, 120, '', 'LEFT')
    label12:SetPoint('LEFT', label11, 'RIGHT', 0, 0)
    mainFrame.label12 = label12

    local label21 = XUI.createLabel(mainFrame, 80, '血石价格：', 'LEFT')
    label21:SetPoint('TOPLEFT', label11, 'BOTTOMLEFT', 0, -5)
    local label22 = XUI.createLabel(mainFrame, 120, '', 'LEFT')
    label22:SetPoint('LEFT', label21, 'RIGHT', 0, 0)
    mainFrame.label22 = label22

    local label31 = XUI.createLabel(mainFrame, 80, '炸矿剩余：', 'LEFT')
    label31:SetPoint('TOPLEFT', label21, 'BOTTOMLEFT', 0, -20)
    local label32 = XUI.createLabel(mainFrame, 120, '', 'LEFT')
    label32:SetPoint('LEFT', label31, 'RIGHT', 0, 0)
    mainFrame.label32 = label32

    local label41 = XUI.createLabel(mainFrame, 80, '炸矿数量：', 'LEFT')
    label41:SetPoint('TOPLEFT', label31, 'BOTTOMLEFT', 0, -5)
    local label42 = XUI.createLabel(mainFrame, 120, '', 'LEFT')
    label42:SetPoint('LEFT', label41, 'RIGHT', 0, 0)
    mainFrame.label42 = label42

    local label51 = XUI.createLabel(mainFrame, 80, '炸矿价值：', 'LEFT')
    label51:SetPoint('TOPLEFT', label41, 'BOTTOMLEFT', 0, -5)
    local label52 = XUI.createLabel(mainFrame, 120, '', 'LEFT')
    label52:SetPoint('LEFT', label51, 'RIGHT', 0, 0)
    mainFrame.label52 = label52

    local label61 = XUI.createLabel(mainFrame, 80, '产物价值：', 'LEFT')
    label61:SetPoint('TOPLEFT', label51, 'BOTTOMLEFT', 0, -5)
    local label62 = XUI.createLabel(mainFrame, 120, '', 'LEFT')
    label62:SetPoint('LEFT', label61, 'RIGHT', 0, 0)
    mainFrame.label62 = label62

    local lastWidget = preButton
    for i = 1, displayPageSize do
        local frame = XAPI.CreateFrame('Frame', nil, mainFrame)
        frame:SetSize(240, 30)

        if i == 1 then
            frame:SetPoint('TOPLEFT', preButton, 'BOTTOMLEFT', 0, -10)
        else
            frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -5)
        end

        frame:Hide()

        local icon = XUI.createIcon(frame, 25, 25)
        icon:SetPoint('LEFT', frame, 'LEFT', 15, 0)
        frame.icon = icon

        local itemNameLabel = XUI.createLabel(frame, 120, '')
        itemNameLabel:SetPoint('LEFT', icon, 'RIGHT', 5, 0)
        frame.itemNameLabel = itemNameLabel

        local countLabel = XUI.createLabel(frame, 50, '')
        countLabel:SetPoint('LEFT', itemNameLabel, 'RIGHT', 8, 0)
        frame.countLabel = countLabel

        local valueLabel = XUI.createLabel(frame, 120, '')
        valueLabel:SetPoint('LEFT', countLabel, 'RIGHT', 8, 0)
        frame.valueLabel = valueLabel

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end

    if mode == 'mine' and not XCraftQueue.isRunning() then
        mode = ''
    end

    if not mainFrame:IsVisible() then return end

    mainFrame.normalModeButton:SetFocus(mode == 'normal')
    mainFrame.mineCraftStartButton:SetFocus(mode == 'mine')
    mainFrame.jewCraftStartButton:SetFocus(mode == 'rubbish')

    local mineSmallPrice = getMineSmallPrice()
    mainFrame.label12:SetText(XUtils.priceToMoneyString(mineSmallPrice))

    local redJewSmallPrice = getRedJewSmallPrice()
    mainFrame.label22:SetText(XUtils.priceToMoneyString(redJewSmallPrice))

    local mineCount = XInfo.getItemTotalCount('萨隆邪铁矿石')
    local mineTime = math.ceil(mineCount / 5 * 2.5)
    local mineTimeStr = ''
    if mineTime < 60 then
        mineTimeStr = mineTime .. 's'
    elseif mineTime < 60 * 60 then
        mineTimeStr = math.floor(mineTime / 60) .. 'm ' .. (mineTime % 60) .. 's'
    else
        mineTimeStr = math.floor(mineTime / 60 / 60) .. 'h '
            .. math.floor(mineTime / 60) .. 'm '
            .. (mineTime % 60) .. 's'
    end
    mainFrame.label32:SetText(mineTimeStr)

    mainFrame.label42:SetText(successCount * 5)

    local successValue = XBuy.getItemField('萨隆邪铁矿石', 'sellprice', 0) * successCount * 5
    mainFrame.label52:SetText(XUtils.priceToMoneyString(successValue))

    local productValue = 0
    for _, item in ipairs(productList) do
        local itemName = item['itemname']
        local count = item['count']
        productValue = productValue + getPrice(itemName) * count
    end
    mainFrame.label62:SetText(XUtils.priceToMoneyString(productValue))

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #productList then
            local item = productList[idx]
            local itemName = item['itemname']
            local itemId = XInfo.getItemId(itemName)
            local count = item['count']
            local value = XBuy.getItemField(itemName, 'sellprice', 0) * count

            frame.icon:SetTexture(XAPI.GetItemIcon(itemId))
            frame.itemNameLabel:SetText(itemName)
            frame.countLabel:SetText(count)
            frame.valueLabel:SetText(XUtils.priceToMoneyString(value))
            frame:Show()
        else
            frame:Hide()
        end
    end
end

addItem = function(itemName)
    local found = false
    for _, item in ipairs(productList) do
        if item['itemname'] == itemName then
            item['count'] = item['count'] + 1
            found = true
            break
        end
    end
    if not found then
        tinsert(productList, { itemname = itemName, count = 1 })
    end
    refreshUI()
end

reset = function()
    successCount = 0
    productList = {}
    refreshUI()
end

getPrice = function(itemName)
    local jewPrice = 31478
    local tuPrice = XBuy.getItemField('土之结晶', 'sellprice', 0)
    if XUtils.inArray(itemName, { '血石', '茶晶石', '太阳水晶', '玉髓石' }) then
        return jewPrice - tuPrice * 2
    elseif XUtils.inArray(itemName, { '黑玉', '暗影水晶' }) then
        return 10000 * XAPI.PerfectJewRate + 5000 * (1 - XAPI.PerfectJewRate)
    else
        return XBuy.getItemField(itemName, 'sellprice', 0)
    end
end

getMineSmallPrice = function()
    local list = { '血玉石', '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石',
        '血石', '茶晶石', '太阳水晶', '黑玉', '玉髓石', '暗影水晶' }

    local total = 0
    for _, itemName in ipairs(list) do
        total = total + XAPI.MineJewRateSmall[itemName] * getPrice(itemName)
    end

    return math.ceil(total)
end

getRedJewSmallPrice = function()
    local minePrice = XBuy.getItemField('萨隆邪铁矿石', 'sellprice', 0)

    local list = { '帝黄晶', '秋色石', '森林翡翠', '天蓝石', '曙光猫眼石',
        '血石', '茶晶石', '太阳水晶', '黑玉', '玉髓石', '暗影水晶' }

    local totalOther = 0
    for _, itemName in ipairs(list) do
        totalOther = totalOther + XAPI.MineJewRateSmall[itemName] * getPrice(itemName)
    end

    return math.floor(minePrice - totalOther)
end

onUpdate = function()
    XInfo.reloadBag()
    if mode == 'mine' then
        if XInfo.getBagItemCount('萨隆邪铁矿石') < 20 and XInfo.getMailItemCount('萨隆邪铁矿石') > 0 then
            XUtils.receiveMail('萨隆邪铁矿石')
            return
        end

        for _, itemName in ipairs(XInfo.materialList) do
            if XInfo.getBagItemCount(itemName) >= 60 then
                XUtils.sendMail(itemName, 3, true)
                return
            end
        end
    elseif mode == 'rubbish' then
        for _, item in ipairs(XRubbishList) do
            if XInfo.getBagItemCount(item['itemname']) >= 5 then
                XUtils.sendMail(item['itemname'], 5, true)
                return
            end
            if XInfo.getBagItemCount('完美' .. item['itemname']) >= 5 then
                XUtils.sendMail('完美' .. item['itemname'], 5, true)
                return
            end
        end
        for _, item in ipairs(XRubbishList) do
            local reagents = XInfo.getReagentList(item['itemname'])
            for _, reagent in ipairs(reagents) do
                if XInfo.getBagItemCount(reagent['itemname']) < 20 and XInfo.getMailItemCount(reagent['itemname']) > 0 then
                    XUtils.receiveMail(reagent['itemname'])
                    return
                end
            end
        end
        -- TODO 永恒之土特殊处理
        if XInfo.getBagItemCount('永恒之土') <= 0 and XInfo.getBagItemCount('土之结晶') < 10 and XInfo.getMailItemCount('永恒之土') > 0 then
            XUtils.receiveMail('永恒之土')
            return
        end
    end
    XUtils.shrinkBag()
    XUtils.sortJewsInBag()
end

-- Events
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XJewTool.registerRefreshCallback(moduleName, refreshUI)
XJewTool.registerUpdateCallback(moduleName, onUpdate)

XJewTool.registerEventCallback(moduleName, 'UNIT_SPELLCAST_SUCCEEDED', function(self, event, unit, castId, spellId)
    if unit ~= 'player' then return end
    if spellId ~= XAPI.Spell_Mine then return end

    successCount = successCount + 1
    refreshUI()
end)

XJewTool.registerEventCallback(moduleName, 'CHAT_MSG_LOOT', function(self, event, msg)
    local itemLink = msg:match("你获得了物品：(.+)。")
    local itemName = XAPI.GetItemInfo(itemLink)
    xdebug.info(msg)
    xdebug.info(itemName)
    if itemName then
        addItem(itemName)
    end
    refreshUI()
end)

-- Commands
SlashCmdList['XMINECENTER'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XMINECENTER1 = '/xminecenter'

SlashCmdList['XMINECENTERSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XMINECENTERSHOW1 = '/xminecenter_show'

SlashCmdList['XMINECENTERHIDE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XMINECENTERHIDE1 = '/xminecenter_hide'
