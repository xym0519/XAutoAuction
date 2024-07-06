XUIInputDialog = CreateFrame("Frame")

local mainFrame = nil
local titleLabel = nil
local editbox = nil

local key = nil
local callback = nil

local function onConfirm()
    if not mainFrame then return end
    if not callback then return end

    mainFrame:Hide()
    callback(editbox:GetText())
    key = nil
    callback = nil
end

local function onCancel()
    if not mainFrame then return end

    callback = nil
    key = nil
    mainFrame:Hide()
end

local function initUI()
    mainFrame = XUI.createFrame('XUIInputDialog', 200, 70, 'DIALOG')
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:Hide()

    titleLabel = mainFrame.title
    titleLabel:SetText("")

    editbox = XUI.createEditbox(mainFrame, 90, true)
    editbox:SetPoint("LEFT", mainFrame, "LEFT", 15, -10)
    editbox:SetScript("OnEscapePressed", onCancel)
    editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
    editbox:SetScript("OnEditFocusLost", function(self)
        self:SetText(self:GetText())
    end)
    editbox:SetScript("OnEnterPressed", onConfirm)

    local confirmButton = XUI.createButton(editbox, 80, '确定')
    confirmButton:SetPoint("LEFT", editbox, "RIGHT", 5, 0)
    confirmButton:SetScript("OnClick", onConfirm)
end

initUI()

XUIInputDialog.isVisible = function(pkey)
    if not pkey then
        return mainFrame:IsVisible()
    else
        return mainFrame:IsVisible() and key == pkey
    end
end

XUIInputDialog.close = function(pkey)
    if mainFrame:IsVisible() and key == pkey then
        key = nil
        callback = nil
        mainFrame:Hide()
    end
end

XUIInputDialog.show = function(pkey, pcallback, content, title)
    if not mainFrame then return end
    if mainFrame:IsVisible() then return end

    if not content then content = '' end
    if not title then title = '请输入' end

    key = pkey
    callback = pcallback

    titleLabel:SetText(title)
    editbox:SetText(content)
    mainFrame:Show()
end
