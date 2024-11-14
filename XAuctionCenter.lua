XAuctionCenter = {}
local moduleName = 'XAuctionCenter'

-- Variable definition
local mainFrame = nil
local scrollView = nil
local materialFrames = {}

local dft_mainFrameHeightL = 600
local dft_mainFrameHeightS = 300
local dft_mainFrameWidthL = 1325
local dft_mainFrameWidthS = 1000
local dft_minPrice = 9999999
local dft_maxPrice = 2180000
local dft_basePriceRate = 1.5
local dft_taskInterval = 0.9
local dft_taskTimeout = 15
local dft_filterList = { '全部', '星星', '优质', '可售', '缺货', '有效', '潜力', '价低', '无效', '垃圾', '不做', '邮寄', '收件', '量大' }
local dft_deltaPrice = 10
local dft_postdelay = 2
local dft_oldInterval = 1800
local dft_maxCraftCount = 12
local dft_materialTaskInterval = 30
local dft_multiSellList = { '单倍', '双倍', '全部' }

local dft_buttonWidth = 45
local dft_buttonGap = 1
local dft_sectionGap = 10

local mainFrameHeightType = 1
local mainFrameHeight = dft_mainFrameHeightL
local mainFrameWidthType = 1
local mainFrameWidth = dft_mainFrameWidthL
local displayList = {}

local isStarted = false
local err453Count = 0
local taskList = {}
local curTask = nil
local lastTaskFinishTime = 0

local buyPriceEnabled = true
local buyEnabled = true
local multiSell = 1

local queryIndex = 1
local starQueryIndex = 1
local queryStarFlag = true

local lastMaterialTaskTime = time()
local materialQueryIndex = 0

local cleaningItems = {}

-- Function definition
local initData
local resetData
local initUI
local reloadUI
local reloadBuyList
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
local itemOnEnter
local itemOnLeave

local processQueryTask
local processMaterialQueryTask

-- Function implemention
initData = function()

end

resetData = function()
    for _, item in ipairs(XItemList) do
        resetItem(item)
    end
    isStarted = false
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0

    queryIndex = 1
    starQueryIndex = 1
    queryStarFlag = true

    materialQueryIndex = 0
    lastMaterialTaskTime = time()
end

initUI = function()
    mainFrame = XUI.createFrame('XAuctionCenterMainFrame', mainFrameWidth, mainFrameHeight)
    mainFrame:SetFrameStrata('HIGH')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame.title:SetText('')
    mainFrame:Hide()
    mainFrame.titleList = {}
    mainFrame.titleFrame = XAPI.CreateFrame('Frame', nil, mainFrame)
    mainFrame.titleFrame:SetPoint('TOP', mainFrame, 'TOP', 0, 0)
    mainFrame.addTitle = function(self, prefix)
        local tlabel = XUI.createLabel(self.titleFrame, 70, '', 'Left')
        tlabel:SetHeight(20)
        tlabel.prefix = prefix
        if #self.titleList == 0 then
            tlabel:SetPoint('Left', self.titleFrame, 'Left', 0, 0)
        else
            tlabel:SetPoint('Left', self.titleList[#self.titleList], 'RIGHT', 5, 0)
        end
        table.insert(self.titleList, tlabel)
        self.titleFrame:SetSize(#self.titleList * 75, 20)
    end
    mainFrame.setTitle = function(self, index, text)
        local tlabel = self.titleList[index]
        if not tlabel then return end
        tlabel:SetText(tlabel.prefix .. ':' .. text)
    end
    mainFrame:addTitle('售中')
    mainFrame:addTitle('回款')
    mainFrame:addTitle('收款')
    mainFrame:addTitle('已售')
    mainFrame:addTitle('制作')
    mainFrame:addTitle('购买')
    mainFrame:addTitle('背包')
    mainFrame:addTitle('制造')
    tinsert(UISpecialFrames, mainFrame:GetName())

    local widthTypeButton = XUI.createButton(mainFrame, 30, 'W')
    widthTypeButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', 0, -30)
    widthTypeButton:SetScript('OnClick', function(self)
        mainFrameWidthType = mainFrameWidthType % 2 + 1
        if mainFrameWidthType == 1 then
            mainFrameWidth = dft_mainFrameWidthL
        else
            mainFrameWidth = dft_mainFrameWidthS
        end
        reloadUI()
    end)

    local heightTypeButton = XUI.createButton(mainFrame, 30, 'H')
    heightTypeButton:SetPoint('TOPLEFT', widthTypeButton, 'BOTTOMLEFT', 0, -2)
    heightTypeButton:SetScript('OnClick', function(self)
        mainFrameHeightType = mainFrameHeightType % 2 + 1
        if mainFrameHeightType == 1 then
            mainFrameHeight = dft_mainFrameHeightL
        else
            mainFrameHeight = dft_mainFrameHeightS
        end
        reloadUI()
    end)

    local largeUIButton = XUI.createButton(mainFrame, 30, 'L')
    largeUIButton:SetPoint('TOPLEFT', heightTypeButton, 'BOTTOMLEFT', 0, -2)
    largeUIButton:SetScript('OnClick', function(self)
        mainFrameWidthType = 1
        mainFrameHeightType = 1
        mainFrameHeight = dft_mainFrameHeightL
        mainFrameWidth = dft_mainFrameWidthL
        reloadUI()
    end)

    local smallUIButton = XUI.createButton(mainFrame, 30, 'S')
    smallUIButton:SetPoint('TOPLEFT', largeUIButton, 'BOTTOMLEFT', 0, -2)
    smallUIButton:SetScript('OnClick', function(self)
        mainFrameWidthType = 2
        mainFrameHeightType = 2
        mainFrameHeight = dft_mainFrameHeightS
        mainFrameWidth = dft_mainFrameWidthS
        reloadUI()
    end)

    local auctionBoardButton = XUI.createButton(mainFrame, dft_buttonWidth, '面板')
    auctionBoardButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -30, 0)
    auctionBoardButton:SetScript('OnClick', function(self)
        XAuctionBoard.toggle()
        refreshUI()
    end)
    mainFrame.auctionBoardButton = auctionBoardButton

    local jewCountButton = XUI.createButton(mainFrame, dft_buttonWidth, '材料')
    jewCountButton:SetPoint('RIGHT', auctionBoardButton, 'LEFT', -3, 0)
    jewCountButton:SetScript('OnClick', function(self)
        XJewCount.toggle()
        refreshUI()
    end)
    mainFrame.jewCountButton = jewCountButton

    local craftQueueButton = XUI.createButton(mainFrame, dft_buttonWidth, '制造')
    craftQueueButton:SetPoint('RIGHT', jewCountButton, 'LEFT', -3, 0)
    craftQueueButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            XCraftQueue.start(true)
        elseif IsLeftControlKeyDown() then
            XCraftQueue.reset()
        else
            XCraftQueue.toggle()
        end
        refreshUI()
    end)
    mainFrame.craftQueueButton = craftQueueButton

    local speakButton = XUI.createButton(mainFrame, dft_buttonWidth, '喊话')
    speakButton:SetPoint('RIGHT', craftQueueButton, 'LEFT', -3, 0)
    speakButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            XSpeakWord.start()
        elseif IsLeftControlKeyDown() then
            XSpeakWord.printList()
        else
            XSpeakWord.toggle()
        end
    end)
    mainFrame.speakButton = speakButton

    local multiSellButton = XUI.createButton(mainFrame, dft_buttonWidth, '单倍')
    multiSellButton:SetPoint('TOPRIGHT', auctionBoardButton, 'BOTTOMRIGHT', 0, -2)
    multiSellButton:SetScript('OnClick', function(self)
        multiSell = multiSell % #dft_multiSellList + 1
        refreshUI()
    end)
    mainFrame.multiSellButton = multiSellButton

    local buyButton = XUI.createButton(mainFrame, dft_buttonWidth, '购买')
    buyButton:SetPoint('RIGHT', multiSellButton, 'LEFT', -3, 0)
    buyButton:SetScript('OnClick', function(self)
        buyEnabled = not buyEnabled
        refreshUI()
    end)
    mainFrame.buyButton = buyButton

    local buyPriceButton = XUI.createButton(mainFrame, dft_buttonWidth, '买价')
    buyPriceButton:SetPoint('RIGHT', buyButton, 'LEFT', -3, 0)
    buyPriceButton:SetScript('OnClick', function(self)
        buyPriceEnabled = not buyPriceEnabled
        refreshUI()
    end)
    mainFrame.buyPriceButton = buyPriceButton

    local startButton = XUI.createButton(mainFrame, dft_buttonWidth, '开始')
    startButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    startButton:SetScript('OnClick', function(self)
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
            XBuy.reset()
            XAuctionBoard.draft()
            refreshUI()
        end)
    end)

    local putonButton = XUI.createButton(mainFrame, dft_buttonWidth, '上架')
    putonButton:SetPoint('LEFT', resetButton, 'RIGHT', dft_sectionGap, 0)
    putonButton:SetScript('OnClick', function()
        local count = puton(IsLeftShiftKeyDown())
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

    local cleanMassButton = XUI.createButton(mainFrame, dft_buttonWidth, '量大')
    cleanMassButton:SetPoint('LEFT', craftAllButton, 'RIGHT', dft_buttonGap, 0)
    cleanMassButton:SetScript('OnClick', function()
        XInfo.reloadAuction()
        for i, item in ipairs(XItemList) do
            local itemName = item['itemname']
            local auctionCount = XInfo.getAuctionItemCount(itemName)
            local minPriceOther = item['minpriceother']
            local basePrice = item['baseprice']
            if auctionCount >= 8 and (IsLeftShiftKeyDown() or (enabled and minPriceOther >= basePrice)) then
                cleanLower(itemName)
            end
        end
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
        local itemNames = { '简易研磨器', '珠宝制作工具' }
        for _, item in ipairs(XItemList) do
            table.insert(itemNames, item['itemname'])
        end
        XUtils.moveToBag(itemNames, nil, nil, false)
        cleanShort()
    end)

    local refreshButton = XUI.createButton(mainFrame, dft_buttonWidth, '刷新')
    refreshButton:SetPoint('LEFT', allToBagButton, 'RIGHT', dft_sectionGap, 0)
    refreshButton:SetScript('OnClick', function()
        XJewTool.refreshUI()
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

    local filter2Button = XUI.createButton(mainFrame, dft_buttonWidth, '缺货')
    filter2Button:SetPoint('LEFT', filter1Button, 'RIGHT', dft_buttonGap, 0)
    filter2Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '缺货')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        refreshUI()
    end)

    local filter3Button = XUI.createButton(mainFrame, dft_buttonWidth, '量大')
    filter3Button:SetPoint('LEFT', filter2Button, 'RIGHT', dft_buttonGap, 0)
    filter3Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '量大')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        refreshUI()
    end)

    local filter4Button = XUI.createButton(mainFrame, dft_buttonWidth, '可售')
    filter4Button:SetPoint('LEFT', filter3Button, 'RIGHT', dft_buttonGap, 0)
    filter4Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '可售')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        refreshUI()
    end)

    local filter5Button = XUI.createButton(mainFrame, dft_buttonWidth, '邮寄')
    filter5Button:SetPoint('LEFT', filter4Button, 'RIGHT', dft_buttonGap, 0)
    filter5Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '邮寄')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        refreshUI()
    end)

    local filter6Button = XUI.createButton(mainFrame, dft_buttonWidth, '收件')
    filter6Button:SetPoint('LEFT', filter5Button, 'RIGHT', dft_buttonGap, 0)
    filter6Button:SetScript('OnClick', function()
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
    filterDropDown:SetPoint('LEFT', filter6Button, 'RIGHT', -15, 0)
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

    local materialFrame = XAPI.CreateFrame('Frame', nil, mainFrame)
    materialFrame:SetSize(mainFrameWidth, 0)
    materialFrame:SetPoint('TOP', mainFrame, 'TOP', 0, -95)
    mainFrame.materialFrame = materialFrame

    local listFrame = XAPI.CreateFrame('Frame', nil, mainFrame)
    listFrame:SetSize(mainFrameWidth - 20, mainFrameHeight - 100)
    listFrame:SetPoint('Bottom', mainFrame, 'Bottom', 0, 10)
    mainFrame.listFrame = listFrame

    local labelFrame = XAPI.CreateFrame('Frame', nil, listFrame)
    labelFrame:SetSize(listFrame:GetWidth(), 30)
    labelFrame:SetPoint('TOP', listFrame, 'TOP', 0, 0)
    listFrame.labelFrame = labelFrame

    local indexLabel = XUI.createLabel(labelFrame, 35, '序号', 'CENTER')
    indexLabel:SetPoint('LEFT', labelFrame, 'LEFT', 5, 0)
    labelFrame.indexLabel = indexLabel

    local nameLabel = XUI.createLabel(labelFrame, 75, '名称', 'CENTER')
    nameLabel:SetPoint('LEFT', indexLabel, 'RIGHT', 150, 0)
    labelFrame.nameLabel = nameLabel

    local timeLabel = XUI.createLabel(labelFrame, 50, '时间', 'CENTER')
    timeLabel:SetPoint('LEFT', nameLabel, 'RIGHT', 3, 0)
    labelFrame.timeLabel = timeLabel

    local bagLabel = XUI.createLabel(labelFrame, 130, '银/邮/包/总', 'CENTER')
    bagLabel:SetPoint('LEFT', timeLabel, 'RIGHT', 3, 0)
    labelFrame.bagLabel = bagLabel

    local auctionLabel = XUI.createLabel(labelFrame, 150, '卖/我/低/底', 'CENTER')
    auctionLabel:SetPoint('LEFT', bagLabel, 'RIGHT', 3, 0)
    labelFrame.auctionLabel = auctionLabel

    local dealLabel = XUI.createLabel(labelFrame, 130, '率/次/今/堆', 'CENTER')
    dealLabel:SetPoint('LEFT', auctionLabel, 'RIGHT', 3, 0)
    labelFrame.dealLabel = dealLabel

    local priceLabel = XUI.createLabel(labelFrame, 210, '现/上/高/基', 'CENTER')
    priceLabel:SetPoint('LEFT', dealLabel, 'RIGHT', 3, 0)
    labelFrame.priceLabel = priceLabel

    local sellerLabel = XUI.createLabel(labelFrame, 80, '卖家', 'CENTER')
    sellerLabel:SetPoint('LEFT', priceLabel, 'RIGHT', 3, 0)
    labelFrame.sellerLabel = sellerLabel

    scrollView = XUI.createScrollView(listFrame, listFrame:GetWidth(),
        listFrame:GetHeight() - labelFrame:GetHeight())
    scrollView:SetPoint('TOPLEFT', labelFrame, 'BottomLeft', 0, 0)

    refreshUI()
end

reloadUI = function()
    if mainFrame == nil then return end
    if scrollView == nil then return end

    mainFrame:SetWidth(mainFrameWidth)
    mainFrame:SetHeight(mainFrameHeight + mainFrame.materialFrame:GetHeight())

    mainFrame.materialFrame:SetWidth(mainFrameWidth)

    mainFrame.listFrame:SetWidth(mainFrameWidth - 20)
    mainFrame.listFrame:SetHeight(mainFrameHeight - 100)
    mainFrame.listFrame.labelFrame:SetWidth(mainFrame.listFrame:GetWidth())

    scrollView:SetWidth(mainFrame.listFrame:GetWidth())
    scrollView:SetHeight(mainFrame.listFrame:GetHeight() - mainFrame.listFrame.labelFrame:GetHeight())

    filterDisplayList()
    reloadBuyList()

    refreshUI()
end

filterDisplayList = function()
    if not mainFrame then return end
    if not scrollView then return end

    local filterWord = mainFrame.filterBox:GetText();
    local displayFilter = XAPI.UIDropDownMenu_GetText(mainFrame.filterDropDown)
    local dataList = {}
    for i, item in ipairs(XItemList) do
        item.index = i
        local itemName = item['itemname']
        local materialName = XInfo.getMaterialName(itemName)
        local enabled = item['enabled']
        if enabled == nil then enabled = false end
        local star = item['star']
        if star == nil then star = false end
        local canCraft = item['cancraft']
        if canCraft == nil then canCraft = true end
        local minPriceOther = item['minpriceother']
        local basePrice = item['baseprice']
        local stackCount = item['stackcount']
        local materialBuyPrice = XBuy.getItemField(materialName, 'price', 0)
        local bagCount = XInfo.getBagItemCount(itemName)
        local mailCount = XInfo.getMailItemCount(itemName)
        local auctionCount = XInfo.getAuctionItemCount(itemName)
        local dealCount = XInfo.getItemInfoField(itemName, 'dealcount', 0)
        local dealRate = XInfo.getItemInfoField(itemName, 'dealrate', 99)
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
            if enabled and (star or important) and (IsLeftShiftKeyDown() or minPriceOther >= basePrice) then
                disFlag = true
            end
        elseif displayFilter == '价低' then
            if enabled and (minPriceOther <= materialBuyPrice) then
                disFlag = true
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
            if auctionCount >= 8 and (IsLeftShiftKeyDown() or (enabled and minPriceOther >= basePrice)) then
                disFlag = true
            end
        elseif displayFilter == '邮寄' then
            if bagCount > 5 and (IsLeftShiftKeyDown() or (enabled and minPriceOther >= basePrice)) then
                disFlag = true
            end
        elseif displayFilter == '收件' then
            if mailCount > 0 and (IsLeftShiftKeyDown() or (enabled and minPriceOther >= basePrice)) then
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
        elseif displayFilter == '缺货' then
            if enabled and (IsLeftShiftKeyDown() or important or star) and minPriceOther >= basePrice and bagCount < stackCount then
                disFlag = true
            end
        end

        if filterWord ~= '' and (not XUtils.stringContains(itemName, filterWord)) then
            disFlag = false
        end

        if disFlag then table.insert(dataList, item) end
    end
    displayList = dataList;

    local labelFrame = mainFrame.listFrame.labelFrame
    if mainFrameWidthType == 1 then
        labelFrame.indexLabel:SetWidth(35)
        labelFrame.indexLabel:SetPoint('LEFT', labelFrame, 'LEFT', 5, 0)

        labelFrame.nameLabel:SetWidth(75)
        labelFrame.nameLabel:SetPoint('LEFT', labelFrame.indexLabel, 'RIGHT', 150, 0)

        labelFrame.timeLabel:SetWidth(50)
        labelFrame.timeLabel:SetPoint('LEFT', labelFrame.nameLabel, 'RIGHT', 3, 0)

        labelFrame.bagLabel:SetWidth(130)
        labelFrame.bagLabel:SetPoint('LEFT', labelFrame.timeLabel, 'RIGHT', 3, 0)
        labelFrame.bagLabel:SetText('银/邮/包/总')

        labelFrame.auctionLabel:SetWidth(150)
        labelFrame.auctionLabel:SetPoint('LEFT', labelFrame.bagLabel, 'RIGHT', 3, 0)
        labelFrame.auctionLabel:SetText('卖/我/低/底')

        labelFrame.dealLabel:SetWidth(130)
        labelFrame.dealLabel:SetPoint('LEFT', labelFrame.auctionLabel, 'RIGHT', 3, 0)
        labelFrame.dealLabel:SetText('率/次/今/堆')

        labelFrame.priceLabel:SetWidth(210)
        labelFrame.priceLabel:SetPoint('LEFT', labelFrame.dealLabel, 'RIGHT', 3, 0)
        labelFrame.priceLabel:SetText('现/上/高/基')

        labelFrame.sellerLabel:SetWidth(80)
        labelFrame.sellerLabel:SetPoint('LEFT', labelFrame.priceLabel, 'RIGHT', 3, 0)
        labelFrame.sellerLabel:SetText('卖家')
    else
        labelFrame.indexLabel:SetWidth(0)

        labelFrame.nameLabel:SetWidth(75)
        labelFrame.nameLabel:SetPoint('LEFT', labelFrame, 'LEFT', 68, 0)

        labelFrame.timeLabel:SetWidth(50)
        labelFrame.timeLabel:SetPoint('LEFT', labelFrame.nameLabel, 'RIGHT', 3, 0)

        labelFrame.bagLabel:SetWidth(110)
        labelFrame.bagLabel:SetPoint('LEFT', labelFrame.timeLabel, 'RIGHT', 3, 0)
        labelFrame.bagLabel:SetText('邮/包/总')

        labelFrame.auctionLabel:SetWidth(80)
        labelFrame.auctionLabel:SetPoint('LEFT', labelFrame.bagLabel, 'RIGHT', 3, 0)
        labelFrame.auctionLabel:SetText('卖/我')

        labelFrame.dealLabel:SetWidth(130)
        labelFrame.dealLabel:SetPoint('LEFT', labelFrame.auctionLabel, 'RIGHT', 3, 0)
        labelFrame.dealLabel:SetText('率/次/今/堆')

        labelFrame.priceLabel:SetWidth(210)
        labelFrame.priceLabel:SetPoint('LEFT', labelFrame.dealLabel, 'RIGHT', 3, 0)
        labelFrame.priceLabel:SetText('现/上/高/基')

        labelFrame.sellerLabel:SetWidth(150)
        labelFrame.sellerLabel:SetPoint('LEFT', labelFrame.priceLabel, 'RIGHT', 3, 0)
        labelFrame.sellerLabel:SetText('卖家')
    end

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

        local itemIndexButton = nil
        if mainFrameWidthType == 1 then
            itemIndexButton = XUI.createButton(frame, 35, '999')
            itemIndexButton:SetPoint('LEFT', frame, 'LEFT', 0, 0)
            itemIndexButton:SetScript('OnClick', itemSortClick)
            frame.itemIndexButton = itemIndexButton
            itemIndexButton.frame = frame
            itemIndexButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            itemIndexButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local itemMailButton = nil
        if mainFrameWidthType == 1 then
            itemMailButton = XUI.createButton(frame, 30, 'U')
            itemMailButton:SetPoint('LEFT', itemIndexButton, 'RIGHT', 0, 0)
            itemMailButton:SetScript('OnClick', itemMailClick)
            frame.itemMailButton = itemMailButton
            itemMailButton.frame = frame
            itemMailButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            itemMailButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local itemReceiveButton = XUI.createButton(frame, 30, 'R')
        if mainFrameWidthType == 1 then
            itemReceiveButton:SetPoint('LEFT', itemMailButton, 'RIGHT', 0, 0)
        else
            itemReceiveButton:SetPoint('LEFT', frame, 'LEFT', 0, 0)
        end
        itemReceiveButton:SetScript('OnClick', itemReceiveClick)
        frame.itemReceiveButton = itemReceiveButton
        itemReceiveButton.frame = frame
        itemReceiveButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
        itemReceiveButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)

        local itemToBankButton = nil
        local itemToBagButton = nil
        if mainFrameWidthType == 1 then
            itemToBankButton = XUI.createButton(frame, 30, 'O')
            itemToBankButton:SetPoint('LEFT', itemReceiveButton, 'RIGHT', 0, 0)
            itemToBankButton:SetScript('OnClick', itemToBankClick)
            frame.itemToBankButton = itemToBankButton
            itemToBankButton.frame = frame
            itemToBankButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            itemToBankButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)

            itemToBagButton = XUI.createButton(frame, 30, 'I')
            itemToBagButton:SetPoint('LEFT', itemToBankButton, 'RIGHT', 0, 0)
            itemToBagButton:SetScript('OnClick', itemToBagClick)
            frame.itemToBagButton = itemToBagButton
            itemToBagButton.frame = frame
            itemToBagButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            itemToBagButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local itemIcon = XUI.createIcon(frame, 25, 25)
        if mainFrameWidthType == 1 then
            itemIcon:SetPoint('LEFT', itemToBagButton, 'RIGHT', 2, 0)
        else
            itemIcon:SetPoint('LEFT', itemReceiveButton, 'RIGHT', 2, 0)
        end
        itemIcon:SetScript("OnEnter", itemOnEnter)
        itemIcon:SetScript("OnLeave", itemOnLeave)
        frame.itemIcon = itemIcon
        itemIcon.frame = frame

        local itemNameButton = XUI.createButton(frame, 80, '')
        itemNameButton:SetPoint('LEFT', itemIcon, 'RIGHT', 0, 0)
        itemNameButton:SetScript('OnClick', itemNameClick)
        itemNameButton:SetScript("OnEnter", itemOnEnter)
        itemNameButton:SetScript("OnLeave", itemOnLeave)

        local itemNameButtonBorderLeft = itemNameButton:CreateTexture(nil, 'OVERLAY')
        itemNameButtonBorderLeft:SetColorTexture(1, 1, 0, 0)
        itemNameButtonBorderLeft:SetPoint('TOPLEFT', itemNameButton, 'TOPLEFT', 5, -5)
        itemNameButtonBorderLeft:SetPoint('BOTTOMRIGHT', itemNameButton, 'BOTTOMLEFT', 8, 5)
        itemNameButton.borderLeft = itemNameButtonBorderLeft

        itemNameButton.SetHighlight = function(self, highlight)
            if highlight then
                self.borderLeft:SetColorTexture(1, 1, 0, 1)
            else
                self.borderLeft:SetColorTexture(1, 1, 0, 0)
            end
        end

        frame.itemNameButton = itemNameButton
        itemNameButton.frame = frame

        local labelTime = XUI.createLabel(frame, 50, '', 'CENTER')
        labelTime:SetPoint('LEFT', itemNameButton, 'RIGHT', 3, 0)
        frame.labelTime = labelTime

        local labelBag = XUI.createLabel(frame, 130, '', 'CENTER')
        if mainFrameWidthType == 2 then
            labelBag:SetWidth(110)
        end
        labelBag:SetPoint('LEFT', labelTime, 'RIGHT', 3, 0)
        frame.labelBag = labelBag
        labelBag.frame = frame

        local labelAuction = XUI.createLabel(frame, 150, '', 'CENTER')
        if mainFrameWidthType == 2 then
            labelAuction:SetWidth(80)
        end
        labelAuction:SetPoint('LEFT', labelBag, 'RIGHT', 3, 0)
        frame.labelAuction = labelAuction
        labelAuction.frame = frame

        local labelDeal = XUI.createLabel(frame, 130, '', 'CENTER')
        labelDeal:SetPoint('LEFT', labelAuction, 'RIGHT', 3, 0)
        frame.labelDeal = labelDeal
        labelDeal.frame = frame

        local labelPrice = XUI.createLabel(frame, 210, '', 'CENTER')
        labelPrice:SetPoint('LEFT', labelDeal, 'RIGHT', 3, 0)
        frame.labelPrice = labelPrice
        labelPrice.frame = frame

        local labelSeller = XUI.createLabel(frame, 80, '', 'CENTER')
        if mainFrameWidthType == 2 then
            labelSeller:SetWidth(150)
        end
        labelSeller:SetPoint('LEFT', labelPrice, 'RIGHT', 3, 0)
        frame.labelSeller = labelSeller
        labelSeller.frame = frame

        local deleteButton = nil
        if mainFrameWidthType == 1 then
            deleteButton = XUI.createButton(frame, 30, '删')
            deleteButton:SetPoint('LEFT', labelSeller, 'RIGHT', 3, 0)
            deleteButton:SetScript('OnClick', itemDeleteClick)
            deleteButton.frame = frame
            deleteButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            deleteButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local rubbishButton = nil
        if mainFrameWidthType == 1 then
            rubbishButton = XUI.createButton(frame, 30, '圾')
            rubbishButton:SetPoint('LEFT', deleteButton, 'RIGHT', 0, 0)
            rubbishButton:SetScript('OnClick', itemRubbishClick)
            rubbishButton.frame = frame
            rubbishButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            rubbishButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local settingButton = nil
        if mainFrameWidthType == 1 then
            settingButton = XUI.createButton(frame, 30, '设')
            settingButton:SetPoint('LEFT', rubbishButton, 'RIGHT', 0, 0)
            settingButton:SetScript('OnClick', itemSettingClick)
            settingButton.frame = frame
            settingButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            settingButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local enableButton = nil
        if mainFrameWidthType == 1 then
            enableButton = XUI.createButton(frame, 30, '')
            enableButton:SetPoint('LEFT', settingButton, 'RIGHT', 0, 0)
            enableButton:SetScript('OnClick', itemEnableClick)
            frame.enableButton = enableButton
            enableButton.frame = frame
            enableButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            enableButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local starButton = nil
        if mainFrameWidthType == 1 then
            starButton = XUI.createButton(frame, 30, '星')
            starButton:SetPoint('LEFT', enableButton, 'RIGHT', 0, 0)
            starButton:SetScript('OnClick', itemStarClick)
            frame.starButton = starButton
            starButton.frame = frame
            starButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            starButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local itemCanCraftButton = nil
        if mainFrameWidthType == 1 then
            itemCanCraftButton = XUI.createButton(frame, 30, '造')
            itemCanCraftButton:SetPoint('LEFT', starButton, 'RIGHT', 0, 0)
            itemCanCraftButton:SetScript('OnClick', itemCanCraftClick)
            frame.itemCanCraftButton = itemCanCraftButton
            itemCanCraftButton.frame = frame
            itemCanCraftButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
            itemCanCraftButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
        end

        local itemRefreshButton = XUI.createButton(frame, 30, '刷')
        if mainFrameWidthType == 1 then
            itemRefreshButton:SetPoint('LEFT', itemCanCraftButton, 'RIGHT', 0, 0)
        else
            itemRefreshButton:SetPoint('LEFT', labelSeller, 'RIGHT', 3, 0)
        end
        itemRefreshButton:SetScript('OnClick', itemRefreshClick)
        itemRefreshButton.frame = frame
        itemRefreshButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
        itemRefreshButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)

        local itemCleanButton = XUI.createButton(frame, 30, '清')
        itemCleanButton:SetPoint('LEFT', itemRefreshButton, 'RIGHT', 0, 0)
        itemCleanButton:SetScript('OnClick', itemCleanClick)
        itemCleanButton.frame = frame
        itemCleanButton:SetScript('OnEnter', function(self) self.frame.bg:Show() end)
        itemCleanButton:SetScript('OnLeave', function(self) self.frame.bg:Hide() end)
    end
end

reloadBuyList = function()
    if not mainFrame then return end
    for _, item in ipairs(materialFrames) do
        item:Hide()
    end
    materialFrames = {}
    local enabledBuyList = {}
    for _, item in ipairs(XBuyItemList) do
        if item['enabled'] then
            table.insert(enabledBuyList, item)
        end
    end
    local buyPerRow = math.floor(mainFrameWidth / 96)
    local preRowFrame = mainFrame.materialFrame
    local preFrame = mainFrame.materialFrame
    for _index, item in ipairs(enabledBuyList) do
        local materialItemFrame = XAPI.CreateFrame('Frame', nil, mainFrame.materialFrame)
        materialItemFrame:SetSize(93, 30)

        if _index == 1 then
            materialItemFrame:SetPoint('TOPLEFT', mainFrame.materialFrame, 'TOPLEFT', 15, 0)
            preRowFrame = materialItemFrame
            preFrame = materialItemFrame
        elseif _index % buyPerRow == 1 then
            materialItemFrame:SetPoint('TOPLEFT', preRowFrame, 'BottomLeft', 0, 0)
            preRowFrame = materialItemFrame
            preFrame = materialItemFrame
        else
            materialItemFrame:SetPoint('LEFT', preFrame, 'RIGHT', 3, 0)
            preFrame = materialItemFrame
        end

        materialItemFrame.itemName = item['itemname']

        local icon = XUI.createItemIcon(materialItemFrame, 25, 25, item['itemname'])
        icon:SetPoint('LEFT', materialItemFrame, 'LEFT', 0, 0)

        local countLabel = XUI.createLabel(materialItemFrame, 60, '', 'LEFT')
        countLabel:SetPoint('LEFT', icon, 'RIGHT', 3, 0)
        materialItemFrame.countLabel = countLabel

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
            if IsLeftAltKeyDown() then
                XAPI.Auctionator_SearchExact(self.itemName)
            elseif IsLeftShiftKeyDown() then
                addMaterialQueryTaskByItemName(self.itemName)
                refreshUI()
            elseif IsLeftControlKeyDown() then
                XInfo.printBuyHistory(self.itemName)
            end
        end)

        materialItemFrame.refreshUI = function(self)
            local cprice = XBuy.getItemField(self.itemName, 'minbuyoutprice', 0)
            local bprice = XBuy.getItemField(self.itemName, 'price', 0)
            local cpriceStr = ''
            if cprice > 1000000 then
                cpriceStr = math.floor(cprice / 10000) .. ''
            else
                cpriceStr = (math.floor(cprice / 1000) / 10) .. ''
            end
            if cprice > bprice then
                cpriceStr = XUI.Color_Bad .. cpriceStr
            else
                cpriceStr = XUI.Color_Good .. cpriceStr
            end
            local bagCount = XInfo.getBagItemCount(self.itemName)
            local bagCountStr = XUI.getColor_MaterialCount(bagCount) .. bagCount
            self.countLabel:SetText(cpriceStr .. XUI.White .. '(' .. bagCountStr .. XUI.White .. ')')
        end

        table.insert(materialFrames, materialItemFrame)
    end
    local height = (math.ceil(#enabledBuyList / buyPerRow)) * 30
    mainFrame.materialFrame:SetHeight(height)
    mainFrame:SetHeight(mainFrameHeight + height)
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

    if buyPriceEnabled then
        mainFrame.buyPriceButton:SetText(XUI.Green .. '买价')
    else
        mainFrame.buyPriceButton:SetText(XUI.Red .. '买价')
    end

    if buyEnabled then
        mainFrame.buyButton:SetText(XUI.Green .. '购买')
    else
        mainFrame.buyButton:SetText(XUI.Red .. '购买')
    end

    if XSpeakWord.isRunning() then
        mainFrame.speakButton:SetText(XUI.Green .. '喊话')
    else
        mainFrame.speakButton:SetText(XUI.Red .. '喊话')
    end

    if XCraftQueue.isRunning() then
        mainFrame.craftQueueButton:SetText(XUI.Green .. '制造')
    else
        mainFrame.craftQueueButton:SetText(XUI.Red .. '制造')
    end

    if XAuctionBoard.mainFrame:IsVisible() then
        mainFrame.auctionBoardButton:SetText(XUI.Green .. '面板')
    else
        mainFrame.auctionBoardButton:SetText(XUI.Red .. '面板')
    end

    if XJewCount.mainFrame:IsVisible() then
        mainFrame.jewCountButton:SetText(XUI.Green .. '材料')
    else
        mainFrame.jewCountButton:SetText(XUI.Red .. '材料')
    end

    mainFrame.multiSellButton:SetText(dft_multiSellList[multiSell])

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

    local totalDealCount = 0
    local totalCraftCount = 0
    local totalBuyCount = 0
    local boardItem = XAuctionBoardList[1]
    if boardItem then
        for _, dataItem in ipairs(boardItem['data']) do
            totalDealCount = totalDealCount + dataItem['dealcount']
            totalCraftCount = totalCraftCount + dataItem['craftcount']
            totalBuyCount = totalBuyCount + dataItem['buycount']
        end
    end

    local emptyBagCountStr = XInfo.emptyBagCount .. ''
    if XInfo.emptyBagCount >= 20 then
        emptyBagCountStr = XUI.Color_Great .. emptyBagCountStr
    elseif XInfo.emptyBagCount >= 10 then
        emptyBagCountStr = XUI.Color_Good .. emptyBagCountStr
    elseif XInfo.emptyBagCount >= 5 then
        emptyBagCountStr = XUI.Color_Fair .. emptyBagCountStr
    elseif XInfo.emptyBagCount > 0 then
        emptyBagCountStr = XUI.Color_Poor .. emptyBagCountStr
    else
        emptyBagCountStr = XUI.Color_Bad .. emptyBagCountStr
    end

    local craftCount = XCraftQueue.getItemCount()
    local craftCountStr = craftCount .. ''
    if craftCount >= 20 then
        craftCountStr = XUI.Color_Worst .. craftCountStr
    elseif craftCount >= 10 then
        craftCountStr = XUI.Color_Bad .. craftCountStr
    elseif craftCount >= 5 then
        craftCountStr = XUI.Color_Poor .. craftCountStr
    elseif craftCount > 0 then
        craftCountStr = XUI.Color_Fair .. craftCountStr
    else
        craftCountStr = XUI.Color_Good .. craftCountStr
    end

    mainFrame:setTitle(1, XUI.Green .. XInfo.auctioningCount)
    mainFrame:setTitle(2, XUI.Green .. XInfo.auctionedCount)
    mainFrame:setTitle(3, XUI.Green .. (XUtils.round(XInfo.auctionedMoney / 10000)))
    mainFrame:setTitle(4, XUI.Green .. totalDealCount)
    mainFrame:setTitle(5, XUI.Green .. totalCraftCount)
    mainFrame:setTitle(6, XUI.Green .. totalBuyCount)
    mainFrame:setTitle(7, XUI.Green .. emptyBagCountStr)
    mainFrame:setTitle(8, XUI.Green .. craftCountStr)

    for _, materialItem in ipairs(materialFrames) do
        materialItem:refreshUI()
    end

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
        local minPriceSeller = item['minpriceseller']
        local maxPriceOther = item['maxpriceother']
        local lastPriceOther = item['lastpriceother']
        local stackCount = item['stackcount']
        local lowerCount = item['lowercount']
        local priceLowerCount = item['pricelowercount']
        local cDealCount = XAuctionBoard.getItemCount(itemName)

        local bagCount = XInfo.getBagItemCount(itemName)
        local bankCount = XInfo.getBankItemCount(itemName)
        local mailCount = XInfo.getMailItemCount(itemName)
        local totalCount = XInfo.getItemTotalCount(itemName)

        local auctionCount = XInfo.getAuctionItemCount(itemName)
        local validCount = getMyValidCount(itemName)

        local dealRate = XInfo.getItemInfoField(itemName, 'dealrate', 99)
        local dealCount = XInfo.getItemInfoField(itemName, 'dealcount', 0)

        local recipe = XInfo.getTradeSkillItem(itemName)

        local itemNameStr = string.sub(itemName, 1, 6);
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

        if not recipe then
            itemNameStr = itemNameStr .. XUI.Red .. '■'
        end

        local updateTimeStr = XUtils.formatTime(item['updatetime'])

        local bagCountStr = XUI.getColor_BagStackCount(bagCount, stackCount) .. 'B' .. bagCount
        local mailCountStr = XUI.getColor_MailCount(mailCount) .. 'M' .. mailCount
        local bankCountStr = XUI.getColor_BankCount(bankCount) .. bankCount
        local totalCountStr = XUI.getColor_TotalStackCount(totalCount, stackCount) .. 'T' .. totalCount

        local auctionCountStr = XUI.getColor_AuctionStackCount(auctionCount, stackCount) .. 'A' .. auctionCount
        local validCountStr = XUI.getColor_AuctionValidStackCount(validCount, stackCount) .. 'M' .. validCount
        local lowerCountStr = lowerCount .. ''
        if lowerCount > 5 then
            lowerCountStr = XUI.Color_Bad .. lowerCountStr
        elseif lowerCount > 0 then
            lowerCountStr = XUI.Color_Fair .. lowerCountStr
        else
            lowerCountStr = XUI.Color_Normal .. lowerCountStr
        end
        local priceLowerCountStr = priceLowerCount .. ''
        if priceLowerCount > 10 then
            priceLowerCountStr = XUI.Color_Bad .. priceLowerCountStr
        elseif priceLowerCount > 0 then
            priceLowerCountStr = XUI.Color_Fair .. priceLowerCountStr
        else
            priceLowerCountStr = XUI.Color_Normal .. priceLowerCountStr
        end

        local dealRateStr = XUI.getColor_DealRate(dealRate) .. 'R' .. XUtils.round(dealRate)
        local dealCountStr = XUI.getColor_DealCount(dealCount) .. 'D'
        if dealCount > 999 then
            dealCountStr = dealCountStr .. '999'
        else
            dealCountStr = dealCountStr .. dealCount
        end
        local cDealCountStr = XUI.getColor_DealCount(cDealCount * 3) .. cDealCount
        local stackCountStr = 'S' .. stackCount
        if stackCount > 4 then
            stackCountStr = XUI.Color_Worst .. stackCountStr
        elseif stackCount > 3 then
            stackCountStr = XUI.Color_Bad .. stackCountStr
        elseif stackCount > 2 then
            stackCountStr = XUI.Color_Great .. stackCountStr
        elseif stackCount > 1 then
            stackCountStr = XUI.Color_Good .. stackCountStr
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
        local lastPriceOtherStr = XUI.White .. XUtils.priceToString(lastPriceOther)

        local maxPriceOtherStr  = XUtils.priceToString(maxPriceOther)
        if maxPriceOther > minPriceOther * 1.3 then
            maxPriceOtherStr = XUI.Color_Great .. maxPriceOtherStr
        elseif maxPriceOther > minPriceOther * 1.1 then
            maxPriceOtherStr = XUI.Color_Good .. maxPriceOtherStr
        end

        local basePriceStr = XUI.White .. XUtils.priceToString(basePrice)

        if XUtils.inArray(minPriceSeller, XInfo.partnerList) then
            minPriceSeller = XUI.Orange .. string.sub(minPriceSeller, 1, 12)
        else
            if minPriceSeller then
                minPriceSeller = string.sub(minPriceSeller, 1, 12)
            else
                minPriceSeller = ''
            end
        end

        if frame.itemIndexButton then
            frame.itemIndexButton:SetText(idx)
        end
        frame.itemIcon:SetTexture(XAPI.GetItemIcon(itemId))
        frame.itemNameButton:SetText(itemNameStr)
        frame.itemNameButton:SetHighlight(star)

        frame.labelTime:SetText(updateTimeStr)
        if mainFrameWidthType == 1 then
            frame.labelBag:SetText(bankCountStr .. ' / ' .. mailCountStr
                .. XUI.White .. ' / ' .. bagCountStr .. XUI.White .. ' / ' .. totalCountStr)
            frame.labelAuction:SetText(auctionCountStr .. XUI.White .. ' / ' .. validCountStr
                .. XUI.White .. ' / ' .. priceLowerCountStr
                .. XUI.White .. ' / ' .. lowerCountStr .. XUI.White)
            frame.labelDeal:SetText(dealRateStr
                .. XUI.White .. ' / ' .. dealCountStr
                .. XUI.White .. ' / ' .. cDealCountStr
                .. XUI.White .. ' / ' .. stackCountStr)
            frame.labelPrice:SetText(minPriceOtherStr
                .. XUI.White .. ' / ' .. lastPriceOtherStr
                .. XUI.White .. ' / ' .. maxPriceOtherStr .. ' / ' .. basePriceStr)
            frame.labelSeller:SetText(minPriceSeller)
        else
            frame.labelBag:SetText(mailCountStr
                .. XUI.White .. ' / ' .. bagCountStr .. XUI.White .. ' / ' .. totalCountStr)
            frame.labelAuction:SetText(auctionCountStr .. XUI.White .. ' / ' .. validCountStr)
            frame.labelDeal:SetText(dealRateStr
                .. XUI.White .. ' / ' .. dealCountStr
                .. XUI.White .. ' / ' .. cDealCountStr
                .. XUI.White .. ' / ' .. stackCountStr)
            frame.labelPrice:SetText(minPriceOtherStr
                .. XUI.White .. ' / ' .. lastPriceOtherStr
                .. XUI.White .. ' / ' .. maxPriceOtherStr .. ' / ' .. basePriceStr)
            frame.labelSeller:SetText(minPriceSeller)
        end

        if frame.enableButton then
            if enabled then
                frame.enableButton:SetText(XUI.Green .. '起')
            else
                frame.enableButton:SetText(XUI.Red .. '停')
            end
        end

        if frame.starButton then
            if star then
                frame.starButton:SetText(XUI.Green .. '星')
            else
                frame.starButton:SetText(XUI.Red .. '星')
            end
        end

        if frame.itemCanCraftButton then
            if canCraft then
                frame.itemCanCraftButton:SetText(XUI.Green .. '造')
            else
                frame.itemCanCraftButton:SetText(XUI.Red .. '禁')
            end
        end
    end
end

start = function()
    isStarted = true
    err453Count = 0
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0
    refreshUI()
end

stop = function()
    if curTask and curTask['action'] == 'query' then
        local item = XItemList[curTask['index']];
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

    if buyPriceEnabled then
        if lastMaterialTaskTime + dft_materialTaskInterval < time() then
            lastMaterialTaskTime = time()
            if #XBuyItemList > 0 then
                local tEnabledIndex = -1
                local tAvailableIndex = -1
                for idx = 0, #XBuyItemList - 1 do
                    local tIndex = ((materialQueryIndex + idx) % #XBuyItemList) + 1
                    local item = XBuyItemList[tIndex]
                    if item ~= nil then
                        if item['enabled'] then
                            if tEnabledIndex == -1 then
                                tEnabledIndex = tIndex
                            end
                        end
                        if item['minbuyoutprice'] <= item['price'] then
                            if tAvailableIndex == -1 then
                                tAvailableIndex = tIndex
                            end
                        end
                    end
                end

                if tAvailableIndex ~= -1 then
                    materialQueryIndex = tAvailableIndex
                elseif tEnabledIndex ~= -1 then
                    materialQueryIndex = tEnabledIndex
                end

                local item = XBuyItemList[materialQueryIndex]
                if item then
                    addMaterialQueryTaskByItemName(item['itemname'])
                    curTask = taskList[1]
                    table.remove(taskList, 1)
                    curTask['starttime'] = time()

                    processMaterialQueryTask(curTask)
                    refreshUI()
                    return
                end
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
        minpriceseller = '',
        minpriceotherispartner = false,
        maxpriceother = 0,
        lastpriceother = 0,
    }
    resetItem(item)
    table.insert(XItemList, item)
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
    item['minpriceseller'] = ''
    item['minpriceotherispartner'] = false
    item['maxpriceother'] = 0
    if not keepUpdateTime then
        item['updatetime'] = 0
    end
end

resetItemByName = function(itemName)
    for _, item in ipairs(XItemList) do
        if item['itemname'] == itemName then
            resetItem(item)
            return
        end
    end
end

getItem = function(itemName)
    for _, item in ipairs(XItemList) do
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

    local item = XItemList[index];
    if not item then return end
    local itemName = item['itemname']

    local important = checkImportant(item)
    local deltaPrice = 0
    local tItem = XAuctionCenter.getItem(itemName)
    if tItem then
        local materialName = XInfo.getMaterialName(itemName)
        local materialBuyPrice = XBuy.getItemField(materialName, 'price', 0)
        deltaPrice = tItem['lastpriceother'] - materialBuyPrice
    end

    if force then
        resetItem(item)
        local task = {
            action = 'query',
            index = index,
            page = 1,
            timeout = dft_taskTimeout,
            important = important,
            deltaprice = deltaPrice,
            itemname = itemName
        }
        table.insert(taskList, 1, task)
        return
    end

    XInfo.reloadBag()

    local idx = 0
    for _index, task in pairs(taskList) do
        if task['action'] == 'query' then
            if important then
                if (task['important'] and task['deltaprice'] < deltaPrice) or (not task['important']) then
                    idx = _index
                    break
                end
            else
                if (not task['important']) and task['deltaprice'] < deltaPrice then
                    idx = _index
                    break
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
        deltaprice = deltaPrice,
        itemname = itemName
    }
    if idx == 0 then
        table.insert(taskList, task)
    else
        table.insert(taskList, idx, task)
    end
end

addQueryTaskByItemName = function(itemName, force)
    for i, item in ipairs(XItemList) do
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
        timeout = 30
    }
    table.insert(taskList, 1, task)
end

getNextQueryTask = function()
    local nextTaskIndex = -1

    if queryStarFlag then
        for idx = 0, #XItemList - 1 do
            local index = ((starQueryIndex + idx) % #XItemList) + 1
            local item = XItemList[index]
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
        for idx = 0, #XItemList - 1 do
            local index = ((queryIndex + idx) % #XItemList) + 1
            local item = XItemList[index]
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
        local item = XItemList[nextTaskIndex];
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
    local dealCount = XInfo.getItemInfoField(item['itemname'], 'dealcount', 0)
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
    for idx, item in ipairs(XItemList) do
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
                    -- local auctionCount = XInfo.getAuctionItemCount(item['itemname'])
                    local itemTotalCount = XInfo.getItemTotalCount(item['itemname'])
                    local stackCount = item['stackcount']
                    local materialCount = XInfo.getMaterialBagCount(item['itemname'])
                    local dealCount = XInfo.getItemInfoField(item['itemname'], 'dealcount', 0)

                    -- local subCount = 0
                    -- if checkImportant(item) then
                    --     subCount = stackCount - bagCount
                    -- else
                    --     subCount = stackCount - auctionCount - bagCount
                    -- end
                    local subCount = stackCount - bagCount
                    local maxCount = math.ceil(dealCount / 10)
                    if checkImportant(item) then
                        maxCount = dft_maxCraftCount
                    elseif maxCount < 1 then
                        maxCount = 1
                    elseif maxCount > dft_maxCraftCount then
                        maxCount = dft_maxCraftCount
                    end
                    if subCount > maxCount - itemTotalCount then
                        subCount = maxCount - itemTotalCount
                    end
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
                for _, item in ipairs(XItemList) do
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
            if timeLeft < 2 then
                XAPI.CancelAuction(i)

                for _, item in ipairs(XItemList) do
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

puton = function(isForce)
    if isForce == nil then isForce = false end
    XInfo.reloadBag()
    XInfo.reloadAuction()
    local count = 0
    local queue = {}
    for i, item in ipairs(XItemList) do
        if item['enabled'] then
            local bagCount = XInfo.getBagItemCount(item['itemname'])
            local validCount = getMyValidCount(item['itemname'])
            local stackCount = item['stackcount']
            if checkImportant(item) then
                local multiple = dft_multiSellList[multiSell]
                if multiple == '双倍' then
                    stackCount = stackCount * 2
                elseif multiple == '全部' then
                    stackCount = 99
                end
            end
            if isForce or bagCount > 0 then
                if item['minpriceother'] >= item['baseprice'] and validCount < stackCount and XCraftQueue.getCurItemName() ~= item['itemname'] then
                    table.insert(queue, i)
                    count = count + 1
                end
            end
        end
    end
    for _, idx in ipairs(queue) do
        addQueryTaskByIndex(idx)
    end
    refreshUI()
    return count
end

putonNoPrice = function()
    local count = 0
    local starQueue = {}
    local unStarQueue = {}
    for i, item in ipairs(XItemList) do
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
    for i, item in ipairs(XItemList) do
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
    XJewTool.refreshUI()
    xdebug.info('----------')
    if (not curTask) and #taskList <= 0 then
        xdebug.info('暂无任务')
        return
    end
    for i = #taskList, 1, -1 do
        local task = taskList[i]
        if task['action'] == 'query' then
            xdebug.info('[' .. i .. ']查询: ' .. XItemList[task['index']]['itemname'])
        elseif task['action'] == 'material' then
            xdebug.info('[' .. i .. ']查询: ' .. task['itemname'])
        else
            xdebug.info('[' .. i .. ']不支持的任务类型')
        end
    end
    if curTask then
        if curTask['action'] == 'query' then
            xdebug.info('当前任务：查询: ' .. XItemList[curTask['index']]['itemname'])
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
    for _, item in ipairs(XItemList) do
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
        for _, item in ipairs(XItemList) do
            if XUtils.stringContains(item['itemname'], itemName) then
                if item['enabled'] ~= nil and item['enabled'] then
                    if all or (not item['star']) then
                        local vendorPrice = XInfo.getItemInfoField(item['itemname'], 'vendorprice', 0)
                        local dealRate = XInfo.getItemInfoField(item['itemname'], 'dealrate', 99)
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
    for _, item in ipairs(XItemList) do
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
            for _, item in ipairs(XItemList) do
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
    XUISortDialog.show('XAuctionCenter_Sort', XItemList, index, function()
        filterDisplayList()
    end)
end

itemMailClick = function(this)
    local index = this.frame.index
    local item = XItemList[index];
    if not item then return end

    local count = 5
    if IsShiftKeyDown() then
        local bagItem = XInfo.getBagItem(item['itemname'])
        if not bagItem then
            xdebug.error('背包中未找到该物品')
            return
        end
        count = #bagItem['positions']
    end

    XUtils.sendMail(item['itemname'], count)
    refreshUI()
end

itemReceiveClick = function(this)
    local index = this.frame.index
    local item = XItemList[index];
    if not item then return end

    if IsLeftShiftKeyDown() then
        XUtils.receiveMail(item['itemname'], true)
    else
        XUtils.receiveMail(item['itemname'])
    end
    refreshUI()
end

itemToBankClick = function(this)
    local index = this.frame.index
    local item = XItemList[index];
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
    local item = XItemList[index];
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
    local item = XItemList[index];
    if not item then return end

    if IsLeftAltKeyDown() then
        XAPI.Auctionator_SearchExact(item['itemname'])
    elseif IsLeftControlKeyDown() then
        XInfo.printBuyHistory(item['itemname'])
    elseif IsLeftShiftKeyDown() then
        XCraftQueue.addItem(item['itemname'], 1, 'fulfil')
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
    local item = XItemList[index]
    if not item then return end

    XUIConfirmDialog.show(moduleName, '删除', '是否确定删除：' .. item['itemname'], function()
        table.remove(XItemList, index)
        filterDisplayList()
    end)
end

itemRubbishClick = function(this)
    local index = this.frame.index
    local item = XItemList[index]
    if not item then return end

    XUIConfirmDialog.show(moduleName, '确认', '是否确认设为垃圾', function()
        item['baseprice'] = 1
        item['stackcount'] = 1
        refreshUI()
    end)
end

itemSettingClick = function(this)
    local index = this.frame.index
    local item = XItemList[index]
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
    local item = XItemList[index];
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
    local item = XItemList[index];
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
    local item = XItemList[index];
    if not item then return end

    item['cancraft'] = not item['cancraft']
    refreshUI()
end

itemRefreshClick = function(this)
    local index = this.frame.index
    local item = XItemList[index];
    if not item then return end

    addQueryTaskByIndex(index, IsShiftKeyDown())
end

itemCleanClick = function(this)
    local index = this.frame.index
    local item = XItemList[index];
    if not item then return end

    cleanLower(item['itemname'])
end

itemOnEnter = function(self)
    local tindex = self.frame.index
    local titem = XItemList[tindex];
    if not titem then return end
    local itemid = XInfo.getItemId(titem['itemname'])
    if itemid > 0 then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. itemid) -- 显示物品信息
    end
    self.frame.bg:Show()
end

itemOnLeave = function(self)
    GameTooltip:Hide()
    self.frame.bg:Hide()
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
            err453Count = 0
            break
        end
        itemIndex = itemIndex + 1
    end
end

local function onMaterialBuyFailed()
    if not curTask then return end
    if curTask['action'] == 'material' and curTask['status'] == 'buying' then
        xdebug.error('Material buy failed')
        finishTask()
    end
end

processQueryTask = function(task)
    XInfo.reloadBag()
    XInfo.reloadAuction()
    local index = task['index']
    local item = XItemList[index]
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

                    if XInfo.isMe(seller) then
                        if buyoutPrice <= item['minpriceother'] then
                            table.insert(item['myvalidlist'], buyoutPrice)
                        end
                    else
                        if buyoutPrice < item['minpriceother'] then
                            local newPriceList = {}
                            for _, tprice in ipairs(item['myvalidlist']) do
                                if tprice <= buyoutPrice then
                                    table.insert(newPriceList, tprice)
                                end
                            end
                            item['myvalidlist'] = newPriceList
                            item['minpriceother'] = buyoutPrice
                            item['minpriceseller'] = seller
                            item['minpriceotherispartner'] = XInfo.isPartner(seller)
                        elseif buyoutPrice == item['minpriceother'] then
                            if not item['minpriceotherispartner'] then
                                item['minpriceotherispartner'] = XInfo.isPartner(seller)
                            end
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
                if item['minpriceotherispartner'] then
                    price = item['minpriceother']
                else
                    price = item['minpriceother'] - dft_deltaPrice
                end
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
            if checkImportant(item) then
                local multiple = dft_multiSellList[multiSell]
                if multiple == '双倍' then
                    targetCount = targetCount * 2
                elseif multiple == '全部' then
                    targetCount = 99
                end
            end
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

        local stackSize = 1
        local stackCount = task['count']
        if XUtils.inArray(item['itemname'], XInfo.materialListSS) then
            stackSize = task['count']
            if stackSize > 20 then
                stackSize = 20
            end
            stackCount = 1
        end

        XAPI.PostAuction(task['price'], task['price'], 1, stackSize, stackCount)

        xdebug.info('拍卖：' .. item['itemname'] .. '(' .. XUtils.priceToMoneyString(task['price']) .. ')')
        for _ = 1, stackSize * stackCount do
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

        for _, item in ipairs(XBuyItemList) do
            if task['itemname'] == item['itemname'] then
                item['minbuyoutprice'] = minBuyoutPrice
                item['updatetime'] = time()
                break
            end
        end

        if buyEnabled then
            task['status'] = 'buying'
        else
            finishTask()
            startNextTask()
            return
        end
    elseif task['status'] == 'buying' then
        local buyingItem = XBuy.getItem(task['itemname'])
        if buyingItem == nil then
            finishTask()
            startNextTask()
            return
        end
        local itemIndex = 1
        local found = false
        while true do
            local res = { XAPI.GetAuctionItemInfo('list', itemIndex) }
            local timeLeft = XAPI.GetAuctionItemTimeLeft('list', itemIndex)
            local itemName = res[1]
            local stackCount = res[3]
            local bidStart = res[8]
            local bidIncrease = res[9]
            local buyoutPrice = res[10]
            local bidPrice = res[11]
            local isMine = res[12]
            local seller = res[14]

            if not itemName then break end

            if itemName == task['itemname'] then
                local nextBidPrice = 0
                if bidPrice == 0 then
                    nextBidPrice = bidStart
                else
                    nextBidPrice = bidPrice + bidIncrease
                end

                if (timeLeft < 3 and nextBidPrice / stackCount <= buyingItem['price'])
                    or (buyoutPrice > 0 and buyoutPrice / stackCount <= buyingItem['price']) then
                    if (not XInfo.isMe(seller)) and (not isMine) and (not XInfo.isPartner(seller)) then
                        found = true
                    end
                end

                if (not XInfo.isMe(seller)) and (not isMine) and (not XInfo.isPartner(seller)) then
                    if buyoutPrice / stackCount <= buyingItem['price'] and buyoutPrice > 0 then
                        xdebug.info('Buyout: ' .. itemName .. ' (' .. stackCount .. ')'
                            .. '    ' .. XUtils.priceToMoneyString(buyoutPrice / stackCount))
                        XAPI.PlaceAuctionBid('list', itemIndex, buyoutPrice)
                        XAuctionBoard.addItem(itemName, 'buy', stackCount)
                        break
                    elseif timeLeft < 3 and nextBidPrice / stackCount <= buyingItem['price'] then
                        xdebug.info('Bid: ' .. itemName .. ' (' .. stackCount .. ')'
                            .. '    ' .. XUtils.priceToMoneyString(nextBidPrice / stackCount))
                        XAPI.PlaceAuctionBid('list', itemIndex, nextBidPrice)
                        XAuctionBoard.addItem(itemName, 'buy', stackCount)
                        break
                    end
                end
            end
            itemIndex = itemIndex + 1
        end

        if not found then
            finishTask()
            startNextTask()
            return
        end
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
        elseif curTask['action'] == 'material' and curTask['status'] ~= 'buying' then
            processMaterialQueryTask(curTask)
        end
        refreshUI()
        return
    end

    puton()

    startNextTask()
end

local function onFastUpdate()
    if not isStarted then return end

    if curTask then
        if curTask['action'] == 'material' and curTask['status'] == 'buying' then
            processMaterialQueryTask(curTask)
        end
        return
    end
end

-- Events
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initData()
    initUI()
    reloadBuyList()
    filterDisplayList()
    refreshUI()
end)

XJewTool.registerEventCallback(moduleName, 'AUCTION_ITEM_LIST_UPDATE', onQueryItemListUpdate)
XJewTool.registerEventCallback(moduleName, 'UI_ERROR_MESSAGE', function(_, _, code, message)
    if code == 28 then
        onMaterialBuyFailed()
    elseif code == 453 then
        err453Count = err453Count + 1
        if err453Count > 30 then
            stop()
        end
    end
end)

XJewTool.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function()
    stop()
    if mainFrame then mainFrame:Hide() end
end)

XJewTool.registerEventCallback(moduleName, 'CHAT_MSG_SYSTEM', function(...)
    local text = select(3, ...)
    if text == ERR_AUCTION_STARTED then
        -- TODO 这里干嘛用的
        -- onAuctionSuccess()
    elseif XUtils.stringStartsWith(text, '你拍卖的') and XUtils.stringEndsWith(text, '已经售出。') then
        local itemname = string.sub(text, string.len('你拍卖的') + 1, string.len(text) - string.len('已经售出。'))
        local tindex = nil
        for i = 1, #XItemList do
            if XItemList[i]['itemname'] == itemname then
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

XJewTool.registerUpdateCallback(moduleName, onUpdate)
XJewTool.registerFastUpdateCallback(moduleName, onFastUpdate)

XJewTool.registerRefreshCallback(moduleName, refreshUI)

XBuy.registerItemChangeCallback(moduleName, function()
    reloadBuyList()
end)

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
XAuctionCenter.addMaterialQueryTaskByItemName = addMaterialQueryTaskByItemName
XAuctionCenter.getItem = getItem
XAuctionCenter.printItemsByName = printItemsByName
XAuctionCenter.setPriceByName = setPriceByName
XAuctionCenter.getMyValidCount = getMyValidCount
XAuctionCenter.checkImportantByName = checkImportantByName
