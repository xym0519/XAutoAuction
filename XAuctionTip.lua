GameTooltip:HookScript('OnTooltipSetItem', function(self)
    XInfo.reloadBag()
    local itemName, itemLink = self:GetItem()
    local itemId = XUtils.itemIDfromLink(itemLink)
    itemName = strtrim(itemName)

    local type = '10Day'
    if XInfo.allHistory then
        type = 'All'
    end
    self:AddDoubleLine('类型:', type)

    local bagItem = XInfo.getBagItem(itemName)
    if bagItem ~= nil then
        self:AddDoubleLine('|cFF00FF00背包:', '|cFF00FF00' .. bagItem['count'])
        self:AddDoubleLine('|cFF00FF00银行:', '|cFF00FF00' .. bagItem['bankcount'])
    else
        self:AddDoubleLine('|cFFFF0000背包:', '|cFFFF0000' .. 0)
        self:AddDoubleLine('|cFFFF0000银行:', '|cFFFF0000' .. 0)
    end

    local succRate = XInfo.getAuctionInfoField(itemName, 'succrate', 99)
    local succRateColor = XUI.getColor_SuccRate(succRate)

    local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)
    local dealCountColor = XUI.getColor_DealCount(dealCount)

    self:AddDoubleLine(succRateColor .. '成交几率:', succRateColor .. succRate .. '次')
    self:AddDoubleLine(dealCountColor .. '成交次数:', dealCountColor .. dealCount .. '次')
    self:AddDoubleLine('|cFFFF0000保本价:',
        '|cFFFFFFFF' .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'lowestprice', 0)))
    self:AddDoubleLine('成本价:',
        '|cFFFFFFFF' .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'costprice', 0)))
    self:AddDoubleLine('平均售价:',
        '|cFFFFFFFF' .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'sellprice', 0)))
    self:AddDoubleLine('最低售价:',
        '|cFFFFFFFF' .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'minsellprice', 0)))
    self:AddDoubleLine('最高售价:',
        '|cFFFFFFFF' .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'maxsellprice', 0)))

    self:AddDoubleLine('ItemId:', itemId)
end)
