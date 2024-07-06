XAuctionCenter = CreateFrame("Frame")

local dft_minPrice = 9999999
local dft_maxPrice = 2180000
local dft_lowestPriceRate = 1.5
local dft_roundInterval = 3
local dft_taskInterval = 1
local dft_taskTimeout = 30
local dft_filterList = { '全部', '可售', '优质', '价低'}
local dft_deltaPrice = 10

local fastAuction = true
local autoAuction = false
local displayFilter = 1
local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local isStarted = false
local curTask = nil
local lastTaskFinishTime = 0
local taskList = {}

local isQuerying = false
local queryIndex = 0
local queryRound = 1
local starQueryIndex = 0
local queryStarFlag = true
local queryRoundFinishTime = 0
local multiAuction = 0

local isAuction = false

local function getMaterialCount(itemName, type)
    if type == nil then type = 'totalcount' end
    local materialBagItem = XInfo.getMaterialBagItem(itemName)
    if not materialBagItem then return 0 end
    return materialBagItem[type]
end

local function getMaterialPrice(itemName)
    local price = 0
    local materialName = XInfo.getMaterialName(itemName)
    if materialName then
        local autoBuyItem = XAutoBuy.getBuyItem(materialName)
        if autoBuyItem then price = autoBuyItem['price'] end
    end
    return price
end

local function initData()
    if not XAutoAuctionList then return end
    for _, item in ipairs(XAutoAuctionList) do
        item['lastround'] = -99
    end
end

local function resetData()
    for _, item in ipairs(XAutoAuctionList) do
        item['minprice'] = dft_minPrice
        item['minpricelist'] = {}
        item['lowercount'] = 0
        item['minpriceother'] = dft_minPrice
        item['allcount'] = 0
        item['updatetime'] = 0
        item['lastround'] = -99
    end
    queryIndex = 0
    queryRound = 1
    starQueryIndex = 0
    queryStarFlag = true
end

XAuctionCenter.refreshUI = function()
    XInfo.reloadBag()
    XInfo.reloadAuction()
    if XAuctionCenter.mainFrame ~= nil then
        XAuctionCenter.mainFrame.title:SetText('自动拍卖 (' .. (displayPageNo + 1) .. '/'
            .. (math.ceil(#XAutoAuctionList / displayPageSize)) .. ')    Querying: '
            .. queryIndex .. '    StarQuerying: ' .. starQueryIndex .. '    Round: ' .. queryRound
            .. '    Queue: ' .. #taskList .. '    EmptyBag: ' .. XInfo.emptyBagCount)

        if fastAuction then
            XAuctionCenter.mainFrame.fastAuctionButton:SetText('快速')
        else
            XAuctionCenter.mainFrame.fastAuctionButton:SetText('慢速')
        end

        if autoAuction then
            XAuctionCenter.mainFrame.autoAuctionButton:SetText('自动')
        else
            XAuctionCenter.mainFrame.autoAuctionButton:SetText('手动')
        end

        if isStarted then
            XAuctionCenter.mainFrame.startButton:SetText('停止')
        else
            XAuctionCenter.mainFrame.startButton:SetText('开始')
        end

        if XInfo.allHistory then
            XAuctionCenter.mainFrame.dealCountTypeButton:SetText('ALL')
        else
            XAuctionCenter.mainFrame.dealCountTypeButton:SetText('10D')
        end

        if multiAuction == 2 then
            XAuctionCenter.mainFrame.multiAuctionButton:SetText('全部')
        elseif multiAuction == 1 then
            XAuctionCenter.mainFrame.multiAuctionButton:SetText('双倍')
        else
            XAuctionCenter.mainFrame.multiAuctionButton:SetText('单倍')
        end

        XAuctionCenter.mainFrame.filterButton:SetText(dft_filterList[displayFilter])
        UIDropDownMenu_SetText(XAuctionCenter.mainFrame.filterFrame, dft_filterList[displayFilter])

        if not curTask then
            XAuctionCenter.mainFrame.hintLabel:SetText('等待')
        else
            if curTask['action'] == 'query' then
                local item = XAutoAuctionList[curTask['index']]
                if item == nil then
                    XAuctionCenter.mainFrame.hintLabel:SetText('查询: 无')
                else
                    local page = curTask['page']
                    if page == nil then page = 0 end
                    XAuctionCenter.mainFrame.hintLabel:SetText('查询: [' .. curTask['index']
                        .. ']' .. item['itemname'] .. '(' .. page .. ')')
                end
            elseif curTask['action'] == 'auction' then
                XAuctionCenter.mainFrame.hintLabel:SetText('拍卖: ' .. curTask['itemname'])
            end
        end
    end

    local filterWord = XAuctionCenter.mainFrame.filterBox:GetText();
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
            local minPriceCount = #item['minpricelist']
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

            local succRate = XInfo.getAuctionInfoField(itemName, 'succrate', 99)
            local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)

            local disFlag = false
            if displayFilter == 1 then     -- 全部
                disFlag = true
            elseif displayFilter == 2 then -- 可售
                if enabled then
                    if star or minPriceOther >= lowestPrice then
                        disFlag = true
                    end
                end
            elseif displayFilter == 3 then -- 优质
                if enabled then
                    if star or minPriceOther >= lowestPrice then
                        if dealCount > 20 then
                            disFlag = true
                        end
                    end
                end
            elseif displayFilter == 4 then -- 价低
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
                        itemNameStr = '|cFF00FF00' .. itemNameStr
                    else
                        itemNameStr = '|cFFFF0000' .. itemNameStr
                    end
                else
                    itemNameStr = '|cFF999999' .. itemNameStr
                end

                local updateTimeStr = XUtils.formatTime(item['updatetime'])

                local bagCountStr = 'B' .. XUtils.formatCount(bagCount, 1)
                if bagCount >= stackCount * 2 then
                    bagCountStr = '|cFF00FFFF' .. bagCountStr
                elseif bagCount >= stackCount then
                    bagCountStr = '|cFF00FF00' .. bagCountStr
                elseif bagCount > 0 then
                    bagCountStr = '|cFFFFFF00' .. bagCountStr
                else
                    bagCountStr = '|cFFFF0000' .. bagCountStr
                end

                local materialCountStr = 'M' .. XUtils.formatCount2(materialCount)

                local auctionCountStr = 'A' .. XUtils.formatCount(auctionCount, 1)
                if auctionCount >= stackCount * 2 or auctionCount <= 0 then
                    auctionCountStr = '|cFFFF0000' .. auctionCountStr
                elseif auctionCount > stackCount or auctionCount < stackCount then
                    auctionCountStr = '|cFFFFFF00' .. auctionCountStr
                else
                    auctionCountStr = '|cFF00FF00' .. auctionCountStr
                end

                local minPriceCountStr = 'M' .. XUtils.formatCount(minPriceCount, 1)
                if minPriceCount >= stackCount * 2 or minPriceCount <= 0 then
                    minPriceCountStr = '|cFFFF0000' .. minPriceCountStr
                elseif minPriceCount > stackCount or minPriceCount < stackCount then
                    minPriceCountStr = '|cFFFFFF00' .. minPriceCountStr
                else
                    minPriceCountStr = '|cFF00FF00' .. minPriceCountStr
                end

                local bagAuctionCountStr = 'T' .. XUtils.formatCount(bagAuctionCount, 2)
                if bagAuctionCount >= stackCount * 2 then
                    bagAuctionCountStr = '|cFF00FFFF' .. bagAuctionCountStr
                elseif bagAuctionCount >= stackCount then
                    bagAuctionCountStr = '|cFF00FF00' .. bagAuctionCountStr
                elseif bagAuctionCount > 0 then
                    bagAuctionCountStr = '|cFFFFFF00' .. bagAuctionCountStr
                else
                    bagAuctionCountStr = '|cFFFF0000' .. bagAuctionCountStr
                end

                local lowerCountStr = 'L' .. XUtils.formatCount(lowerCount)
                if lowerCount > 5 then
                    lowerCountStr = '|cFFFF0000' .. lowerCountStr
                elseif lowerCount > 0 then
                    lowerCountStr = '|cFFFFFF00' .. lowerCountStr
                else
                    lowerCountStr = '|cFFFFFFFF' .. lowerCountStr
                end

                local allCountStr = 'A' .. XUtils.formatCount(allCount)
                if allCount > 20 then
                    allCountStr = '|cFFFF0000' .. allCountStr
                elseif allCount > 10 then
                    allCountStr = '|cFFFFFF00' .. allCountStr
                else
                    allCountStr = '|cFF00FF00' .. allCountStr
                end

                local stackCountStr = 'S' .. XUtils.formatCount(stackCount, 1)
                if stackCount > 2 then
                    stackCountStr = '|cFF00FFFF' .. stackCountStr
                elseif stackCount > 1 then
                    stackCountStr = '|cFF00FF00' .. stackCountStr
                end

                local minPriceStr = XUtils.priceToString(minPrice)
                if minPrice < lowestPrice then
                    minPriceStr = '|cFFFF0000' .. minPriceStr
                elseif minPrice < lowestPrice * dft_lowestPriceRate then
                    minPriceStr = '|cFFFFFF00' .. minPriceStr
                elseif minPrice < lowestPrice * dft_lowestPriceRate * dft_lowestPriceRate then
                    minPriceStr = '|cFF00FF00' .. minPriceStr
                else
                    minPriceStr = '|cFF00FFFF' .. minPriceStr
                end

                local lowestPriceStr = '|cFFFFFFFF' .. XUtils.priceToString(lowestPrice)

                local succRateStr = 'R' .. XUtils.formatCount(XUtils.round(succRate))
                if succRate > 5 then
                    succRateStr = '|cFFFF0000' .. succRateStr
                elseif succRate > 3 then
                    succRateStr = '|cFFFFFF00' .. succRateStr
                elseif succRate > 2 then
                    succRateStr = '|cFF00FF00' .. succRateStr
                else
                    succRateStr = '|cFF00FFFF' .. succRateStr
                end

                local dealCountStr = 'D' .. XUtils.formatCount(dealCount)
                if dealCount > 20 then
                    dealCountStr = '|cFF00FFFF' .. dealCountStr
                elseif dealCount > 10 then
                    dealCountStr = '|cFF00FF00' .. dealCountStr
                elseif dealCount > 3 then
                    dealCountStr = '|cFFFFFF00' .. dealCountStr
                else
                    dealCountStr = '|cFFFF0000' .. dealCountStr
                end

                frame.itemIndexButton:SetText(idx)
                frame.itemNameButton:SetText(itemNameStr)
                frame.label:SetText(updateTimeStr .. '  '
                    .. bagCountStr .. "|cFFFFFFFF/" .. bagAuctionCountStr .. '|cFFFFFFFF/' .. materialCountStr
                    .. '|cFFFFFFFF/' .. auctionCountStr .. '|cFFFFFFFF/' .. minPriceCountStr
                    .. '|cFFFFFFFF/' .. lowerCountStr .. '|cFFFFFFFF/' .. allCountStr
                    .. '|cFFFFFFFF/' .. stackCountStr .. '  ' .. succRateStr
                    .. '|cFFFFFFFF/' .. dealCountStr .. '  ' .. minPriceStr
                    .. '|cFFFFFFFF/' .. lowestPriceStr)

                if enabled then
                    frame.enableButton:SetText('|cFF00FF00起')
                else
                    frame.enableButton:SetText('|cFFFF0000停')
                end

                if star then
                    frame.starButton:SetText('|cFF00FF00星')
                else
                    frame.starButton:SetText('|cFFFF0000星')
                end
                frame:Show()
            else
                frame:Hide()
            end
        else
            frame:Hide()
        end
    end
end

local function addCraftQueue(printCount, manualAdd)
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
                    local minPriceCount = #item['minpricelist']

                    local subCount = stackCount - auctionCount - bagCount
                    if queryRound > 1 or manualAdd then
                        if item['star'] or dealCount >= 20 then
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
    XAuctionCenter.refreshUI()
end

local function puton(printCount)
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
            local minPriceCount = #item['minpricelist']
            if minPriceCount < auctionCount then auctionCount = minPriceCount end
            local stackCount = item['stackcount']
            local dealCount = XInfo.getAuctionInfoField(item['itemname'], 'dealcount', 0)
            if multiAuction == 2 then
                stackCount = 999
            elseif multiAuction == 1 then
                if item['star'] or dealCount >= 20 then
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
        XAuctionCenter.addQueryTaskByIndex(idx)
    end
    for _, idx in ipairs(unStarQueue) do
        XAuctionCenter.addQueryTaskByIndex(idx)
    end
    if printCount == nil or printCount then
        print('Up: ' .. count)
    end
    XAuctionCenter.refreshUI()
end

local function clearAll(printCount)
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
    XAuctionCenter.refreshUI()
end

local function shortPeriod(printCount)
    local numItems = GetNumAuctionItems("owner")
    if numItems <= 0 then
        return
    end
    local count = 0;
    for i = 1, numItems do
        local timeLeft = GetAuctionItemTimeLeft("owner", i)
        local itemName = GetAuctionItemInfo("owner", i);
        if timeLeft < 3 then
            count = count + 1
            CancelAuction(i)

            for _, item in ipairs(XAutoAuctionList) do
                if item['itemname'] == itemName then
                    item['minprice'] = dft_minPrice
                    item['minpricelist'] = {}
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
    XAuctionCenter.refreshUI()
end

local function printList()
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

local function start()
    queryIndex = queryIndex - 1
    if queryIndex < 0 then queryIndex = 0 end
    isStarted = true
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0
    isQuerying = false
    queryRoundFinishTime = 0
    isAuction = false
    XAuctionCenter.refreshUI()
end

local function stop()
    isStarted = false
    taskList = {}
    curTask = nil
    lastTaskFinishTime = 0
    isQuerying = false
    queryRoundFinishTime = 0
    isAuction = false
    XAuctionCenter.refreshUI()
end

local function finishTask()
    curTask = nil
    table.remove(taskList, 1)
    lastTaskFinishTime = time()
    isQuerying = false
    isAuction = false
end

local function initUI_Filter()
    local dropdown = CreateFrame("Frame", "XXAutoAuctionFilterFrame", UIParent, "UIDropDownMenuTemplate")
    dropdown:SetFrameStrata("DIALOG")
    dropdown:Hide()
    XAuctionCenter.mainFrame.filterFrame = dropdown

    -- Set initial text for the dropdown
    UIDropDownMenu_SetText(dropdown, "全部")

    -- Define the initialize function for the dropdown
    UIDropDownMenu_Initialize(dropdown, function()
        for i = 1, #dft_filterList do
            local info = UIDropDownMenu_CreateInfo()
            info.text = dft_filterList[i]
            info.func = function()
                displayFilter = i
                XAuctionCenter.mainFrame.filterFrame:Hide()
                XAuctionCenter.refreshUI()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    dropdown:SetPoint("BOTTOM", UIParent, "CENTER")
    dropdown:SetSize(100, 30) -- Set the width and height

    -- Show the dropdown
    UIDropDownMenu_SetAnchor(dropdown, 0, 0, "TOP", UIParent, "CENTER")
    -- UIDropDownMenu_Show(dropdown)
end

local function initUI_Setting()
    local settingFrame = XUI.createFrame('XAuctionCenterSettingFrame', 220, 150, 'DIALOG')
    settingFrame.title:SetText("自动拍卖设置")
    settingFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    settingFrame:Hide()
    XAuctionCenter.mainFrame.settingFrame = settingFrame

    local itemNameLabel = XUI.createLabel(settingFrame, 50, 'NM')
    itemNameLabel:SetPoint("TOPLEFT", settingFrame, "TOPLEFT", 15, -30)

    local itemNameEditBox = XUI.createEditbox(settingFrame, 145, true)
    itemNameEditBox:SetPoint("LEFT", itemNameLabel, "RIGHT", 5, 0)
    itemNameEditBox:SetScript("OnEscapePressed", function() XAuctionCenter.mainFrame.settingFrame:Hide() end)
    itemNameEditBox:SetScript("OnTabPressed", function()
        XAuctionCenter.mainFrame.settingFrame.lowestPriceEditBox:SetFocus()
    end)
    settingFrame.itemNameEditBox = itemNameEditBox

    local lowestPriceLabel = XUI.createLabel(settingFrame, 50, 'LP')
    lowestPriceLabel:SetPoint("TOP", itemNameLabel, "BOTTOM", 0, 0)

    local lowestPriceEditBox = XUI.createEditbox(settingFrame, 180, false)
    lowestPriceEditBox:SetPoint("LEFT", lowestPriceLabel, "RIGHT", 5, 0)
    lowestPriceEditBox:SetScript("OnEscapePressed", function() XAuctionCenter.mainFrame.settingFrame:Hide() end)
    lowestPriceEditBox:SetScript("OnTabPressed", function()
        XAuctionCenter.mainFrame.settingFrame.defaultPriceEditBox:SetFocus()
    end)
    settingFrame.lowestPriceEditBox = lowestPriceEditBox

    local defaultPriceLabel = XUI.createLabel(settingFrame, 50, 'DP')
    defaultPriceLabel:SetPoint("TOP", lowestPriceLabel, "BOTTOM", 0, 0)

    local defaultPriceEditBox = XUI.createEditbox(settingFrame, 180, false)
    defaultPriceEditBox:SetPoint("LEFT", defaultPriceLabel, "RIGHT", 5, 0)
    defaultPriceEditBox:SetScript("OnEscapePressed", function() XAuctionCenter.mainFrame.settingFrame:Hide() end)
    defaultPriceEditBox:SetScript("OnTabPressed", function()
        XAuctionCenter.mainFrame.settingFrame.countEditBox:SetFocus()
    end)
    settingFrame.defaultPriceEditBox = defaultPriceEditBox

    local countLabel = XUI.createLabel(settingFrame, 50, 'CT')
    countLabel:SetPoint("TOP", defaultPriceLabel, "BOTTOM", 0, 0)

    local countEditBox = XUI.createEditbox(settingFrame, 180, false)
    countEditBox:SetPoint("LEFT", countLabel, "RIGHT", 5, 0)
    countEditBox:SetScript("OnEscapePressed", function() XAuctionCenter.mainFrame.settingFrame:Hide() end)
    countEditBox:SetScript("OnEnterPressed", function()
        local name = XAuctionCenter.mainFrame.settingFrame.itemNameEditBox:GetText()
        local lowestPrice = tonumber(XAuctionCenter.mainFrame.settingFrame.lowestPriceEditBox:GetText())
        local defaultPrice = tonumber(XAuctionCenter.mainFrame.settingFrame.defaultPriceEditBox:GetText())
        local count = tonumber(XAuctionCenter.mainFrame.settingFrame.countEditBox:GetText())
        if displaySettingItem == nil then
            XAuctionCenter.addItem(name, lowestPrice, defaultPrice, count)
        else
            displaySettingItem['itemname'] = name
            displaySettingItem['lowestprice'] = lowestPrice
            displaySettingItem['defaultprice'] = defaultPrice
            displaySettingItem['stackcount'] = count
        end
        XAuctionCenter.mainFrame.settingFrame:Hide()
        XAuctionCenter.refreshUI()
    end)
    settingFrame.countEditBox = countEditBox
end

local function initUI_Price()
    local priceFrame = XUI.createFrame('XAuctionCenterPriceFrame', 220, 160, 'DIALOG')
    priceFrame.title:SetText("价格调整")
    priceFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    priceFrame:Hide()
    XAuctionCenter.mainFrame.priceFrame = priceFrame

    local itemNameLabel = XUI.createLabel(priceFrame, 50, '名称:')
    itemNameLabel:SetPoint("TOPLEFT", priceFrame, "TOPLEFT", 15, -30)

    local itemNameEditBox = XUI.createEditbox(priceFrame, 145, true)
    itemNameEditBox:SetPoint("LEFT", itemNameLabel, "RIGHT", 5, 0)
    itemNameEditBox:SetScript("OnEscapePressed", function() XAuctionCenter.mainFrame.priceFrame:Hide() end)
    itemNameEditBox:SetScript("OnTabPressed", function()
        XAuctionCenter.mainFrame.priceFrame.lowestPriceEditBox:SetFocus()
    end)
    itemNameEditBox:SetScript("OnEnterPressed", function()
        local name = XAuctionCenter.mainFrame.priceFrame.itemNameEditBox:GetText()
        local all = false
        if XUtils.stringStartsWith(name, '*') then
            all = true
            name = string.gsub(name, "^%*", "")
        end
        print('----------')
        for _, item in ipairs(XAutoAuctionList) do
            if XUtils.stringContains(item['itemname'], name) then
                if item['enabled'] ~= nil and item['enabled'] then
                    if all or (not item['star']) or (not item['star']) then
                        print(item['itemname'] .. ':  '
                            .. XUtils.priceToMoneyString(item['lowestprice']) .. ' / '
                            .. XUtils.priceToMoneyString(item['defaultprice']))
                    end
                end
            end
        end
    end)
    priceFrame.itemNameEditBox = itemNameEditBox

    local lowestPriceLabel = XUI.createLabel(priceFrame, 50, '底价:')
    lowestPriceLabel:SetPoint("TOP", itemNameLabel, "BOTTOM", 0, 0)

    local lowestPriceEditBox = XUI.createEditbox(priceFrame, 180, false)
    lowestPriceEditBox:SetPoint("LEFT", lowestPriceLabel, "RIGHT", 5, 0)
    lowestPriceEditBox:SetScript("OnEscapePressed", function() XAuctionCenter.mainFrame.priceFrame:Hide() end)
    lowestPriceEditBox:SetScript("OnTabPressed", function()
        XAuctionCenter.mainFrame.priceFrame.defaultPriceEditBox:SetFocus()
    end)
    lowestPriceEditBox:SetScript("OnEnterPressed", function()
        local name = XAuctionCenter.mainFrame.priceFrame.itemNameEditBox:GetText()
        local all = false
        if XUtils.stringStartsWith(name, '*') then
            all = true
            name = string.gsub(name, "^%*", "")
        end
        print('----------')
        for _, item in ipairs(XAutoAuctionList) do
            if XUtils.stringContains(item['itemname'], name) then
                if item['enabled'] ~= nil and item['enabled'] then
                    if all or (not item['star']) or (not item['star']) then
                        print(item['itemname'] .. ':  '
                            .. XUtils.priceToMoneyString(item['lowestprice']) .. ' / '
                            .. XUtils.priceToMoneyString(item['defaultprice']))
                    end
                end
            end
        end
    end)
    priceFrame.lowestPriceEditBox = lowestPriceEditBox

    local defaultPriceLabel = XUI.createLabel(priceFrame, 50, '高价:')
    defaultPriceLabel:SetPoint("TOP", lowestPriceLabel, "BOTTOM", 0, 0)

    local defaultPriceEditBox = XUI.createEditbox(priceFrame, 180, false)
    defaultPriceEditBox:SetPoint("LEFT", defaultPriceLabel, "RIGHT", 5, 0)
    defaultPriceEditBox:SetScript("OnEscapePressed", function() XAuctionCenter.mainFrame.priceFrame:Hide() end)
    defaultPriceEditBox:SetScript("OnEnterPressed", function()
        local name = XAuctionCenter.mainFrame.priceFrame.itemNameEditBox:GetText()
        local all = false
        if XUtils.stringStartsWith(name, '*') then
            all = true
            name = string.gsub(name, "^%*", "")
        end
        print('----------')
        for _, item in ipairs(XAutoAuctionList) do
            if XUtils.stringContains(item['itemname'], name) then
                if item['enabled'] ~= nil and item['enabled'] then
                    if all or (not item['star']) or (not item['star']) then
                        print(item['itemname'] .. ':  '
                            .. XUtils.priceToMoneyString(item['lowestprice']) .. ' / '
                            .. XUtils.priceToMoneyString(item['defaultprice']))
                    end
                end
            end
        end
    end)
    priceFrame.defaultPriceEditBox = defaultPriceEditBox

    local confirmButton = XUI.createButton(priceFrame, 80, '调整')
    confirmButton:SetPoint('BOTTOM', priceFrame, 'BOTTOM', 0, 15)
    confirmButton:SetScript("OnClick", function(self)
        local name = XAuctionCenter.mainFrame.priceFrame.itemNameEditBox:GetText()
        local lowestPrice = tonumber(XAuctionCenter.mainFrame.priceFrame.lowestPriceEditBox:GetText())
        local defaultPrice = tonumber(XAuctionCenter.mainFrame.priceFrame.defaultPriceEditBox:GetText())
        local all = false
        if XUtils.stringStartsWith(name, '*') then
            all = true
            name = string.gsub(name, "^%*", "")
        end

        local count = 0
        for _, item in ipairs(XAutoAuctionList) do
            if XUtils.stringContains(item['itemname'], name) then
                if item['enabled'] ~= nil and item['enabled'] then
                    if all or (not item['star']) or (not item['star']) then
                        item['lowestprice'] = lowestPrice
                        item['defaultprice'] = defaultPrice
                        count = count + 1
                    end
                end
            end
        end

        print('Modified Count: ' .. count)
        XAuctionCenter.mainFrame.priceFrame:Hide()
        XAuctionCenter.refreshUI()
    end)
end

local function initUI()
    local mainFrame = XUI.createFrame("XAuctionCenterMainFrame", 905, 430)
    mainFrame.title:SetText("自动拍卖")
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", -50, 0)
    mainFrame:Hide()
    XAuctionCenter.mainFrame = mainFrame

    local preButton = XUI.createButton(mainFrame, 45, '上页')
    preButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -30)
    preButton:SetScript("OnClick", function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            XAuctionCenter.refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, 45, '下页')
    nextButton:SetPoint("LEFT", preButton, "RIGHT", 1, 0)
    nextButton:SetScript("OnClick", function()
        if displayPageNo < math.ceil(#XAutoAuctionList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            XAuctionCenter.refreshUI()
        end
    end)

    local startButton = XUI.createButton(mainFrame, 45, '开始')
    startButton:SetPoint("LEFT", nextButton, "RIGHT", 10, 0)
    startButton:SetScript("OnClick", function()
        if isStarted then
            stop()
        else
            start()
        end
    end)
    mainFrame.startButton = startButton

    local resetButton = XUI.createButton(mainFrame, 45, '重置')
    resetButton:SetPoint("LEFT", startButton, "RIGHT", 1, 0)
    resetButton:SetScript("OnClick", function()
        resetData()
        XAuctionCenter.refreshUI()
    end)

    local autoAuctionButton = XUI.createButton(mainFrame, 45, '自动')
    autoAuctionButton:SetPoint("LEFT", resetButton, "RIGHT", 1, 0)
    autoAuctionButton:SetScript("OnClick", function()
        autoAuction = not autoAuction
        XAuctionCenter.refreshUI()
    end)
    mainFrame.autoAuctionButton = autoAuctionButton

    local fastAuctionButton = XUI.createButton(mainFrame, 45, '快速')
    fastAuctionButton:SetPoint("LEFT", autoAuctionButton, "RIGHT", 1, 0)
    fastAuctionButton:SetScript("OnClick", function()
        fastAuction = not fastAuction
        XAuctionCenter.refreshUI()
    end)
    mainFrame.fastAuctionButton = fastAuctionButton

    local putonButton = XUI.createButton(mainFrame, 45, '上架')
    putonButton:SetPoint("LEFT", fastAuctionButton, "RIGHT", 10, 0)
    putonButton:SetScript("OnClick", function()
        puton()
    end)

    local craftAllButton = XUI.createButton(mainFrame, 45, '制造')
    craftAllButton:SetPoint("LEFT", putonButton, "RIGHT", 1, 0)
    craftAllButton:SetScript("OnClick", function()
        addCraftQueue(true, true)
    end)

    local cleanButton = XUI.createButton(mainFrame, 45, '清理')
    cleanButton:SetPoint("LEFT", craftAllButton, "RIGHT", 1, 0)
    cleanButton:SetScript("OnClick", function()
        clearAll()
    end)

    local shortPeriodButton = XUI.createButton(mainFrame, 45, '短期')
    shortPeriodButton:SetPoint("LEFT", cleanButton, "RIGHT", 1, 0)
    shortPeriodButton:SetScript("OnClick", function()
        shortPeriod()
    end)

    local refreshButton = XUI.createButton(mainFrame, 45, '刷新')
    refreshButton:SetPoint("LEFT", shortPeriodButton, "RIGHT", 10, 0)
    refreshButton:SetScript("OnClick", function()
        XAutoAuction.refreshUI()
    end)

    local printButton = XUI.createButton(mainFrame, 45, '打印')
    printButton:SetPoint("LEFT", refreshButton, "RIGHT", 1, 0)
    printButton:SetScript("OnClick", function()
        printList()
    end)

    local hintLabel = XUI.createLabel(mainFrame, 220, '')
    hintLabel:SetPoint("LEFT", printButton, "RIGHT", 5, 0)
    mainFrame.hintLabel = hintLabel

    local firstButton = XUI.createButton(mainFrame, 45, '首页')
    firstButton:SetPoint("TOPLEFT", preButton, "BOTTOMLEFT")
    firstButton:SetScript("OnClick", function()
        displayPageNo = 0
        XAuctionCenter.refreshUI()
    end)

    local lastButton = XUI.createButton(mainFrame, 45, '末页')
    lastButton:SetPoint("LEFT", firstButton, "RIGHT", 1, 0)
    lastButton:SetScript("OnClick", function()
        displayPageNo = math.ceil(#XAutoAuctionList / displayPageSize) - 1;
        XAuctionCenter.refreshUI()
    end)

    local filter1Button = XUI.createButton(mainFrame, 45, '全部')
    filter1Button:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    filter1Button:SetScript("OnClick", function()
        XAuctionCenter.mainFrame.filterBox:SetText("")
        displayFilter = 1
        XAuctionCenter.refreshUI()
    end)

    local filter2Button = XUI.createButton(mainFrame, 45, '可售')
    filter2Button:SetPoint("LEFT", filter1Button, "RIGHT", 1, 0)
    filter2Button:SetScript("OnClick", function()
        displayFilter = 2
        XAuctionCenter.refreshUI()
    end)

    local filter3Button = XUI.createButton(mainFrame, 45, '优质')
    filter3Button:SetPoint("LEFT", filter2Button, "RIGHT", 1, 0)
    filter3Button:SetScript("OnClick", function()
        displayFilter = 3
        XAuctionCenter.refreshUI()
    end)

    local filter4Button = XUI.createButton(mainFrame, 45, '价低')
    filter4Button:SetPoint("LEFT", filter3Button, "RIGHT", 1, 0)
    filter4Button:SetScript("OnClick", function()
        displayFilter = 4
        XAuctionCenter.refreshUI()
    end)

    local filterButton = XUI.createButton(mainFrame, 45, '全部')
    filterButton:SetPoint("LEFT", filter4Button, "RIGHT", 1, 0)
    filterButton:SetScript("OnClick", function()
        XAuctionCenter.mainFrame.filterFrame:Show()
    end)
    mainFrame.filterButton = filterButton

    local dealCountTypeButton = XUI.createButton(mainFrame, 45, '10D')
    dealCountTypeButton:SetPoint("LEFT", filterButton, "RIGHT", 1, 0)
    dealCountTypeButton:SetScript("OnClick", function()
        XInfo.allHistory = not XInfo.allHistory
        XAuctionCenter.refreshUI()
    end)
    mainFrame.dealCountTypeButton = dealCountTypeButton

    local settingButton = XUI.createButton(mainFrame, 45, '添加')
    settingButton:SetPoint("LEFT", dealCountTypeButton, "RIGHT", 10, 0)
    settingButton:SetScript("OnClick", function()
        if XAuctionCenter.mainFrame.settingFrame ~= nil then
            displaySettingItem = nil
            XAuctionCenter.mainFrame.settingFrame.itemNameEditBox:SetText('')
            XAuctionCenter.mainFrame.settingFrame.lowestPriceEditBox:SetText('')
            XAuctionCenter.mainFrame.settingFrame.defaultPriceEditBox:SetText('')
            XAuctionCenter.mainFrame.settingFrame.countEditBox:SetText('')
            XAuctionCenter.mainFrame.settingFrame:Show()
            XAuctionCenter.mainFrame.settingFrame.itemNameEditBox:SetFocus()
        end
    end)

    local priceButton = XUI.createButton(mainFrame, 45, '调价')
    priceButton:SetPoint("LEFT", settingButton, "RIGHT", 1, 0)
    priceButton:SetScript("OnClick", function()
        if XAuctionCenter.mainFrame.settingFrame ~= nil then
            XAuctionCenter.mainFrame.priceFrame.itemNameEditBox:SetText('')
            XAuctionCenter.mainFrame.priceFrame.lowestPriceEditBox:SetText('')
            XAuctionCenter.mainFrame.priceFrame.defaultPriceEditBox:SetText('')
            XAuctionCenter.mainFrame.priceFrame:Show()
            XAuctionCenter.mainFrame.priceFrame.itemNameEditBox:SetFocus()
        end
    end)

    local multiAuctionButton = XUI.createButton(mainFrame, 45, '单倍')
    multiAuctionButton:SetPoint("LEFT", priceButton, "RIGHT", 1, 0)
    multiAuctionButton:SetScript("OnClick", function()
        multiAuction = (multiAuction + 1) % 3
        XAuctionCenter.refreshUI()
    end)
    mainFrame.multiAuctionButton = multiAuctionButton

    local filterBox = XUI.createEditbox(mainFrame, 90, false)
    filterBox:SetPoint("LEFT", multiAuctionButton, "RIGHT", 10, 0)
    filterBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    filterBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    filterBox:SetScript("OnEditFocusLost", function(self) self:SetText(self:GetText()) end)
    filterBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus();
        XAuctionCenter.refreshUI()
    end)
    mainFrame.filterBox = filterBox

    local lastWidget = nil
    for i = 1, displayPageSize do
        local frame = CreateFrame("Frame", nil, mainFrame)
        frame:SetSize(905, 30)

        if i == 1 then
            frame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -90)
        else
            frame:SetPoint("TOPLEFT", lastWidget, "BOTTOMLEFT", 0, -2)
        end

        frame:Hide()

        local itemIndexButton = XUI.createButton(frame, 35, '999')
        itemIndexButton:SetPoint("LEFT", frame, "LEFT", 15, 0)
        itemIndexButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i

            XUISortDialog.show('XAuctionCenter_Sort', XAutoAuctionList, idx, function()
                XAuctionCenter.refreshUI()
            end)
        end)
        frame.itemIndexButton = itemIndexButton

        local itemNameButton = XUI.createButton(frame, 160, '')
        itemNameButton:SetPoint("LEFT", itemIndexButton, "RIGHT", 0, 0)
        itemNameButton:SetScript("OnClick", function()
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

        local label = XUI.createLabel(frame, 470, '')
        label:SetPoint("LEFT", itemNameButton, "RIGHT", 3, 0)
        frame.label = label

        local deleteButton = XUI.createButton(frame, 30, '删')
        deleteButton:SetPoint("LEFT", label, "RIGHT", 0, 0)
        deleteButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #XAutoAuctionList then
                table.remove(XAutoAuctionList, idx)
                XAuctionCenter.refreshUI()
            end
        end)

        local cleanButton = XUI.createButton(frame, 30, '清')
        cleanButton:SetPoint("LEFT", deleteButton, "RIGHT", 0, 0)
        cleanButton:SetScript("OnClick", function()
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
        lowestButton:SetPoint("LEFT", cleanButton, "RIGHT", 0, 0)
        lowestButton:SetScript("OnClick", function()
            XInfo.reloadBag()
            XInfo.reloadAuction()
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoAuctionList[idx];
            if not item then return end
            local lowestPrice = XInfo.getAuctionInfoField(item['itemname'], 'lowestprice')
            if lowestPrice ~= nil then
                item['lowestprice'] = lowestPrice
            end
            XAuctionCenter.refreshUI()
        end)

        local craftButton = XUI.createButton(frame, 30, '设')
        craftButton:SetPoint("LEFT", lowestButton, "RIGHT", 0, 0)
        craftButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            displaySettingItem = XAutoAuctionList[idx]
            if not displaySettingItem then return end
            if not XAuctionCenter.mainFrame.settingFrame then return end

            XAuctionCenter.mainFrame.settingFrame.itemNameEditBox:SetText(displaySettingItem['itemname'])
            XAuctionCenter.mainFrame.settingFrame.lowestPriceEditBox:SetText(displaySettingItem['lowestprice'])
            XAuctionCenter.mainFrame.settingFrame.defaultPriceEditBox:SetText(displaySettingItem['defaultprice'])
            XAuctionCenter.mainFrame.settingFrame.countEditBox:SetText(displaySettingItem['stackcount'])
            XAuctionCenter.mainFrame.settingFrame:Show()
            XAuctionCenter.mainFrame.settingFrame.itemNameEditBox:SetFocus()
        end)

        local enableButton = XUI.createButton(frame, 30, '')
        enableButton:SetPoint("LEFT", craftButton, "RIGHT", 0, 0)
        enableButton:SetScript("OnClick", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoAuctionList[idx];
            if not item then return end
            if item['enabled'] ~= true then
                item['enabled'] = true
            else
                item['enabled'] = false
            end
            XAuctionCenter.refreshUI()
        end)
        frame.enableButton = enableButton

        local starButton = XUI.createButton(frame, 30, '星')
        starButton:SetPoint("LEFT", enableButton, "RIGHT", 0, 0)
        starButton:SetScript("OnClick", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoAuctionList[idx];
            if not item then return end
            if item['star'] == nil or item['star'] == false then
                item['star'] = true
            else
                item['star'] = false
            end
            XAuctionCenter.refreshUI()
        end)
        frame.starButton = starButton

        local itemRefreshButton = XUI.createButton(frame, 30, '刷')
        itemRefreshButton:SetPoint("LEFT", starButton, "RIGHT", 0, 0)
        itemRefreshButton:SetScript("OnClick", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XAutoAuctionList[idx];
            if not item then return end

            XAuctionCenter.addQueryTaskByIndex(idx)
        end)

        displayFrameList[#displayFrameList + 1] = frame
        lastWidget = frame
    end

    initUI_Filter()
    initUI_Setting()
    initUI_Price()

    XAuctionCenter.refreshUI()
end

XAuctionCenter.addQueryTaskByIndex = function(index)
    for _, task in ipairs(taskList) do
        if task['action'] == 'query' and task['index'] == index then
            return
        end
    end

    local item = XAutoAuctionList[index];
    if not item then return end

    item['minprice'] = dft_minPrice
    item['minpricelist'] = {}
    item['lowercount'] = 0
    item['allcount'] = 0
    item['minpriceother'] = dft_minPrice
    item['updatetime'] = 0
    item['lastround'] = -99
    local task = { action = 'query', index = index, page = 0 }
    table.insert(taskList, task)
end

XAuctionCenter.addQueryTaskByItemName = function(itemName)
    for i, item in ipairs(XAutoAuctionList) do
        if item['itemname'] == itemName then
            XAuctionCenter.addQueryTaskByIndex(i)
            return
        end
    end
end

XAuctionCenter.addAuctionTaskByIndex = function(index, price, count)
    for i = 2, #taskList do
        local ttask = taskList[i]
        if ttask['action'] == 'auction' and ttask['index'] == index then
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
    table.insert(taskList, 2, task)
end

XAuctionCenter.addItem = function(itemName, lowestPrice, defaultPrice, stackCount)
    if XAuctionCenter.getAuctionItem(itemName) then return end

    local item = {
        itemname = itemName,
        lowestprice = lowestPrice,
        defaultprice = defaultPrice,
        stackcount = stackCount,
        minprice = dft_minPrice,
        minpricelist = {},
        minpriceother = dft_minPrice,
        lowercount = 0,
        allcount = 0,
        updatetime = 0,
        lastround = 0
    }
    table.insert(XAutoAuctionList, item)
    XAuctionCenter.refreshUI()
end

XAuctionCenter.getAuctionItem = function(itemName)
    for _, item in ipairs(XAutoAuctionList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

local function onQueryListener()
    if curTask ~= nil then return end
    if #taskList > 0 then return end

    if autoAuction then
        addCraftQueue(false)
        puton(false)
    end

    local nextTaskIndex = -1

    if queryRound == 1 then
        for i = starQueryIndex + 1, #XAutoAuctionList do
            local item = XAutoAuctionList[i]
            if item and item['enabled'] and item['star'] and item['lastround'] < 1 then
                starQueryIndex = i
                nextTaskIndex = i
                break
            end
        end

        if nextTaskIndex == -1 then
            starQueryIndex = #XAutoAuctionList

            for i = queryIndex + 1, #XAutoAuctionList do
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
            starQueryIndex = 0
            queryIndex = 0
            queryRound = queryRound + 1
            queryRoundFinishTime = time()
            queryStarFlag = true
            autoAuction = true
            return
        end

        XAuctionCenter.addQueryTaskByIndex(nextTaskIndex)
        return
    end

    if queryStarFlag then
        for i = 0, #XAutoAuctionList - 1 do
            local idx = ((starQueryIndex + i) % #XAutoAuctionList) + 1
            local item = XAutoAuctionList[idx]
            if item and item['enabled'] and item['star'] then
                starQueryIndex = idx
                nextTaskIndex = idx
                break
            end
        end
        queryStarFlag = not queryStarFlag

        if nextTaskIndex ~= -1 then
            XAuctionCenter.addQueryTaskByIndex(nextTaskIndex)
            return
        end
    end

    for i = 0, #XAutoAuctionList - 1 do
        local idx = ((queryIndex + i) % #XAutoAuctionList) + 1
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

    if nextTaskIndex ~= -1 then
        XAuctionCenter.addQueryTaskByIndex(nextTaskIndex)
    end
end

local function onQueryTask()
    if time() - queryRoundFinishTime < dft_roundInterval then return end
    if isQuerying then return end
    if not CanSendAuctionQuery() then return end
    if not curTask then return end

    local item = XAutoAuctionList[curTask['index']]
    if not item then
        finishTask()
        return
    end
    if not item['enabled'] then
        finishTask()
        return
    end

    item['lastround'] = queryRound
    if not curTask['lastcount'] then
        isQuerying = true
        QueryAuctionItems(item['itemname'], nil, nil, nil, 0, 0, curTask['page'])
        return
    elseif curTask['lastcount'] > 0 then
        curTask['page'] = curTask['page'] + 1
        isQuerying = true
        QueryAuctionItems(item['itemname'], nil, nil, nil, 0, 0, curTask['page'])
        return
    end

    XInfo.reloadBag()
    XInfo.reloadAuction()
    XAuctionCenter.refreshUI()

    local itemBag = XInfo.getBagItem(item['itemname'])
    if not itemBag then
        finishTask()
        return
    end

    local price = item['minpriceother'] - dft_deltaPrice
    if item['minprice'] == dft_minPrice then
        price = item['defaultprice']
    end
    if item['minpriceother'] >= item['lowestprice'] and price < item['lowestprice'] then
        price = item['lowestprice']
    end
    if price > dft_maxPrice then
        price = dft_maxPrice
    end
    if price < item['lowestprice'] then
        finishTask()
    end

    local dealCount = XInfo.getAuctionInfoField(item['itemname'], 'dealcount', 0)
    local auctionCount = 0
    local auctionItem = XInfo.getAuctionItem(item['itemname'])
    if auctionItem then auctionCount = auctionItem['count'] end
    local minPriceCount = #item['minpricelist']
    if minPriceCount < auctionCount then auctionCount = minPriceCount end

    local stackCount = item['stackcount']
    if multiAuction == 2 then
        stackCount = 999
    elseif multiAuction == 1 then
        if item['star'] or dealCount >= 20 then
            stackCount = stackCount * 2
        end
    end
    local subcount = stackCount - auctionCount
    if auctionCount <= 0 then
        subcount = stackCount
    end
    if itemBag['count'] < subcount then
        subcount = itemBag['count']
    end
    if subcount <= 0 then
        finishTask()
        return
    end

    XAuctionCenter.addAuctionTaskByIndex(curTask['index'], price, subcount)
    finishTask()
end

local function onQueryItemListUpdate()
    if not isQuerying then return end
    if not curTask then return end
    if curTask['action'] ~= 'query' then return end
    if not XAutoAuctionList[curTask['index']] then return end

    local item = XAutoAuctionList[curTask['index']]

    local index = 1
    while true do
        local itemName, _, _, _, _, _, _, _, buyoutPrice, _, _, seller = GetAuctionItemInfo("list", index);
        if not itemName then break end
        if not string.find(itemName, item['itemname']) then return end
        if item['itemname'] == itemName then
            if curTask['page'] == 0 and index == 1 then
                item['minprice'] = dft_minPrice
                item['minpriceother'] = dft_minPrice
                item['minpricelist'] = {}
                item['lowercount'] = 0
                item['allcount'] = 0
            end

            item['allcount'] = item['allcount'] + 1
            if buyoutPrice < item['lowestprice'] then
                item['lowercount'] = item['lowercount'] + 1
            end
            if buyoutPrice < item['minpriceother'] then
                if buyoutPrice ~= nil and buyoutPrice > 0 then
                    item['minprice'] = buyoutPrice
                    item['updatetime'] = time()
                    if XInfo.isMe(seller) then
                        table.insert(item['minpricelist'], buyoutPrice)
                    else
                        local newPriceList = {}
                        for _, tprice in ipairs(item['minpricelist']) do
                            if tprice <= buyoutPrice then
                                table.insert(newPriceList, tprice)
                            end
                        end
                        item['minpricelist'] = newPriceList
                        item['minpriceother'] = buyoutPrice
                    end
                end
            elseif buyoutPrice == item['minpriceother'] then
                item['updatetime'] = time()
                if XInfo.isMe(seller) then
                    table.insert(item['minpricelist'], buyoutPrice)
                end
            end
        end
        index = index + 1
    end

    curTask['lastcount'] = index - 1
    if curTask['page'] == 0 and index == 1 then
        item['minprice'] = dft_minPrice
        item['minpricelist'] = {}
        item['minpriceother'] = dft_minPrice
        item['lowercount'] = 0
        item['allcount'] = 0
    end
    isQuerying = false
end

local function onAuctionTask()
    if isAuction then return end
    if not curTask then return end

    isAuction = true
    local price = curTask['price']
    local count = curTask['count']
    local index = curTask['index']
    local item = XAutoAuctionList[index]
    if not item then return end

    XInfo.reloadBag()
    local bagItem = XInfo.getBagItem(item['itemname'])
    if not bagItem then return end
    local position = bagItem['positions'][1]
    ClearCursor()
    PickupContainerItem(position[1], position[2])
    ClickAuctionSellItemButton()
    StartAuction(price, price, 1, 1, count)
    for _ = 1, count do
        table.insert(item['minpricelist'], price)
    end
end

local function onAuctionSuccess()
    if not curTask then return end
    if curTask['action'] ~= 'auction' then return end

    XInfo.reloadBag()
    XInfo.reloadAuction()
    XAuctionCenter.refreshUI()
    isAuction = false

    if not fastAuction then
        XAuctionCenter.addQueryTaskByIndex(curTask['index'])
    end
    finishTask()
end

local function onUpdate()
    if not isStarted then return end
    XAuctionCenter.refreshUI()
    if time() - lastTaskFinishTime < dft_taskInterval then return end

    if curTask ~= nil then
        if time() - curTask['starttime'] > dft_taskTimeout then
            finishTask()
            return
        end
    end

    curTask = taskList[1]
    if not curTask then
        onQueryListener() -- 没有任务执行时，监听查询任务
        return
    end

    if not curTask['starttime'] then
        curTask['starttime'] = time()
    end

    if curTask['action'] == 'query' then
        onQueryTask()
    elseif curTask['action'] == 'auction' then
        onAuctionTask()
    end
end

XAutoAuction.registerEventCallback('XAuctionCenter', 'ADDON_LOADED', function()
    initData()
    initUI()
    XAuctionCenter.refreshUI()
end)

XAutoAuction.registerEventCallback('XAuctionCenter', 'AUCTION_ITEM_LIST_UPDATE', function()
    onQueryItemListUpdate()
end)

XAutoAuction.registerEventCallback('XAuctionCenter', 'AUCTION_HOUSE_SHOW', function()
    stop()
    if XAuctionCenter.mainFrame then
        XAuctionCenter.mainFrame:Show()
    end
end)

XAutoAuction.registerEventCallback('XAuctionCenter', 'AUCTION_HOUSE_CLOSED', function()
    stop()
    if XAuctionCenter.mainFrame then
        XAuctionCenter.mainFrame:Hide()
    end
end)

XAutoAuction.registerEventCallback('XAuctionCenter', 'CHAT_MSG_SYSTEM', function(self, event, text, context)
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
        XAuctionCenter.addQueryTaskByIndex(tindex)
    end
end)

XAutoAuction.registerUpdateCallback('XAuctionCenter', onUpdate)


SlashCmdList["XAUCTIONCENTER"] = function()
    if XAuctionCenter.mainFrame ~= nil then
        if XAuctionCenter.mainFrame:IsVisible() then
            XAuctionCenter.mainFrame:Hide()
        else
            XAuctionCenter.mainFrame:Show()
        end
    end
end
SLASH_XAUCTIONCENTER1 = "/xauctioncenter"

SlashCmdList["XAUCTIONCENTERADDCRAFTQUEUE"] = function()
    addCraftQueue(true)
end
SLASH_XAUCTIONCENTERADDCRAFTQUEUE1 = "/xauctioncenter_addcreaftqueue"

SlashCmdList["XAUCTIONCENTERPUTON"] = function()
    puton()
end
SLASH_XAUCTIONCENTERPUTON1 = "/xauctioncenter_puton"

SlashCmdList["XAUCTIONCENTERPRINT"] = function()
    printList()
end
SLASH_XAUCTIONCENTERPRINT1 = "/xauctioncenter_print"

SlashCmdList["XAUCTIONCENTERCLEARALL"] = function()
    clearAll()
    shortPeriod()
end
SLASH_XAUCTIONCENTERCLEARALL1 = "/xauctioncenter_clearall"
