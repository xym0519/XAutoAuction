XAuctionCenter = {}
local moduleName = 'XAuctionCenter'

-- Variable definition
local mainFrame = nil
local debug = false

local dft_minPrice = 9999999
local dft_maxPrice = 2180000
local dft_lowestPriceRate = 1.5
local dft_roundInterval = 3
local dft_taskInterval = 1
local dft_taskTimeout = 30
local dft_filterList = { '全部', '可售', '优质', '价低' }
local dft_deltaPrice = 10

local dft_buttonWidth = 45
local dft_buttonGap = 1
local dft_sectionGap = 10

local fastAuction = true
local autoAuction = false
local multiAuction = 0

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local isStarted = false
local taskList = {}
local curTask = nil
local isTasking = false
local lastTaskFinishTime = 0

local queryIndex = 1
local starQueryIndex = 1
local queryStarFlag = true

local queryRound = 1
local queryRoundFinishTime = 0

-- local isAuction = false

-- Function definition
local initData
local resetData
local initUI
local refreshUI

local start
local stop
local finishTask
local addItem
local getAuctionItem
local addQueryTaskByIndex
local addQueryTaskByItemName
local insertAuctionTaskByIndex

local getMaterialCount
local getMaterialPrice

local addCraftQueue
local puton
local clearAll
local shortPeriod
local printList

-- Function implemention
initData = function()
    if not XAutoAuctionList then return end
    for _, item in ipairs(XAutoAuctionList) do
        item['lastround'] = -99
    end
end

resetData = function()
    for _, item in ipairs(XAutoAuctionList) do
        item['minprice'] = dft_minPrice
        item['myvalidlist'] = {}
        item['lowercount'] = 0
        item['minpriceother'] = dft_minPrice
        item['allcount'] = 0
        item['updatetime'] = 0
        item['lastround'] = -99
    end
    isStarted = false
    taskList = {}
    curTask = nil
    isTasking = false
    lastTaskFinishTime = 0

    queryIndex = 1
    starQueryIndex = 1
    queryStarFlag = true

    queryRound = 1
    queryRoundFinishTime = 0
end

initUI = function()
    if debug then print('initUI') end
    mainFrame = XUI.createFrame('XAuctionCenterMainFrame', 905, 430)
    mainFrame:SetFrameStrata('HIGH')
    mainFrame.title:SetText('自动拍卖')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()

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
        if displayPageNo < math.ceil(#XAutoAuctionList / displayPageSize) - 1 then
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

    local autoAuctionButton = XUI.createButton(mainFrame, dft_buttonWidth, '自动')
    autoAuctionButton:SetPoint('LEFT', resetButton, 'RIGHT', dft_buttonGap, 0)
    autoAuctionButton:SetScript('OnClick', function()
        autoAuction = not autoAuction
        refreshUI()
    end)
    mainFrame.autoAuctionButton = autoAuctionButton

    local fastAuctionButton = XUI.createButton(mainFrame, dft_buttonWidth, '快速')
    fastAuctionButton:SetPoint('LEFT', autoAuctionButton, 'RIGHT', dft_buttonGap, 0)
    fastAuctionButton:SetScript('OnClick', function()
        fastAuction = not fastAuction
        refreshUI()
    end)
    mainFrame.fastAuctionButton = fastAuctionButton

    local putonButton = XUI.createButton(mainFrame, dft_buttonWidth, '上架')
    putonButton:SetPoint('LEFT', fastAuctionButton, 'RIGHT', dft_sectionGap, 0)
    putonButton:SetScript('OnClick', function()
        puton(true)
    end)

    local craftAllButton = XUI.createButton(mainFrame, dft_buttonWidth, '制造')
    craftAllButton:SetPoint('LEFT', putonButton, 'RIGHT', dft_buttonGap, 0)
    craftAllButton:SetScript('OnClick', function()
        addCraftQueue(true, true)
    end)

    local cleanButton = XUI.createButton(mainFrame, dft_buttonWidth, '清理')
    cleanButton:SetPoint('LEFT', craftAllButton, 'RIGHT', dft_buttonGap, 0)
    cleanButton:SetScript('OnClick', function()
        clearAll()
    end)

    local shortPeriodButton = XUI.createButton(mainFrame, dft_buttonWidth, '短期')
    shortPeriodButton:SetPoint('LEFT', cleanButton, 'RIGHT', dft_buttonGap, 0)
    shortPeriodButton:SetScript('OnClick', function()
        shortPeriod()
    end)

    local refreshButton = XUI.createButton(mainFrame, dft_buttonWidth, '刷新')
    refreshButton:SetPoint('LEFT', shortPeriodButton, 'RIGHT', dft_sectionGap, 0)
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
        displayPageNo = math.ceil(#XAutoAuctionList / displayPageSize) - 1;
        refreshUI()
    end)

    local dealCountTypeButton = XUI.createButton(mainFrame, dft_buttonWidth, '10D')
    dealCountTypeButton:SetPoint('LEFT', lastButton, 'RIGHT', dft_sectionGap, 0)
    dealCountTypeButton:SetScript('OnClick', function()
        XInfo.allHistory = (XInfo.allHistory + 1) % 3
        refreshUI()
    end)
    mainFrame.dealCountTypeButton = dealCountTypeButton

    local filterResetButton = XUI.createButton(mainFrame, dft_buttonWidth, '全部')
    filterResetButton:SetPoint('LEFT', dealCountTypeButton, 'RIGHT', dft_buttonGap, 0)
    filterResetButton:SetScript('OnClick', function()
        UIDropDownMenu_SetText(mainFrame.filterDropDown, '全部')
        mainFrame.filterBox:SetText('')
        refreshUI()
    end)

    local filterDropDown = XUI.createDropDown(mainFrame, 80, dft_filterList, '全部',
        function(value) refreshUI() end)
    filterDropDown:SetPoint('LEFT', filterResetButton, 'RIGHT', -15, 0)
    mainFrame.filterDropDown = filterDropDown

    local filterBox = XUI.createEditbox(mainFrame, 90)
    filterBox:SetPoint('LEFT', filterDropDown, 'RIGHT', -5, 0)
    filterBox:SetScript('OnEnterPressed', function(self)
        self:ClearFocus();
        refreshUI()
    end)
    filterBox:SetScript('OnEscapePressed', function(self)
        self:SetText('')
        self:ClearFocus();
        refreshUI()
    end)
    mainFrame.filterBox = filterBox

    local settingButton = XUI.createButton(mainFrame, dft_buttonWidth, '添加')
    settingButton:SetPoint('LEFT', filterBox, 'RIGHT', dft_sectionGap, 0)
    settingButton:SetScript('OnClick', function()
        displaySettingItem = nil
        XUIInputDialog.show(moduleName, function(data)
            local itemName = nil
            local lowestPrice = nil
            local defaultPrice = nil
            local stackCount = nil
            for _, item in ipairs(data) do
                if item.Name == '宝石名称' then itemName = item.Value end
                if item.Name == '最低售价' then lowestPrice = item.Value end
                if item.Name == '默认价格' then defaultPrice = item.Value end
                if item.Name == '拍卖数量' then stackCount = item.Value end
            end
            if itemName and lowestPrice and defaultPrice and stackCount then
                addItem(itemName, lowestPrice, defaultPrice, stackCount)
            end
        end, { { Name = '宝石名称' }, { Name = '最低售价' }, { Name = '默认价格' }, { Name = '拍卖数量' } }, '添加')
    end)

    local priceButton = XUI.createButton(mainFrame, dft_buttonWidth, '调价')
    priceButton:SetPoint('LEFT', settingButton, 'RIGHT', dft_buttonGap, 0)
    priceButton:SetScript('OnClick', function()
        XUIInputDialog.show(moduleName, function(data)
            local itemName = nil
            local lowestPrice = nil
            local defaultPrice = nil
            local stackCount = nil
            for _, item in ipairs(data) do
                if item.Name == '宝石名称' then itemName = item.Value end
                if item.Name == '最低售价' then lowestPrice = item.Value end
                if item.Name == '默认价格' then defaultPrice = item.Value end
                if item.Name == '拍卖数量' then stackCount = item.Value end
            end
            if itemName and lowestPrice and defaultPrice and stackCount then
                addItem(itemName, lowestPrice, defaultPrice, stackCount)
            end
        end, { {
            Name = '宝石名称',
            OnEnterPressed = function(tname)
                local all = false
                if XUtils.stringStartsWith(tname, '*') then
                    all = true
                    tname = string.gsub(tname, '^%*', '')
                end
                print('----------')
                for _, item in ipairs(XAutoAuctionList) do
                    if XUtils.stringContains(item['itemname'], tname) then
                        if item['enabled'] ~= nil and item['enabled'] then
                            if all or (not item['star']) or (not item['star']) then
                                print(item['itemname'] .. ':  '
                                    .. XUtils.priceToMoneyString(item['lowestprice']) .. ' / '
                                    .. XUtils.priceToMoneyString(item['defaultprice']))
                            end
                        end
                    end
                end
            end
        }, { Name = '最低售价' }, { Name = '默认价格' } }, '调价')
    end)

    local multiAuctionButton = XUI.createButton(mainFrame, dft_buttonWidth, '单倍')
    multiAuctionButton:SetPoint('LEFT', priceButton, 'RIGHT', dft_buttonGap, 0)
    multiAuctionButton:SetScript('OnClick', function()
        multiAuction = (multiAuction + 1) % 3
        refreshUI()
    end)
    mainFrame.multiAuctionButton = multiAuctionButton

    local lastWidget = nil
    for i = 1, displayPageSize do
        local frame = CreateFrame('Frame', nil, mainFrame)
        frame:SetSize(mainFrame:GetWidth(), 30)

        if i == 1 then
            frame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 0, -90)
        else
            frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -2)
        end

        frame:Hide()

        local itemIndexButton = XUI.createButton(frame, 35, '999')
        itemIndexButton:SetPoint('LEFT', frame, 'LEFT', 15, 0)
        itemIndexButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i

            XUISortDialog.show('XAuctionCenter_Sort', XAutoAuctionList, idx, function()
                refreshUI()
            end)
        end)
        frame.itemIndexButton = itemIndexButton

        local itemNameButton = XUI.createButton(frame, 160, '')
        itemNameButton:SetPoint('LEFT', itemIndexButton, 'RIGHT', 0, 0)
        itemNameButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoAuctionList[idx];
            if not item then return end

            XUIInputDialog.show('XAuctionCenter_Craft', function(input)
                local itemName = item['itemname']
                local count = tonumber(input)
                XCraftQueue.addItem(itemName, count, 'fulfil')
                XCraftQueue.start()
            end, item['stackcount'], item['itemname'])
        end)
        frame.itemNameButton = itemNameButton

        local labelTime = XUI.createLabel(frame, 50, '')
        labelTime:SetPoint('LEFT', itemNameButton, 'RIGHT', 3, 0)
        frame.labelTime = labelTime

        local labelBag = XUI.createLabel(frame, 110, '')
        labelBag:SetPoint('LEFT', labelTime, 'RIGHT', 3, 0)
        frame.labelBag = labelBag

        local labelAuction = XUI.createLabel(frame, 125, '')
        labelAuction:SetPoint('LEFT', labelBag, 'RIGHT', 3, 0)
        frame.labelAuction = labelAuction

        local labelDeal = XUI.createLabel(frame, 70, '')
        labelDeal:SetPoint('LEFT', labelAuction, 'RIGHT', 3, 0)
        frame.labelDeal = labelDeal

        local labelPrice = XUI.createLabel(frame, 100, '')
        labelPrice:SetPoint('LEFT', labelDeal, 'RIGHT', 3, 0)
        frame.labelPrice = labelPrice

        local deleteButton = XUI.createButton(frame, 30, '删')
        deleteButton:SetPoint('LEFT', labelPrice, 'RIGHT', 0, 0)
        deleteButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            local titem = XAutoAuctionList[idx]
            if idx <= #XAutoAuctionList then
                XUIConfirmDialog.show(moduleName, '删除', '是否确定删除：' .. titem['itemname'], function()
                    table.remove(XAutoAuctionList, idx)
                    refreshUI()
                end)
            end
        end)

        local cleanButton = XUI.createButton(frame, 30, '清')
        cleanButton:SetPoint('LEFT', deleteButton, 'RIGHT', 0, 0)
        cleanButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoAuctionList[idx];
            if not item then return end
            XInfo.reloadBag()
            XInfo.reloadAuction()
            local auctionItem = XInfo.getAuctionItem(item['itemname'])
            if not auctionItem then return end
            for _, titem in ipairs(auctionItem['items']) do
                if titem['price'] > item['otherminprice'] then
                    CancelAuction(titem['index'])
                end
            end
            XInfo.reloadBag()
            XInfo.reloadAuction()
        end)

        local lowestButton = XUI.createButton(frame, 30, '底')
        lowestButton:SetPoint('LEFT', cleanButton, 'RIGHT', 0, 0)
        lowestButton:SetScript('OnClick', function()
            XUIConfirmDialog.show(moduleName, '确认', '是否确认重设低价', function()
                XInfo.reloadBag()
                XInfo.reloadAuction()
                local idx = displayPageNo * displayPageSize + i
                local item = XAutoAuctionList[idx];
                if not item then return end
                local lowestPrice = XInfo.getAuctionInfoField(item['itemname'], 'lowestprice', 9999999, 1)
                if lowestPrice then
                    item['lowestprice'] = lowestPrice
                end
                refreshUI()
            end)
        end)

        local craftButton = XUI.createButton(frame, 30, '设')
        craftButton:SetPoint('LEFT', lowestButton, 'RIGHT', 0, 0)
        craftButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            displaySettingItem = XAutoAuctionList[idx]
            if not displaySettingItem then return end

            XUIInputDialog.show(moduleName, function(data)
                local itemName = nil
                local lowestPrice = nil
                local defaultPrice = nil
                local stackCount = nil
                for _, item in ipairs(data) do
                    if item.Name == '宝石名称' then itemName = item.Value end
                    if item.Name == '最低售价' then lowestPrice = item.Value end
                    if item.Name == '默认价格' then defaultPrice = item.Value end
                    if item.Name == '拍卖数量' then stackCount = item.Value end
                end
                if itemName and lowestPrice and defaultPrice and stackCount then
                    displaySettingItem['itemname'] = itemName
                    displaySettingItem['lowestprice'] = lowestPrice
                    displaySettingItem['defaultprice'] = defaultPrice
                    displaySettingItem['stackcount'] = stackCount
                end
            end, {
                { Name = '宝石名称', Value = displaySettingItem['itemname'] },
                { Name = '最低售价', Value = displaySettingItem['lowestprice'] },
                { Name = '默认价格', Value = displaySettingItem['defaultprice'] },
                { Name = '拍卖数量', Value = displaySettingItem['stackcount'] }
            }, '添加')
        end)

        local enableButton = XUI.createButton(frame, 30, '')
        enableButton:SetPoint('LEFT', craftButton, 'RIGHT', 0, 0)
        enableButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
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

        local starButton = XUI.createButton(frame, 30, '星')
        starButton:SetPoint('LEFT', enableButton, 'RIGHT', 0, 0)
        starButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
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

        local itemRefreshButton = XUI.createButton(frame, 30, '刷')
        itemRefreshButton:SetPoint('LEFT', starButton, 'RIGHT', 0, 0)
        itemRefreshButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoAuctionList[idx];
            if not item then return end

            addQueryTaskByIndex(idx)
        end)

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    refreshUI()

    if debug then print('initUI Finished') end
end

refreshUI = function()
    if debug then print('refreshUI') end
    if not mainFrame then return end

    XInfo.reloadBag()
    XInfo.reloadAuction()

    mainFrame.title:SetText('自动拍卖 (' .. (displayPageNo + 1) .. '/'
        .. (math.ceil(#XAutoAuctionList / displayPageSize)) .. ')    Querying: '
        .. queryIndex .. '    StarQuerying: ' .. starQueryIndex .. '    Round: ' .. queryRound
        .. '    Queue: ' .. #taskList .. '    EmptyBag: ' .. XInfo.emptyBagCount)

    if fastAuction then
        mainFrame.fastAuctionButton:SetText('快速')
    else
        mainFrame.fastAuctionButton:SetText('慢速')
    end

    if autoAuction then
        mainFrame.autoAuctionButton:SetText('自动')
    else
        mainFrame.autoAuctionButton:SetText('手动')
    end

    if isStarted then
        mainFrame.startButton:SetText('停止')
    else
        mainFrame.startButton:SetText('开始')
    end

    if XInfo.allHistory == 0 then
        mainFrame.dealCountTypeButton:SetText('ALL')
    elseif XInfo.allHistory == 1 then
        mainFrame.dealCountTypeButton:SetText('10D')
    else
        mainFrame.dealCountTypeButton:SetText('30D')
    end

    if multiAuction == 2 then
        mainFrame.multiAuctionButton:SetText('全部')
    elseif multiAuction == 1 then
        mainFrame.multiAuctionButton:SetText('双倍')
    else
        mainFrame.multiAuctionButton:SetText('单倍')
    end

    if not curTask then
        mainFrame.hintLabel:SetText('等待')
    else
        if curTask['action'] == 'query' then
            local item = XAutoAuctionList[curTask['index']]
            if item == nil then
                mainFrame.hintLabel:SetText('查询: 无')
            else
                local page = curTask['page']
                if page == nil then page = 0 end
                mainFrame.hintLabel:SetText('查询: [' .. curTask['index']
                    .. ']' .. item['itemname'] .. '(' .. page .. ')')
            end
        elseif curTask['action'] == 'auction' then
            mainFrame.hintLabel:SetText('拍卖: ' .. curTask['itemname'])
        end
    end

    local filterWord = mainFrame.filterBox:GetText();
    local displayFilter = UIDropDownMenu_GetText(mainFrame.filterDropDown)
    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #XAutoAuctionList then
            local item = XAutoAuctionList[idx]
            local itemName = item['itemname']
            local enabled = item['enabled']
            if enabled == nil then enabled = false end
            local star = item['star']
            if star == nil then star = false end
            local minPriceOther = item['minpriceother']
            local lowestPrice = item['lowestprice']
            local minPrice = item['minprice']
            local minPriceCount = 0
            if item['myvalidlist'] then minPriceCount = #item['myvalidlist'] end
            local stackCount = item['stackcount']
            local lowerCount = item['lowercount']
            local allCount = item['allcount']
            local materialCount = getMaterialCount(itemName)
            local materialPrice = getMaterialPrice(itemName)

            local itemBag = XInfo.getBagItem(itemName)
            local bagCount = 0
            local bagTotalCount = 0
            if itemBag then
                bagCount = itemBag['count']
                bagTotalCount = itemBag['totalcount']
            end

            local auctionItem = XInfo.getAuctionItem(itemName)
            local auctionCount = 0
            if auctionItem then auctionCount = auctionItem['count'] end
            local bagAuctionCount = bagTotalCount + auctionCount

            local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
            local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)

            local disFlag = false
            if displayFilter == '全部' then
                disFlag = true
            elseif displayFilter == '可售' then
                if enabled then
                    if star or minPriceOther >= lowestPrice then
                        disFlag = true
                    end
                end
            elseif displayFilter == '优质' then
                if enabled then
                    if star or minPriceOther >= lowestPrice then
                        if dealCount > 20 then
                            disFlag = true
                        end
                    end
                end
            elseif displayFilter == '价低' then
                if enabled then
                    if minPriceOther <= materialPrice then
                        disFlag = true
                    end
                end
            end

            if filterWord ~= '' and not XUtils.stringContains(itemName, filterWord) then
                disFlag = false
            end

            if disFlag then
                local itemNameStr = string.sub(itemName, 1, 18);
                if star then
                    itemNameStr = '*' .. itemNameStr
                end
                if enabled then
                    if minPriceCount > 0 then
                        itemNameStr = XUI.Green .. itemNameStr
                    else
                        itemNameStr = XUI.Red .. itemNameStr
                    end
                else
                    itemNameStr = XUI.Gray .. itemNameStr
                end

                local updateTimeStr = XUtils.formatTime(item['updatetime'])

                local bagCountStr = XUI.getColor_BagStackCount(bagCount, stackCount) ..
                    'B' .. XUtils.formatCount(bagCount, 1)

                local materialCountStr = 'M' .. XUtils.formatCount2(materialCount)

                local auctionCountStr = XUI.getColor_AuctionStackCount(auctionCount, stackCount) ..
                    'A' .. XUtils.formatCount(auctionCount, 1)

                local minPriceCountStr = XUI.getColor_AuctionStackCount(minPriceCount, stackCount) ..
                    'M' .. XUtils.formatCount(minPriceCount, 1)

                local bagAuctionCountStr = XUI.getColor_BagStackCount(bagAuctionCount, stackCount) ..
                    'T' .. XUtils.formatCount(bagAuctionCount, 2)

                local lowerCountStr = 'L' .. XUtils.formatCount(lowerCount)
                if lowerCount > 5 then
                    lowerCountStr = XUI.Red .. lowerCountStr
                elseif lowerCount > 0 then
                    lowerCountStr = XUI.Yellow .. lowerCountStr
                else
                    lowerCountStr = XUI.White .. lowerCountStr
                end

                local allCountStr = 'G' .. XUtils.formatCount(allCount)
                if allCount > 20 then
                    allCountStr = XUI.Red .. allCountStr
                elseif allCount > 10 then
                    allCountStr = XUI.Yellow .. allCountStr
                else
                    allCountStr = XUI.Green .. allCountStr
                end

                local stackCountStr = 'S' .. XUtils.formatCount(stackCount, 1)
                if stackCount > 2 then
                    stackCountStr = XUI.Cyan .. stackCountStr
                elseif stackCount > 1 then
                    stackCountStr = XUI.Green .. stackCountStr
                end

                local minPriceStr = XUtils.priceToString(minPrice)
                if minPrice < lowestPrice then
                    minPriceStr = XUI.Red .. minPriceStr
                elseif minPrice < lowestPrice * dft_lowestPriceRate then
                    minPriceStr = XUI.Yellow .. minPriceStr
                elseif minPrice < lowestPrice * dft_lowestPriceRate * dft_lowestPriceRate then
                    minPriceStr = XUI.Green .. minPriceStr
                else
                    minPriceStr = XUI.Cyan .. minPriceStr
                end

                local lowestPriceStr = XUI.White .. XUtils.priceToString(lowestPrice)

                local dealRateStr = XUI.getColor_DealRate(dealRate) .. 'R' .. XUtils.formatCount(XUtils.round(dealRate))
                local dealCountStr = XUI.getColor_DealCount(dealCount) .. 'D' .. XUtils.formatCount(dealCount)

                frame.itemIndexButton:SetText(idx)
                frame.itemNameButton:SetText(itemNameStr)

                frame.labelTime:SetText(updateTimeStr)
                frame.labelBag:SetText(bagCountStr .. XUI.White .. '/' .. bagAuctionCountStr
                    .. XUI.White .. '/' .. materialCountStr .. XUI.White .. '/' .. stackCountStr)
                frame.labelAuction:SetText(auctionCountStr .. XUI.White .. '/' .. minPriceCountStr
                    .. XUI.White .. '/' .. lowerCountStr .. XUI.White .. '/' .. allCountStr)
                frame.labelDeal:SetText(dealRateStr .. XUI.White .. '/' .. dealCountStr)
                frame.labelPrice:SetText(minPriceStr .. XUI.White .. '/' .. lowestPriceStr)

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
                frame:Show()
            else
                frame:Hide()
            end
        else
            frame:Hide()
        end
    end
    if debug then print('refreshUI Finished') end
end

start = function()
    isStarted = true
    taskList = {}
    curTask = nil
    isTasking = false
    lastTaskFinishTime = 0
    refreshUI()
end

stop = function()
    if curTask and curTask['action'] == 'query' then
        local item = XAutoAuctionList[curTask.index];
        item['minprice'] = dft_minPrice
        item['minpriceother'] = dft_minPrice
        item['myvalidlist'] = {}
        item['lowercount'] = 0
        item['allcount'] = 0
    end
    isStarted = false
    taskList = {}
    curTask = nil
    isTasking = false
    lastTaskFinishTime = 0
    refreshUI()
end

finishTask = function()
    curTask = nil
    isTasking = false
    lastTaskFinishTime = time()
end

addItem = function(itemName, lowestPrice, defaultPrice, stackCount)
    if getAuctionItem(itemName) then return end

    local item = {
        itemname = itemName,
        lowestprice = lowestPrice,
        defaultprice = defaultPrice,
        stackcount = stackCount,
        minprice = dft_minPrice,
        myvalidlist = {},
        minpriceother = dft_minPrice,
        lowercount = 0,
        allcount = 0,
        updatetime = 0,
        lastround = -99
    }
    table.insert(XAutoAuctionList, item)
    refreshUI()
end

getAuctionItem = function(itemName)
    for _, item in ipairs(XAutoAuctionList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

addQueryTaskByIndex = function(index)
    if debug then print('addQueryTaskByIndex') end
    for _, task in ipairs(taskList) do
        if task['action'] == 'query' and task['index'] == index then
            return
        end
    end

    local item = XAutoAuctionList[index];
    if not item then return end

    item['minprice'] = dft_minPrice
    item['myvalidlist'] = {}
    item['lowercount'] = 0
    item['allcount'] = 0
    item['minpriceother'] = dft_minPrice
    item['updatetime'] = 0
    item['lastround'] = -99
    local task = { action = 'query', index = index, page = 1 }
    table.insert(taskList, task)
    if debug then print('addQueryTaskByIndex Finished') end
end

addQueryTaskByItemName = function(itemName)
    if debug then print('addQueryTaskByItemName') end
    for i, item in ipairs(XAutoAuctionList) do
        if item['itemname'] == itemName then
            addQueryTaskByIndex(i)
            return
        end
    end
    if debug then print('addQueryTaskByItemName Finished') end
end

insertAuctionTaskByIndex = function(index, price, count)
    if debug then print('insertAuctionTaskByIndex') end
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
        itemname = item['itemname'],
        index = index,
        price = price,
        count = count
    }
    table.insert(taskList, 1, task)
    if debug then print('insertAuctionTaskByIndex Finished') end
end

getMaterialCount = function(itemName, type)
    if type == nil then type = 'totalcount' end
    local materialBagItem = XInfo.getMaterialBagItem(itemName)
    if not materialBagItem then return 0 end
    return materialBagItem[type]
end

getMaterialPrice = function(itemName)
    local price = 0
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        local autoBuyItem = XAutoBuy.getBuyItem(materialName)
        if autoBuyItem then price = autoBuyItem['price'] end
    end
    return price
end

addCraftQueue = function(printCount, manualAdd)
    if debug then print('addCraftQueue') end
    XInfo.reloadBag()
    XInfo.reloadAuction()
    local count = 0
    local starQueue = {}
    local unStarQueue = {}
    for idx, item in ipairs(XAutoAuctionList) do
        if item['enabled'] then
            local inQuery = false
            for _, task in ipairs(taskList) do
                if task['action'] == 'query' and task['index'] == idx then
                    inQuery = true
                    break
                end
            end
            if not inQuery then
                if item['minpriceother'] >= item['lowestprice'] then
                    local bagCount = 0
                    local bagItem = XInfo.getBagItem(item['itemname'])
                    if bagItem ~= nil then
                        bagCount = bagItem['count']
                    end
                    local auctionCount = 0
                    local auctionItem = XInfo.getAuctionItem(item['itemname'])
                    if auctionItem ~= nil then
                        auctionCount = auctionItem['count']
                    end
                    local stackCount = item['stackcount']
                    local dealCount = XInfo.getAuctionInfoField(item['itemname'], 'dealcount', 0)
                    local materialCount = getMaterialCount(item['itemname'])
                    local minPriceCount = #item['myvalidlist']
                    local multiRate = 3
                    if XInfo.allHistory == 1 then multiRate = 1 end

                    local subCount = stackCount - auctionCount - bagCount
                    if queryRound > 1 or manualAdd then
                        if item['star'] or dealCount >= 20 * multiRate then
                            if auctionCount + bagCount < stackCount * 3 then
                                subCount = stackCount * 2 - minPriceCount - bagCount
                            end
                        end
                    end
                    if subCount > materialCount then subCount = materialCount end
                    if subCount > 0 then
                        if item['star'] then
                            table.insert(starQueue, { itemname = item['itemname'], count = subCount })
                        else
                            table.insert(unStarQueue, { itemname = item['itemname'], count = subCount })
                        end
                        count = count + 1
                    end
                end
            end
        end
    end
    for _, item in ipairs(starQueue) do
        XCraftQueue.addItem(item['itemname'], item['count'], 'fulfil')
    end
    for _, item in ipairs(unStarQueue) do
        XCraftQueue.addItem(item['itemname'], item['count'], 'fulfil')
    end
    if printCount then
        print('Craft: ' .. count)
    end
    XCraftQueue.start()
    refreshUI()
    if debug then print('addCraftQueue Finished') end
end

puton = function(printCount)
    if debug then print('puton') end
    XInfo.reloadBag()
    XInfo.reloadAuction()
    local count = 0
    local starQueue = {}
    local unStarQueue = {}
    for i, item in ipairs(XAutoAuctionList) do
        if item['enabled'] then
            local bagCount = 0
            local bagItem = XInfo.getBagItem(item['itemname'])
            if bagItem then bagCount = bagItem['count'] end
            local auctionCount = 0
            local auctionItem = XInfo.getAuctionItem(item['itemname'])
            if auctionItem then auctionCount = auctionItem['count'] end
            local minPriceCount = #item['myvalidlist']
            if minPriceCount < auctionCount then auctionCount = minPriceCount end
            local stackCount = item['stackcount']
            local dealCount = XInfo.getAuctionInfoField(item['itemname'], 'dealcount', 0)
            local multiRate = 3
            if XInfo.allHistory == 1 then multiRate = 1 end
            if multiAuction == 2 then
                stackCount = 999
            elseif multiAuction == 1 then
                if item['star'] or dealCount >= 20 * multiRate then
                    stackCount = stackCount * 2
                end
            end
            if item['minpriceother'] >= item['lowestprice'] and bagCount > 0 and auctionCount < stackCount then
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
        print('Up: ' .. count)
    end
    refreshUI()
    if debug then print('puton Finished') end
end

clearAll = function(printCount)
    if debug then print('clearAll') end
    XInfo.reloadBag()
    XInfo.reloadAuction()
    local count = 0
    for _, item in ipairs(XAutoAuctionList) do
        local auctionItem = XInfo.getAuctionItem(item['itemname'])
        if auctionItem ~= nil then
            for _, record in ipairs(auctionItem['items']) do
                if record['price'] > item['minpriceother'] then
                    count = count + 1
                    CancelAuction(record['index'])
                end
            end
        end
    end
    if printCount == nil or printCount then
        print('Clear: ' .. count)
    end
    XInfo.reloadBag()
    XInfo.reloadAuction()
    refreshUI()
    if debug then print('clearAll Finished') end
end

shortPeriod = function(printCount)
    if debug then print('shortPeriod') end
    local numItems = GetNumAuctionItems('owner')
    if numItems <= 0 then
        return
    end
    local count = 0;
    for i = 1, numItems do
        local timeLeft = GetAuctionItemTimeLeft('owner', i)
        local itemName = GetAuctionItemInfo('owner', i);
        if timeLeft < 3 then
            count = count + 1
            CancelAuction(i)

            for _, item in ipairs(XAutoAuctionList) do
                if item['itemname'] == itemName then
                    item['minprice'] = dft_minPrice
                    item['myvalidlist'] = {}
                    item['lowercount'] = 0
                    item['allcount'] = 0
                    item['minpriceother'] = dft_minPrice
                    item['updatetime'] = 0
                    item['lastround'] = -99
                    break
                end
            end
        end
    end
    if printCount == nil or printCount then
        print('Short: ' .. count)
    end
    XInfo.reloadAuction()
    refreshUI()
    if debug then print('shortPeriod Finished') end
end

printList = function()
    XAutoAuction.refreshUI()
    print('----------')
    if #taskList <= 0 then
        print('暂无任务')
        return
    end
    for i = #taskList, 1, -1 do
        local task = taskList[i]
        if task['action'] == 'query' then
            print('[' .. i .. ']查询: ' .. XAutoAuctionList[task['index']]['itemname'])
        elseif task['action'] == 'auction' then
            print('[' .. i .. ']拍卖: ' .. task['itemname'])
        end
    end
    print('total: ' .. #taskList)
end

-- Event callback
local function onQueryItemListUpdate()
    if debug then print('onQueryItemListUpdate') end
    if not isTasking then return end
    if not curTask then return end
    if curTask['action'] ~= 'query' then return end
    if not XAutoAuctionList[curTask['index']] then return end

    local item = XAutoAuctionList[curTask['index']]

    local itemName, _, stackCount, _, _, _, _, _, _, buyoutPrice, _, _, _, seller = GetAuctionItemInfo('list', 1);
    if not itemName then
        curTask['queryfound'] = false

        isTasking = false
        curTask['queryresultprocessed'] = false
        return
    end

    if itemName ~= item['itemname'] then return end

    buyoutPrice = buyoutPrice / stackCount

    if fastAuction then -- 快速模式
        if buyoutPrice <= item['lowestprice'] then
            curTask['queryfound'] = true
        else
            if not curTask['onemorepage'] then
                curTask['onemorepage'] = true
                curTask['queryfound'] = true
            else
                curTask['queryfound'] = false
            end
        end
    else
        curTask['queryfound'] = true
    end

    isTasking = false
    curTask['queryresultprocessed'] = false
    if debug then print('onQueryItemListUpdate Finished') end
end

local function onAuctionSuccess()
    if debug then print('onAuctionSuccess') end
    if not isTasking then return end
    if not curTask then return end
    if curTask['action'] ~= 'auction' then return end

    isTasking = false
    if debug then print('onAuctionSuccess Finished') end
end

local function onUpdate()
    if debug then print('onUpdate') end
    refreshUI()

    if not isStarted then return end

    if isTasking then
        if not curTask then
            finishTask()
            refreshUI()
            return
        end

        if time() - curTask['starttime'] > dft_taskTimeout then
            finishTask()
            refreshUI()
            return
        end
    end

    if curTask then
        if curTask['action'] == 'auction' then
            finishTask()
            refreshUI()
            return
        end

        if curTask['queryfound'] == true then
            local item = XAutoAuctionList[curTask['index']]
            if not curTask['queryresultprocessed'] then
                item['updatetime'] = time()

                local index = 1
                while true do
                    local itemName, _, stackCount, _, _, _, _, _, _, buyoutPrice, _, _, _, seller, _, _, itemId =
                        GetAuctionItemInfo('list', index);

                    if not itemName then break end

                    buyoutPrice = buyoutPrice / stackCount
                    XExternal.addScanHistory(itemName, itemId, time(), buyoutPrice)

                    if buyoutPrice ~= nil and buyoutPrice > 0 then
                        if buyoutPrice < item['minprice'] then
                            item['minprice'] = buyoutPrice
                        end

                        if buyoutPrice < item['lowestprice'] then
                            item['lowercount'] = item['lowercount'] + 1
                        end

                        item['allcount'] = item['allcount'] + 1

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

                curTask['queryresultprocessed'] = true
            end

            if time() - lastTaskFinishTime < dft_taskInterval then return end
            if not CanSendAuctionQuery() then return end

            curTask['page'] = curTask['page'] + 1
            curTask['starttime'] = time()
            curTask['queryfound'] = nil
            curTask['queryresultprocessed'] = false
            isTasking = true
            QueryAuctionItems(item['itemname'], nil, nil, curTask['page'], nil, nil, false, true)

            refreshUI()
            return
        end

        if curTask['queryfound'] == false then
            local item = XAutoAuctionList[curTask['index']]

            item['updatetime'] = time()
            item['lastround'] = queryRound

            XInfo.reloadBag()
            XInfo.reloadAuction()

            local itemBag = XInfo.getBagItem(item['itemname'])
            if not itemBag then
                finishTask()
                refreshUI()
                return
            end

            local price = item['defaultprice']
            if item['minpriceother'] ~= dft_minPrice then
                price = item['minpriceother'] - dft_deltaPrice
            end
            if item['minpriceother'] >= item['lowestprice'] and price < item['lowestprice'] then
                price = item['lowestprice']
            end
            if price > dft_maxPrice then
                price = dft_maxPrice
            end
            if price < item['lowestprice'] then
                finishTask()
                refreshUI()
                return
            end

            local dealCount = XInfo.getAuctionInfoField(item['itemname'], 'dealcount', 0)
            local multiRate = 3
            if XInfo.allHistory == 1 then multiRate = 1 end
            local myValidCount = 0
            local auctionItem = XInfo.getAuctionItem(item['itemname'])
            if auctionItem then myValidCount = auctionItem['count'] end
            local minPriceCount = #item['myvalidlist']
            if minPriceCount < myValidCount then myValidCount = minPriceCount end

            local targetCount = item['stackcount']
            if multiAuction == 2 then
                targetCount = 999
            elseif multiAuction == 1 then
                if item['star'] or dealCount >= 20 * multiRate then
                    targetCount = targetCount * 2
                end
            end
            local subcount = targetCount - myValidCount
            if myValidCount <= 0 then
                subcount = targetCount
            end
            if itemBag['count'] < subcount then
                subcount = itemBag['count']
            end
            if subcount <= 0 then
                finishTask()
                refreshUI()
                return
            end

            insertAuctionTaskByIndex(curTask['index'], price, subcount)

            finishTask()
            refreshUI()
            return
        end

        finishTask()
        refreshUI()
        return
    end

    if #taskList > 0 then
        if time() - lastTaskFinishTime < dft_taskInterval then return end

        if taskList[1]['action'] == 'auction' then
            curTask = taskList[1]
            table.remove(taskList, 1)
            isTasking = true
            curTask['starttime'] = time()

            local price = curTask['price']
            local count = curTask['count']
            local index = curTask['index']

            local item = XAutoAuctionList[index]
            if not item then
                finishTask()
                refreshUI()
                return
            end

            XInfo.reloadBag()
            local bagItem = XInfo.getBagItem(item['itemname'])
            if not bagItem then
                finishTask()
                refreshUI()
                return
            end

            local position = bagItem['positions'][1]
            ClearCursor()
            ClickAuctionSellItemButton()
            ClearCursor()
            C_Container.PickupContainerItem(position[1], position[2])
            ClickAuctionSellItemButton()

            if GetAuctionSellItemInfo() == nil then
                finishTask()
                refreshUI()
                return
            end

            -- PostAuction(startPrice, buyoutPrice, duration, stackSize, stacks)
            PostAuction(price, price, 1, 1, count)

            for _ = 1, count do
                table.insert(item['myvalidlist'], price)
            end

            refreshUI()
            return
        end

        if taskList[1]['action'] == 'query' then
            if not CanSendAuctionQuery() then return end

            curTask = taskList[1]
            table.remove(taskList, 1)
            isTasking = true
            curTask['starttime'] = time()

            local index = curTask['index']
            local item = XAutoAuctionList[index]

            item['minprice'] = dft_minPrice
            item['myvalidlist'] = {}
            item['lowercount'] = 0
            item['allcount'] = 0
            item['minpriceother'] = dft_minPrice

            curTask['page'] = 0
            curTask['starttime'] = time()
            curTask['queryfound'] = nil
            curTask['queryresultprocessed'] = false
            QueryAuctionItems(item['itemname'], nil, nil, curTask['page'], nil, nil, false, true)

            refreshUI()
            return
        end

        finishTask()
        refreshUI()
        return
    end

    if autoAuction then
        addCraftQueue(false, false)
        puton(false)
    end

    if time() - queryRoundFinishTime < dft_roundInterval then return end

    local nextTaskIndex = -1

    if queryRound == 1 then
        for i = starQueryIndex, #XAutoAuctionList do
            local item = XAutoAuctionList[i]
            if item and item['enabled'] and item['star'] and item['lastround'] < 1 then
                starQueryIndex = i
                nextTaskIndex = i
                break
            end
        end

        if nextTaskIndex == -1 then
            starQueryIndex = #XAutoAuctionList

            for i = queryIndex, #XAutoAuctionList do
                local item = XAutoAuctionList[i]
                if item and item['enabled'] and (not item['star']) and item['lastround'] < 1 then
                    local round = math.floor(item['lowercount'] / 20)
                    if round > 3 then round = 3 end
                    if item['lastround'] + round <= queryRound then
                        queryIndex = i
                        nextTaskIndex = i
                        break
                    end
                end
            end
        end

        if nextTaskIndex == -1 then
            queryIndex = 1
            starQueryIndex = 1
            queryStarFlag = true

            queryRound = queryRound + 1
            queryRoundFinishTime = time()
            autoAuction = true

            refreshUI()
            return
        end

        addQueryTaskByIndex(nextTaskIndex)
        refreshUI()
        return
    end

    if queryStarFlag then
        for idx = starQueryIndex, #XAutoAuctionList do
            local item = XAutoAuctionList[idx]
            if item and item['enabled'] and item['star'] then
                starQueryIndex = idx
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
                    queryIndex = idx
                    nextTaskIndex = idx
                    break
                end
            end
        end
        queryStarFlag = not queryStarFlag
    end

    if nextTaskIndex == -1 then
        refreshUI()
        return
    end

    addQueryTaskByIndex(nextTaskIndex)
    if debug then print('onUpdate Finished') end
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initData()
    initUI()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_ITEM_LIST_UPDATE', onQueryItemListUpdate)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_SHOW', function(self, event, text, context)
    stop()
    if mainFrame then mainFrame:Show() end
end)

XAutoAuction.registerEventCallback(moduleName, 'AUCTION_HOUSE_CLOSED', function(self, event, text, context)
    stop()
    if mainFrame then mainFrame:Hide() end
end)

XAutoAuction.registerEventCallback(moduleName, 'CHAT_MSG_SYSTEM', function(self, event, text, context)
    -- TODO 确定文字内容，以及拍卖的回调
    if text == '已开始拍卖。' then
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
    addCraftQueue(true, true)
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

SlashCmdList['XAUCTIONCENTERCLEARALL'] = function()
    clearAll()
    shortPeriod()
end
SLASH_XAUCTIONCENTERCLEARALL1 = '/xauctioncenter_clearall'

-- Interfaces
XAuctionCenter.addQueryTaskByItemName = addQueryTaskByItemName
XAuctionCenter.getAuctionItem = getAuctionItem
