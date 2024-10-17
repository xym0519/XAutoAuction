XUIConfirmDialog = {}
local moduleName = 'XUIConfirmDialog'

-- Variables definition
local mainFrame = nil
local titleLabel = nil
local labelList = {}

local key = nil
local confirmCallback = nil
local cancelCallback = nil

-- function definition
local initUI

-- function implemention
initUI = function()
    mainFrame = XUI.createFrame(moduleName, 250, 145, 'DIALOG')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER')
    mainFrame:Hide()

    titleLabel = mainFrame.title
    titleLabel:SetText('')

    local confirm = XUI.createButton(mainFrame, 80, '确定')
    confirm:SetPoint('BOTTOMRIGHT', mainFrame, 'BOTTOM', -10, 15)
    confirm:SetScript('OnClick', function()
        if confirmCallback then
            confirmCallback()
        end
        key = nil
        confirmCallback = nil
        cancelCallback = nil
        mainFrame:Hide()
    end)

    local cancel = XUI.createButton(mainFrame, 80, '取消')
    cancel:SetPoint('BOTTOMLEFT', mainFrame, 'BOTTOM', 10, 15)
    cancel:SetScript('OnClick', function()
        if cancelCallback then
            cancelCallback()
        end
        key = nil
        confirmCallback = nil
        cancelCallback = nil
        mainFrame:Hide()
    end)
end

-- Events
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
end)

-- Interfaces
XUIConfirmDialog.isVisible = function(pkey)
    if not mainFrame then return false end

    if not pkey then
        return mainFrame:IsVisible()
    else
        return mainFrame:IsVisible() and key == pkey
    end
end

XUIConfirmDialog.close = function(pkey)
    if not mainFrame then return end

    if mainFrame:IsVisible() and key == pkey then
        key = nil
        confirmCallback = nil
        cancelCallback = nil
        mainFrame:Hide()
    end
end

XUIConfirmDialog.show = function(pkey, title, content, onConfirm, onCancel)
    if not mainFrame then return end
    if not titleLabel then return end
    if mainFrame:IsVisible() then return end

    key = pkey
    confirmCallback = onConfirm
    cancelCallback = onCancel

    if type(content) ~= 'table' then
        content = { content }
    end

    if not title then title = '请确认' end
    titleLabel:SetText(title)

    for _, label in ipairs(labelList) do
        label:Hide()
    end

    local lastWidget = mainFrame
    for idx, tcontent in ipairs(content) do
        local tlabel = nil
        if idx <= #labelList then
            tlabel = labelList[idx]
            tlabel:Show()
        else
            tlabel = XUI.createLabel(mainFrame, mainFrame:GetWidth() - 20, '', 'CENTER')
            table.insert(labelList, tlabel)
        end
        tlabel:SetText(tcontent)

        if idx == 1 then
            tlabel:SetPoint('TOP', mainFrame, 'TOP', 0, -30)
        else
            tlabel:SetPoint('TOP', lastWidget, 'BOTTOM', 0, 0)
        end
        lastWidget = tlabel
    end

    mainFrame:SetHeight(85 + 25 * #content)
    mainFrame:Show()
end
