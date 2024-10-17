XUIInputDialog = {}
local moduleName = 'XUIInputDialog'

-- Variable definition
local mainFrame = nil
local titleLabel = nil
local editGroupList = {}

local key = nil
local data = nil
local callback = nil

-- Function definition
local initUI

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame(moduleName, 250, 145, 'DIALOG')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    mainFrame:Hide()

    titleLabel = mainFrame.title
    titleLabel:SetText('')

    local confirmButton = XUI.createButton(mainFrame, 80, '确定')
    confirmButton:SetPoint('BOTTOM', mainFrame, 'BOTTOM', 0, 15)
    confirmButton:SetScript('OnClick', function()
        if not mainFrame then return end
        if not callback then return end
        if not data then return end

        for idx, item in ipairs(data) do
            item.Value = editGroupList[idx].edit:GetText()
        end
        callback(data)
        key = nil
        callback = nil
        mainFrame:Hide()
    end)
end

-- Events
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
end)

-- Interfaces
XUIInputDialog.isVisible = function(pkey)
    if not mainFrame then return false end

    if not pkey then
        return mainFrame:IsVisible()
    else
        return mainFrame:IsVisible() and key == pkey
    end
end

XUIInputDialog.close = function(pkey)
    if not mainFrame then return end
    if mainFrame:IsVisible() and key == pkey then
        key = nil
        data = nil
        callback = nil
        mainFrame:Hide()
    end
end

XUIInputDialog.show = function(pkey, pcallback, pdata, title)
    if not mainFrame then return end
    if not titleLabel then return end
    if not pcallback then return end
    if not pdata then return end
    if mainFrame:IsVisible() then return end

    if type(pdata) ~= 'table' then
        data = { { Name = pdata } }
    else
        data = pdata
    end

    key = pkey
    callback = pcallback

    if not title then title = '请输入' end
    titleLabel:SetText(title)

    for _, editGroup in ipairs(editGroupList) do
        editGroup.edit:SetText('')
        editGroup:Hide()
    end

    local lastWidget = mainFrame
    local firstEdit = nil
    for idx, tdata in ipairs(data) do
        local editGroup = nil
        if idx <= #editGroupList then
            editGroup = editGroupList[idx]
            editGroup:Show()
        else
            editGroup = XAPI.CreateFrame('Frame', nil, mainFrame)
            editGroup:SetSize(mainFrame:GetWidth(), 30)

            editGroup.label = XUI.createLabel(editGroup, 70, '', 'CENTER')
            editGroup.label:SetPoint('LEFT', editGroup, 'LEFT', 15, 0)

            editGroup.edit = XUI.createEditbox(editGroup,
                mainFrame:GetWidth() - 15 - editGroup.label:GetWidth() - 10 - 15)
            editGroup.edit:SetPoint('LEFT', editGroup.label, 'RIGHT', 10, 0)

            editGroup.edit.index = idx

            table.insert(editGroupList, editGroup)
        end

        if idx == 1 then
            editGroup:SetPoint('TOP', mainFrame, 'TOP', 0, -30)
            firstEdit = editGroup.edit
        else
            editGroup:SetPoint('TOP', lastWidget, 'BOTTOM', 0, 0)
        end
        lastWidget = editGroup

        editGroup.label:SetText(tdata.Name)
        if tdata.Value then editGroup.edit:SetText(tdata.Value) end

        if tdata.OnEscapePressed and type(tdata.OnEscapePressed) == 'function' then
            editGroup.edit:SetScript('OnEscapePressed', function(self)
                for tidx, item in ipairs(data) do
                    item.Value = editGroupList[tidx].edit:GetText()
                end
                tdata.OnEscapePressed(self:GetText(), data)
            end)
        else
            editGroup.edit:SetScript('OnEscapePressed', function(self)
                XUIInputDialog.close(key)
            end)
        end

        if tdata.OnEnterPressed and type(tdata.OnEnterPressed) == 'function' then
            editGroup.edit:SetScript('OnEnterPressed', function(self)
                for tidx, item in ipairs(data) do
                    item.Value = editGroupList[tidx].edit:GetText()
                end
                tdata.OnEnterPressed(self:GetText(), data)
            end)
        else
            if idx == #data then
                editGroup.edit:SetScript('OnEnterPressed', function(self)
                    for tidx, item in ipairs(data) do
                        item.Value = editGroupList[tidx].edit:GetText()
                    end
                    callback(data)
                    mainFrame:Hide()
                end)
            else
                editGroup.edit:SetScript('OnEnterPressed', function(self)
                    local teditGroup = editGroupList[self.index + 1]
                    teditGroup.edit:SetFocus()
                end)
            end
        end

        editGroup.edit:SetScript('OnTabPressed', function(self)
            local tindex = self.index + 1
            if tindex > #data then tindex = 1 end
            local teditGroup = editGroupList[tindex]
            teditGroup.edit:SetFocus()
        end)
    end

    mainFrame:SetHeight(80 + 30 * #data)
    mainFrame:Show()

    if firstEdit then
        firstEdit:SetFocus()
    end
end
