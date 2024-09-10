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
    local frame = XAPI.CreateFrame('Frame', name, UIParent, 'BasicFrameTemplateWithInset')

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
    frame:Hide()

    XFrameLevel = XFrameLevel + 10

    frame:HookScript('OnMouseDown', handleMouseClick)
    table.insert(XUI.frames, frame)
    return frame
end

XUI.createButton = function(parent, width, text)
    local button = XAPI.CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
    button:SetSize(width, 30)
    button:SetText(text)
    return button
end

XUI.createLabel = function(parent, width, text, align)
    local debug = true
    local label = nil
    if align == nil then align = 'LEFT' end
    if text == nil then text = '' end

    label = XAPI.CreateFrame('Frame', nil, parent)
    label.text = label:CreateFontString(nil, 'ARTWORK')
    label.text:SetJustifyH(align)
    label.text:SetAllPoints()
    label.text:SetFontObject(ChatFontNormal)
    label.SetText = function(self, t)
        label.text:SetText(t)
    end
    label:SetSize(width, 25)
    label:SetText(text)
    if debug then
        local bg = label:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints(label)
        bg:SetColorTexture(1, 0, 0, 0.5)
    end
    return label
end

XUI.createEditbox = function(parent, width)
    local debug = false
    local editBox = XAPI.CreateFrame('EditBox', nil, parent, 'InputBoxTemplate')
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

    local frame = XAPI.CreateFrame('Frame', nil, parent)
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

    local scroll = XAPI.CreateFrame('ScrollFrame', nil, frame, 'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT', borderWidth + margin, -borderWidth - margin)
    scroll:SetPoint('BOTTOMRIGHT', -23 - borderWidth - margin, borderWidth + margin)

    local scrollBG = scroll:CreateTexture(nil, 'BACKGROUND')
    scrollBG:SetAllPoints(scroll)
    scrollBG:SetColorTexture(0, 0, 0)

    local editBox = XAPI.CreateFrame('EditBox', nil, scroll)
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

    local dropdown = XAPI.CreateFrame('Frame', nil, parent, 'UIDropDownMenuTemplate')
    XAPI.UIDropDownMenu_SetWidth(dropdown, width)
    XAPI.UIDropDownMenu_JustifyText(dropdown, 'LEFT')
    -- dropdown:SetFrameStrata('DIALOG')
    -- XAPI.UIDropDownMenu_SetAnchor(dropdown, 0, 0, 'TOP', UIParent, 'CENTER')
    -- XAPI.UIDropDownMenu_Show(dropdown)

    -- Set initial text for the dropdown
    XAPI.UIDropDownMenu_SetText(dropdown, defaultValue)

    -- Define the initialize function for the dropdown
    XAPI.UIDropDownMenu_Initialize(dropdown, function(self)
        for _, item in ipairs(items) do
            local info = XAPI.UIDropDownMenu_CreateInfo()
            info.text = item
            info.func = function(tinfo)
                XAPI.UIDropDownMenu_SetText(dropdown, tinfo.value)
                if onSelected and type(onSelected) == 'function' then
                    onSelected(tinfo.value)
                end
            end
            XAPI.UIDropDownMenu_AddButton(info)
        end
    end)

    if debug then
        local bg = dropdown:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints()
        bg:SetColorTexture(1, 0, 0, 1)
    end
    return dropdown
end

-- contentWidth = width - 23
XUI.createScrollView = function(parent, width, height)
    local debug = true

    local borderWidth = 1
    local margin = 3

    local frame = XAPI.CreateFrame('Frame', nil, parent)
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

    local scrollView = XAPI.CreateFrame('ScrollFrame', nil, frame, 'UIPanelScrollFrameTemplate')
    scrollView:SetPoint('TOPLEFT', borderWidth + margin, -borderWidth - margin)
    scrollView:SetPoint('BOTTOMRIGHT', -23 - borderWidth - margin, borderWidth + margin)

    local scrollBG = scrollView:CreateTexture(nil, 'BACKGROUND')
    scrollBG:SetAllPoints(scrollView)
    scrollBG:SetColorTexture(0, 0, 0)

    local contentView = XAPI.CreateFrame('Frame', nil, scrollView)
    contentView:SetSize(width - 23, 1)

    scrollView:SetScrollChild(contentView)

    if debug then
        local frameBG = frame:CreateTexture(nil, 'BACKGROUND')
        frameBG:SetAllPoints(frame)
        frameBG:SetColorTexture(0, 0, 1, 0.5)

        scrollBG:SetColorTexture(0, 1, 0, 0.5)

        local contentBG = contentView:CreateTexture(nil, 'BACKGROUND')
        contentBG:SetAllPoints(contentView)
        contentBG:SetColorTexture(1, 0, 0, 0.5)
    end

    frame.scrollView = scrollView
    frame.contentView = contentView
    frame.itemFrameList = {}

    frame.CreateFrame = function(this, iwidth, iheight)
        local itemFrame = XAPI.CreateFrame('Frame', nil, this.contentView)
        itemFrame:SetSize(iwidth, iheight)
        if #this.itemFrameList == 0 then
            itemFrame:SetPoint('TOPLEFT', this.contentView, 'TOPLEFT', 0, 0)
            this.contentView:SetHeight(iheight)
        else
            local lastFrame = this.itemFrameList[#this.itemFrameList];
            itemFrame:SetPoint('TOPLEFT', lastFrame, 'BOTTOMLEFT', 0, 0)
            this.contentView:SetHeight(this.contentView:GetHeight() + iheight)
        end
        table.insert(this.itemFrameList, itemFrame)
        return itemFrame
    end
    frame.ClearContents = function(this)
        for _, itemFrame in ipairs(this.itemFrameList) do
            itemFrame:Hide()
            itemFrame:ClearAllPoints()
            itemFrame = nil
        end
        this.itemFrameList = {}
    end
    frame.GetItemFrame = function(this, index)
        return this.itemFrameList[index]
    end
    return frame
end

XUI.toggleVisible = function(frame)
    if not frame then return end

    if frame:IsVisible() then
        frame:Hide()
    else
        frame:Show()
    end
end

XUI.Red = '|cFFFF0000'
XUI.Green = '|cFF00FF00'
XUI.Blue = '|cFF0000FF'
XUI.Yellow = '|cFFFFFF00'
XUI.Orange = '|cFFFF8000'
XUI.Cyan = '|cFF00FFFF'
XUI.Purple = '|cFFFF00FF'
XUI.White = '|cFFFFFFFF'
XUI.Gray = '|cFF999999'

XUI.Color_Worst = XUI.Purple
XUI.Color_Bad = XUI.Red
XUI.Color_Poor = XUI.Orange
XUI.Color_Fair = XUI.Yellow
XUI.Color_Normal = XUI.White
XUI.Color_Good = XUI.Green
XUI.Color_Great = XUI.Cyan

-- <20%(>5): 红 / 20%-33%(3~5): 黄 / 33%-50%(2~3): 绿 / >50%(<2) 青
XUI.getColor_DealRate = function(dealRate)
    local res = XUI.Color_Normal
    if dealRate > 5 then
        res = XUI.Color_Bad
    elseif dealRate > 3 then
        res = XUI.Color_Fair
    elseif dealRate > 2 then
        res = XUI.Color_Good
    else
        res = XUI.Color_Great
    end
    return res
end

-- >40/天: 青 / 10~40/天: 绿 / 3~10: 黄 / <3个: 红
XUI.getColor_DealCount = function(dealCount)
    local res = XUI.Color_Normal
    if dealCount > 40 * 3 then
        res = XUI.Color_Great
    elseif dealCount > 10 * 3 then
        res = XUI.Color_Good
    elseif dealCount > 3 * 3 then
        res = XUI.Color_Fair
    else
        res = XUI.Color_Bad
    end
    return res
end

-- >3组: 青 / 2-3组: 绿 / 1-2组: 黄 / <1组: 红
XUI.getColor_BagCount = function(bagCount)
    local res = XUI.Color_Normal
    if bagCount >= 60 then
        res = XUI.Color_Great
    elseif bagCount >= 40 then
        res = XUI.Color_Good
    elseif bagCount >= 20 then
        res = XUI.Color_Fair
    else
        res = XUI.Color_Bad
    end
    return res
end

-- >10组: 青 / 5-10组: 绿 / 2-5组: 黄 / <2组: 红
XUI.getColor_TotalCount = function(totalCount)
    local res = XUI.Color_Normal
    if totalCount >= 200 then
        res = XUI.Color_Great
    elseif totalCount >= 100 then
        res = XUI.Color_Good
    elseif totalCount >= 40 then
        res = XUI.Color_Fair
    else
        res = XUI.Red
    end
    return res
end

XUI.getColor_BagStackCount = function(bagCount, stackCount)
    local res = XUI.Color_Normal
    if bagCount >= stackCount * 2 then
        res = XUI.Color_Great
    elseif bagCount >= stackCount then
        res = XUI.Color_Good
    elseif bagCount > 0 then
        res = XUI.Color_Fair
    else
        res = XUI.Color_Bad
    end
    return res
end

XUI.getColor_AuctionStackCount = function(auctionCount, stackCount)
    local res = XUI.Color_Normal
    if auctionCount > stackCount * 3 then
        res = XUI.Color_Worst
    elseif auctionCount >= stackCount * 2 or auctionCount <= 0 then
        res = XUI.Color_Bad
    elseif auctionCount > stackCount or auctionCount < stackCount then
        res = XUI.Color_Fair
    else
        res = XUI.Color_Good
    end
    return res
end
