XJewWords = CreateFrame("Frame")

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 13
local displaySettingItem = nil
local wordType = true

local mainFrame = nil
local settingFrame = nil

XJewWords.refreshUI = function()
    if not mainFrame then return end
    mainFrame.title:SetText('珠宝文案 (' .. (displayPageNo + 1) .. '/'
        .. (math.ceil(#XJewWordList / displayPageSize)) .. ')')

    XInfo.reloadBag()

    if wordType then
        mainFrame.wordTypeButton:SetText('喊话')
    else
        mainFrame.wordTypeButton:SetText('邮件')
    end

    for i = 1, displayPageSize do
        local frame = displayFrameList[i]
        local idx = displayPageNo * displayPageSize + i
        if idx <= #XJewWordList then
            local item = XJewWordList[idx]
            local itemName = item['itemname']
            local price1 = item['price1']
            local price2 = 0;
            local autoBuyItem = XAutoBuy.getBuyItem(itemName)
            if autoBuyItem then price2 = autoBuyItem['price'] / 10000 end
            local unit = item['unit']
            local ccount = item['ccount']
            local totalCount = 0
            local itemBag = XInfo.getBagItem(itemName)
            if itemBag ~= nil then
                totalCount = itemBag['totalcount']
            end

            local totalCountStr = totalCount
            if totalCount >= 100 then
                totalCountStr = '|cFF00FFFF' .. totalCountStr
            elseif totalCount >= 60 then
                totalCountStr = '|cFF00FF00' .. totalCountStr
            elseif totalCount >= 40 then
                totalCountStr = '|cFFFFFF00' .. totalCountStr
            else
                totalCountStr = '|cFFFF0000' .. totalCountStr
            end

            local price1Str = '喊' .. price1
            local price2Str = '收' .. price2

            if item['enabled'] ~= true then
                itemName = '|cFFFF0000' .. itemName
                price1Str = '|cFFFF0000' .. price1Str
                unit = '|cFFFF0000' .. unit
            else
                itemName = '|cFF00FF00' .. itemName
                price1Str = '|cFF00FF00' .. price1Str
                unit = '|cFF00FF00' .. unit
            end
            if price1 .. '' == price2 .. '' then
                price2Str = '|cFF00FF00' .. price2Str
            else
                price2Str = '|cFFFF0000' .. price2Str
            end

            frame.indexButton:SetText(idx)
            frame.itemNameButton:SetText(itemName)
            frame.countEditBox:SetText(ccount)
            frame.countLabel:SetText(totalCountStr)
            frame.price1Label:SetText(price1Str)
            frame.price2Label:SetText(price2Str)
            frame.unitLabel:SetText(unit)

            if item['enabled'] ~= true then
                frame.enableButton:SetText('|cFFFF0000停')
            else
                frame.enableButton:SetText('|cFF00FF00起')
            end
            frame:Show()
        else
            frame:Hide()
        end
    end

    local price1Str = "长期收："
    local price2Str = "珠宝价格表：\n"
    local price3Str = ""
    local price3 = 0
    for _, item in ipairs(XJewWordList) do
        local price1 = item['price1']

        if item['enabled'] ~= nil and item['enabled'] then
            price1Str = price1Str .. price1 .. item['unit'] .. item['itemname'] .. '，'
        end
        price2Str = price2Str .. item['itemname'] .. '：' .. price1 .. 'G' .. item['unit'] .. "，\n"
        local ccount = item['ccount']
        if ccount > 0 then
            price3Str = price3Str .. string.sub(item['itemname'], 1, 6) .. price1 .. '*' .. ccount .. '+'
            price3 = price3 + price1 * ccount
        end
    end
    price1Str = price1Str .. '直邮'
    price2Str = price2Str .. "\nPS：零头自行向上取整"
    if XUtils.stringEndsWith(price3Str, '+') then
        price3Str = string.sub(price3Str, 1, string.len(price3Str) - 1)
        price3Str = price3Str .. '=' .. price3
    end

    mainFrame.price1Editbox:SetText(price1Str)
    mainFrame.price2Editbox:SetText(price2Str)
    mainFrame.price3Editbox:SetText(price3Str)
end

local function getWordItem(itemName)
    for _, item in ipairs(XJewWordList) do
        if item['itemname'] == itemName then
            return item
        end
    end
    return nil
end

local function addItem(itemName, price1, unit)
    if getWordItem(itemName) then return end
    local item = {
        itemname = itemName,
        price1 = price1,
        unit = unit,
        ccount = 0
    }
    table.insert(XJewWordList, item)
    XJewWords.refreshUI()
end

local function initUI_Setting()
    settingFrame = XUI.createFrame('XJewWordsSettingFrame', 260, 120, 'DIALOG')
    settingFrame.title:SetText("珠宝文案设置")
    settingFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    settingFrame:Hide()

    local itemNameLabel = XUI.createLabel(settingFrame, 80, '物品名称')
    itemNameLabel:SetPoint("TOPLEFT", settingFrame, "TOPLEFT", 15, -30)

    local itemNameEditBox = XUI.createEditbox(settingFrame, 150, true)
    itemNameEditBox:SetPoint("LEFT", itemNameLabel, "RIGHT", 5, 0)
    itemNameEditBox:SetScript("OnEscapePressed", function() settingFrame:Hide() end)
    itemNameEditBox:SetScript("OnTabPressed", function()
        settingFrame.price1EditBox:SetFocus()
    end)
    settingFrame.itemNameEditBox = itemNameEditBox

    local price1Label = XUI.createLabel(settingFrame, 80, '喊话价格')
    price1Label:SetPoint("TOP", itemNameLabel, "BOTTOM", 0, 0)

    local price1EditBox = XUI.createEditbox(settingFrame, 150, false)
    price1EditBox:SetPoint("LEFT", price1Label, "RIGHT", 5, 0)
    price1EditBox:SetScript("OnEscapePressed", function() settingFrame:Hide() end)
    price1EditBox:SetScript("OnTabPressed", function()
        settingFrame.unitEditBox:SetFocus()
    end)
    settingFrame.price1EditBox = price1EditBox

    local unitLabel = XUI.createLabel(settingFrame, 80, '收购单位')
    unitLabel:SetPoint("TOP", price1Label, "BOTTOM", 0, 0)

    local unitEditBox = XUI.createEditbox(settingFrame, 150, false)
    unitEditBox:SetPoint("LEFT", unitLabel, "RIGHT", 5, 0)
    unitEditBox:SetScript("OnEscapePressed", function() settingFrame:Hide() end)
    unitEditBox:SetScript("OnEnterPressed", function()
        local itemName = settingFrame.itemNameEditBox:GetText()
        local price1 = settingFrame.price1EditBox:GetText()
        local unit = settingFrame.unitEditBox:GetText()

        if not itemName or itemName == '' then return end
        if not price1 or price1 == '' then return end

        if not displaySettingItem then
            addItem(itemName, price1, unit)
        else
            displaySettingItem['itemname'] = itemName
            displaySettingItem['price1'] = price1
            displaySettingItem['unit'] = unit
        end
        settingFrame:Hide()
        XJewWords.refreshUI()
    end)
    settingFrame.unitEditBox = unitEditBox
end

local function initUI()
    mainFrame = XUI.createFrame("XJewWordsMainFrame", 880, 530)
    mainFrame.title:SetText("珠宝文案")
    mainFrame:SetPoint("RIGHT", UIParent, "RIGHT", -80, 0)
    mainFrame:Hide()
    XJewWords.mainFrame = mainFrame

    local preButton = XUI.createButton(mainFrame, 45, '上')
    preButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -30)
    preButton:SetScript("OnClick", function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            XJewWords.refreshUI()
        end
    end)

    local nextButton = XUI.createButton(mainFrame, 45, '下')
    nextButton:SetPoint("LEFT", preButton, "RIGHT", 5, 0)
    nextButton:SetScript("OnClick", function()
        if displayPageNo < math.ceil(#XJewWordList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            XJewWords.refreshUI()
        end
    end)

    local settingButton = XUI.createButton(mainFrame, 45, '加')
    settingButton:SetPoint("LEFT", nextButton, "RIGHT", 5, 0)
    settingButton:SetScript("OnClick", function()
        if settingFrame ~= nil then
            displaySettingItem = nil
            settingFrame.itemNameEditBox:SetText('')
            settingFrame.price1EditBox:SetText('')
            settingFrame.unitEditBox:SetText('')
            settingFrame:Show()
        end
    end)

    local startButton = XUI.createButton(mainFrame, 45, '起')
    startButton:SetPoint("LEFT", settingButton, "RIGHT", 5, 0)
    startButton:SetScript("OnClick", function()
        for _, item in ipairs(XJewWordList) do
            item['enabled'] = true
        end
        XAutoAuction.refreshUI()
    end)

    local stopButton = XUI.createButton(mainFrame, 45, '停')
    stopButton:SetPoint("LEFT", startButton, "RIGHT", 5, 0)
    stopButton:SetScript("OnClick", function()
        for _, item in ipairs(XJewWordList) do
            item['enabled'] = false
        end
        XAutoAuction.refreshUI()
    end)

    local lastWidget = preButton
    for i = 1, displayPageSize do
        local frame = CreateFrame("Frame", nil, mainFrame)
        frame:SetSize(580, 30)

        if i == 1 then
            frame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -65)
        else
            frame:SetPoint("TOPLEFT", lastWidget, "BOTTOMLEFT", 0, -5)
        end

        frame:Hide()

        local indexButton = XUI.createButton(frame, 30, '')
        indexButton:SetPoint("LEFT", frame, "LEFT", 15, 0)
        indexButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            XUISortDialog.show('XJewWords_Sort', XJewWordList, idx, function()
                XUISortDialog.refreshUI()
            end)
        end)
        frame.indexButton = indexButton

        local itemNameButton = XUI.createButton(frame, 140, '')
        itemNameButton:SetPoint("LEFT", indexButton, "RIGHT", 3, 0)
        itemNameButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            displaySettingItem = XJewWordList[idx]
            if not displaySettingItem then return end
            if not settingFrame then return end
            settingFrame.itemNameEditBox:SetText(displaySettingItem['itemname'])
            settingFrame.price1EditBox:SetText(displaySettingItem['price1'])
            settingFrame.unitEditBox:SetText(displaySettingItem['unit'])
            settingFrame:Show()
        end)
        frame.itemNameButton = itemNameButton

        local countEditBox = XUI.createEditbox(frame, 30, false)
        countEditBox:SetPoint("LEFT", itemNameButton, "RIGHT", 10, 0)
        countEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        countEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        countEditBox:SetScript("OnEditFocusLost", function(self)
            self:SetText(self:GetText())
            local idx = displayPageNo * displayPageSize + i
            local item = XJewWordList[idx]
            local count = tonumber(self:GetText())
            if count == nil then count = 0 end
            item['ccount'] = count

            XJewWords.refreshUI()
        end)
        frame.countEditBox = countEditBox

        local countLabel = XUI.createLabel(frame, 40, '')
        countLabel:SetPoint("LEFT", countEditBox, "RIGHT", 10, 0)
        frame.countLabel = countLabel

        local price1Label = XUI.createLabel(frame, 60, '')
        price1Label:SetPoint("LEFT", countLabel, "RIGHT", 0, 0)
        frame.price1Label = price1Label

        local price2Label = XUI.createLabel(frame, 70, '')
        price2Label:SetPoint("LEFT", price1Label, "RIGHT", 0, 0)
        frame.price2Label = price2Label

        local unitLabel = XUI.createLabel(frame, 50, '')
        unitLabel:SetPoint("LEFT", price2Label, "RIGHT", 0, 0)
        frame.unitLabel = unitLabel

        local setAutoBuyButton = XUI.createButton(frame, 30, '=')
        setAutoBuyButton:SetPoint("LEFT", unitLabel, "RIGHT", 0, 0)
        setAutoBuyButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            local item = XJewWordList[idx]
            local autoBuyItem = XAutoBuy.getBuyItem(item['itemname'])
            print(autoBuyItem['price'])
            if autoBuyItem then
                autoBuyItem['price'] = item['price1'] * 10000
            end
            XJewWords.refreshUI()
        end)

        local deleteButton = XUI.createButton(frame, 30, '删')
        deleteButton:SetPoint("LEFT", setAutoBuyButton, "RIGHT", 0, 0)
        deleteButton:SetScript("OnClick", function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #XJewWordList then
                table.remove(XJewWordList, idx)
                XJewWords.refreshUI()
            end
        end)

        local enableButton = XUI.createButton(frame, 30, '')
        enableButton:SetPoint("LEFT", deleteButton, "RIGHT", 0, 0)
        enableButton:SetScript("OnClick", function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XJewWordList[idx]
            if not item then return end
            item['enabled'] = not item['enabled']
            XJewWords.refreshUI()
        end)
        frame.enableButton = enableButton

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end

    local setButton = XUI.createButton(mainFrame, 60, '喊话')
    setButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -15, -30)
    setButton:SetScript("OnClick", function(self)
        local text = mainFrame.price1Editbox:GetText()
        local wordItem = XAutoSpeak.getWordItem(1)
        if wordItem ~= nil then
            wordItem['text'] = text
        else
            XAutoSpeak.addItem(text, true)
        end
        print('setted: ' .. text)
    end)

    local refreshButton = XUI.createButton(mainFrame, 60, '刷新')
    refreshButton:SetPoint("RIGHT", setButton, "LEFT", -5, 0)
    refreshButton:SetScript("OnClick", function()
        XJewWords.refreshUI()
    end)

    local wordTypeButton = XUI.createButton(mainFrame, 60, '喊话')
    wordTypeButton:SetPoint("RIGHT", refreshButton, "LEFT", -5, 0)
    wordTypeButton:SetScript("OnClick", function()
        wordType = not wordType
        XJewWords.refreshUI()
    end)
    mainFrame.wordTypeButton = wordTypeButton

    local clearCountButton = XUI.createButton(mainFrame, 60, '清除')
    clearCountButton:SetPoint("RIGHT", wordTypeButton, "LEFT", -5, 0)
    clearCountButton:SetScript("OnClick", function()
        for _, item in ipairs(XJewWordList) do
            item['ccount'] = 0
        end

        XJewWords.refreshUI()
    end)

    local price1Editbox = XUI.createEditbox(mainFrame, 280, false)
    price1Editbox:SetMultiLine(true)
    price1Editbox:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 560, -65)
    price1Editbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    price1Editbox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    price1Editbox:SetScript("OnEditFocusLost", function(self) self:SetText(self:GetText()) end)
    mainFrame.price1Editbox = price1Editbox

    local price2Editbox = XUI.createEditbox(mainFrame, 280, false)
    price2Editbox:SetMultiLine(true)
    price2Editbox:SetPoint("TOPLEFT", price1Editbox, "BOTTOMLEFT", 0, -40)
    price2Editbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    price2Editbox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    price2Editbox:SetScript("OnEditFocusLost", function(self) self:SetText(self:GetText()) end)
    mainFrame.price2Editbox = price2Editbox

    local price3Editbox = XUI.createEditbox(mainFrame, 280, false)
    price3Editbox:SetMultiLine(true)
    price3Editbox:SetPoint("TOPLEFT", price2Editbox, "BOTTOMLEFT", 0, -40)
    price3Editbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    price3Editbox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    price3Editbox:SetScript("OnEditFocusLost", function(self) self:SetText(self:GetText()) end)
    mainFrame.price3Editbox = price3Editbox

    initUI_Setting()

    XJewWords.refreshUI()
end

XAutoAuction.registerEventCallback('XJewWords', 'ADDON_LOADED', function()
    initUI()
    XJewWords.refreshUI()
end)

SlashCmdList["XJEWWORDS"] = function()
    if mainFrame then
        if mainFrame:IsVisible() then
            mainFrame:Hide()
        else
            mainFrame:Show()
        end
    end
end
SLASH_XJEWWORDS1 = "/xjewwords"
