XSpeakWord = {}
local moduleName = 'XSpeakWord'

-- Variable definition
local mainFrame = nil
local settingFrame = nil
local editFrame = nil
local hintFrame = nil

local dft_interval = 90
local dft_buttonWidth = 60
local dft_buttonGap = 1
local dft_defaultReply = '抱歉人不在，材料可以直接u我，看到消息后我会尽快回复'

local displayPageNo = 0
local displayFrameList = {}
local displayPageSize = 10
local displaySettingItem = nil

local lastUpdatetime = 0
local isRunning = false
local curIndex = 1;
local autoReply = true
local replyList = {}

-- Function definition
local initUI
local initUI_Setting
local initUI_Edit
local refreshUI
local addItem
local getItem
local send
local printList
local addReplyList
local setAutoReply
local getAutoReply

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame('XSpeakWordMainFrame', 250, 80)
    mainFrame.title:SetText('自动喊话')
    mainFrame:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -30, -50)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local startButton = XUI.createButton(mainFrame, 50, XUI.Red .. '开始')
    startButton:SetPoint('LEFT', mainFrame, 'LEFT', 15, -10)
    startButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            xdebug.info('----------自动喊话设置----------')
            for idx, cnt in pairs(XSpeakWordList) do
                local status = 'disabled'
                if cnt['enabled'] ~= nil and cnt['enabled'] then
                    status = 'enabled'
                end
                xdebug.info(idx .. '(' .. status .. '): ' .. cnt['text'])
            end
        else
            isRunning = not isRunning
            lastUpdatetime = 0
            refreshUI()
        end
    end)
    mainFrame.startButton = startButton

    local replyButton = XUI.createButton(mainFrame, 50, XUI.Green .. '回复')
    replyButton:SetPoint('LEFT', startButton, 'RIGHT', 5, 0)
    replyButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            xdebug.info(getAutoReply())
        else
            autoReply = not autoReply
            replyList = {}
            refreshUI()
        end
    end)
    mainFrame.replyButton = replyButton

    local resetButton = XUI.createButton(mainFrame, 50, '重置')
    resetButton:SetPoint('LEFT', replyButton, 'RIGHT', 5, 0)
    resetButton:SetScript('OnClick', function()
        isRunning = false
        lastUpdatetime = 0
        curIndex = 1
        replyList = {}
        refreshUI()
    end)

    local settingButton = XUI.createButton(mainFrame, 50, '设置')
    settingButton:SetPoint('LEFT', resetButton, 'RIGHT', 5, 0)
    settingButton:SetScript('OnClick', function()
        if not settingFrame then return end
        settingFrame:Show()
        refreshUI()
    end)

    initUI_Setting()
    initUI_Edit()

    hintFrame = XAPI.CreateFrame('Frame', nil, UIParent)
    hintFrame:SetSize(300, 100)
    hintFrame:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', 0, 0)
    hintFrame:SetFrameStrata('DIALOG')
    hintFrame:Hide()
    hintFrame.text = hintFrame:CreateFontString(nil, 'ARTWORK')
    hintFrame.text:SetJustifyH('CENTER')
    hintFrame.text:SetAllPoints()
    hintFrame.text:SetFontObject(ChatFontNormal)
    hintFrame.text:SetText('新消息')
    hintFrame.hintBg = hintFrame:CreateTexture(nil, 'BACKGROUND')
    hintFrame.hintBg:SetAllPoints(hintFrame)
    hintFrame.hintBg:SetColorTexture(1, 1, 0, 0.9)
    hintFrame:SetScript('OnMouseDown', function(self) self:Hide() end)
end

initUI_Setting = function()
    settingFrame = XUI.createFrame('XSpeakWordSettingFrame', 500, 400)
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
    printButton:SetScript('OnClick', printList)

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
    editFrame = XUI.createFrame('XSpeakWordEditFrame', 400, 200, 'DIALOG')
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

    local time = time() - lastUpdatetime
    if lastUpdatetime == 0 then time = 0 end
    if time < 0 then time = 0 end
    mainFrame.title:SetText('自动喊话(' .. curIndex .. ')    ' .. XUtils.formatTimeLeft(time) .. ' / ' .. dft_interval)

    if mainFrame.startButton then
        if isRunning then
            mainFrame.startButton:SetText(XUI.Green .. '停止')
        else
            mainFrame.startButton:SetText(XUI.Red .. '开始')
        end
    end
    if mainFrame.replyButton then
        if autoReply then
            mainFrame.replyButton:SetText(XUI.Green .. '回复')
        else
            mainFrame.replyButton:SetText(XUI.Red .. '回复')
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

printList = function()
    xdebug.info('----------自动喊话设置----------')
    for idx, cnt in pairs(XSpeakWordList) do
        local status = 'disabled'
        if cnt['enabled'] ~= nil and cnt['enabled'] then
            status = 'enabled'
        end
        xdebug.info(idx .. '(' .. status .. '): ' .. cnt['text'])
    end
end

addReplyList = function(userName)
    for _, item in ipairs(replyList) do
        if item['username'] == userName then return end
    end
    tinsert(replyList, { username = userName, step = 1, createtime = time() })
end

setAutoReply = function(text)
    XSpeakWordSetting['autoreplycontent'] = text
end

getAutoReply = function()
    return XSpeakWordSetting['autoreplycontent']
end

-- Event callback
local function onUpdate()
    if not isRunning then return end

    if #XSpeakWordList <= 0 then
        xdebug.warn('请先设置喊话内容')
        lastUpdatetime = 0
        curIndex = 1
        isRunning = false
        return
    end

    send()

    if not autoReply then return end
    for _ = 1, #replyList do
        if replyList[1]['createtime'] < time() - 3 then
            tremove(replyList, 1)
        else
            break
        end
    end

    if #replyList < 1 then return end
    if replyList[1]['step'] == 1 then
        XAPI.SendChatMessage(dft_defaultReply, "WHISPER", nil, replyList[1]['username'])
        replyList[1]['step'] = 2
    else
        local reply = getAutoReply()
        if reply then
            XAPI.SendChatMessage(reply, "WHISPER", nil, replyList[1]['username'])
        end
        tremove(replyList, 1)
    end
end

-- Events
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
end)

XJewTool.registerEventCallback(moduleName, 'CHAT_MSG_WHISPER', function(self, event, message, sender, ...)
    if not hintFrame then return end
    hintFrame:Show()
    if isRunning and autoReply then
        addReplyList(sender)
    end
end)

XJewTool.registerUpdateCallback(moduleName, onUpdate)
XJewTool.registerUIUpdateCallback(moduleName, refreshUI, 1)

-- Commands
SlashCmdList['XSPEAKWORD'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XSPEAKWORD1 = '/xspeakword'

SlashCmdList['XSPEAKWORDSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XSPEAKWORDSHOW1 = '/xspeakword_show'

SlashCmdList['XSPEAKWORDCLOSE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XSPEAKWORDCLOSE1 = '/xspeakword_close'

SlashCmdList['XSPEAKWORDSEND'] = function()
    send()
end
SLASH_XSPEAKWORDSEND1 = '/xspeakword_send'

-- Interface
XSpeakWord.addItem = addItem
XSpeakWord.getItem = getItem
XSpeakWord.setAutoReply = setAutoReply
XSpeakWord.toggle = function() XUI.toggleVisible(mainFrame) end
XSpeakWord.isRunning = function() return isRunning end
XSpeakWord.start = function()
    isRunning = not isRunning
    lastUpdatetime = 0
end
XSpeakWord.printList = printList
