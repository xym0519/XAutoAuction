XAuctionCenter = {}
local moduleName = 'XAuctionCenter'

-- Variable definition
local mainFrame = nil

local dft_minPrice = 9999999
local dft_maxPrice = 2180000
local dft_basePriceRate = 1.5
local dft_roundInterval = 3
local dft_taskInterval = 1
local dft_taskTimeout = 30
local dft_filterList = { '全部', '星星', '优质', '可售', '有效', '价低', '无效', '垃圾', '不做', '邮寄', '收件', '量大' }
local dft_deltaPrice = 10
local dft_postdelay = 2
local dft_autoCleanInterval = 60
local dft_oldInterval = 1800
local dft_maxCraftCount = 20

local dft_buttonWidth = 45
local dft_buttonGap = 1
local dft_sectionGap = 10

local autoClean = false

local displayList = {}
local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local isStarted = false
local taskList = {}
local curTask = nil
local lastTaskFinishTime = 0
local lastAutoCleanTime = 0

local queryIndex = 1
local starQueryIndex = 1
local queryStarFlag = true

local queryRound = 1
local queryRoundFinishTime = 0

local cleaningItems = {}
local craftRunning = false

-- Function definition
local initData
local resetData
local initUI
local refreshUI
local filterDisplayList

local start
local stop
local finishTask
local addItem
local resetItem
local resetItemByName
local getItem
local addQueryTaskByIndex
local addQueryTaskByItemName
local insertAuctionTaskByIndex
local insertCleanLowerTask

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

-- Function implemention
initData = function()
    if not XAutoAuctionList then return end
    for _, item in ipairs(XAutoAuctionList) do
        item['lastround'] = -99
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

    queryRound = 1
    queryRoundFinishTime = 0
end

initUI = function()
    mainFrame = XUI.createFrame('XAuctionCenterMainFrame', 1095, 430)
    mainFrame:SetFrameStrata('HIGH')
    mainFrame.title:SetText('自动拍卖')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local auctionBoardButton = XUI.createButton(mainFrame, dft_buttonWidth, '面板')
    auctionBoardButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -30, 0)
    auctionBoardButton:SetScript('OnClick', function()
        XAuctionBoard.toggle()
    end)

    local craftQueueButton = XUI.createButton(mainFrame, dft_buttonWidth, '制造')
    craftQueueButton:SetPoint('RIGHT', auctionBoardButton, 'LEFT', -3, 0)
    craftQueueButton:SetScript('OnClick', function()
        XCraftQueue.toggle()
    end)

    local jewCountButton = XUI.createButton(mainFrame, dft_buttonWidth, '材料')
    jewCountButton:SetPoint('RIGHT', craftQueueButton, 'LEFT', -3, 0)
    jewCountButton:SetScript('OnClick', function()
        XJewCount.toggle()
    end)

    local autoSpeakButton = XUI.createButton(mainFrame, dft_buttonWidth, '喊话')
    autoSpeakButton:SetPoint('RIGHT', jewCountButton, 'LEFT', -3, 0)
    autoSpeakButton:SetScript('OnClick', function()
        XAutoSpeak.toggle()
    end)

    local preButton = XUI.createButton(mainFrame, dft_buttonWidth, '上页')
    preButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    preButton:SetScript('OnClick', function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, dft_buttonWidth, '下页')
    nextButton:SetPoint('LEFT', preButton, 'RIGHT', dft_buttonGap, 0)
    nextButton:SetScript('OnClick', function()
        if displayPageNo < math.ceil(#displayList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            refreshUI()
        end
    end)

    local startButton = XUI.createButton(mainFrame, dft_buttonWidth, '开始')
    startButton:SetPoint('LEFT', nextButton, 'RIGHT', dft_sectionGap, 0)
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
        puton(true)
    end)

    local putonNoPriceButton = XUI.createButton(mainFrame, dft_buttonWidth, '无价')
    putonNoPriceButton:SetPoint('LEFT', putonButton, 'RIGHT', dft_buttonGap, 0)
    putonNoPriceButton:SetScript('OnClick', function()
        putonNoPrice()
    end)

    local putonOldButton = XUI.createButton(mainFrame, dft_buttonWidth, '未刷')
    putonOldButton:SetPoint('LEFT', putonNoPriceButton, 'RIGHT', dft_buttonGap, 0)
    putonOldButton:SetScript('OnClick', function()
        putonOld()
    end)

    local craftAllButton = XUI.createButton(mainFrame, dft_buttonWidth, '制造')
    craftAllButton:SetPoint('LEFT', putonOldButton, 'RIGHT', dft_buttonGap, 0)
    craftAllButton:SetScript('OnClick', function()
        addCraftQueue(true)
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

    local refreshButton = XUI.createButton(mainFrame, dft_buttonWidth, '刷新')
    refreshButton:SetPoint('LEFT', cleanShortButton, 'RIGHT', dft_sectionGap, 0)
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

    local firstButton = XUI.createButton(mainFrame, dft_buttonWidth, '首页')
    firstButton:SetPoint('TOPLEFT', preButton, 'BOTTOMLEFT')
    firstButton:SetScript('OnClick', function()
        displayPageNo = 0
        refreshUI()
    end)

    local lastButton = XUI.createButton(mainFrame, dft_buttonWidth, '末页')
    lastButton:SetPoint('LEFT', firstButton, 'RIGHT', dft_buttonGap, 0)
    lastButton:SetScript('OnClick', function()
        displayPageNo = math.ceil(#displayList / displayPageSize) - 1;
        refreshUI()
    end)

    local filter1Button = XUI.createButton(mainFrame, dft_buttonWidth, '优质')
    filter1Button:SetPoint('LEFT', lastButton, 'RIGHT', dft_sectionGap, 0)
    filter1Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '优质')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        displayPageNo = 0
        refreshUI()
    end)

    local filter2Button = XUI.createButton(mainFrame, dft_buttonWidth, '量大')
    filter2Button:SetPoint('LEFT', filter1Button, 'RIGHT', dft_buttonGap, 0)
    filter2Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '量大')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        displayPageNo = 0
        refreshUI()
    end)

    local filter3Button = XUI.createButton(mainFrame, dft_buttonWidth, '邮寄')
    filter3Button:SetPoint('LEFT', filter2Button, 'RIGHT', dft_buttonGap, 0)
    filter3Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '邮寄')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        displayPageNo = 0
        refreshUI()
    end)

    local filter4Button = XUI.createButton(mainFrame, dft_buttonWidth, '收件')
    filter4Button:SetPoint('LEFT', filter3Button, 'RIGHT', dft_buttonGap, 0)
    filter4Button:SetScript('OnClick', function()
        XAPI.UIDropDownMenu_SetText(mainFrame.filterDropDown, '收件')
        mainFrame.filterBox:SetText('')
        filterDisplayList()
        displayPageNo = 0
        refreshUI()
    end)

    local filterDropDown = XUI.createDropDown(mainFrame, 80, dft_filterList, '优质',
        function(value)
            filterDisplayList()
            displayPageNo = 0
            refreshUI()
        end)
    filterDropDown:SetPoint('LEFT', filter4Button, 'RIGHT', -15, 0)
    mainFrame.filterDropDown = filterDropDown

    local filterBox = XUI.createEditbox(mainFrame, 90)
    filterBox:SetPoint('LEFT', filterDropDown, 'RIGHT', -5, 0)
    filterBox:SetScript('OnEnterPressed', function(self)
        self:ClearFocus();
        displayPageNo = 0
        filterDisplayList()
        refreshUI()
    end)
    filterBox:SetScript('OnEscapePressed', function(self)
        self:SetText('')
        self:ClearFocus();
        displayPageNo = 0
        filterDisplayList()
        refreshUI()
    end)
    mainFrame.filterBox = filterBox

    local settingButton = XUI.createButton(mainFrame, dft_buttonWidth, '添加')
    settingButton:SetPoint('LEFT', filterBox, 'RIGHT', dft_sectionGap, 0)
    settingButton:SetScript('OnClick', function()
        displaySettingItem = nil
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
        end, { { Name = '宝石名称' }, { Name = '基准价格' }, { Name = '默认价格' }, { Name = '拍卖数量' } }, '添加')
    end)

    local checkRecipeButton = XUI.createButton(mainFrame, dft_buttonWidth, '配方')
    checkRecipeButton:SetPoint('LEFT', settingButton, 'RIGHT', dft_buttonGap, 0)
    checkRecipeButton:SetScript('OnClick', function()
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
    end)

    local priceButton = XUI.createButton(mainFrame, dft_buttonWidth, '调价')
    priceButton:SetPoint('LEFT', checkRecipeButton, 'RIGHT', dft_buttonGap, 0)
    priceButton:SetScript('OnClick', function()
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
    end)

    local autoCleanButton = XUI.createButton(mainFrame, dft_buttonWidth, '清理')
    autoCleanButton:SetPoint('LEFT', priceButton, 'RIGHT', dft_buttonGap, 0)
    autoCleanButton:SetScript('OnClick', function()
        autoClean = not autoClean
        refreshUI()
    end)
    mainFrame.autoCleanButton = autoCleanButton

    local lastWidget = nil
    for i = 1, displayPageSize do
        local frame = XAPI.CreateFrame('Frame', nil, mainFrame)
        frame:SetSize(mainFrame:GetWidth(), 30)

        if i == 1 then
            frame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 0, -90)
        else
            frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -2)
        end

        frame:Hide()

        local itemIndexButton = XUI.createButton(frame, 35, '999')
        itemIndexButton:SetPoint('LEFT', frame, 'LEFT', 15, 0)
        itemIndexButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            XUISortDialog.show('XAuctionCenter_Sort', XAutoAuctionList, idx, function()
                refreshUI()
            end)
        end)
        frame.itemIndexButton = itemIndexButton
        itemIndexButton.frame = frame

        local itemMailButton = XUI.createButton(frame, 30, 'U')
        itemMailButton:SetPoint('LEFT', itemIndexButton, 'RIGHT', 0, 0)
        itemMailButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
            if not item then return end

            if not XAPI.IsMailBoxOpen() then
                xdebug.error('请先打开邮箱')
                return
            end

            XInfo.reloadBag()
            local bagItem = XInfo.getBagItem(item['itemname'])
            if not bagItem then
                xdebug.error('背包中未找到该物品')
                return
            end

            local batchCount = 5
            if IsShiftKeyDown() then batchCount = 12 end

            if bagItem['count'] < batchCount then
                xdebug.error(item['itemname'] .. '数量不足')
                return
            end

            for t = 1, 12 do
                XAPI.ClickSendMailItemButton(t, true)
            end
            for pidx = 1, batchCount do
                local position = bagItem['positions'][pidx];
                XAPI.C_Container_PickupContainerItem(position[1], position[2])

                XAPI.ClickSendMailItemButton(pidx)
            end
            XAPI.SendMail('阿肌', 'P-' .. item['itemname'] .. '-' .. batchCount)
            xdebug.info(item['itemname'] .. '发送成功')
            XInfo.reloadBag()
            XInfo.reloadMail()
            refreshUI()
        end)
        frame.itemMailButton = itemMailButton
        itemMailButton.frame = frame

        local itemReceiveButton = XUI.createButton(frame, 30, 'R')
        itemReceiveButton:SetPoint('LEFT', itemMailButton, 'RIGHT', 0, 0)
        itemReceiveButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
            if not item then return end

            if not XAPI.IsMailBoxOpen() then
                xdebug.error('请先打开邮箱')
                return
            end

            local mailCount = XAPI.GetInboxNumItems()
            if mailCount <= 0 then
                xdebug.error('没有邮件')
                return
            end

            XInfo.reloadBag()

            if XInfo.emptyBagCount <= 0 then
                xdebug.error('包裹已满')
                return
            end

            for midx = 1, mailCount do
                local mailInfo = { XAPI.GetInboxHeaderInfo(midx) }
                local subject = mailInfo[4]
                local itemCount = mailInfo[8]
                if itemCount then
                    if itemCount > 0 then
                        local _itemName, _itemCount = string.match(subject, 'P%-([^-]*)%-(.*)')
                        if _itemName and _itemCount then
                            if _itemName == item['itemname'] then
                                for iidx = 1, 12 do
                                    local _titemName = XAPI.GetInboxItem(midx, iidx)
                                    if _titemName == item['itemname'] then
                                        XAPI.TakeInboxItem(midx, iidx)
                                        break
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end

            xdebug.info('收取' .. item['itemname'])
            XInfo.reloadBag()
            XInfo.reloadMail()
            refreshUI()
        end)
        frame.itemReceiveButton = itemReceiveButton
        itemReceiveButton.frame = frame

        local itemNameButton = XUI.createButton(frame, 160, '')
        itemNameButton:SetPoint('LEFT', itemReceiveButton, 'RIGHT', 0, 0)
        itemNameButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
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
        end)
        itemNameButton:SetScript("OnEnter", function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
            if not item then return end
            local itemid = XInfo.getAuctionInfoField(item['itemname'], 'itemid')
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

        local labelTime = XUI.createLabel(frame, 50, '')
        labelTime:SetPoint('LEFT', itemNameButton, 'RIGHT', 3, 0)
        frame.labelTime = labelTime

        local labelBag = XUI.createLabel(frame, 110, '')
        labelBag:SetPoint('LEFT', labelTime, 'RIGHT', 3, 0)
        frame.labelBag = labelBag
        labelBag.frame = frame

        local labelAuction = XUI.createLabel(frame, 155, '')
        labelAuction:SetPoint('LEFT', labelBag, 'RIGHT', 3, 0)
        frame.labelAuction = labelAuction
        labelAuction.frame = frame

        local labelDeal = XUI.createLabel(frame, 90, '')
        labelDeal:SetPoint('LEFT', labelAuction, 'RIGHT', 3, 0)
        frame.labelDeal = labelDeal
        labelDeal.frame = frame

        local labelPrice = XUI.createLabel(frame, 150, '')
        labelPrice:SetPoint('LEFT', labelDeal, 'RIGHT', 3, 0)
        frame.labelPrice = labelPrice
        labelPrice.frame = frame

        local deleteButton = XUI.createButton(frame, 30, '删')
        deleteButton:SetPoint('LEFT', labelPrice, 'RIGHT', 0, 0)
        deleteButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local titem = XAutoAuctionList[idx]
            if idx <= #XAutoAuctionList then
                XUIConfirmDialog.show(moduleName, '删除', '是否确定删除：' .. titem['itemname'], function()
                    table.remove(XAutoAuctionList, idx)
                    refreshUI()
                end)
            end
        end)
        deleteButton.frame = frame

        local basePriceButton = XUI.createButton(frame, 30, '圾')
        basePriceButton:SetPoint('LEFT', deleteButton, 'RIGHT', 0, 0)
        basePriceButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            XUIConfirmDialog.show(moduleName, '确认', '是否确认重设低价', function()
                XInfo.reloadBag()
                XInfo.reloadAuction()
                local item = XAutoAuctionList[idx];
                if not item then return end
                item['baseprice'] = 1
                item['stackcount'] = 1
                refreshUI()
            end)
        end)
        basePriceButton.frame = frame

        local craftButton = XUI.createButton(frame, 30, '设')
        craftButton:SetPoint('LEFT', basePriceButton, 'RIGHT', 0, 0)
        craftButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            displaySettingItem = XAutoAuctionList[idx]
            if not displaySettingItem then return end

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
                    displaySettingItem['itemname'] = itemName
                    displaySettingItem['baseprice'] = basePrice
                    displaySettingItem['defaultprice'] = defaultPrice
                    displaySettingItem['stackcount'] = stackCount
                end
            end, {
                { Name = '宝石名称', Value = displaySettingItem['itemname'] },
                { Name = '基准价格', Value = displaySettingItem['baseprice'] },
                { Name = '默认价格', Value = displaySettingItem['defaultprice'] },
                { Name = '拍卖数量', Value = displaySettingItem['stackcount'] }
            }, '添加')
        end)
        craftButton.frame = frame

        local enableButton = XUI.createButton(frame, 30, '')
        enableButton:SetPoint('LEFT', craftButton, 'RIGHT', 0, 0)
        enableButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
            if not item then return end
            if item['enabled'] ~= true then
                item['enabled'] = true
            else
                item['enabled'] = false
            end
            refreshUI()
        end)
        frame.enableButton = enableButton
        enableButton.frame = frame

        local starButton = XUI.createButton(frame, 30, '星')
        starButton:SetPoint('LEFT', enableButton, 'RIGHT', 0, 0)
        starButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
            if not item then return end
            if item['star'] == nil or item['star'] == false then
                item['star'] = true
            else
                item['star'] = false
            end
            refreshUI()
        end)
        frame.starButton = starButton
        starButton.frame = frame

        local itemCanCraftButton = XUI.createButton(frame, 30, '造')
        itemCanCraftButton:SetPoint('LEFT', starButton, 'RIGHT', 0, 0)
        itemCanCraftButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
            if not item then return end

            item['cancraft'] = not item['cancraft']
            refreshUI()
        end)
        frame.itemCanCraftButton = itemCanCraftButton
        itemCanCraftButton.frame = frame

        local itemRefreshButton = XUI.createButton(frame, 30, '刷')
        itemRefreshButton:SetPoint('LEFT', itemCanCraftButton, 'RIGHT', 0, 0)
        itemRefreshButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
            if not item then return end

            addQueryTaskByIndex(idx, IsShiftKeyDown())
        end)
        itemRefreshButton.frame = frame

        local itemCleanButton = XUI.createButton(frame, 30, '清')
        itemCleanButton:SetPoint('LEFT', itemRefreshButton, 'RIGHT', 0, 0)
        itemCleanButton:SetScript('OnClick', function(self)
            local idx = self.frame.index
            local item = XAutoAuctionList[idx];
            if not item then return end

            cleanLower(item['itemname'])
        end)
        itemCleanButton.frame = frame

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end

    XInfo.reloadBag()
    XInfo.reloadAuction()

    if autoClean then
        mainFrame.autoCleanButton:SetText('清理')
    else
        mainFrame.autoCleanButton:SetText('不清')
    end

    if isStarted then
        mainFrame.startButton:SetText('停止')
    else
        mainFrame.startButton:SetText('开始')
    end

    local labelText = format('%s) ', #taskList)
    if not curTask then
        labelText = labelText .. '等待'
    else
        if curTask['action'] == 'query' then
            local item = XAutoAuctionList[curTask['index']]
            if item == nil then
                labelText = labelText .. '查询: 无'
            else
                labelText = labelText .. format('查询: [%s]%s', curTask['index'], item['itemname'])
            end
        elseif curTask['action'] == 'auction' then
            labelText = labelText .. '拍卖: ' .. curTask['itemname']
        elseif curTask['action'] == 'cleanlower' then
            labelText = labelText .. '清理低价'
        elseif curTask['action'] == 'cleanshort' then
            labelText = labelText .. '清理短期'
        end
    end
    mainFrame.hintLabel:SetText(labelText)

    mainFrame.title:SetText('自动拍卖 (' .. (displayPageNo + 1) .. '/'
        .. (math.ceil(#displayList / displayPageSize)) .. ')'
        .. '    出售中: ' .. XInfo.auctioningCount
        .. '    已出售: ' .. XInfo.auctionedCount
        .. '    待收款: ' .. (XUtils.round(XInfo.auctionedMoney / 10000))
        .. '    背包: ' .. XInfo.emptyBagCount)

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #displayList then
            local item = displayList[idx]
            frame.index = item.index
            local itemName = item['itemname']
            local enabled = item['enabled']
            if enabled == nil then enabled = false end
            local star = item['star']
            if star == nil then star = false end
            local canCraft = item['cancraft']
            if canCraft == nil then canCraft = false end
            local basePrice = item['baseprice']
            local minPriceOther = item['minpriceother']
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
            if stackCount > 2 then
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

            local basePriceStr = XUI.White .. XUtils.priceToString(basePrice)
            local lastPriceOtherStr = XUI.White .. XUtils.priceToString(lastPriceOther)

            local dealRateStr = XUI.getColor_DealRate(dealRate) .. 'R' .. XUtils.formatCount(XUtils.round(dealRate))
            local dealCountStr = XUI.getColor_DealCount(dealCount) .. 'D' .. XUtils.formatCount(dealCount, 3)

            frame.itemIndexButton:SetText(idx)
            frame.itemNameButton:SetText(itemNameStr)

            frame.labelTime:SetText(updateTimeStr)
            frame.labelBag:SetText(bagCountStr .. XUI.White .. ' / ' .. mailCountStr .. ' / ' .. bankCountStr
                .. XUI.White .. ' / ' .. stackCountStr)
            frame.labelAuction:SetText(auctionCountStr .. XUI.White .. ' / ' .. validCountStr
                .. XUI.White .. ' / ' .. priceLowerCountStr .. ' / ' .. lowerCountStr .. XUI.White)
            frame.labelDeal:SetText(dealRateStr .. XUI.White .. ' / ' .. dealCountStr)
            frame.labelPrice:SetText(minPriceOtherStr .. XUI.White .. ' / ' .. lastPriceOtherStr .. ' / ' .. basePriceStr)

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

            frame:Show()
        else
            frame:Hide()
        end
    end
end

filterDisplayList = function()
    if not mainFrame then return end

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
        local materialBuyPrice = XAutoBuy.getItemField(itemName, 'price', 0)
        local bagCount = XInfo.getBagItemCount(itemName)
        local mailCount = XInfo.getMailItemCount(itemName)
        local itemTotalCount = XInfo.getItemTotalCount(itemName)
        local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)
        local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)

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
                if star or checkImportant(item) then
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
            if itemTotalCount >= 20 then
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
        end

        if filterWord ~= '' and (not XUtils.stringContains(itemName, filterWord)) then
            disFlag = false
        end

        if disFlag then table.insert(dataList, item) end
    end
    displayList = dataList;
end

start = function()
    isStarted = true
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0
    lastAutoCleanTime = time()
    refreshUI()
end

stop = function()
    if curTask and curTask['action'] == 'query' then
        local item = XAutoAuctionList[curTask.index];
        resetItem(item)
    end
    isStarted = false
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0
    lastAutoCleanTime = 0
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
        minpriceother = 0,
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
    if not keepUpdateTime then
        item['updatetime'] = 0
        item['lastround'] = -99
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
            dealcount = dealCount
        }
        table.insert(taskList, 1, task)
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
        page = 1,
        timeout = dft_taskTimeout,
        important = important,
        dealcount = dealCount
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

insertAuctionTaskByIndex = function(index, price, count)
    for _, task in ipairs(taskList) do
        if task['action'] == 'auction' and task['index'] == index then
            task['price'] = price
            task['count'] = count
            return
        end
    end
    local item = XAutoAuctionList[index]
    local task = {
        action = 'auction',
        timeout = dft_taskTimeout,
        itemname = item['itemname'],
        index = index,
        price = price,
        count = count
    }
    table.insert(taskList, 1, task)
end

insertCleanLowerTask = function()
    if curTask and curTask['action'] == 'cleanlower' then
        return
    end
    for _, task in ipairs(taskList) do
        if task['action'] == 'cleanlower' then
            return
        end
    end
    local task = {
        action = 'cleanlower',
        timeout = 120
    }
    table.insert(taskList, 1, task)
    craftRunning = XCraftQueue.isRunning()
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

addCraftQueue = function(printCount)
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
    if printCount then
        xdebug.info('Craft: ' .. count)
    end
    refreshUI()
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
    if #cleaningItems > 0 then
        for _, itemName in ipairs(cleaningItems) do
            resetItemByName(itemName)
        end
    end
    cleaningItems = {}
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

puton = function(printCount)
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
    if printCount then
        xdebug.info('Up: ' .. count)
    end
    refreshUI()
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
    xdebug.info('Up: ' .. count)
    refreshUI()
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
    xdebug.info('Up: ' .. count)
    refreshUI()
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
        elseif task['action'] == 'auction' then
            xdebug.info('[' .. i .. ']拍卖: ' .. task['itemname'])
        elseif task['action'] == 'cleanlower' then
            xdebug.info('[' .. i .. ']清理低价')
        elseif task['action'] == 'cleanshort' then
            xdebug.info('[' .. i .. ']清理短期')
        else
            xdebug.info('[' .. i .. ']不支持的任务类型')
        end
    end
    if curTask then
        if curTask['action'] == 'query' then
            xdebug.info('当前任务：查询: ' .. XAutoAuctionList[curTask['index']]['itemname'])
        elseif curTask['action'] == 'auction' then
            xdebug.info('当前任务：拍卖: ' .. curTask['itemname'])
        elseif curTask['action'] == 'cleanlower' then
            xdebug.info('当前任务：清理低价')
        elseif curTask['action'] == 'cleanshort' then
            xdebug.info('当前任务：清理短期')
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
                            price = price + dealRate * vendorPrice * XAPI.FeeRate
                        end
                        if confirm then
                            item['baseprice'] = price
                            item['defaultprice'] = price * 2
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

-- Event callback
local function onQueryItemListUpdate(...)
    if not curTask then return end
    if curTask['action'] ~= 'query' then return end
    if not XAutoAuctionList[curTask['index']] then return end

    local item = XAutoAuctionList[curTask['index']]

    local batchCount, totalCount = XAPI.GetNumAuctionItems('list')

    if totalCount <= 0 or batchCount <= 0 then
        curTask['queryfound'] = false
        curTask['queryresultprocessed'] = false
        return
    end

    local res = { XAPI.GetAuctionItemInfo('list', 1) }
    local itemName = res[1]
    if not itemName then
        curTask['queryfound'] = false
        curTask['queryresultprocessed'] = false
        return
    end

    if itemName ~= item['itemname'] then return end

    curTask['queryfound'] = true
    curTask['queryresultprocessed'] = false
end

local function onAuctionSuccess()
    if not curTask then return end
    if curTask['action'] ~= 'auction' then return end

    curTask['status'] = 'finished'
end

local function processQueryTask_Auction(task)
    local index = task['index']
    local item = XAutoAuctionList[index]
    XInfo.reloadBag()
    XInfo.reloadAuction()

    local itemBagCount = XInfo.getBagItemCount(item['itemname'])
    if itemBagCount <= 0 then
        finishTask()
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
    if price < item['baseprice'] then
        finishTask()
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
        return
    end

    insertAuctionTaskByIndex(task['index'], price, subcount)
    finishTask()
end

local function processQueryTask(task)
    XInfo.reloadAuction()
    local index = task['index']
    local item = XAutoAuctionList[index]
    local auctionItem = XInfo.getAuctionItem(item['itemname'])
    local myMaxPrice = 0
    if auctionItem then myMaxPrice = auctionItem['maxprice'] end

    if not item then
        finishTask()
        return
    end
    if not task['status'] then
        if not XAPI.CanSendAuctionQuery() then return end
        resetItem(item, true)
        task['status'] = 'querying'
        task['page'] = 0
        task['queryfound'] = nil
        task['queryresultprocessed'] = false
        XAPI.QueryAuctionItems(item['itemname'], nil, nil, task['page'], nil, nil, false, true)
        return
    elseif task['status'] == 'querying' or task['status'] == 'confirm' then
        if task['queryfound'] == true then
            if not task['queryresultprocessed'] then
                item['updatetime'] = time()

                local index = 1
                while true do
                    local res = { XAPI.GetAuctionItemInfo('list', index) }
                    local itemName = res[1]
                    local stackCount = res[3]
                    local buyoutPrice = res[10]
                    local seller = res[14]
                    local itemId = res[17]

                    if not itemName then break end

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
                    end
                    index = index + 1
                end

                task['queryresultprocessed'] = true
            end

            if item['minpriceother'] < item['baseprice'] then
                finishTask()
                return
            else
                processQueryTask_Auction(task)
                return
            end

            if not XAPI.CanSendAuctionQuery() then return end

            task['status'] = 'querying'
            task['page'] = task['page'] + 1
            task['starttime'] = time()
            task['queryfound'] = nil
            task['queryresultprocessed'] = false
            XAPI.QueryAuctionItems(item['itemname'], nil, nil, task['page'], nil, nil, false, true)

            return
        elseif task['queryfound'] == false then
            if task['status'] == 'querying' then
                if not XAPI.CanSendAuctionQuery() then return end

                task['status'] = 'confirm'
                task['starttime'] = time()
                task['queryfound'] = nil
                task['queryresultprocessed'] = false
                XAPI.QueryAuctionItems(item['itemname'], nil, nil, task['page'], nil, nil, false, true)

                return
            end

            item['updatetime'] = time()
            item['lastround'] = queryRound

            processQueryTask_Auction(task)
            return
        end

        return
    end
end

local function processAuctionTask(task)
    local index = task['index']
    local item = XAutoAuctionList[index]
    if not item then
        finishTask()
        return
    end

    if not task['status'] then
        XInfo.reloadBag()
        local bagItem = XInfo.getBagItem(item['itemname'])
        if not bagItem then
            finishTask()
            return
        end

        local position = bagItem['positions'][1]
        XAPI.ClearCursor()
        XAPI.ClickAuctionSellItemButton()
        XAPI.ClearCursor()
        XAPI.C_Container_PickupContainerItem(position[1], position[2])
        XAPI.ClickAuctionSellItemButton()

        task['location'] = XAPI.ItemLocation_CreateFromBagAndSlot(position[1], position[2])
        XAPI.C_Item_LockItem(task['location'])

        task['status'] = 'inited'
        return
    elseif task['status'] == 'inited' then
        local price = task['price']
        local count = task['count']

        if XAPI.GetAuctionSellItemInfo() ~= item['itemname'] then
            finishTask()
            return
        end

        if task['starttime'] + dft_postdelay > time() then
            return
        end

        xdebug.info('拍卖：' .. task['itemname'] .. '(' .. XUtils.priceToMoneyString(price) .. ')')
        XAPI.PostAuction(price, price, 1, 1, count)

        task['status'] = 'posted'
        return
    elseif task['status'] == 'posted' then
        return
    elseif task['status'] == 'finished' then
        local price = task['price']
        local count = task['count']
        for _ = 1, count do
            table.insert(item['myvalidlist'], price)
        end
        finishTask()
        return
    else
        finishTask()
        return
    end
end

local function processCleanLowerTask(task)
    lastAutoCleanTime = time()

    if not XAPI.IsAuctionFrameOpen() then
        finishTask()
        return
    end
    local numItems = XAPI.GetNumAuctionItems('owner')
    if numItems <= 0 then
        finishTask()
        return
    end

    XCraftQueue.stop()
    for i = numItems, 1, -1 do
        local res = { XAPI.GetAuctionItemInfo('owner', i) }
        local itemName = res[1]
        local stackCount = res[3]
        local buyoutPrice = res[10]
        local saleStatus = res[16]

        if saleStatus ~= 1 then
            for _, item in ipairs(XAutoAuctionList) do
                if item['itemname'] == itemName then
                    if checkImportant(item) then
                        if buyoutPrice / stackCount > item['minpriceother'] then
                            xdebug.info('清理低价：' .. item['itemname']
                                .. '(' .. XUtils.priceToMoneyString(buyoutPrice / stackCount)
                                .. '/' .. XUtils.priceToMoneyString(item['minpriceother']) .. ')')
                            XAPI.CancelAuction(i)

                            if task['cleaned'] == nil then
                                task['cleaned'] = { item['itemname'] }
                            else
                                if not XUtils.inArray(item['itemname'], task['cleaned']) then
                                    table.insert(task['cleaned'], item['itemname'])
                                end
                            end
                            return
                        end
                    end
                    break
                end
            end
        end
    end
    XInfo.reloadAuction()
    if task['cleaned'] then
        for _, itemName in ipairs(task['cleaned']) do
            resetItemByName(itemName)
        end
    end
    finishTask()
    XCraftQueue.reset()
    if craftRunning then
        XCraftQueue.start()
    end
    xdebug.warn('清理低价结束')
end

local function onUpdate()
    refreshUI()
    if not XAutoAuction.XSellBuyFlag then return end
    if not isStarted then
        if XAutoAuction.XSellBuyFlag then
            XAutoAuction.XSellBuyFlag = false
        end
        return
    end

    addCraftQueue(false)

    if curTask then
        if time() - curTask['starttime'] > curTask['timeout'] then
            xdebug.error('XAuctionCenter Task Timeout')
            finishTask()
            refreshUI()
            return
        end

        if curTask['action'] == 'auction' then
            if processAuctionTask(curTask) then return end
        elseif curTask['action'] == 'query' then
            if processQueryTask(curTask) then return end
        elseif curTask['action'] == 'cleanlower' then
            if processCleanLowerTask(curTask) then return end
        end
        refreshUI()
        return
    end

    if autoClean then
        if time() - lastAutoCleanTime > dft_autoCleanInterval then
            insertCleanLowerTask()
        end
    end

    if #taskList > 0 then
        if time() - lastTaskFinishTime < dft_taskInterval then return end
        curTask = taskList[1]
        table.remove(taskList, 1)
        curTask['starttime'] = time()

        if curTask['action'] == 'auction' then
            if processAuctionTask(curTask) then return end
        elseif curTask['action'] == 'query' then
            if processQueryTask(curTask) then return end
        elseif curTask['action'] == 'cleanlower' then
            if processCleanLowerTask(curTask) then return end
        end
        refreshUI()
        return
    end

    puton(false)

    if time() - queryRoundFinishTime < dft_roundInterval then return end

    local nextTaskIndex = -1

    -- if queryRound == 1 then
    --     for i = starQueryIndex, #XAutoAuctionList do
    --         local item = XAutoAuctionList[i]
    --         if item and item['enabled'] and item['star'] and item['lastround'] < 1 then
    --             starQueryIndex = i + 1
    --             nextTaskIndex = i
    --             break
    --         end
    --     end

    --     if nextTaskIndex == -1 then
    --         starQueryIndex = #XAutoAuctionList

    --         for i = queryIndex, #XAutoAuctionList do
    --             local item = XAutoAuctionList[i]
    --             if item and item['enabled'] and (not item['star']) and item['lastround'] < 1 then
    --                 local round = math.floor(item['lowercount'] / 20)
    --                 if round > 3 then round = 3 end
    --                 if item['lastround'] + round <= queryRound then
    --                     queryIndex = i + 1
    --                     nextTaskIndex = i
    --                     break
    --                 end
    --             end
    --         end
    --     end

    --     if nextTaskIndex == -1 then
    --         queryIndex = 1
    --         starQueryIndex = 1
    --         queryStarFlag = true

    --         queryRound = queryRound + 1
    --         queryRoundFinishTime = time()

    --         refreshUI()
    --         return
    --     end

    --     addQueryTaskByIndex(nextTaskIndex)
    --     refreshUI()
    --     return
    -- end

    if queryStarFlag then
        for idx = starQueryIndex, #XAutoAuctionList do
            local item = XAutoAuctionList[idx]
            if item and item['enabled'] and item['star'] then
                starQueryIndex = idx + 1
                nextTaskIndex = idx
                break
            end
        end
        queryStarFlag = not queryStarFlag
    end

    if nextTaskIndex == -1 then
        for idx = queryIndex, #XAutoAuctionList do
            local item = XAutoAuctionList[idx]
            if item and item['enabled'] and (not item['star']) then
                local round = math.floor(item['lowercount'] / 20)
                if round > 3 then round = 3 end
                if item['lastround'] + round <= queryRound then
                    queryIndex = idx + 1
                    nextTaskIndex = idx
                    break
                end
            end
        end
        queryStarFlag = not queryStarFlag
    end

    if nextTaskIndex == -1 then
        queryIndex = 1
        starQueryIndex = 1
        queryStarFlag = true

        queryRound = queryRound + 1
        queryRoundFinishTime = time()

        if XAutoAuction.XSellBuyFlag then
            XAutoAuction.XSellBuyFlag = not XAutoAuction.XSellBuyFlag
        end
        refreshUI()
        return
    end

    addQueryTaskByIndex(nextTaskIndex)
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
    addCraftQueue(true)
end
SLASH_XAUCTIONCENTERADDCRAFTQUEUE1 = '/xauctioncenter_addcreaftqueue'

SlashCmdList['XAUCTIONCENTERPUTON'] = function()
    puton(true)
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
