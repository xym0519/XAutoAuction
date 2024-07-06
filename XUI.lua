XUI = {}

XUI.createFrame = function(name, width, height, strata)
    if strata == nil then strata = 'HIGH' end
    local frame = CreateFrame("Frame", name, UIParent, "UIPanelDialogTemplate")
    frame:EnableMouse(true)
    frame:SetSize(width, height)
    frame.title:SetText(name)
    frame:SetFrameStrata(strata)
    frame:Hide()
    return frame
end

XUI.createButton = function(parent, width, text)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 30)
    button:SetText(text)
    return button
end

XUI.createLabel = function(parent, width, text)
    local label = CreateFrame("EditBox", nil, parent)
    label:SetSize(width, 25)
    -- 设置编辑框为只读
    label:SetCursorPosition(0) -- 设置光标位置为开头
    label:EnableMouse(false)   -- 禁用鼠标交互
    label:ClearFocus()         -- 清除焦点
    label:SetAutoFocus(false)  -- 禁止自动获得焦点
    label:SetFontObject(ChatFontNormal)
    label:SetText(text)
    return label
end

XUI.createEditbox = function(parent, width, autoFocus)
    local editBox = CreateFrame("EditBox", "", parent)
    editBox:EnableMouse(true)
    editBox:SetAutoFocus(autoFocus)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetSize(width, 25)
    return editBox
end

XUI.getColor_SuccRate = function(succRate)
    local res = '|cFFFFFFFF'
    if succRate > 5 then
        res = '|cFFFF0000'
    elseif succRate > 3 then
        res = '|cFFFFFF00'
    elseif succRate > 2 then
        res = '|cFF00FF00'
    else
        res = '|cFF00FFFF'
    end
    return res
end

XUI.getColor_DealCount = function(dealCount)
    local res = '|cFFFFFFFF'
    if dealCount > 20 then
        res = '|cFF00FFFF'
    elseif dealCount > 10 then
        res = '|cFF00FF00'
    elseif dealCount > 3 then
        res = '|cFFFFFF00'
    else
        res = '|cFFFF0000'
    end
    return res
end
