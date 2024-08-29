XAuctionItemToolTip = {}
XAuctionItemToolTip.Show = function(itemName, frame, anchor, sections)
    if IsShiftKeyDown() then
        local item = XAuctionCenter.getItem(itemName)
        if not item then return end
        if not sections then sections = { 1, 2, 3, 4 } end

        local minPriceOther = item['minpriceother']
        local basePrice = item['baseprice']
        local materialCount = XInfo.getMaterialCount(itemName)
        local materialPrice = XInfo.getMaterialPrice(itemName)
        local stackCount = item['stackcount']
        local lowerCount = item['lowercount']

        local itemBag = XInfo.getBagItem(itemName)
        local bagCount = 0
        local bagTotalCount = 0
        if itemBag then
            bagCount = itemBag['count']
            bagTotalCount = itemBag['totalcount']
        end

        local auctionCount = #item['mylist']
        local validCount = #item['myvalidlist']
        local bagAuctionCount = bagTotalCount + auctionCount

        local auctionCount2 = 0
        local auctionItem = XInfo.getAuctionItem(itemName)
        if auctionItem then
            auctionCount2 = auctionItem['count']
        end

        local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
        local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)

        local updateTimeStr = XUtils.formatTime(item['updatetime'])

        GameTooltip:SetOwner(frame, anchor)
        GameTooltip:AddLine(itemName .. ' (' .. updateTimeStr .. ')')

        if XUtils.inArray(1, sections) then
            GameTooltip:AddLine('----------')
            GameTooltip:AddDoubleLine('背包数量', bagCount)
            GameTooltip:AddDoubleLine('全部数量', bagAuctionCount)
            GameTooltip:AddDoubleLine('材料数量', materialCount)
            GameTooltip:AddDoubleLine('出售数量', stackCount)
        end

        if XUtils.inArray(2, sections) then
            GameTooltip:AddLine('----------')
            GameTooltip:AddDoubleLine('拍卖数量', auctionCount)
            GameTooltip:AddDoubleLine('有效数量', validCount)
            GameTooltip:AddDoubleLine('拍卖行数量', auctionCount2)
            GameTooltip:AddDoubleLine('低于基准价格', lowerCount)
        end

        if XUtils.inArray(3, sections) then
            GameTooltip:AddLine('----------')
            GameTooltip:AddDoubleLine('几次成交一次', dealRate)
            GameTooltip:AddDoubleLine('成交数量', dealCount)
        end

        if XUtils.inArray(4, sections) then
            GameTooltip:AddLine('----------')
            GameTooltip:AddDoubleLine('当前价格', XUtils.priceToMoneyString(minPriceOther))
            GameTooltip:AddDoubleLine('基准价格', XUtils.priceToMoneyString(basePrice))
            GameTooltip:AddDoubleLine('材料价格', XUtils.priceToMoneyString(materialPrice))
        end

        GameTooltip:Show()
    end
end
