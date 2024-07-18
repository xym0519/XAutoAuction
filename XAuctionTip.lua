GameTooltip:HookScript('OnTooltipSetItem', function(self)
    XInfo.reloadBag()
    local itemName, itemLink = self:GetItem()
    local itemId = XUtils.itemIDfromLink(itemLink)
    itemName = strtrim(itemName)

    local type = ''
    if XInfo.allHistory == 0 then
        type = 'All'
    elseif XInfo.allHistory == 1 then
        type = '10D'
    else
        type = '30D'
    end
    self:AddDoubleLine('类型:', type)

    local bagItem = XInfo.getBagItem(itemName)
    if bagItem ~= nil then
        self:AddDoubleLine(XUI.Green .. '背包:', XUI.Green .. bagItem['count'])
        self:AddDoubleLine(XUI.Green .. '银行:', XUI.Green .. bagItem['bankcount'])
    else
        self:AddDoubleLine(XUI.Red .. '背包:', XUI.Red .. 0)
        self:AddDoubleLine(XUI.Red .. '银行:', XUI.Red .. 0)
    end

    local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
    local dealRateColor = XUI.getColor_DealRate(dealRate)

    local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)
    local dealCountColor = XUI.getColor_DealCount(dealCount)

    self:AddDoubleLine(dealRateColor .. '成交几率:', dealRateColor .. dealRate .. '次')
    self:AddDoubleLine(dealCountColor .. '成交次数:', dealCountColor .. dealCount .. '次')
    self:AddDoubleLine(XUI.Red .. '保本价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'lowestprice', 0)))
    self:AddDoubleLine('成本价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'costprice', 0)))
    self:AddDoubleLine('平均价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'scanprice', 0)))
    self:AddDoubleLine('最低价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'minscanprice', 0)))
    self:AddDoubleLine('最高价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'maxscanprice', 0)))

    self:AddDoubleLine('ItemId:', itemId)
end)
