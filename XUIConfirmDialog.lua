XUIConfirmDialog = CreateFrame("Frame")

local mainFrame = nil
local titleLabel = nil
local labelList = {}

local key = nil
local confirmCallback = nil
local cancelCallback = nil

local function initUI()
    mainFrame = XUI.createFrame("XUIConfirmDialog", 250, 145, 'DIALOG')
    mainFrame:SetPoint("CENTER", UIParent, "CENTER")
    mainFrame:Hide()

    titleLabel = mainFrame.title
    titleLabel:SetText("")

    local confirm = XUI.createButton(mainFrame, 80, '确定')
    confirm:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOM", -10, 15)
    confirm:SetScript("OnClick", function()
        if confirmCallback then
            confirmCallback()
        end
        key = nil
        confirmCallback = nil
        cancelCallback = nil
        mainFrame:Hide()
    end)

    local cancel = XUI.createButton(mainFrame, 80, '取消')
    cancel:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOM", 10, 15)
    cancel:SetScript("OnClick", function()
        if cancelCallback then
            cancelCallback()
        end
        key = nil
        confirmCallback = nil
        cancelCallback = nil
        mainFrame:Hide()
    end)
end

initUI()

XUIConfirmDialog.isVisible = function(pkey)
    if not pkey then
        return mainFrame:IsVisible()
    else
        return mainFrame:IsVisible() and key == pkey
    end
end

XUIConfirmDialog.close = function(pkey)
    if mainFrame:IsVisible() and key == pkey then
        key = nil
        confirmCallback = nil
        cancelCallback = nil
        mainFrame:Hide()
    end
end

XUIConfirmDialog.show = function(pkey, title, content, onConfirm, onCancel)
    if not mainFrame then return end
    if mainFrame:IsVisible() then return end

    key = pkey
    confirmCallback = onConfirm
    cancelCallback = onCancel

    if type(content) ~= 'table' then
        content = { content }
    end

    titleLabel:SetText(title)
    for _, label in ipairs(labelList) do
        label:Hide()
        label = nil
    end
    labelList = {}

    local lastWidget = mainFrame
    for idx, tcontent in ipairs(content) do
        local tlabel = XUI.createLabel(mainFrame, 200, tcontent)
        tlabel:SetHeight(25)

        if idx == 1 then
            tlabel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 25, -30)
        else
            tlabel:SetPoint("TOPLEFT", lastWidget, "BOTTOMLEFT", 0, 0)
        end
        table.insert(labelList, tlabel)
        lastWidget = tlabel
    end

    mainFrame:SetHeight(85 + 25 * #content)
    mainFrame:Show()
end
