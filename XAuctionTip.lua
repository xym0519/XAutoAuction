local lastUpdateTime = 0
local dft_updateInterval = 10
GameTooltip:HookScript('OnTooltipSetItem', function(self)
    if lastUpdateTime + dft_updateInterval < time() then
        XInfo.reloadBag()
        if XAPI.IsBankOpen() then XInfo.reloadBank() end
        lastUpdateTime = time()
    end

    local itemName, itemLink = self:GetItem()
    local itemId = XUtils.itemIDfromLink(itemLink)
    itemName = strtrim(itemName)
    if itemId and itemId > 0 then
        XExternal.updateItemInfo(itemName, itemId)
    end

    local item = XAuctionCenter.getItem(itemName)
    local stackCount = 0
    if item then stackCount = item['stackcount'] end

    local bagCount = XInfo.getBagItemCount(itemName)
    local bagCountStr = XUI.getColor_BagCount(bagCount) .. bagCount
    local bankCount = XInfo.getBankItemCount(itemName)
    local bankCountStr = XUI.getColor_BagCount(bankCount) .. bankCount
    local mailCount = XInfo.getMailItemCount(itemName)
    local mailCountStr = XUI.getColor_BagCount(mailCount) .. mailCount
    local auctionCount = XInfo.getAuctionItemCount(itemName)
    local auctionCountStr = XUI.getColor_AuctionStackCount(auctionCount, stackCount) .. auctionCount

    local materialName = XInfo.getMaterialName(itemName)
    local materialCount = XInfo.getMaterialTotalCount(materialName)
    local materialCountStr = XUI.getColor_TotalCount(materialCount) .. materialCount

    self:AddLine(' ')
    self:AddLine('---------- 数量信息 ----------')
    self:AddDoubleLine('背包', bagCountStr)
    self:AddDoubleLine('银行', bankCountStr)
    self:AddDoubleLine('邮件', mailCountStr)
    self:AddDoubleLine('拍卖', auctionCountStr)
    self:AddDoubleLine('材料', materialCountStr)

    local basePrice = 0
    if item then basePrice = item['baseprice'] end
    local minPriceOther = 0
    if item then minPriceOther = item['minpriceother'] end
    local minPriceOtherStr = XUtils.priceToMoneyString(minPriceOther)
    if minPriceOther >= basePrice then
        minPriceOtherStr = XUI.Green .. minPriceOtherStr
    else
        minPriceOtherStr = XUI.Red .. minPriceOtherStr
    end
    local materialBuyoutPrice = XAutoBuy.getItemField(materialName, 'minbuyoutprice', 9999999)
    local materialBuyoutPriceStr = XUtils.priceToMoneyString(materialBuyoutPrice)
    local materialCostPrice = XInfo.getAuctionInfoField(materialName, 'costprice', 0)
    local materialCostPriceStr = XUtils.priceToMoneyString(materialCostPrice)

    self:AddLine(' ')
    self:AddLine('---------- 价格信息 ----------')
    self:AddDoubleLine('当前价格', minPriceOtherStr)
    self:AddDoubleLine('到手价格', XUI.Cyan .. XUtils.priceToMoneyString(minPriceOther * XAPI.ProfitRate))
    self:AddDoubleLine('材料现价', materialBuyoutPriceStr)
    self:AddDoubleLine('材料均价', materialCostPriceStr)
    self:AddDoubleLine('最低售价', XUI.Cyan .. XUtils.priceToMoneyString(materialCostPrice / XAPI.ProfitRate))

    local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
    local dealRateStr = XUI.getColor_DealRate(dealRate) .. dealRate
    local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)
    local dealCountStr = XUI.getColor_DealCount(dealCount) .. dealCount

    self:AddLine(' ')
    self:AddLine('---------- 交易信息 ----------')
    self:AddDoubleLine('几次成交一次', dealRateStr)
    self:AddDoubleLine('成交数量', dealCountStr)
    self:AddLine(' ')
end)
