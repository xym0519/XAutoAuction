XAuctionCenter = {}
local moduleName = 'XAuctionCenter'

-- Variable definition
local mainFrame = nil
local scrollView = nil
local materialFrames = {}

local dft_minPrice = 9999999
local dft_maxPrice = 2180000
local dft_basePriceRate = 1.5
local dft_taskInterval = 0.9
local dft_taskTimeout = 30
local dft_filterList = { '全部', '星星', '优质', '可售', '有效', '潜力', '价低', '无效', '垃圾', '不做', '邮寄', '收件', '量大' }
local dft_deltaPrice = 10
local dft_postdelay = 2
local dft_oldInterval = 1800
local dft_maxCraftCount = 20
local dft_materialTaskInterval = 30

local dft_buttonWidth = 45
local dft_buttonGap = 1
local dft_sectionGap = 10

local displayList = {}

local isStarted = false
local taskList = {}
local curTask = nil
local lastTaskFinishTime = 0

local queryIndex = 1
local starQueryIndex = 1
local queryStarFlag = true

local materialList = {}
local lastMaterialTaskTime = time()
local materialQueryIndex = 1

local cleaningItems = {}

-- Function definition
local initData
local resetData
local initUI
local filterDisplayList
local refreshUI

local start
local stop
local finishTask
local startNextTask
local addItem
local resetItem
local resetItemByName
local getItem
local addQueryTaskByIndex
local addQueryTaskByItemName
local addMaterialQueryTaskByItemName
local getNextQueryTask

local checkImportant
local checkImportantByName

local addCraftQueue
local cleanLower
local cleanShort
local puton
local putonNoPrice
local putonOld
local printList
local printItemsByName
local setPriceByName
local getMyValidCount

local addClick
local checkRecipeClick
local priceAdjustClick

local itemSortClick
local itemMailClick
local itemReceiveClick
local itemToBankClick
local itemToBagClick
local itemNameClick
local itemDeleteClick
local itemRubbishClick
local itemSettingClick
local itemEnableClick
local itemStarClick
local itemCanCraftClick
local itemRefreshClick
local itemCleanClick

local processQueryTask
local processMaterialQueryTask

-- Function implemention
initData = function()
    materialList = {}
    for _, itemName in ipairs(XInfo.materialListS) do
        table.insert(materialList, { itemname = itemName, price = dft_minPrice })
    end
end

resetData = function()
    for _, item in ipairs(XAutoAuctionList) do
        resetItem(item)
    end
    isStarted = false
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0

    queryIndex = 1
    starQueryIndex = 1
    queryStarFlag = true

    materialQueryIndex = 1
    lastMaterialTaskTime = time()
end

initUI = function()
    mainFrame = XUI.createFrame('XAuctionCenterMainFrame', 1260, 500)
    mainFrame:SetFrameStrata('HIGH')
    mainFrame.title:SetText('自动拍卖')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local auctionBoardButton = XUI.createButton(mainFrame, dft_buttonWidth, '面板')
    auctionBoardButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -30, 0)
    auctionBoardButton:SetScript('OnClick', XAuctionBoard.toggle)

    local craftQueueButton = XUI.createButton(mainFrame, dft_buttonWidth, '制造')
    craftQueueButton:SetPoint('RIGHT', auctionBoardButton, 'LEFT', -3, 0)
    craftQueueButton:SetScript('OnClick', XCraftQueue.toggle)
    mainFrame.craftQueueButton = craftQueueButton

    local jewCountButton = XUI.createButton(mainFrame, dft_buttonWidth, '材料')
    jewCountButton:SetPoint('RIGHT', craftQueueButton, 'LEFT', -3, 0)
    jewCountButton:SetScript('OnClick', XJewCount.toggle)

    local autoSpeakButton = XUI.createButton(mainFrame, dft_buttonWidth, XUI.Red .. '喊话')
    autoSpeakButton:SetPoint('RIGHT', jewCountButton, 'LEFT', -3, 0)
    autoSpeakButton:SetScript('OnClick', XAutoSpeak.toggle)
    mainFrame.autoSpeakButton = autoSpeakButton

    local startButton = XUI.createButton(mainFrame, dft_buttonWidth, '开始')
    startButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    startButton:SetScript('OnClick', function()
        if isStarted then
            stop()
        else
            start()
        end
    end)
    mainFrame.startButton = startButton

    local resetButton = XUI.createButton(mainFrame, dft_buttonWidth, '重置')
    resetButton:SetPoint('LEFT', startButton, 'RIGHT', dft_buttonGap, 0)
    resetButton:SetScript('OnClick', function()
        XUIConfirmDialog.show(moduleName, '确认', '是否确认重置所有数据', function()
            resetData()
            refreshUI()
        end)
    end)

    local putonButton = XUI.createButton(mainFrame, dft_buttonWidth, '上架')
    putonButton:SetPoint('LEFT', resetButton, 'RIGHT', dft_sectionGap, 0)
    putonButton:SetScript('OnClick', function()
        local count = puton()
        xdebug.info('PutOn: ' .. count)
    end)

    local putonNoPriceButton = XUI.createButton(mainFrame, dft_buttonWidth, '无价')
    putonNoPriceButton:SetPoint('LEFT', putonButton, 'RIGHT', dft_buttonGap, 0)
    putonNoPriceButton:SetScript('OnClick', function()
        local count = putonNoPrice()
        xdebug.info('PutOn: ' .. count)
    end)

    local putonOldButton = XUI.createButton(mainFrame, dft_buttonWidth, '未刷')
    putonOldButton:SetPoint('LEFT', putonNoPriceButton, 'RIGHT', dft_buttonGap, 0)
    putonOldButton:SetScript('OnClick', function()
        local count = putonOld()
        xdebug.info('PutOn: ' .. count)
    end)

    local craftAllButton = XUI.createButton(mainFrame, dft_buttonWidth, '制造')
    craftAllButton:SetPoint('LEFT', putonOldButton, 'RIGHT', dft_buttonGap, 0)
    craftAllButton:SetScript('OnClick', function()
        local count = addCraftQueue()
        xdebug.info('Craft: ' .. count)
    end)

    local cleanLowerButton = XUI.createButton(mainFrame, dft_buttonWidth, '清理')
    cleanLowerButton:SetPoint('LEFT', craftAllButton, 'RIGHT', dft_buttonGap, 0)
    cleanLowerButton:SetScript('OnClick', function()
        cleanLower()
    end)

    local cleanShortButton = XUI.createButton(mainFrame, dft_buttonWidth, '短期')
    cleanShortButton:SetPoint('LEFT', cleanLowerButton, 'RIGHT', dft_buttonGap, 0)
    cleanShortButton:SetScript('OnClick', function()
        cleanShort()
    end)

    local allToBankButton = XUI.createButton(mainFrame, dft_buttonWidth, '全存')
    allToBankButton:SetPoint('LEFT', cleanShortButton, 'RIGHT', dft_sectionGap, 0)
    allToBankButton:SetScript('OnClick', function()
        XUtils.moveToBank(nil, nil, nil, false)
        cleanShort()
    end)

    local allToBagButton = XUI.createButton(mainFrame, dft_buttonWidth, '全取')
    allToBagButton:SetPoint('LEFT', allToBankButton, 'RIGHT', dft_buttonGap, 0)
    allToBagButton:SetScript('OnClick', function()
        local itemNames = {}
        for _, item in ipairs(XAutoAuctionList) do
            table.insert(itemNames, item['itemname'])
        end
        XUtils.moveToBag(itemNames, nil, nil, false)
        cleanShort()
    end)

    local refreshButton = XUI.createButton(mainFrame, dft_buttonWidth, '刷新')
    refreshButton:SetPoint('LEFT', allToBagButton, 'RIGHT', dft_sectionGap, 0)
    refreshButton:SetScript('OnClick', function()
        XAutoAuction.refreshUI()
    end)

    local printButton = XUI.createButton(mainFrame, dft_buttonWidth, '打印')
    printButton:SetPoint('LEFT', refreshButton, 'RIGHT', dft_buttonGap, 0)
    printButton:SetScript('OnClick', function()
        printList()
    end)

    local hintLabel = XUI.createLabel(mainFrame, 290, '')
    hintLabel:SetPoint('LEFT', printButton, 'RIGHT', 5, 0)
    mainFrame.hintLabel = hintLabel

    local filter1Button = XUI.createButton(mainFrame, dft_buttonWidth, '优质')
    filter1Button:SetPoint('TOPLEFT', startButton, 'BottomLeft', 0, 0)
    filter1Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '优质')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        refreshUI()
    end)

    local filter2Button = XUI.createButton(mainFrame, dft_buttonWidth, '量大')
    filter2Button:SetPoint('LEFT', filter1Button, 'RIGHT', dft_buttonGap, 0)
    filter2Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '量大')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        refreshUI()
    end)

    local filter3Button = XUI.createButton(mainFrame, dft_buttonWidth, '邮寄')
    filter3Button:SetPoint('LEFT', filter2Button, 'RIGHT', dft_buttonGap, 0)
    filter3Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '邮寄')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        refreshUI()
    end)

    local filter4Button = XUI.createButton(mainFrame, dft_buttonWidth, '收件')
    filter4Button:SetPoint('LEFT', filter3Button, 'RIGHT', dft_buttonGap, 0)
    filter4Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '收件')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        refreshUI()
    end)

    local filterDropDown = XUI.createDropDown(mainFrame, 80, dft_filterList, '优质',
        function(value)
            filterDisplayList()
            refreshUI()
        end)
    filterDropDown:SetPoint('LEFT', filter4Button, 'RIGHT', -15, 0)
    mainFrame.filterDropDown = filterDropDown

    local filterBox = XUI.createEditbox(mainFrame, 90)
    filterBox:SetPoint('LEFT', filterDropDown, 'RIGHT', -5, 0)
    filterBox:SetScript('OnEnterPressed', function(self)
        self:ClearFocus();
        filterDisplayList()
        refreshUI()
    end)
    filterBox:SetScript('OnEscapePressed', function(self)
        self:SetText('')
        self:ClearFocus();
        filterDisplayList()
        refreshUI()
    end)
    mainFrame.filterBox = filterBox

    local addButton = XUI.createButton(mainFrame, dft_buttonWidth, '添加')
    addButton:SetPoint('LEFT', filterBox, 'RIGHT', dft_sectionGap, 0)
    addButton:SetScript('OnClick', addClick)

    local checkRecipeButton = XUI.createButton(mainFrame, dft_buttonWidth, '配方')
    checkRecipeButton:SetPoint('LEFT', addButton, 'RIGHT', dft_buttonGap, 0)
    checkRecipeButton:SetScript('OnClick', checkRecipeClick)

    local priceAdjustButton = XUI.createButton(mainFrame, dft_buttonWidth, '调价')
    priceAdjustButton:SetPoint('LEFT', checkRecipeButton, 'RIGHT', dft_buttonGap, 0)
    priceAdjustButton:SetScript('OnClick', priceAdjustClick)

    local preFrame = priceAdjustButton
    for _, item in ipairs(materialList) do
        local materialItemFrame = XAPI.CreateFrame('Frame', nil, mainFrame)
        materialItemFrame:SetSize(63, 30)
        if preFrame == priceAdjustButton then
            materialItemFrame:SetPoint('LEFT', preFrame, 'RIGHT', dft_sectionGap, 0)
        else
            materialItemFrame:SetPoint('LEFT', preFrame, 'RIGHT', 3, 0)
        end
        materialItemFrame.itemName = item['itemname']

        local icon = XUI.createItemIcon(materialItemFrame, 25, 25, item['itemname'])
        icon:SetPoint('LEFT', materialItemFrame, 'LEFT', 0, 0)

        local countLabel = XUI.createLabel(materialItemFrame, 30, '', 'LEFT')
        countLabel:SetPoint('LEFT', icon, 'RIGHT', 3, 0)

        materialItemFrame:SetScript("OnEnter", function(self)
            local itemid = XInfo.getItemId(self.itemName)
            if itemid > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. itemid) -- 显示物品信息
            end
        end)
        materialItemFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        materialItemFrame:SetScript('OnMouseDown', function(self)
            if IsLeftShiftKeyDown() then
                addMaterialQueryTaskByItemName(self.itemName)
                refreshUI()
            elseif IsLeftControlKeyDown() then
                XInfo.printBuyHistory(self.itemName)
            end
        end)

        materialFrames[item['itemname']] = countLabel

        preFrame = materialItemFrame
    end

    local labelFrame = XAPI.CreateFrame('Frame', nil, mainFrame)
    labelFrame:SetSize(mainFrame:GetWidth() - 20, 30)
    labelFrame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 10, -90)

    local indexLabel = XUI.createLabel(labelFrame, 35, '序号', 'CENTER')
    indexLabel:SetPoint('LEFT', labelFrame, 'LEFT', 8, 0)

    local nameLabel = XUI.createLabel(labelFrame, 155, '名称', 'CENTER')
    nameLabel:SetPoint('LEFT', indexLabel, 'RIGHT', 150, 0)

    local timeLabel = XUI.createLabel(labelFrame, 50, '时间', 'CENTER')
    timeLabel:SetPoint('LEFT', nameLabel, 'RIGHT', 3, 0)

    local bagLabel = XUI.createLabel(labelFrame, 110, '包/邮/银/堆', 'CENTER')
    bagLabel:SetPoint('LEFT', timeLabel, 'RIGHT', 3, 0)

    local auctionLabel = XUI.createLabel(labelFrame, 155, '卖/我/低/底', 'CENTER')
    auctionLabel:SetPoint('LEFT', bagLabel, 'RIGHT', 3, 0)

    local dealLabel = XUI.createLabel(labelFrame, 90, '率/次', 'CENTER')
    dealLabel:SetPoint('LEFT', auctionLabel, 'RIGHT', 3, 0)

    local priceLabel = XUI.createLabel(labelFrame, 150, '现/上/高/基', 'CENTER')
    priceLabel:SetPoint('LEFT', dealLabel, 'RIGHT', 3, 0)

    scrollView = XUI.createScrollView(mainFrame, mainFrame:GetWidth() - 20,
        mainFrame:GetHeight() - labelFrame:GetHeight() - 100)
    scrollView:SetPoint('TOPLEFT', labelFrame, 'BottomLeft', 0, 0)

    refreshUI()
end

filterDisplayList = function()
    if not mainFrame then return end
    if not scrollView then return end

    local filterWord = mainFrame.filterBox:GetText();
    local displayFilter = XAPI.UIDropDownMenu_GetText(mainFrame.filterDropDown)
    local dataList = {}
    for i, item in ipairs(XAutoAuctionList) do
        item.index = i
        local itemName = item['itemname']
        local enabled = item['enabled']
        if enabled == nil then enabled = false end
        local star = item['star']
        if star == nil then star = false end
        local canCraft = item['cancraft']
        if canCraft == nil then canCraft = true end
        local minPriceOther = item['minpriceother']
        local basePrice = item['baseprice']
        local stackCount = item['stackcount']
        local materialBuyPrice = XAutoBuy.getItemField(itemName, 'price', 0)
        local bagCount = XInfo.getBagItemCount(itemName)
        local mailCount = XInfo.getMailItemCount(itemName)
        local auctionCount = XInfo.getAuctionItemCount(itemName)
        local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)
        local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
        local important = checkImportant(item)

        local disFlag = false
        if displayFilter == '全部' then
            disFlag = true
        elseif displayFilter == '可售' then
            if enabled then
                if star or minPriceOther >= basePrice then
                    disFlag = true
                end
            end
        elseif displayFilter == '优质' then
            if enabled then
                if star or important then
                    disFlag = true
                end
            end
        elseif displayFilter == '价低' then
            if enabled then
                if minPriceOther <= materialBuyPrice then
                    disFlag = true
                end
            end
        elseif displayFilter == '有效' then
            if enabled then
                disFlag = true
            end
        elseif displayFilter == '无效' then
            if not enabled then
                disFlag = true
            end
        elseif displayFilter == '星星' then
            if enabled and star then
                disFlag = true
            end
        elseif displayFilter == '量大' then
            if auctionCount >= 10 then
                disFlag = true
            end
        elseif displayFilter == '邮寄' then
            if bagCount > 5 then
                disFlag = true
            end
        elseif displayFilter == '收件' then
            if mailCount > 0 then
                disFlag = true
            end
        elseif displayFilter == '垃圾' then
            if enabled then
                if dealRate > 5 and dealCount < 6 then
                    disFlag = true
                end
            end
        elseif displayFilter == '不做' then
            if not canCraft then
                disFlag = true
            end
        elseif displayFilter == '潜力' then
            if (not important) and (dealCount / 3 / stackCount >= 10) then
                disFlag = true
            end
        end

        if filterWord ~= '' and (not XUtils.stringContains(itemName, filterWord)) then
            disFlag = false
        end

        if disFlag then table.insert(dataList, item) end
    end
    displayList = dataList;

    scrollView:ClearContents()
    for _, item in ipairs(dataList) do
        local frame = scrollView:CreateFrame(mainFrame:GetWidth() - 20, 30)
        frame.index = item['index']
        frame:SetScript('OnEnter', function(self)
            self.bg:Show()
        end)
        frame:SetScript('OnLeave', function(self)
            self.bg:Hide()
        end)
        local frameBG = frame:CreateTexture(nil, 'BACKGROUND')
        frameBG:SetAllPoints(frame)
        frameBG:SetColorTexture(1, 1, 1, 0.2)
        frameBG:Hide()
        frame.bg = frameBG

        local itemIndexButton = XUI.createButton(frame, 35, '999')
        itemIndexButton:SetPoint('LEFT', frame, 'LEFT', 0, 0)
        itemIndexButton:SetScript('OnClick', itemSortClick)
        frame.itemIndexButton = itemIndexButton
        itemIndexButton.frame = frame

        local itemMailButton = XUI.createButton(frame, 30, 'U')
        itemMailButton:SetPoint('LEFT', itemIndexButton, 'RIGHT', 0, 0)
        itemMailButton:SetScript('OnClick', itemMailClick)
        frame.itemMailButton = itemMailButton
        itemMailButton.frame = frame

        local itemReceiveButton = XUI.createButton(frame, 30, 'R')
        itemReceiveButton:SetPoint('LEFT', itemMailButton, 'RIGHT', 0, 0)
        itemReceiveButton:SetScript('OnClick', itemReceiveClick)
        frame.itemReceiveButton = itemReceiveButton
        itemReceiveButton.frame = frame

        local itemToBankButton = XUI.createButton(frame, 30, 'O')
        itemToBankButton:SetPoint('LEFT', itemReceiveButton, 'RIGHT', 0, 0)
        itemToBankButton:SetScript('OnClick', itemToBankClick)
        frame.itemToBankButton = itemToBankButton
        itemToBankButton.frame = frame

        local itemToBagButton = XUI.createButton(frame, 30, 'I')
        itemToBagButton:SetPoint('LEFT', itemToBankButton, 'RIGHT', 0, 0)
        itemToBagButton:SetScript('OnClick', itemToBagClick)
        frame.itemToBagButton = itemToBagButton
        itemToBagButton.frame = frame

        local icon = XUI.createIcon(frame, 25, 25)
        icon:SetPoint('LEFT', itemToBagButton, 'RIGHT', 3, 0)
        frame.icon = icon

        local itemNameButton = XUI.createButton(frame, 160, '')
        itemNameButton:SetPoint('LEFT', icon, 'RIGHT', 2, 0)
        itemNameButton:SetScript('OnClick', itemNameClick)
        itemNameButton:SetScript("OnEnter", function(self)
            local tindex = self.frame.index
            local titem = XAutoAuctionList[tindex];
            if not titem then return end
            local itemid = XInfo.getItemId(titem['itemname'])
            if itemid > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. itemid) -- 显示物品信息
            end
        end)
        itemNameButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        frame.itemNameButton = itemNameButton
        itemNameButton.frame = frame

        local labelTime = XUI.createLabel(frame, 50, '', 'CENTER')
        labelTime:SetPoint('LEFT', itemNameButton, 'RIGHT', 3, 0)
        frame.labelTime = labelTime

        local labelBag = XUI.createLabel(frame, 110, '', 'CENTER')
        labelBag:SetPoint('LEFT', labelTime, 'RIGHT', 3, 0)
        frame.labelBag = labelBag
        labelBag.frame = frame

        local labelAuction = XUI.createLabel(frame, 155, '', 'CENTER')
        labelAuction:SetPoint('LEFT', labelBag, 'RIGHT', 3, 0)
        frame.labelAuction = labelAuction
        labelAuction.frame = frame

        local labelDeal = XUI.createLabel(frame, 90, '', 'CENTER')
        labelDeal:SetPoint('LEFT', labelAuction, 'RIGHT', 3, 0)
        frame.labelDeal = labelDeal
        labelDeal.frame = frame

        local labelPrice = XUI.createLabel(frame, 200, '', 'CENTER')
        labelPrice:SetPoint('LEFT', labelDeal, 'RIGHT', 3, 0)
        frame.labelPrice = labelPrice
        labelPrice.frame = frame

        local deleteButton = XUI.createButton(frame, 30, '删')
        deleteButton:SetPoint('LEFT', labelPrice, 'RIGHT', 0, 0)
        deleteButton:SetScript('OnClick', itemDeleteClick)
        deleteButton.frame = frame

        local rubbishButton = XUI.createButton(frame, 30, '圾')
        rubbishButton:SetPoint('LEFT', deleteButton, 'RIGHT', 0, 0)
        rubbishButton:SetScript('OnClick', itemRubbishClick)
        rubbishButton.frame = frame

        local settingButton = XUI.createButton(frame, 30, '设')
        settingButton:SetPoint('LEFT', rubbishButton, 'RIGHT', 0, 0)
        settingButton:SetScript('OnClick', itemSettingClick)
        settingButton.frame = frame

        local enableButton = XUI.createButton(frame, 30, '')
        enableButton:SetPoint('LEFT', settingButton, 'RIGHT', 0, 0)
        enableButton:SetScript('OnClick', itemEnableClick)
        frame.enableButton = enableButton
        enableButton.frame = frame

        local starButton = XUI.createButton(frame, 30, '星')
        starButton:SetPoint('LEFT', enableButton, 'RIGHT', 0, 0)
        starButton:SetScript('OnClick', itemStarClick)
        frame.starButton = starButton
        starButton.frame = frame

        local itemCanCraftButton = XUI.createButton(frame, 30, '造')
        itemCanCraftButton:SetPoint('LEFT', starButton, 'RIGHT', 0, 0)
        itemCanCraftButton:SetScript('OnClick', itemCanCraftClick)
        frame.itemCanCraftButton = itemCanCraftButton
        itemCanCraftButton.frame = frame

        local itemRefreshButton = XUI.createButton(frame, 30, '刷')
        itemRefreshButton:SetPoint('LEFT', itemCanCraftButton, 'RIGHT', 0, 0)
        itemRefreshButton:SetScript('OnClick', itemRefreshClick)
        itemRefreshButton.frame = frame

        local itemCleanButton = XUI.createButton(frame, 30, '清')
        itemCleanButton:SetPoint('LEFT', itemRefreshButton, 'RIGHT', 0, 0)
        itemCleanButton:SetScript('OnClick', itemCleanClick)
        itemCleanButton.frame = frame
    end
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end
    if not scrollView then return end

    XInfo.reloadBag()
    XInfo.reloadAuction()

    if isStarted then
        mainFrame.startButton:SetText('停止')
    else
        mainFrame.startButton:SetText('开始')
    end

    if XAutoSpeak.isRunning() then
        mainFrame.autoSpeakButton:SetText(XUI.Green .. '喊话')
    else
        mainFrame.autoSpeakButton:SetText(XUI.Red .. '喊话')
    end

    if XCraftQueue.isRunning() then
        mainFrame.craftQueueButton:SetText(XUI.Green .. '制造')
    else
        mainFrame.craftQueueButton:SetText(XUI.Red .. '制造')
    end

    local labelText = format('%s) ', #taskList)
    if not curTask then
        labelText = labelText .. '等待'
    else
        if curTask['action'] == 'query' then
            if curTask['status'] == nil or XUtils.inArray(curTask['status'], { 'querying', 'loaded' }) then
                labelText = labelText .. format('查询: [%s]%s', curTask['index'], curTask['itemname'])
            else
                labelText = labelText .. '拍卖: ' .. curTask['itemname']
            end
        elseif curTask['action'] == 'material' then
            labelText = labelText .. format('查询: %s', curTask['itemname'])
        end
    end
    mainFrame.hintLabel:SetText(labelText)

    mainFrame.title:SetText('自动拍卖'
        .. '    出售中: ' .. XInfo.auctioningCount
        .. '    已出售: ' .. XInfo.auctionedCount
        .. '    待收款: ' .. (XUtils.round(XInfo.auctionedMoney / 10000))
        .. '    背包: ' .. XInfo.emptyBagCount)

    for idx, item in ipairs(displayList) do
        local frame = scrollView:GetItemFrame(idx)
        local itemName = item['itemname']
        local itemId = XInfo.getItemId(itemName)
        local enabled = item['enabled']
        if enabled == nil then enabled = false end
        local star = item['star']
        if star == nil then star = false end
        local canCraft = item['cancraft']
        if canCraft == nil then canCraft = false end
        local basePrice = item['baseprice']
        local minPriceOther = item['minpriceother']
        local maxPriceOther = item['maxpriceother']
        local lastPriceOther = item['lastpriceother']
        local stackCount = item['stackcount']
        local lowerCount = item['lowercount']
        local priceLowerCount = item['pricelowercount']

        local bagCount = XInfo.getBagItemCount(itemName)
        local bankCount = XInfo.getBankItemCount(itemName)
        local mailCount = XInfo.getMailItemCount(itemName)

        local auctionCount = XInfo.getAuctionItemCount(itemName)
        local validCount = getMyValidCount(itemName)

        local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
        local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)

        local recipe = XInfo.getTradeSkillItem(itemName)

        local itemNameStr = string.sub(itemName, 1, 18);
        if not enabled then
            itemNameStr = XUI.Gray .. itemNameStr
        elseif minPriceOther < basePrice then
            itemNameStr = XUI.Red .. itemNameStr
        elseif validCount <= 0 then
            itemNameStr = XUI.Purple .. itemNameStr
        elseif validCount < stackCount then
            itemNameStr = XUI.Yellow .. itemNameStr
        elseif validCount == stackCount then
            itemNameStr = XUI.Green .. itemNameStr
        else
            itemNameStr = XUI.Cyan .. itemNameStr
        end

        if star then
            itemNameStr = XUI.Green .. '*' .. itemNameStr
        end

        if not recipe then
            itemNameStr = itemNameStr .. XUI.Red .. '■'
        end

        local updateTimeStr = XUtils.formatTime(item['updatetime'])

        local bagCountStr = 'B' .. bagCount;
        if bagCount > 10 then
            bagCountStr = XUI.Purple .. bagCountStr
        elseif bagCount > 5 then
            bagCountStr = XUI.Yellow .. bagCountStr
        elseif bagCount > 0 then
            bagCountStr = XUI.Green .. bagCountStr
        else
            bagCountStr = XUI.Red .. bagCountStr
        end

        local mailCountStr = '' .. mailCount;
        if mailCount > 20 then
            mailCountStr = XUI.Purple .. mailCountStr
        elseif mailCount > 10 then
            mailCountStr = XUI.Red .. mailCountStr
        elseif mailCount > 5 then
            mailCountStr = XUI.Yellow .. mailCountStr
        else
            mailCountStr = XUI.Green .. mailCountStr
        end

        local bankCountStr = '' .. bankCount;
        if bankCount > 200 then
            bankCountStr = XUI.Cyan .. bankCountStr
        elseif bankCount > 100 then
            bankCountStr = XUI.Green .. bankCountStr
        elseif bankCount > 40 then
            bankCountStr = XUI.Yellow .. bankCountStr
        else
            bankCountStr = XUI.Red .. bankCountStr
        end

        local auctionCountStr = XUI.getColor_AuctionStackCount(auctionCount, stackCount) ..
            'A' .. auctionCount

        local validCountStr = 'M' .. validCount
        if validCount > stackCount then
            validCountStr = XUI.Cyan .. validCountStr
        elseif validCount == stackCount then
            validCountStr = XUI.Green .. validCountStr
        elseif validCount > 0 then
            validCountStr = XUI.Yellow .. validCountStr
        else
            validCountStr = XUI.Red .. validCountStr
        end

        local lowerCountStr = 'L' .. lowerCount
        if lowerCount > 5 then
            lowerCountStr = XUI.Red .. lowerCountStr
        elseif lowerCount > 0 then
            lowerCountStr = XUI.Yellow .. lowerCountStr
        else
            lowerCountStr = XUI.White .. lowerCountStr
        end

        local priceLowerCountStr = 'P' .. priceLowerCount
        if priceLowerCount > 10 then
            priceLowerCountStr = XUI.Red .. priceLowerCountStr
        elseif priceLowerCount > 0 then
            priceLowerCountStr = XUI.Yellow .. priceLowerCountStr
        else
            priceLowerCountStr = XUI.White .. priceLowerCountStr
        end

        local stackCountStr = 'S' .. stackCount
        if stackCount > 4 then
            stackCountStr = XUI.Purple .. stackCountStr
        elseif stackCount > 3 then
            stackCountStr = XUI.Red .. stackCountStr
        elseif stackCount > 2 then
            stackCountStr = XUI.Cyan .. stackCountStr
        elseif stackCount > 1 then
            stackCountStr = XUI.Green .. stackCountStr
        end

        local minPriceOtherStr = XUtils.priceToString(minPriceOther)
        if minPriceOther < basePrice then
            minPriceOtherStr = XUI.Red .. minPriceOtherStr
        elseif minPriceOther < basePrice * dft_basePriceRate then
            minPriceOtherStr = XUI.Yellow .. minPriceOtherStr
        elseif minPriceOther < basePrice * dft_basePriceRate * dft_basePriceRate then
            minPriceOtherStr = XUI.Green .. minPriceOtherStr
        else
            minPriceOtherStr = XUI.Cyan .. minPriceOtherStr
        end

        local maxPriceOtherStr = XUtils.priceToString(maxPriceOther)
        if maxPriceOther > minPriceOther * 1.3 then
            maxPriceOtherStr = XUI.Color_Great .. maxPriceOtherStr
        elseif maxPriceOther > minPriceOther * 1.1 then
            maxPriceOtherStr = XUI.Color_Good .. maxPriceOtherStr
        end

        local basePriceStr = XUI.White .. XUtils.priceToString(basePrice)
        local lastPriceOtherStr = XUI.White .. XUtils.priceToString(lastPriceOther)

        local dealRateStr = XUI.getColor_DealRate(dealRate) .. 'R' .. XUtils.round(dealRate)
        local dealCountStr = XUI.getColor_DealCount(dealCount) .. 'D' .. dealCount

        frame.itemIndexButton:SetText(idx)
        frame.icon:SetTexture(XAPI.GetItemIcon(itemId))
        frame.itemNameButton:SetText(itemNameStr)

        frame.labelTime:SetText(updateTimeStr)
        frame.labelBag:SetText(bagCountStr .. XUI.White .. ' / ' .. mailCountStr .. ' / ' .. bankCountStr
            .. XUI.White .. ' / ' .. stackCountStr)
        frame.labelAuction:SetText(auctionCountStr .. XUI.White .. ' / ' .. validCountStr
            .. XUI.White .. ' / ' .. priceLowerCountStr .. ' / ' .. lowerCountStr .. XUI.White)
        frame.labelDeal:SetText(dealRateStr .. XUI.White .. ' / ' .. dealCountStr)
        frame.labelPrice:SetText(minPriceOtherStr
            .. XUI.White .. ' / ' .. lastPriceOtherStr
            .. XUI.White .. ' / ' .. maxPriceOtherStr .. ' / ' .. basePriceStr)

        if enabled then
            frame.enableButton:SetText(XUI.Green .. '起')
        else
            frame.enableButton:SetText(XUI.Red .. '停')
        end

        if star then
            frame.starButton:SetText(XUI.Green .. '星')
        else
            frame.starButton:SetText(XUI.Red .. '星')
        end

        if canCraft then
            frame.itemCanCraftButton:SetText(XUI.Green .. '造')
        else
            frame.itemCanCraftButton:SetText(XUI.Red .. '禁')
        end
    end

    for _, item in ipairs(materialList) do
        local label = materialFrames[item['itemname']]
        if label then
            local tprice = item['price']
            if tprice > 1000000 then
                tprice = math.floor(tprice / 10000)
            else
                tprice = math.floor(tprice / 1000) / 10
            end
            label:SetText(tprice)
        end
    end
end

start = function()
    isStarted = true
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0
    refreshUI()
end

stop = function()
    if curTask and curTask['action'] == 'query' then
        local item = XAutoAuctionList[curTask['index']];
        resetItem(item)
    end
    isStarted = false
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0
    refreshUI()
end

finishTask = function()
    if curTask then
        if curTask['action'] == 'auction' then
            if curTask['location'] then
                if XAPI.C_Item_DoesItemExist(curTask['location']) then
                    XAPI.C_Item_UnlockItem(curTask['location'])
                end
            end
        end
    end
    curTask = nil
    lastTaskFinishTime = time()
end

startNextTask = function()
    if time() - lastTaskFinishTime < dft_taskInterval then return end
    if #taskList > 0 then
        curTask = taskList[1]
        table.remove(taskList, 1)
        curTask['starttime'] = time()

        if curTask['action'] == 'query' then
            processQueryTask(curTask)
        elseif curTask['action'] == 'material' then
            processMaterialQueryTask(curTask)
        end
        refreshUI()
        return
    end

    if lastMaterialTaskTime + dft_materialTaskInterval < time() then
        lastMaterialTaskTime = time()
        if #materialList > 0 then
            local item = materialList[materialQueryIndex]
            if item then
                addMaterialQueryTaskByItemName(item['itemname'])
                curTask = taskList[1]
                table.remove(taskList, 1)
                curTask['starttime'] = time()

                processMaterialQueryTask(curTask)
                refreshUI()
                materialQueryIndex = (materialQueryIndex % #materialList) + 1
                return
            end
        end
    end

    local task = getNextQueryTask()
    if task ~= nil then
        curTask = task
        curTask['starttime'] = time()
        refreshUI()
        processQueryTask(curTask)
    end
end

addItem = function(itemName, basePrice, defaultPrice, stackCount)
    if getItem(itemName) then return end

    local item = {
        itemname = itemName,
        baseprice = basePrice,
        defaultprice = defaultPrice,
        stackcount = stackCount,
        cancraft = true,

        myvalidlist = {},
        lowercount = 0,
        pricelowcount = 0,
        minpriceother = dft_minPrice,
        maxpriceother = 0,
        lastpriceother = 0,
    }
    resetItem(item)
    table.insert(XAutoAuctionList, item)
    refreshUI()
end

resetItem = function(item, keepUpdateTime)
    item['myvalidlist'] = {}
    item['lowercount'] = 0
    item['pricelowercount'] = 0
    if item['lastpriceother'] == nil then
        item['lastpriceother'] = 0
    end
    if item['minpriceother'] ~= dft_minPrice then
        item['lastpriceother'] = item['minpriceother']
    end
    item['minpriceother'] = dft_minPrice
    item['maxpriceother'] = 0
    if not keepUpdateTime then
        item['updatetime'] = 0
    end
end

resetItemByName = function(itemName)
    for _, item in ipairs(XAutoAuctionList) do
        if item['itemname'] == itemName then
            resetItem(item)
            return
        end
    end
end

getItem = function(itemName)
    for _, item in ipairs(XAutoAuctionList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

addQueryTaskByIndex = function(index, force)
    if force == nil then force = false end

    for idx, task in ipairs(taskList) do
        if task['action'] == 'query' and task['index'] == index then
            if force then
                table.remove(taskList, idx)
            else
                return
            end
        end
    end

    local item = XAutoAuctionList[index];
    if not item then return end

    local important = XAuctionCenter.checkImportantByName(item['itemname'])
    local dealCount = XInfo.getAuctionInfoField(item['itemname'], 'dealcount', 0)

    if force then
        resetItem(item)
        local task = {
            action = 'query',
            index = index,
            page = 1,
            timeout = dft_taskTimeout,
            important = important,
            dealcount = dealCount,
            itemname = item['itemname']
        }
        table.insert(taskList, 1, task)
        return
    end

    XInfo.reloadBag()
    local bagCount = XInfo.getBagItemCount(item['itemname'])
    if bagCount <= 0 then
        return
    end

    local idx = 0
    for _index, task in pairs(taskList) do
        if task['action'] == 'query' then
            if important then
                if task['important'] then
                    if task['dealcount'] < dealCount then
                        idx = _index
                        break
                    end
                else
                    idx = _index
                    break;
                end
            else
                if not task['important'] then
                    if task['dealcount'] < dealCount then
                        idx = _index
                        break
                    end
                end
            end
        end
    end
    resetItem(item)
    local task = {
        action = 'query',
        index = index,
        timeout = dft_taskTimeout,
        important = important,
        dealcount = dealCount,
        itemname = item['itemname']
    }
    if idx == 0 then
        table.insert(taskList, task)
    else
        table.insert(taskList, idx, task)
    end
end

addQueryTaskByItemName = function(itemName, force)
    for i, item in ipairs(XAutoAuctionList) do
        if item['itemname'] == itemName then
            addQueryTaskByIndex(i, force)
            return
        end
    end
end

addMaterialQueryTaskByItemName = function(itemName)
    local task = {
        action = 'material',
        itemname = itemName,
        starttime = time(),
        timeout = dft_taskTimeout
    }
    table.insert(taskList, 1, task)
end

getNextQueryTask = function()
    local nextTaskIndex = -1

    if queryStarFlag then
        for idx = 0, #XAutoAuctionList - 1 do
            local index = ((starQueryIndex + idx) % #XAutoAuctionList) + 1
            local item = XAutoAuctionList[index]
            if item ~= nil then
                if item['enabled'] and item['star'] then
                    starQueryIndex = index
                    nextTaskIndex = index
                    break
                end
            end
        end
        queryStarFlag = not queryStarFlag
    end

    if nextTaskIndex == -1 then
        for idx = 0, #XAutoAuctionList - 1 do
            local index = ((queryIndex + idx) % #XAutoAuctionList) + 1
            local item = XAutoAuctionList[index]
            if item ~= nil then
                if item['enabled'] and (not item['star']) then
                    queryIndex = index
                    nextTaskIndex = index
                    break
                end
            end
        end
        queryStarFlag = not queryStarFlag
    end

    if nextTaskIndex ~= -1 then
        local item = XAutoAuctionList[nextTaskIndex];
        if not item then return end

        local task = {
            action = 'query',
            index = nextTaskIndex,
            timeout = dft_taskTimeout,
            itemname = item['itemname']
        }
        return task
    end
end

checkImportant = function(item)
    local dealCount = XInfo.getAuctionInfoField(item['itemname'], 'dealcount', 0)
    if item['star'] or dealCount >= 30 * 3 then
        return true
    end
    return false
end

checkImportantByName = function(itemName)
    local item = getItem(itemName)
    if not item then return false end
    return checkImportant(item)
end

addCraftQueue = function()
    XInfo.reloadBag()
    XInfo.reloadAuction()
    local count = 0
    for idx, item in ipairs(XAutoAuctionList) do
        if item['enabled'] and item['cancraft'] then
            local inQuery = false
            if curTask and curTask['action'] == 'query' and curTask['index'] == idx then
                inQuery = true
            end
            if not inQuery then
                for _, task in ipairs(taskList) do
                    if task['action'] == 'query' and task['index'] == idx then
                        inQuery = true
                        break
                    end
                end
            end
            if not inQuery then
                if item['minpriceother'] >= item['baseprice'] then
                    local bagCount = XInfo.getBagItemCount(item['itemname'])
                    local auctionCount = XInfo.getAuctionItemCount(item['itemname'])
                    local itemTotalCount = XInfo.getItemTotalCount(item['itemname'])
                    local stackCount = item['stackcount']
                    local materialCount = XInfo.getMaterialBagCount(item['itemname'])

                    local subCount = 0
                    if checkImportant(item) then
                        subCount = stackCount - bagCount
                    else
                        subCount = stackCount - auctionCount - bagCount
                    end
                    -- if not item['star'] then
                    if subCount > dft_maxCraftCount - itemTotalCount then
                        subCount = dft_maxCraftCount - itemTotalCount
                    end
                    -- end
                    if subCount > materialCount then subCount = materialCount end
                    if subCount > 0 then
                        XCraftQueue.addItem(item['itemname'], subCount, 'fulfil')
                        count = count + 1
                    end
                end
            end
        end
    end
    refreshUI()
    return count
end

cleanLower = function(targetItemName)
    if not XAPI.IsAuctionFrameOpen() then
        cleaningItems = {}
        xdebug.warn('拍卖行未打开')
        return
    end
    local numItems = XAPI.GetNumAuctionItems('owner')

    XInfo.reloadAuction()

    XCraftQueue.stop()
    local targetIndex = -1
    local maxPrice = 0
    local minPriceOther = 0
    for i = numItems, 1, -1 do
        local res = { XAPI.GetAuctionItemInfo('owner', i) }
        local itemName = res[1]
        if (targetItemName and targetItemName == itemName) or (not targetItemName) then
            local stackCount = res[3]
            local buyoutPrice = res[10]
            local saleStatus = res[16]

            if saleStatus ~= 1 then
                for _, item in ipairs(XAutoAuctionList) do
                    if item['itemname'] == itemName then
                        if buyoutPrice / stackCount > item['minpriceother'] then
                            if targetItemName == nil then
                                if not checkImportant(item) then
                                    xdebug.info('清理低价：' .. item['itemname']
                                        .. '(' .. XUtils.priceToMoneyString(buyoutPrice / stackCount)
                                        .. '/' .. XUtils.priceToMoneyString(item['minpriceother']) .. ')')
                                    XAPI.CancelAuction(i)

                                    if not XUtils.inArray(item['itemname'], cleaningItems) then
                                        table.insert(cleaningItems, item['itemname'])
                                    end
                                    return
                                end
                            else
                                if buyoutPrice / stackCount > maxPrice then
                                    maxPrice = buyoutPrice / stackCount
                                    minPriceOther = item['minpriceother']
                                    targetIndex = i
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    if targetItemName then
        if targetIndex ~= -1 then
            xdebug.info('清理低价：' .. targetItemName
                .. '(' .. XUtils.priceToMoneyString(maxPrice)
                .. '/' .. XUtils.priceToMoneyString(minPriceOther) .. ')')
            XAPI.CancelAuction(targetIndex)

            if not XUtils.inArray(targetItemName, cleaningItems) then
                table.insert(cleaningItems, targetItemName)
            end
            return
        end
    end

    XInfo.reloadAuction()
    if not targetItemName then
        if #cleaningItems > 0 then
            for _, itemName in ipairs(cleaningItems) do
                resetItemByName(itemName)
            end
        end
        cleaningItems = {}
    end
    xdebug.warn('清理低价结束')
end

cleanShort = function()
    if not XAPI.IsAuctionFrameOpen() then
        cleaningItems = {}
        xdebug.warn('拍卖行未打开')
        return
    end
    local numItems = XAPI.GetNumAuctionItems('owner')

    XCraftQueue.stop()

    for i = numItems, 1, -1 do
        local res = { XAPI.GetAuctionItemInfo('owner', i) }
        local saleStatus = res[16]
        if saleStatus ~= 1 then
            local timeLeft = XAPI.GetAuctionItemTimeLeft('owner', i)
            local itemName = XAPI.GetAuctionItemInfo('owner', i);
            if timeLeft < 3 then
                XAPI.CancelAuction(i)

                for _, item in ipairs(XAutoAuctionList) do
                    if item['itemname'] == itemName then
                        resetItem(item)
                        xdebug.info('清理短期：' .. item['itemname'])
                        break
                    end
                end
                return
            end
        end
    end

    XInfo.reloadAuction()
    xdebug.warn('清理短期结束')
end

puton = function()
    XInfo.reloadBag()
    XInfo.reloadAuction()
    local count = 0
    local starQueue = {}
    local unStarQueue = {}
    for i, item in ipairs(XAutoAuctionList) do
        if item['enabled'] then
            local bagCount = XInfo.getBagItemCount(item['itemname'])
            local validCount = getMyValidCount(item['itemname'])
            local stackCount = item['stackcount']
            if item['minpriceother'] >= item['baseprice'] and bagCount > 0 and validCount < stackCount then
                if item['star'] then
                    table.insert(starQueue, i)
                else
                    table.insert(unStarQueue, i)
                end
                count = count + 1
            end
        end
    end
    for _, idx in ipairs(starQueue) do
        addQueryTaskByIndex(idx)
    end
    for _, idx in ipairs(unStarQueue) do
        addQueryTaskByIndex(idx)
    end
    refreshUI()
    return count
end

putonNoPrice = function()
    local count = 0
    local starQueue = {}
    local unStarQueue = {}
    for i, item in ipairs(XAutoAuctionList) do
        if item['enabled'] then
            if item['minpriceother'] == dft_minPrice then
                if item['star'] then
                    table.insert(starQueue, i)
                else
                    table.insert(unStarQueue, i)
                end
                count = count + 1
            end
        end
    end
    for _, idx in ipairs(starQueue) do
        addQueryTaskByIndex(idx)
    end
    for _, idx in ipairs(unStarQueue) do
        addQueryTaskByIndex(idx)
    end
    refreshUI()
    return count
end

putonOld = function()
    local count = 0
    local starQueue = {}
    local unStarQueue = {}
    for i, item in ipairs(XAutoAuctionList) do
        if item['enabled'] then
            if time() - item['updatetime'] > dft_oldInterval then
                if item['star'] then
                    table.insert(starQueue, i)
                else
                    table.insert(unStarQueue, i)
                end
                count = count + 1
            end
        end
    end
    for _, idx in ipairs(starQueue) do
        addQueryTaskByIndex(idx)
    end
    for _, idx in ipairs(unStarQueue) do
        addQueryTaskByIndex(idx)
    end
    refreshUI()
    return count
end

printList = function()
    XAutoAuction.refreshUI()
    xdebug.info('----------')
    if (not curTask) and #taskList <= 0 then
        xdebug.info('暂无任务')
        return
    end
    for i = #taskList, 1, -1 do
        local task = taskList[i]
        if task['action'] == 'query' then
            xdebug.info('[' .. i .. ']查询: ' .. XAutoAuctionList[task['index']]['itemname'])
        elseif task['action'] == 'material' then
            xdebug.info('[' .. i .. ']查询: ' .. task['itemname'])
        else
            xdebug.info('[' .. i .. ']不支持的任务类型')
        end
    end
    if curTask then
        if curTask['action'] == 'query' then
            xdebug.info('当前任务：查询: ' .. XAutoAuctionList[curTask['index']]['itemname'])
        elseif curTask['action'] == 'material' then
            xdebug.info('当前任务：查询: ' .. curTask['itemname'])
        else
            xdebug.info('当前任务：不支持的任务类型')
        end
    else
        xdebug.info('当前任务：无')
    end
    xdebug.info('total: ' .. #taskList)
end

printItemsByName = function(key)
    local all = false
    if XUtils.stringStartsWith(key, '*') then
        all = true
        key = string.gsub(key, '^%*', '')
    end
    xdebug.info('----------')
    for _, item in ipairs(XAutoAuctionList) do
        if XUtils.stringContains(item['itemname'], key) then
            if item['enabled'] ~= nil and item['enabled'] then
                if all or (not item['star']) then
                    xdebug.info(item['itemname'] .. ':  ' .. XUtils.priceToMoneyString(item['baseprice']))
                end
            end
        end
    end
end

setPriceByName = function(itemName, basePrice, profitRate, isDealRate, confirm)
    if profitRate == nil then profitRate = 0.2 end
    if isDealRate == nil then isDealRate = false end
    if confirm == nil then confirm = false end
    if itemName and basePrice then
        local all = false
        if XUtils.stringStartsWith(itemName, '*') then
            all = true
            itemName = string.gsub(itemName, '^%*', '')
        end
        xdebug.info('----------')
        for _, item in ipairs(XAutoAuctionList) do
            if XUtils.stringContains(item['itemname'], itemName) then
                if item['enabled'] ~= nil and item['enabled'] then
                    if all or (not item['star']) then
                        local vendorPrice = XInfo.getAuctionInfoField(item['itemname'], 'vendorprice', 0)
                        local dealRate = XInfo.getAuctionInfoField(item['itemname'], 'dealrate', 99)
                        if dealRate == 99 then dealRate = 1 end
                        local price = basePrice / (1 - profitRate)
                        if isDealRate then
                            price = price + (dealRate - 1) * vendorPrice * XAPI.FeeRate
                        end
                        if confirm then
                            item['baseprice'] = price
                            item['defaultprice'] = price * 3
                        end
                        xdebug.info(item['itemname'] .. ':  ' .. XUtils.priceToMoneyString(price))
                    end
                end
            end
        end
    end
end

getMyValidCount = function(itemName)
    local count = 0
    for _, item in ipairs(XAutoAuctionList) do
        if item['itemname'] == itemName then
            count = #item['myvalidlist']
            break
        end
    end
    return count
end

addClick = function(this)
    XUIInputDialog.show(moduleName, function(data)
        local itemName = nil
        local basePrice = nil
        local defaultPrice = nil
        local stackCount = nil
        for _, item in ipairs(data) do
            if item.Name == '宝石名称' then itemName = item.Value end
            if item.Name == '基准价格' then basePrice = tonumber(item.Value) end
            if item.Name == '默认价格' then defaultPrice = tonumber(item.Value) end
            if item.Name == '拍卖数量' then stackCount = tonumber(item.Value) end
        end
        if itemName and basePrice and defaultPrice and stackCount then
            addItem(itemName, basePrice, defaultPrice, stackCount)
        end
        filterDisplayList()
    end, { { Name = '宝石名称' }, { Name = '基准价格' }, { Name = '默认价格' }, { Name = '拍卖数量' } }, '添加')
end

checkRecipeClick = function(this)
    if not XInfo.reloadTradeSkill() then
        return
    end
    local list = XInfoTradeSkillList['珠宝加工']
    local newList = {}
    local disabledList = {}
    for itemName, _ in pairs(list) do
        if XUtils.stringEndsWith(itemName, '赤玉石')
            or XUtils.stringEndsWith(itemName, '紫黄晶')
            or XUtils.stringEndsWith(itemName, '王者琥珀')
            or XUtils.stringEndsWith(itemName, '祖尔之眼')
            or XUtils.stringEndsWith(itemName, '巨锆石')
            or XUtils.stringEndsWith(itemName, '恐惧石')
            or XUtils.stringEndsWith(itemName, '血玉石')
            or XUtils.stringEndsWith(itemName, '帝黄晶')
            or XUtils.stringEndsWith(itemName, '秋色石')
            or XUtils.stringEndsWith(itemName, '森林翡翠')
            or XUtils.stringEndsWith(itemName, '天蓝石')
            or XUtils.stringEndsWith(itemName, '曙光猫眼石')
            or XUtils.stringEndsWith(itemName, '天焰钻石')
            or XUtils.stringEndsWith(itemName, '大地侵攻钻石') then
            local existed = false
            for _, item in ipairs(XAutoAuctionList) do
                if item['itemname'] == itemName then
                    if not item['enabled'] then
                        table.insert(disabledList, itemName)
                    end
                    existed = true
                    break
                end
            end
            if not existed then
                table.insert(newList, itemName)
            end
        end
    end
    if #disabledList > 0 then
        xdebug.warn('以下配方未开启：')
        for idx, itemName in ipairs(disabledList) do
            local itemLink = select(2, XAPI.GetItemInfo(itemName))
            if not itemLink then itemLink = itemName end
            xdebug.warn(idx .. ': ' .. itemLink)
        end
        xdebug.warn()
    end
    if #newList > 0 then
        xdebug.warn('以下配方未添加：')
        for idx, itemName in ipairs(newList) do
            local itemLink = select(2, XAPI.GetItemInfo(itemName))
            if not itemLink then itemLink = itemName end
            xdebug.warn(idx .. ': ' .. itemLink)
        end
        xdebug.warn()
        XUIConfirmDialog.show(moduleName, '确认', '是否确认添加配方', function()
            for _, itemName in ipairs(newList) do
                addItem(itemName, dft_minPrice, dft_minPrice, 1)
            end
            xdebug.info('添加成功')
        end)
    end
end

priceAdjustClick = function(this)
    XUIInputDialog.show(moduleName, function(data)
        local itemName = nil
        local basePrice = nil
        local profitRate = nil
        local isDealRate = nil
        for _, item in ipairs(data) do
            if item.Name == '宝石名称' then itemName = item.Value end
            if item.Name == '基准价格' then basePrice = tonumber(item.Value) end
            if item.Name == '利润率' then profitRate = tonumber(item.Value) end
            if item.Name == '手续费' then isDealRate = tonumber(item.Value) end
        end
        setPriceByName(itemName, basePrice, profitRate, isDealRate == 1, true)
    end, { {
        Name = '宝石名称',
        OnEnterPressed = function(_, data)
            local itemName = nil
            local basePrice = nil
            local profitRate = nil
            local isDealRate = nil
            for _, item in ipairs(data) do
                if item.Name == '宝石名称' then itemName = item.Value end
                if item.Name == '基准价格' then basePrice = tonumber(item.Value) end
                if item.Name == '利润率' then profitRate = tonumber(item.Value) end
                if item.Name == '手续费' then isDealRate = tonumber(item.Value) end
            end
            setPriceByName(itemName, basePrice, profitRate, isDealRate == 1, false)
        end
    }, { Name = '基准价格' }, { Name = '利润率', Value = 0.1 }, { Name = '手续费', Value = 1 } }, '调价')
end

itemSortClick = function(this)
    local index = this.frame.index
    XUISortDialog.show('XAuctionCenter_Sort', XAutoAuctionList, index, function()
        filterDisplayList()
    end)
end

itemMailClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    local count = 5
    if IsShiftKeyDown() then count = 12 end

    XUtils.sendMail(item['itemname'], count)
    refreshUI()
end

itemReceiveClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    XUtils.receiveMail(item['itemname'])
    refreshUI()
end

itemToBankClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    if IsShiftKeyDown() then
        XUtils.moveToBank(item['itemname'])
    else
        XUtils.moveToBank(item['itemname'], 1)
    end
    refreshUI()
end

itemToBagClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    if IsShiftKeyDown() then
        XUtils.moveToBag(item['itemname'])
    else
        XUtils.moveToBag(item['itemname'], 1)
    end
    refreshUI()
end

itemNameClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    if IsShiftKeyDown() then
        XAPI.AuctionatorSearchExact(item['itemname'])
    elseif IsLeftControlKeyDown() then
        XInfo.printBuyHistory(item['itemname'])
    else
        XUIInputDialog.show(moduleName, function(input)
            local itemName = item['itemname']
            local count = input[1].Value
            XCraftQueue.addItem(itemName, count, 'fulfil')
        end, { { Name = '数量', Value = item['stackcount'] } }, item['itemname'])
    end
end

itemDeleteClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index]
    if not item then return end

    XUIConfirmDialog.show(moduleName, '删除', '是否确定删除：' .. item['itemname'], function()
        table.remove(XAutoAuctionList, index)
        filterDisplayList()
    end)
end

itemRubbishClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index]
    if not item then return end

    XUIConfirmDialog.show(moduleName, '确认', '是否确认设为垃圾', function()
        item['baseprice'] = 1
        item['stackcount'] = 1
        refreshUI()
    end)
end

itemSettingClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index]
    if not item then return end

    XUIInputDialog.show(moduleName, function(data)
        local itemName = nil
        local basePrice = nil
        local defaultPrice = nil
        local stackCount = nil
        for _, titem in ipairs(data) do
            if titem.Name == '宝石名称' then itemName = titem.Value end
            if titem.Name == '基准价格' then basePrice = tonumber(titem.Value) end
            if titem.Name == '默认价格' then defaultPrice = tonumber(titem.Value) end
            if titem.Name == '拍卖数量' then stackCount = tonumber(titem.Value) end
        end
        if itemName and basePrice and defaultPrice and stackCount then
            item['itemname'] = itemName
            item['baseprice'] = basePrice
            item['defaultprice'] = defaultPrice
            item['stackcount'] = stackCount
        end
        refreshUI()
    end, {
        { Name = '宝石名称', Value = item['itemname'] },
        { Name = '基准价格', Value = item['baseprice'] },
        { Name = '默认价格', Value = item['defaultprice'] },
        { Name = '拍卖数量', Value = item['stackcount'] }
    }, '添加')
end

itemEnableClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    if item['enabled'] ~= true then
        item['enabled'] = true
    else
        item['enabled'] = false
    end
    refreshUI()
end

itemStarClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    if item['star'] == nil or item['star'] == false then
        item['star'] = true
    else
        item['star'] = false
    end
    refreshUI()
end

itemCanCraftClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    item['cancraft'] = not item['cancraft']
    refreshUI()
end

itemRefreshClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    addQueryTaskByIndex(index, IsShiftKeyDown())
end

itemCleanClick = function(this)
    local index = this.frame.index
    local item = XAutoAuctionList[index];
    if not item then return end

    cleanLower(item['itemname'])
end

-- Event callback
local function onQueryItemListUpdate(...)
    if not curTask then return end
    if curTask['action'] ~= 'query' and curTask['action'] ~= 'material' then return end
    if curTask['status'] ~= 'querying' then return end

    local batchCount, totalCount = XAPI.GetNumAuctionItems('list')

    if totalCount <= 0 or batchCount <= 0 then
        curTask['status'] = 'loaded'
        return
    end

    local itemIndex = 1
    while true do
        local res = { XAPI.GetAuctionItemInfo('list', itemIndex) }
        local itemName = res[1]

        if not itemName then
            break
        end
        if itemName == curTask['itemname'] then
            curTask['status'] = 'loaded'
            break
        end
        itemIndex = itemIndex + 1
    end
end

local function onAuctionSuccess()
    -- if not curTask then return end
    -- curTask['status'] = 'finished'
end

processQueryTask = function(task)
    XInfo.reloadBag()
    XInfo.reloadAuction()
    local index = task['index']
    local item = XAutoAuctionList[index]
    local auctionItem = XInfo.getAuctionItem(item['itemname'])
    local myMaxPrice = 0
    if auctionItem then myMaxPrice = auctionItem['maxprice'] end

    if not item then
        finishTask()
        startNextTask()
        return
    end
    if not task['status'] then
        if not XAPI.CanSendAuctionQuery() then return end
        resetItem(item, true)
        task['status'] = 'querying'
        XAPI.QueryAuctionItems(item['itemname'], nil, nil, 0, nil, nil, false, true)
        return
    elseif task['status'] == 'querying' then
        return
    elseif task['status'] == 'loaded' then
        item['updatetime'] = time()

        local itemIndex = 1
        while true do
            local res = { XAPI.GetAuctionItemInfo('list', itemIndex) }
            local itemName = res[1]
            local stackCount = res[3]
            local buyoutPrice = res[10]
            local seller = res[14]
            local itemId = res[17]

            if not itemName then break end
            if itemName == item['itemname'] then
                buyoutPrice = buyoutPrice / stackCount

                XExternal.updateItemInfo(itemName, itemId)
                XExternal.addScanHistory(itemName, time(), buyoutPrice)

                if buyoutPrice ~= nil and buyoutPrice > 0 then
                    if buyoutPrice < item['baseprice'] then
                        item['lowercount'] = item['lowercount'] + 1
                    end
                    if buyoutPrice < myMaxPrice then
                        item['pricelowercount'] = item['pricelowercount'] + 1
                    end

                    if buyoutPrice <= item['minpriceother'] then
                        if XInfo.isMe(seller) then
                            table.insert(item['myvalidlist'], buyoutPrice)
                        else
                            local newPriceList = {}
                            for _, tprice in ipairs(item['myvalidlist']) do
                                if tprice <= buyoutPrice then
                                    table.insert(newPriceList, tprice)
                                end
                            end
                            item['myvalidlist'] = newPriceList
                            item['minpriceother'] = buyoutPrice
                        end
                    end
                    if buyoutPrice > item['maxpriceother'] then
                        if not XInfo.isMe(seller) then
                            item['maxpriceother'] = buyoutPrice
                        end
                    end
                end
            end
            itemIndex = itemIndex + 1
        end

        if item['minpriceother'] < item['baseprice'] then
            finishTask()
            startNextTask()
            return
        else
            local itemBagCount = XInfo.getBagItemCount(item['itemname'])
            if itemBagCount <= 0 then
                finishTask()
                startNextTask()
                return
            end

            local price = item['defaultprice']
            if item['minpriceother'] ~= dft_minPrice then
                price = item['minpriceother'] - dft_deltaPrice
            end
            if item['minpriceother'] >= item['baseprice'] and price < item['baseprice'] then
                price = item['baseprice']
            end
            if price > dft_maxPrice then
                price = dft_maxPrice
            end
            if price > item['defaultprice'] then
                price = item['defaultprice']
            end
            if price < item['baseprice'] then
                finishTask()
                startNextTask()
                return
            end

            local validCount = getMyValidCount(item['itemname'])

            local targetCount = item['stackcount']
            local subcount = targetCount - validCount
            if itemBagCount < subcount then
                subcount = itemBagCount
            end
            if subcount <= 0 then
                finishTask()
                startNextTask()
                return
            end

            local bagItem = XInfo.getBagItem(item['itemname'])
            if not bagItem then
                finishTask()
                startNextTask()
                return
            end

            task['price'] = price
            task['count'] = subcount

            local position = bagItem['positions'][1]
            XAPI.ClearCursor()
            XAPI.ClickAuctionSellItemButton()
            XAPI.ClearCursor()
            XAPI.C_Container_PickupContainerItem(position[1], position[2])
            XAPI.ClickAuctionSellItemButton()

            task['location'] = XAPI.ItemLocation_CreateFromBagAndSlot(position[1], position[2])
            if XAPI.C_Item_DoesItemExist(task['location']) then
                XAPI.C_Item_UnlockItem(task['location'])
            end
            -- XAPI.C_Item_LockItem(task['location'])
            task['status'] = 'posting'
            return
        end
    elseif task['status'] == 'posting' then
        if task['starttime'] + dft_postdelay > time() then return end

        if XAPI.GetAuctionSellItemInfo() ~= item['itemname'] then
            finishTask()
            startNextTask()
            return
        end

        XAPI.PostAuction(task['price'], task['price'], 1, 1, task['count'])

        xdebug.info('拍卖：' .. item['itemname'] .. '(' .. XUtils.priceToMoneyString(task['price']) .. ')')
        for _ = 1, task['count'] do
            table.insert(item['myvalidlist'], task['price'])
        end
        finishTask()
        startNextTask()
    end
end

processMaterialQueryTask = function(task)
    if not task['status'] then
        if not XAPI.CanSendAuctionQuery() then return end
        task['status'] = 'querying'
        XAPI.QueryAuctionItems(task['itemname'], nil, nil, 0, nil, nil, false, true)
        return
    elseif task['status'] == 'querying' then
        return
    elseif task['status'] == 'loaded' then
        local itemIndex = 1
        local minBuyoutPrice = dft_minPrice
        while true do
            local res = { XAPI.GetAuctionItemInfo('list', itemIndex) }
            local itemName = res[1]
            local stackCount = res[3]
            local buyoutPrice = res[10]
            local seller = res[14]
            local itemId = res[17]

            if not itemName then break end
            if itemName == task['itemname'] then
                buyoutPrice = buyoutPrice / stackCount

                XExternal.updateItemInfo(itemName, itemId)
                XExternal.addScanHistory(itemName, time(), buyoutPrice)

                if buyoutPrice ~= nil and buyoutPrice > 0 then
                    if buyoutPrice <= minBuyoutPrice then
                        if not XInfo.isMe(seller) then
                            minBuyoutPrice = buyoutPrice
                        end
                    end
                end
            end
            itemIndex = itemIndex + 1
        end
        for _, item in ipairs(materialList) do
            if task['itemname'] == item['itemname'] then
                item['price'] = minBuyoutPrice
                break
            end
        end

        for _, item in ipairs(XAutoBuyList) do
            if task['itemname'] == item['itemname'] then
                item['minbuyoutprice'] = minBuyoutPrice
                item['updatetime'] = time()
                break
            end
        end

        finishTask()
        startNextTask()
    end
end

local function onUpdate()
    if not isStarted then return end
    refreshUI()

    addCraftQueue()

    if curTask then
        if time() - curTask['starttime'] > curTask['timeout'] then
            xdebug.error('XAuctionCenter Task Timeout')
            finishTask()
            refreshUI()
            return
        end

        if curTask['action'] == 'query' then
            processQueryTask(curTask)
        elseif curTask['action'] == 'material' then
            processMaterialQueryTask(curTask)
        end
        refreshUI()
        return
    end

    puton()

    startNextTask()
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initData()
    initUI()
    filterDisplayList()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_ITEM_LIST_UPDATE', onQueryItemListUpdate)

-- XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_SHOW', function(self, event, text, context)
--     stop()
--     if mainFrame then mainFrame:Show() end
-- end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    stop()
    if mainFrame then mainFrame:Hide() end
end)

XAutoAuction.registerEventCallback(moduleName, 'CHAT_MSG_SYSTEM', function(...)
    local text = select(3, ...)
    if text == ERR_AUCTION_STARTED then
        onAuctionSuccess()
    elseif XUtils.stringStartsWith(text, '你拍卖的') and XUtils.stringEndsWith(text, '已经售出。') then
        local itemname = string.sub(text, string.len('你拍卖的') + 1, string.len(text) - string.len('已经售出。'))
        local tindex = nil
        for i = 1, #XAutoAuctionList do
            if XAutoAuctionList[i]['itemname'] == itemname then
                tindex = i
                break
            end
        end
        if tindex == nil then
            return
        end
        addQueryTaskByIndex(tindex)
    end
end)

XAutoAuction.registerUpdateCallback(moduleName, onUpdate)

XAutoAuction.registerRefreshCallback(moduleName, refreshUI)

-- Commands
SlashCmdList['XAUCTIONCENTER'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XAUCTIONCENTER1 = '/xauctioncenter'

SlashCmdList['XAUCTIONCENTERSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XAUCTIONCENTERSHOW1 = '/xauctioncenter_show'

SlashCmdList['XAUCTIONCENTERCLOSE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XAUCTIONCENTERCLOSE1 = '/xauctioncenter_close'

SlashCmdList['XAUCTIONCENTERADDCRAFTQUEUE'] = function()
    local count = addCraftQueue()
    xdebug.info('Craft: ' .. count)
end
SLASH_XAUCTIONCENTERADDCRAFTQUEUE1 = '/xauctioncenter_addcreaftqueue'

SlashCmdList['XAUCTIONCENTERPUTON'] = function()
    local count = puton()
    xdebug.info('PutOn: ' .. count)
end
SLASH_XAUCTIONCENTERPUTON1 = '/xauctioncenter_puton'

SlashCmdList['XAUCTIONCENTERPRINT'] = function()
    printList()
end
SLASH_XAUCTIONCENTERPRINT1 = '/xauctioncenter_print'

SlashCmdList['XAUCTIONCENTERCLEANLOWER'] = function()
    cleanLower()
end
SLASH_XAUCTIONCENTERCLEANLOWER1 = '/xauctioncenter_cleanlower'

-- Interfaces
XAuctionCenter.addQueryTaskByItemName = addQueryTaskByItemName
XAuctionCenter.getItem = getItem
XAuctionCenter.printItemsByName = printItemsByName
XAuctionCenter.setPriceByName = setPriceByName
XAuctionCenter.getMyValidCount = getMyValidCount
XAuctionCenter.checkImportantByName = checkImportantByName
