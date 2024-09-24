XAutoSpeak = {}
local moduleName = 'XAutoSpeak'

-- Variable definition
local mainFrame = nil
local settingFrame = nil
local editFrame = nil

local dft_interval = 90
local dft_buttonWidth = 60
local dft_buttonGap = 1

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local lastUpdatetime = 0
local isRunning = false
local curIndex = 1;

-- Function definition
local initUI
local initUI_Setting
local initUI_Edit
local refreshUI
local addItem
local getItem
local send

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XAutoSpeakMainFrame', 250, 80)
    mainFrame.title:SetText('自动喊话')
    mainFrame:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -30, -50)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local startButton = XUI.createButton(mainFrame, 50, '开始')
    startButton:SetPoint('LEFT', mainFrame, 'LEFT', 15, -10)
    startButton:SetScript('OnClick', function()
        isRunning = not isRunning
        lastUpdatetime = 0
        refreshUI()
    end)
    mainFrame.startButton = startButton

    local resetButton = XUI.createButton(mainFrame, 50, '重置')
    resetButton:SetPoint('LEFT', startButton, 'RIGHT', 5, 0)
    resetButton:SetScript('OnClick', function()
        isRunning = false
        lastUpdatetime = 0
        curIndex = 1
        refreshUI()
    end)

    local settingButton = XUI.createButton(mainFrame, 50, '设置')
    settingButton:SetPoint('LEFT', resetButton, 'RIGHT', 5, 0)
    settingButton:SetScript('OnClick', function()
        if not settingFrame then return end
        settingFrame:Show()
        refreshUI()
    end)

    local printButton = XUI.createButton(mainFrame, 50, '查看')
    printButton:SetPoint('LEFT', settingButton, 'RIGHT', 5, 0)
    printButton:SetScript('OnClick', function()
        xdebug.info('----------自动喊话设置----------')
        for idx, cnt in pairs(XSpeakWordList) do
            local status = 'disabled'
            if cnt['enabled'] ~= nil and cnt['enabled'] then
                status = 'enabled'
            end
            xdebug.info(idx .. '(' .. status .. '): ' .. cnt['text'])
        end
    end)

    initUI_Setting()
    initUI_Edit()
end

initUI_Setting = function()
    settingFrame = XUI.createFrame('XAutoSpeakSettingFrame', 500, 400)
    settingFrame.title:SetText('自动喊话设置')
    settingFrame:SetPoint('CENTER', UIParent, 'CENTER')

    local preButton = XUI.createButton(settingFrame, dft_buttonWidth, '上页')
    preButton:SetPoint('TOPLEFT', settingFrame, 'TOPLEFT', 15, -30)
    preButton:SetScript('OnClick', function()
        if displayPageNo > 0 then
            displayPageNo = displayPageNo - 1
            refreshUI()
        end
    end)

    local nextButton = XUI.createButton(settingFrame, dft_buttonWidth, '下页')
    nextButton:SetPoint('LEFT', preButton, 'RIGHT', dft_buttonGap, 0)
    nextButton:SetScript('OnClick', function()
        if displayPageNo < math.ceil(#XSpeakWordList / displayPageSize) - 1 then
            displayPageNo = displayPageNo + 1
            refreshUI()
        end
    end)

    local clearButton = XUI.createButton(settingFrame, dft_buttonWidth, '清除')
    clearButton:SetPoint('LEFT', nextButton, 'RIGHT', dft_buttonGap, 0)
    clearButton:SetScript('OnClick', function()
        XUIConfirmDialog.show(moduleName, '是否确认清除', '即将清除所有喊话数据', function()
            XSpeakWordList = {}
            refreshUI()
            xdebug.info('cleared')
        end)
    end)

    local stopButton = XUI.createButton(settingFrame, dft_buttonWidth, '全停')
    stopButton:SetPoint('LEFT', clearButton, 'RIGHT', dft_buttonGap, 0)
    stopButton:SetScript('OnClick', function()
        for _, item in ipairs(XSpeakWordList) do
            item['enabled'] = false
        end
        refreshUI()
    end)

    local addButton = XUI.createButton(settingFrame, dft_buttonWidth, '新增')
    addButton:SetPoint('LEFT', stopButton, 'RIGHT', dft_buttonGap, 0)
    addButton:SetScript('OnClick', function()
        if not editFrame then return end

        displaySettingItem = nil
        editFrame:Show()
        editFrame.editBox:SetText('');
        editFrame.editBox:SetFocus()
        refreshUI()
    end)

    local printButton = XUI.createButton(settingFrame, dft_buttonWidth, '查看')
    printButton:SetPoint('LEFT', addButton, 'RIGHT', dft_buttonGap, 0)
    printButton:SetScript('OnClick', function()
        xdebug.info('----------自动喊话设置----------')
        for idx, cnt in pairs(XSpeakWordList) do
            local status = 'disabled'
            if cnt['enabled'] ~= nil and cnt['enabled'] then
                status = 'enabled'
            end
            xdebug.info(idx .. '(' .. status .. '): ' .. cnt['text'])
        end
    end)

    local lastWidget = preButton
    for i = 1, displayPageSize do
        local frame = XAPI.CreateFrame('Frame', nil, settingFrame)
        frame:SetSize(settingFrame:GetWidth(), 30)

        if i == 1 then
            frame:SetPoint('TOPLEFT', settingFrame, 'TOPLEFT', 0, -65)
        else
            frame:SetPoint('TOPLEFT', lastWidget, 'BOTTOMLEFT', 0, -5)
        end

        frame:Hide()

        local indexButton = XUI.createButton(frame, 30, '')
        indexButton:SetPoint('LEFT', frame, 'LEFT', 15, 0)
        indexButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            XUISortDialog.show(moduleName .. '_Sort', XSpeakWordList, idx, function()
                refreshUI()
            end)
        end)
        frame.indexButton = indexButton

        local label = XUI.createLabel(frame, 330, '')
        label:SetPoint('LEFT', indexButton, 'RIGHT', 8, 0)
        frame.label = label

        local editButton = XUI.createButton(frame, 32, '设')
        editButton:SetPoint('LEFT', label, 'RIGHT', 3, 0)
        editButton:SetScript('OnClick', function()
            if not editFrame then return end

            local idx = displayPageNo * displayPageSize + i
            displaySettingItem = XSpeakWordList[idx]
            editFrame:Show()
            editFrame.editBox:SetText(displaySettingItem['text'])
            editFrame.editBox:SetFocus()
            refreshUI()
        end)

        local deleteButton = XUI.createButton(frame, 32, '删')
        deleteButton:SetPoint('LEFT', editButton, 'RIGHT', 1, 0)
        deleteButton:SetScript('OnClick', function()
            local idx = displayPageNo * displayPageSize + i
            if idx <= #XSpeakWordList then
                XUIConfirmDialog.show(moduleName,
                    '确认删除',
                    '是否确认删除：' .. XSpeakWordList[idx]['text'],
                    function()
                        table.remove(XSpeakWordList, idx)
                        refreshUI()
                    end)
            end
        end)

        local enableButton = XUI.createButton(frame, 32, '')
        enableButton:SetPoint('LEFT', deleteButton, 'RIGHT', 1, 0)
        enableButton:SetScript('OnClick', function(self)
            local idx = displayPageNo * displayPageSize + i
            local item = XSpeakWordList[idx]
            if not item then return end
            item['enabled'] = not item['enabled']
            refreshUI()
        end)
        frame.enableButton = enableButton

        table.insert(displayFrameList, frame)
        lastWidget = frame
    end
end

initUI_Edit = function()
    editFrame = XUI.createFrame('XAutoSpeakEditFrame', 400, 200, 'DIALOG')
    editFrame.title:SetText('自动喊话')
    editFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, -50)

    editFrame:Hide()

    local editBox = XUI.createEditboxMultiline(editFrame, editFrame:GetWidth() - 20, editFrame:GetHeight() - 40)
    editBox:SetPoint('TOP', editFrame, 'TOP', 0, -30)
    editBox.editBox:SetScript('OnEscapePressed', function(self) editFrame:Hide() end)
    editBox.editBox:SetScript('OnEnterPressed', function(self)
        if displaySettingItem then
            displaySettingItem['text'] = self:GetText()
        else
            addItem(self:GetText())
        end
        editFrame:Hide()
        refreshUI()
    end)

    editFrame.editBox = editBox.editBox
end

refreshUI = function()
    if not mainFrame then return end
    if not mainFrame:IsVisible() then return end

    if mainFrame.startButton then
        if isRunning then
            mainFrame.startButton:SetText('停止')
        else
            mainFrame.startButton:SetText('开始')
        end
    end

    if not settingFrame then return end
    if settingFrame:IsVisible() then
        for i = 1, displayPageSize do
            local frame = displayFrameList[i]
            local idx = displayPageNo * displayPageSize + i
            if idx <= #XSpeakWordList then
                local item = XSpeakWordList[idx]

                frame.indexButton:SetText(idx)
                frame.label:SetText(item['text'])

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
    end
end

addItem = function(text, enabled)
    if enabled == nil then enabled = false end
    table.insert(XSpeakWordList, { text = text, enabled = enabled })
end

getItem = function(index)
    return XSpeakWordList[index]
end

send = function()
    if #XSpeakWordList <= 0 then
        xdebug.warn('请先设置喊话内容')
        return
    end
    if lastUpdatetime + dft_interval > time() then return end

    for i = curIndex, #XSpeakWordList do
        local item = XSpeakWordList[i]
        if item['enabled'] then
            XAPI.SendChatMessage(item['text'], 'channel', nil, 2)
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

-- Event callback
local function onUIUpdate()
    if mainFrame then
        local time = time() - lastUpdatetime
        if lastUpdatetime == 0 then time = 0 end
        if time < 0 then time = 0 end
        mainFrame.title:SetText('自动喊话(' .. curIndex .. ')    ' .. XUtils.formatTimeLeft(time) .. ' / ' .. dft_interval)
    end
end

local function onUpdate()
    if isRunning then
        if #XSpeakWordList <= 0 then
            xdebug.warn('请先设置喊话内容')
            lastUpdatetime = 0
            curIndex = 1
            isRunning = false
            return
        end
        send()
    end
end

-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
end)
XAutoAuction.registerUIUpdateCallback(moduleName, onUIUpdate)
XAutoAuction.registerUpdateCallback(moduleName, onUpdate)

-- Commands
SlashCmdList['XAUTOSPEAK'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XAUTOSPEAK1 = '/xautospeak'

SlashCmdList['XAUTOSPEAKSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XAUTOSPEAKSHOW1 = '/xautospeak_show'

SlashCmdList['XAUTOSPEAKCLOSE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XAUTOSPEAKCLOSE1 = '/xautospeak_close'

SlashCmdList['XAUTOSPEAKSEND'] = function()
    send()
end
SLASH_XAUTOSPEAKSEND1 = '/xautospeak_send'

-- Interface
XAutoSpeak.addItem = addItem
XAutoSpeak.getItem = getItem
XAutoSpeak.toggle = function() XUI.toggleVisible(mainFrame) end
XAutoSpeak.isRunning = function() return isRunning end
