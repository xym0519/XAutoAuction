XUI = {}
XUI.frames = {}
XUI.focusedFrame = nil

local function handleMouseClick(self, button)
    if button == 'LeftButton' then
        if self ~= XUI.focusedFrame then
            XUI.focusedFrame = self
            for index, frame in ipairs(XUI.frames) do
                if frame == self then
                    table.remove(XUI.frames, index)
                    table.insert(XUI.frames, self)
                    self:SetFrameLevel(XFrameLevel)
                    XFrameLevel = XFrameLevel + 10
                    break
                end
            end

            if XFrameLevel > 2000 then
                for index, frame in ipairs(XUI.frames) do
                    frame:SetFrameLevel(index * 10)
                end
                XFrameLevel = (#XUI.frames + 1) * 10
            end
        end
    end
end

XUI.createFrame = function(name, width, height, strata)
    if strata == nil then strata = 'HIGH' end
    local frame = CreateFrame('Frame', name, UIParent, 'BasicFrameTemplateWithInset')

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', frame.StopMovingOrSizing)

    frame:SetSize(width, height)
    frame.title = frame:CreateFontString(nil, 'ARTWORK')
    frame.title:SetFontObject('GameFontHighlight')
    frame.title:SetPoint('CENTER', frame, 'TOP', 0, -10)
    frame.title:SetText(name)
    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(XFrameLevel)
    XFrameLevel = XFrameLevel + 10
    frame:Hide()

    frame:HookScript('OnMouseDown', handleMouseClick)
    table.insert(XUI.frames, frame)
    return frame
end

XUI.createButton = function(parent, width, text)
    local button = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
    button:SetSize(width, 30)
    button:SetText(text)
    return button
end

XUI.createLabel = function(parent, width, text, align)
    local debug = false
    local label = nil
    if align == nil then align = 'LEFT' end
    if text == nil then text = '' end

    if debug then
        label = CreateFrame('EditBox', nil, parent)
        label:SetCursorPosition(0) -- 设置光标位置为开头
        label:EnableMouse(false)   -- 禁用鼠标交互
        label:ClearFocus()         -- 清除焦点
        label:SetAutoFocus(false)  -- 禁止自动获得焦点
        local bg = label:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints(label)
        bg:SetColorTexture(1, 0, 0, 0.5)
    else
        label = parent:CreateFontString(nil, 'ARTWORK')
        label:SetJustifyH(align)
    end
    -- label:SetFontObject(GameFontHighlight)
    label:SetFontObject(ChatFontNormal)
    label:SetSize(width, 25)
    label:SetText(text)
    return label
end

XUI.createEditbox = function(parent, width)
    local debug = false
    local editBox = CreateFrame('EditBox', nil, parent, 'InputBoxTemplate')
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetSize(width, 25)
    editBox:SetAutoFocus(false)
    editBox:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
    editBox:SetScript('OnEnterPressed', function(self) self:ClearFocus() end)
    editBox:SetScript('OnEditFocusGained', function(self) self:HighlightText() end)
    editBox:SetScript('OnEditFocusLost', function(self) self:SetText(self:GetText()) end)
    if debug then
        local bg = editBox:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints(editBox)
        bg:SetColorTexture(0, 1, 0, 0.5)
    end
    return editBox
end

XUI.createEditboxMultiline = function(parent, width, height)
    local debug = false

    local borderWidth = 1
    local margin = 3

    local frame = CreateFrame('Frame', nil, parent)
    frame:SetSize(width, height)

    local frameBorderTop = frame:CreateTexture(nil, 'OVERLAY')
    frameBorderTop:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    frameBorderTop:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    frameBorderTop:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', 0, -borderWidth)

    local frameBorderBottom = frame:CreateTexture(nil, 'OVERLAY')
    frameBorderBottom:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    frameBorderBottom:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 0, borderWidth)
    frameBorderBottom:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)

    local frameBorderLeft = frame:CreateTexture(nil, 'OVERLAY')
    frameBorderLeft:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    frameBorderLeft:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    frameBorderLeft:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMLEFT', borderWidth, 0)

    local frameBorderRight = frame:CreateTexture(nil, 'OVERLAY')
    frameBorderRight:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    frameBorderRight:SetPoint('TOPLEFT', frame, 'TOPRIGHT', -borderWidth, 0)
    frameBorderRight:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)

    local scroll = CreateFrame('ScrollFrame', nil, frame, 'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT', borderWidth + margin, -borderWidth - margin)
    scroll:SetPoint('BOTTOMRIGHT', -23 - borderWidth - margin, borderWidth + margin)

    local scrollBG = scroll:CreateTexture(nil, 'BACKGROUND')
    scrollBG:SetAllPoints(scroll)
    scrollBG:SetColorTexture(0, 0, 0)

    local editBox = CreateFrame('EditBox', nil, scroll)
    editBox:SetSize(width - 23, height)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetScript('OnEscapePressed', function(self)
        self:ClearFocus()
    end)
    editBox:SetScript('OnEnterPressed', function(self) self:ClearFocus() end)
    editBox:SetScript('OnEditFocusGained', function(self) self:HighlightText() end)

    scroll:SetScrollChild(editBox)

    if debug then
        local frameBG = frame:CreateTexture(nil, 'BACKGROUND')
        frameBG:SetAllPoints(frame)
        frameBG:SetColorTexture(0, 0, 1, 0.5)

        scrollBG:SetColorTexture(0, 1, 0, 0.5)

        local editBG = editBox:CreateTexture(nil, 'BACKGROUND')
        editBG:SetAllPoints(editBox)
        editBG:SetColorTexture(0, 0, 1, 0.5)
    end

    frame.editBox = editBox
    return frame
end

XUI.createDropDown = function(parent, width, items, defaultValue, onSelected)
    local debug = false

    local dropdown = CreateFrame('Frame', nil, parent, 'UIDropDownMenuTemplate')
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_JustifyText(dropdown, 'LEFT')
    -- dropdown:SetFrameStrata('DIALOG')
    -- UIDropDownMenu_SetAnchor(dropdown, 0, 0, 'TOP', UIParent, 'CENTER')
    -- UIDropDownMenu_Show(dropdown)

    -- Set initial text for the dropdown
    UIDropDownMenu_SetText(dropdown, defaultValue)

    -- Define the initialize function for the dropdown
    UIDropDownMenu_Initialize(dropdown, function(self)
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item
            info.func = function(tinfo)
                UIDropDownMenu_SetText(dropdown, tinfo.value)
                if onSelected and type(onSelected) == 'function' then
                    onSelected(tinfo.value)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    if debug then
        local bg = dropdown:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints()
        bg:SetColorTexture(1, 0, 0, 1)
    end
    return dropdown
end

XUI.toggleVisible = function(frame)
    if not frame then return end

    if frame:IsVisible() then
        frame:Hide()
    else
        frame:Show()
    end
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
