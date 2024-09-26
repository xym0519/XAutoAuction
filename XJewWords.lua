XJewWords = {}
local moduleName = 'XJewWords'

-- Variable definition
local mainFrame = nil

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 12
local displaySettingItem = nil

-- Function definition
local initUI
local refreshUI
local getItem
local addItem

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XJewWordsMainFrame', 1075, 495)
    mainFrame.title:SetText('珠宝文案')
    mainFrame:SetPoint('RIGHT', UIParent, 'RIGHT', -80, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local preButton = XUI.createButton(mainFrame, 60, '上页')
    preButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    preButton:SetScript('OnClick', function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, 60, '下页')
    nextButton:SetPoint('LEFT', preButton, 'RIGHT', 5, 0)
    nextButton:SetScript('OnClick', function()
        if displayPageNo < math.ceil(#XJewWordList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            refreshUI()
        end
    end)

    local settingButton = XUI.createButton(mainFrame, 60, '新增')
    settingButton:SetPoint('LEFT', nextButton, 'RIGHT', 5, 0)
    settingButton:SetScript('OnClick', function()
        XUIInputDialog.show(moduleName, function(data)
                local itemName = nil
                local price1 = nil
                local unit = ''
                for _, item in ipairs(data) do
                    if item.Name == '物品名称' then itemName = item.Value end
                    if item.Name == '喊话价格' then price1 = tonumber(item.Value) end
                    if item.Name == '收购单位' then unit = item.Value end
                end

                if itemName and price1 then
                    addItem(itemName, price1, unit)
                else
                    xdebug.warn('珠宝文案，信息不能为空')
                end
                refreshUI()
            end,
            { { Name = '物品名称' }, { Name = '喊话价格' }, { Name = '收购单位' } },
            '新增')
    end)

    local startButton = XUI.createButton(mainFrame, 60, '全开')
    startButton:SetPoint('LEFT', settingButton, 'RIGHT', 5, 0)
    startButton:SetScript('OnClick', function()
        for _, item in ipairs(XJewWordList) do
            item['enabled'] = true
        end
        refreshUI()
    end)

    local stopButton = XUI.createButton(mainFrame, 60, '全停')
    stopButton:SetPoint('LEFT', startButton, 'RIGHT', 5, 0)
    stopButton:SetScript('OnClick', function()
        for _, item in ipairs(XJewWordList) do
            item['enabled'] = false
        end
        refreshUI()
    end)

    local myMoneyButton = XUI.createButton(mainFrame, 60, '库存')
    myMoneyButton:SetPoint('LEFT', stopButton, 'RIGHT', 5, 0)
    myMoneyButton:SetScript('OnClick', function()
        XInfo.reloadCount()
        local str = ''
        local total = 0
        for _, item in ipairs(XJewWordList) do
            local itemName = item['itemname']
            if XUtils.inArray(itemName, XInfo.materialListS) or XUtils.inArray(itemName, XInfo.materialListB) then
                local price = item['price1']
                local count = XInfo.getItemTotalCount(itemName)
                if count > 0 then
                    str = str .. string.sub(item['itemname'], 1, 3) .. price .. '*' .. count .. '+'
                    total = total + price * count
                end
            end
        end
        if XUtils.stringEndsWith(str, '+') then
            str = string.sub(str, 1, string.len(str) - 1)
            str = str .. '=' .. total
            xdebug.info(str)
        end
    end)

    local lastWidget = preButton
    for i = 1, displayPageSize do
        local frame = XAPI.CreateFrame('Frame', nil, mainFrame)
        frame:SetSize(mainFrame:GetWidth() - 300, 30)

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
            XUISortDialog.show('XJewWords_Sort', XJewWordList, idx, function()
                refreshUI()
            end)
        end)
        frame.indexButton = indexButton

        local itemNameButton = XUI.createButton(frame, 140, '')
        itemNameButton:SetPoint('LEFT', indexButton, 'RIGHT', 3, 0)
        itemNameButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            displaySettingItem = XJewWordList[idx]

            if IsLeftControlKeyDown() then
                XInfo.printBuyHistory(displaySettingItem['itemname'])
            else
                XUIInputDialog.show(moduleName, function(data)
                        local itemName = nil
                        local price1 = nil
                        local unit = ''
                        for _, item in ipairs(data) do
                            if item.Name == '物品名称' then itemName = item.Value end
                            if item.Name == '喊话价格' then price1 = tonumber(item.Value) end
                            if item.Name == '收购单位' then unit = item.Value end
                        end

                        if itemName and price1 then
                            displaySettingItem['itemname'] = itemName
                            displaySettingItem['price1'] = price1
                            displaySettingItem['unit'] = unit
                        else
                            xdebug.warn('珠宝文案，信息不能为空')
                        end
                        refreshUI()
                    end,
                    { { Name = '物品名称', Value = displaySettingItem['itemname'] }, { Name = '喊话价格', Value = displaySettingItem['price1'] }, { Name = '收购单位', Value = displaySettingItem['unit'] } },
                    displaySettingItem['itemname'])
            end
        end)
        itemNameButton:SetScript("OnEnter", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XJewWordList[idx]
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

        local icon = XUI.createIcon(frame, 25, 25)
        icon:SetPoint('LEFT', itemNameButton, 'RIGHT', 3, 0)
        frame.icon = icon

        local countEditBox = XUI.createEditbox(frame, 30)
        countEditBox.index = i
        countEditBox:SetPoint('LEFT', icon, 'RIGHT', 10, 0)
        countEditBox:SetScript('OnTabPressed', function(self)
            local index = self.index + 1
            if index > #displayFrameList then index = 1 end
            local tframe = displayFrameList[index]
            tframe.countEditBox:SetFocus()
        end)
        countEditBox:SetScript('OnEnterPressed', function(self)
            mainFrame.price3Editbox:SetFocus()
        end)
        countEditBox:SetScript('OnEditFocusLost', function(self)
            self:SetText(self:GetText())
            local idx = displayPageNo * displayPageSize + i
            local item = XJewWordList[idx]
            local count = tonumber(self:GetText())
            if count == nil then count = 0 end
            item['ccount'] = count

            refreshUI()
        end)
        frame.countEditBox = countEditBox

        local countLabel = XUI.createLabel(frame, 40, '')
        countLabel:SetPoint('LEFT', countEditBox, 'RIGHT', 10, 0)
        frame.countLabel = countLabel

        local price1Label = XUI.createLabel(frame, 60, '')
        price1Label:SetPoint('LEFT', countLabel, 'RIGHT', 0, 0)
        frame.price1Label = price1Label

        local price2Label = XUI.createLabel(frame, 70, '')
        price2Label:SetPoint('LEFT', price1Label, 'RIGHT', 0, 0)
        frame.price2Label = price2Label

        local price3Label = XUI.createLabel(frame, 70, '')
        price3Label:SetPoint('LEFT', price2Label, 'RIGHT', 0, 0)
        frame.price3Label = price3Label

        local price4Label = XUI.createLabel(frame, 70, '')
        price4Label:SetPoint('LEFT', price3Label, 'RIGHT', 0, 0)
        frame.price4Label = price4Label

        local unitLabel = XUI.createLabel(frame, 50, '')
        unitLabel:SetPoint('LEFT', price4Label, 'RIGHT', 0, 0)
        frame.unitLabel = unitLabel

        local setAutoBuyButton = XUI.createButton(frame, 30, '>')
        setAutoBuyButton:SetPoint('LEFT', unitLabel, 'RIGHT', 0, 0)
        setAutoBuyButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            local item = XJewWordList[idx]
            local autoBuyItem = XAutoBuy.getItem(item['itemname'])
            if autoBuyItem then
                autoBuyItem['price'] = item['price1'] * 10000
            end
            refreshUI()
        end)

        local setPriceButton = XUI.createButton(frame, 30, '<')
        setPriceButton:SetPoint('LEFT', setAutoBuyButton, 'RIGHT', 0, 0)
        setPriceButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            local item = XJewWordList[idx]
            local autoBuyItem = XAutoBuy.getItem(item['itemname'])
            if autoBuyItem then
                local price = autoBuyItem['minbuyoutprice'];
                price = math.floor(price * 0.9 / 10000)
                item['price1'] = price
            end
            refreshUI()
        end)

        local deleteButton = XUI.createButton(frame, 30, '删')
        deleteButton:SetPoint('LEFT', setPriceButton, 'RIGHT', 0, 0)
        deleteButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #XJewWordList then
                local titem = XJewWordList[idx]
                XUIConfirmDialog.show(moduleName, '确认删除', '确认删除：' .. titem['itemname'], function()
                    table.remove(XJewWordList, idx)
                    refreshUI()
                end)
            end
        end)

        local enableButton = XUI.createButton(frame, 30, '')
        enableButton:SetPoint('LEFT', deleteButton, 'RIGHT', 0, 0)
        enableButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XJewWordList[idx]
            if not item then return end
            item['enabled'] = not item['enabled']
            refreshUI()
        end)
        frame.enableButton = enableButton

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    local billButton = XUI.createButton(mainFrame, 60, '发送')
    billButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -15, -30)
    billButton:SetScript('OnClick', function(self)
        for _, frame in ipairs(displayFrameList) do
            frame.countEditBox:ClearFocus()
        end
        XUIConfirmDialog.show(moduleName, '确认', '是否发送并记账', function()
            local count = 0
            for _, item in ipairs(XJewWordList) do
                local itemName = item['itemname']
                local price1 = item['price1'] * 10000
                local ccount = item['ccount']
                if ccount > 0 then
                    XExternal.addBuyHistory(itemName, time(), price1, ccount)
                    count = count + 1
                end

                item['ccount'] = 0
            end

            XAPI.SendChatMessage(mainFrame.price3Editbox:GetText(), 'PARTY')

            xdebug.info('记账成功，新增' .. count .. '条购买记录')
            refreshUI()
        end)
    end)

    local setButton = XUI.createButton(mainFrame, 60, '设喊')
    setButton:SetPoint('RIGHT', billButton, 'LEFT', -5, 0)
    setButton:SetScript('OnClick', function(self)
        XUIConfirmDialog.show(moduleName, '确认', '是否设置喊话内容', function()
            local text = mainFrame.price1Editbox:GetText()
            local wordItem = XAutoSpeak.getItem(1)
            if wordItem ~= nil then
                wordItem['text'] = text
            else
                XAutoSpeak.addItem(text, true)
            end
            xdebug.info('自动喊话设置成功: ' .. text)
        end)
    end)

    local refreshButton = XUI.createButton(mainFrame, 60, '刷新')
    refreshButton:SetPoint('RIGHT', setButton, 'LEFT', -5, 0)
    refreshButton:SetScript('OnClick', function()
        refreshUI()
    end)

    local clearCountButton = XUI.createButton(mainFrame, 60, '清除')
    clearCountButton:SetPoint('RIGHT', refreshButton, 'LEFT', -5, 0)
    clearCountButton:SetScript('OnClick', function()
        for _, item in ipairs(XJewWordList) do
            item['ccount'] = 0
        end

        refreshUI()
    end)

    local suffixEdit = XUI.createEditbox(mainFrame, 200)
    suffixEdit:SetPoint('RIGHT', clearCountButton, 'LEFT', -5, 0)
    suffixEdit:SetScript('OnEditFocusLost', function(self)
        self:SetText(self:GetText())
        XJewWordSetting.Suffix = self:GetText()
        refreshUI()
    end)
    mainFrame.suffixEdit = suffixEdit

    local prefixEdit = XUI.createEditbox(mainFrame, 150)
    prefixEdit:SetPoint('RIGHT', suffixEdit, 'LEFT', -5, 0)
    prefixEdit:SetScript('OnEditFocusLost', function(self)
        self:SetText(self:GetText())
        XJewWordSetting.Prefix = self:GetText()
        refreshUI()
    end)
    mainFrame.prefixEdit = prefixEdit

    local price1Editbox = XUI.createEditboxMultiline(mainFrame, 305, 85)
    price1Editbox:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', mainFrame:GetWidth() - 320, -65)
    mainFrame.price1Editbox = price1Editbox.editBox

    local price2Editbox = XUI.createEditboxMultiline(mainFrame, 305, 240)
    price2Editbox:SetPoint('TOPLEFT', price1Editbox, 'BOTTOMLEFT', 0, -10)
    mainFrame.price2Editbox = price2Editbox.editBox

    local price3Editbox = XUI.createEditboxMultiline(mainFrame, 305, 70)
    price3Editbox:SetPoint('TOPLEFT', price2Editbox, 'BOTTOMLEFT', 0, -10)
    mainFrame.price3Editbox = price3Editbox.editBox

    refreshUI()
end

refreshUI = function()
    if not mainFrame then return end

    mainFrame.title:SetText('珠宝文案 (' .. (displayPageNo + 1) .. '/'
        .. (math.ceil(#XJewWordList / displayPageSize)) .. ')')

    XInfo.reloadCount()

    if XJewWordSetting.Prefix then
        if XJewWordSetting.Prefix ~= mainFrame.prefixEdit:GetText() then
            mainFrame.prefixEdit:SetText(XJewWordSetting.Prefix)
        end
    end
    if XJewWordSetting.Suffix then
        if XJewWordSetting.Suffix ~= mainFrame.suffixEdit:GetText() then
            mainFrame.suffixEdit:SetText(XJewWordSetting.Suffix)
        end
    end

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #XJewWordList then
            local item = XJewWordList[idx]
            local itemName = item['itemname']
            local itemId = XInfo.getItemId(itemName)
            local price1 = item['price1']
            local price2 = 0;
            local auctionMinPrice = 0
            local auctionMinBuyoutPrice = 0
            local autoBuyItem = XAutoBuy.getItem(itemName)
            if autoBuyItem then
                price2 = autoBuyItem['price'] / 10000
                auctionMinPrice = XUtils.round(autoBuyItem['minprice'] / 100) / 100
                auctionMinBuyoutPrice = XUtils.round(autoBuyItem['minbuyoutprice'] / 100) / 100
            end
            local unit = item['unit']
            local ccount = item['ccount']
            local totalCount = XInfo.getItemTotalCount(itemName)

            local totalCountStr = XUI.getColor_MaterialTotalCount(totalCount) .. totalCount

            local price1Str = '喊' .. price1
            local price2Str = '扫' .. price2

            if item['enabled'] ~= true then
                itemName = XUI.Red .. itemName
                price1Str = XUI.Red .. price1Str
                unit = XUI.Red .. unit
            else
                itemName = XUI.Green .. itemName
                price1Str = XUI.Green .. price1Str
                unit = XUI.Green .. unit
            end
            if price1 .. '' == price2 .. '' then
                price2Str = XUI.Green .. price2Str
            else
                price2Str = XUI.Red .. price2Str
            end

            local ccountStr = ccount
            if ccount > 0 then
                ccountStr = XUI.Green .. ccount
            else
                ccountStr = XUI.Red .. ccount
            end

            frame.indexButton:SetText(idx)
            frame.icon:SetTexture(XAPI.GetItemIcon(itemId))
            frame.itemNameButton:SetText(itemName)
            frame.countEditBox:SetText(ccountStr)
            frame.countLabel:SetText(totalCountStr)
            frame.price1Label:SetText(price1Str)
            frame.price2Label:SetText(price2Str)
            frame.price3Label:SetText(auctionMinPrice)
            frame.price4Label:SetText(auctionMinBuyoutPrice)
            frame.unitLabel:SetText(unit)

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

    local price1Str = '长期收：'
    if XJewWordSetting.Prefix then
        price1Str = XJewWordSetting.Prefix .. '：'
    end
    local price2Str = '珠宝价格表：\n'
    local price3Str = ''
    local price3 = 0
    for _, item in ipairs(XJewWordList) do
        local price1 = item['price1']

        if item['enabled'] ~= nil and item['enabled'] then
            price1Str = price1Str .. price1 .. item['unit'] .. item['itemname'] .. '，'
        end
        price2Str = price2Str .. item['itemname'] .. '：' .. price1 .. 'G' .. item['unit'] .. '，\n'
        local ccount = item['ccount']
        if ccount > 0 then
            price3Str = price3Str .. string.sub(item['itemname'], 1, 6) .. price1 .. '*' .. ccount .. '+'
            price3 = price3 + price1 * ccount
        end
    end
    if XJewWordSetting.Suffix then
        price1Str = price1Str .. XJewWordSetting.Suffix
    end
    price2Str = price2Str .. '\nPS：零头自行向上取整'
    if XUtils.stringEndsWith(price3Str, '+') then
        price3Str = string.sub(price3Str, 1, string.len(price3Str) - 1)
        price3Str = price3Str .. '=' .. price3
    end

    mainFrame.price1Editbox:SetText(price1Str)
    mainFrame.price2Editbox:SetText(price2Str)
    mainFrame.price3Editbox:SetText(price3Str)
end

getItem = function(itemName)
    for _, item in ipairs(XJewWordList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

addItem = function(itemName, price1, unit)
    if getItem(itemName) then return end
    local item = {
        itemname = itemName,
        price1 = price1,
        unit = unit,
        ccount = 0
    }
    table.insert(XJewWordList, item)
    refreshUI()
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

-- Commands
SlashCmdList['XJEWWORDS'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XJEWWORDS1 = '/xjewwords'

SlashCmdList['XJEWWORDSSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XJEWWORDSSHOW1 = '/xjewwords_show'

SlashCmdList['XJEWWORDSCLOSE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XJEWWORDSCLOSE1 = '/xjewwords_close'

-- Interfaces
XJewWords.getItem = getItem
