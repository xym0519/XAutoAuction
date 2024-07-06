XAutoSpeak = CreateFrame("Frame")

local dft_interval = 40
local lastUpdatetime = 0
local running = false
local curIndex = 1;

XAutoSpeak.addItem = function(text, enabled)
    table.insert(XSpeakWordList, { text = text, enabled = enabled })
end

XAutoSpeak.getWordItem = function(index)
    return XSpeakWordList[index]
end

local function toggle()
    if not running and #XSpeakWordList <= 0 then
        print("请先设置喊话内容")
        return
    end
    running = not running
    if running then
        curIndex = 1
        XAutoSpeak.mainFrame.startButton:SetText("停止")
    else
        XAutoSpeak.mainFrame.startButton:SetText("开始喊话")
    end
end

local function initUI_Setting()
    local settingFrame = XUI.createFrame("XAutoSpeakSettingFrame", 400, 200, 'DIALOG')
    settingFrame.title:SetText("自动喊话")
    settingFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50)
    XAutoSpeak.settingFrame = settingFrame

    local indexEditBox = XUI.createEditbox(settingFrame, 100, true)
    indexEditBox:SetPoint("TOPLEFT", settingFrame, "TOPLEFT", 10, -30)
    indexEditBox:SetScript("OnEscapePressed", function() XAutoSpeak.settingFrame:Hide() end)
    indexEditBox:SetScript("OnTabPressed", function()
        local index = tonumber(XAutoSpeak.settingFrame.indexEditBox:GetText());
        if XSpeakWordList[index] == nil then
            XAutoSpeak.settingFrame.contentEditBox:SetText("")
            XAutoSpeak.settingFrame.enableButton:SetText("禁用")
        else
            local item = XSpeakWordList[index]
            XAutoSpeak.settingFrame.contentEditBox:SetText(item['text']);
            if item['enabled'] ~= nil and item['enabled'] then
                XAutoSpeak.settingFrame.enableButton:SetText('禁用');
            else
                XAutoSpeak.settingFrame.enableButton:SetText('起用');
            end
        end
        XAutoSpeak.settingFrame.contentEditBox:SetFocus()
    end)
    settingFrame.indexEditBox = indexEditBox

    local deleteButton = XUI.createButton(settingFrame, 80, '删除')
    deleteButton:SetPoint("LEFT", indexEditBox, "RIGHT", 5, 0)
    deleteButton:SetScript("OnClick", function(self)
        local index = tonumber(XAutoSpeak.settingFrame.indexEditBox:GetText());
        if XSpeakWordList[index] ~= nil then
            table.remove(XSpeakWordList, index)
        end
        XAutoSpeak.settingFrame:Hide()
    end)

    local enableButton = XUI.createButton(settingFrame, 80, '')
    enableButton:SetPoint("LEFT", deleteButton, "RIGHT", 5, 0)
    enableButton:SetScript("OnClick", function(self)
        local index = tonumber(XAutoSpeak.settingFrame.indexEditBox:GetText());
        if XSpeakWordList[index] ~= nil then
            local item = XSpeakWordList[index]
            if item['enabled'] ~= nil and item['enabled'] then
                item['enabled'] = false
            else
                item['enabled'] = true
            end
        end
        XAutoSpeak.settingFrame:Hide()
    end)
    settingFrame.enableButton = enableButton

    local contentEditBox = XUI.createEditbox(settingFrame, 380, false)
    contentEditBox:SetMultiLine(true)
    contentEditBox:SetPoint("TOPLEFT", indexEditBox, "BOTTOMLEFT", 0, -20)
    contentEditBox:SetScript("OnEscapePressed", function() XAutoSpeak.settingFrame:Hide() end)
    contentEditBox:SetScript("OnEnterPressed", function()
        local index = tonumber(XAutoSpeak.settingFrame.indexEditBox:GetText());
        if XSpeakWordList[index] ~= nil then
            local item = XSpeakWordList[index]
            item['text'] = XAutoSpeak.settingFrame.contentEditBox:GetText()
        else
            XAutoSpeak.addItem(XAutoSpeak.settingFrame.contentEditBox:GetText(), true)
        end
        XAutoSpeak.settingFrame:Hide()
    end)
    settingFrame.contentEditBox = contentEditBox
end

local function initUI()
    local mainFrame = XUI.createFrame("XAutoSpeakMainFrame", 250, 80)
    mainFrame.title:SetText("自动喊话")
    mainFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -50)
    XAutoSpeak.mainFrame = mainFrame;

    local startButton = XUI.createButton(mainFrame, 100, '开始喊话')
    startButton:SetPoint("LEFT", mainFrame, "LEFT", 15, -10)
    startButton:SetScript("OnClick", function()
        toggle()
    end)
    mainFrame.startButton = startButton

    local settingButton = XUI.createButton(mainFrame, 30, 'S')
    settingButton:SetPoint("RIGHT", mainFrame, "RIGHT", -15, -10)
    settingButton:SetScript("OnClick", function()
        if XAutoSpeak.settingFrame:IsVisible() then
            XAutoSpeak.settingFrame:Hide()
        else
            XAutoSpeak.settingFrame.indexEditBox:SetText(#XSpeakWordList + 1)
            XAutoSpeak.settingFrame.contentEditBox:SetText("喊话内容")
            XAutoSpeak.settingFrame:Show()
        end
    end)

    local clearButton = XUI.createButton(mainFrame, 30, 'C')
    clearButton:SetPoint("RIGHT", settingButton, "LEFT", -10, 0)
    clearButton:SetScript("OnClick", function()
        XSpeakWordList = {}
        print('cleared')
    end)

    local printButton = XUI.createButton(mainFrame, 30, 'P')
    printButton:SetPoint("RIGHT", clearButton, "LEFT", -10, 0)
    printButton:SetScript("OnClick", function()
        for idx, cnt in pairs(XSpeakWordList) do
            local status = 'disabled'
            if cnt['enabled'] ~= nil and cnt['enabled'] then
                status = 'enabled'
            end
            print(idx .. '(' .. status .. '): ' .. cnt['text'])
        end
    end)

    initUI_Setting()

    mainFrame:Show()
end

local function onUpdate()
    if not running or (time() - lastUpdatetime < dft_interval) then
        return
    end
    for i = curIndex, #XSpeakWordList do
        local item = XSpeakWordList[i]
        if item['enabled'] then
            SendChatMessage(item['text'], "channel", nil, 1)
            curIndex = curIndex + 1
            if curIndex > #XSpeakWordList then curIndex = 1 end
            lastUpdatetime = time()
            break
        else
            curIndex = curIndex + 1
            if curIndex > #XSpeakWordList then curIndex = 1 end
        end
    end
end

XAutoAuction.registerEventCallback('XAutoSpeak', 'ADDON_LOADED', function()
    initUI()
end)
XAutoAuction.registerUpdateCallback('XAutoSpeak', onUpdate)

SlashCmdList["XAUTOSPEAK"] = function()
    if not XAutoSpeak then return end
    if not XAutoSpeak.mainFrame then return end
    if XAutoSpeak.mainFrame:IsVisible() then
        XAutoSpeak.mainFrame:Hide()
    else
        XAutoSpeak.mainFrame:Show()
    end
end
SLASH_XAUTOSPEAK1 = "/xautospeak"
