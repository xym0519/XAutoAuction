XAuctionBoard = {}
local moduleName = 'XAuctionBoard'

-- Variable definition
local mainFrame = nil
XAuctionBoard = CreateFrame("Frame")

local dataList = {}
local displayFrameList = {}

-- Function definition
local initUI
local refreshUI
local addItem

-- Function implemention
initUI = function()
    mainFrame = XUI.createFrame(moduleName .. 'Frame', 340, 400)
    mainFrame.title:SetText('拍卖纪录')
    mainFrame:SetPoint('CENTER', UIParent, 'CENTER', -50, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())
    XAuctionBoard.mainFrame = mainFrame

    local cleanButton = XUI.createButton(mainFrame, 60, '清除')
    cleanButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -30)
    cleanButton:SetScript("OnClick", function()
        dataList = {}
        refreshUI()
    end)

    local refreshButton = XUI.createButton(mainFrame, 60, '刷新')
    refreshButton:SetPoint("LEFT", cleanButton, "RIGHT", 5, 0)
    refreshButton:SetScript("OnClick", function()
        refreshUI()
    end)

    local labelFrame = XAPI.CreateFrame('Frame', nil, mainFrame)
    labelFrame:SetSize(mainFrame:GetWidth() - 20, 30)
    labelFrame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 10, -60)

    local indexLabel = XUI.createLabel(labelFrame, 40, '序号', 'CENTER')
    indexLabel:SetPoint('LEFT', labelFrame, 'LEFT', 8, 0)

    local nameLabel = XUI.createLabel(labelFrame, 140, '名称', 'CENTER')
    nameLabel:SetPoint('LEFT', indexLabel, 'RIGHT', 5, 0)

    local dealCountLabel = XUI.createLabel(labelFrame, 40, '交易', 'CENTER')
    dealCountLabel:SetPoint('LEFT', nameLabel, 'RIGHT', 5, 0)

    local craftCountLabel = XUI.createLabel(labelFrame, 40, '制造', 'CENTER')
    craftCountLabel:SetPoint('LEFT', dealCountLabel, 'RIGHT', 5, 0)

    local scrollView = XUI.createScrollView(mainFrame, mainFrame:GetWidth() - 20,
        mainFrame:GetHeight() - 70 - labelFrame:GetHeight())
    scrollView:SetPoint('TOPLEFT', labelFrame, 'BottomLeft', 0, 0)
    mainFrame.scrollView = scrollView
end

refreshUI = function()
    if not mainFrame then return end
    local totalDealCount = 0
    local totalCraftCount = 0
    for _, item in ipairs(dataList) do
        totalDealCount = totalDealCount + item['dealcount']
        totalCraftCount = totalCraftCount + item['craftcount']
    end
    mainFrame.title:SetText('拍卖记录'
        .. '    成交: ' .. totalDealCount
        .. '    制造: ' .. totalCraftCount)

    local scrollView = mainFrame.scrollView
    scrollView:ClearContents()

    for i, dataItem in ipairs(dataList) do
        local frame = scrollView:CreateFrame(mainFrame:GetWidth() - 20, 30)
        local indexLabel = XUI.createLabel(frame, 40, i, 'CENTER')
        indexLabel:SetPoint('LEFT', frame, 'LEFT', 5, 0)

        local nameLabel = XUI.createLabel(frame, 140, dataItem['itemname'], 'CENTER')
        nameLabel:SetPoint('LEFT', indexLabel, 'RIGHT', 5, 0)

        local dealCountLabel = XUI.createLabel(frame, 40, dataItem['dealcount'], 'CENTER')
        dealCountLabel:SetPoint('LEFT', nameLabel, 'RIGHT', 5, 0)

        local craftCountLabel = XUI.createLabel(frame, 40, dataItem['craftcount'], 'CENTER')
        craftCountLabel:SetPoint('LEFT', dealCountLabel, 'RIGHT', 5, 0)
    end
end

-- type: deal / craft
addItem = function(itemName, type, count)
    if count == nil then count = 1 end

    local existed = false

    for _, item in ipairs(dataList) do
        if item['itemname'] == itemName then
            if type == 'deal' then
                item['dealcount'] = item['dealcount'] + count
            elseif type == 'craft' then
                item['craftcount'] = item['craftcount'] + count
            end
            existed = true
            break
        end
    end

    if not existed then
        if type == 'deal' then
            table.insert(dataList, { itemname = itemName, dealcount = count, craftcount = 0 })
        elseif type == 'craft' then
            table.insert(dataList, { itemname = itemName, dealcount = 0, craftcount = count })
        end
    end

    refreshUI()
end

-- Event callback


-- Events
XAutoAuction.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
    refreshUI()
end)

XAutoAuction.registerEventCallback(moduleName, 'CHAT_MSG_SYSTEM', function(self, event, text, context)
    if XUtils.stringStartsWith(text, '你拍卖的') and XUtils.stringEndsWith(text, '已经售出。') then
        local itemName = string.sub(text, string.len('你拍卖的') + 1, string.len(text) - string.len('已经售出。'))
        addItem(itemName, 'deal')
        refreshUI()
    end
end)

-- Commands
SlashCmdList["XAUCTIONBOARD"] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XAUCTIONBOARD1 = "/xauctionboard"

SlashCmdList['XAUCTIONBOARDSHOW'] = function()
    if mainFrame then mainFrame:Show() end
end
SLASH_XAUCTIONBOARDSHOW1 = '/xauctionboard_show'

SlashCmdList['XAUCTIONBOARDHIDE'] = function()
    if mainFrame then mainFrame:Hide() end
end
SLASH_XAUCTIONBOARDHIDE1 = '/xauctionboard_hide'

-- Interface
XAuctionBoard.addItem = addItem
XAuctionBoard.toggle = function() XUI.toggleVisible(mainFrame) end
