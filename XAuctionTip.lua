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
    local bagCountStr = XUI.getColor_BagStackCount(bagCount, stackCount) .. bagCount
    local bankCount = XInfo.getBankItemCount(itemName)
    local bankCountStr = XUI.getColor_BankCount(bankCount) .. bankCount
    local mailCount = XInfo.getMailItemCount(itemName)
    local mailCountStr = XUI.getColor_MailCount(mailCount) .. mailCount
    local auctionCount = XInfo.getAuctionItemCount(itemName)
    local auctionCountStr = XUI.getColor_AuctionStackCount(auctionCount, stackCount) .. auctionCount

    local materialName = XInfo.getMaterialName(itemName)
    local materialCount = XInfo.getMaterialTotalCount(materialName)
    local materialCountStr = XUI.getColor_MaterialTotalCount(materialCount) .. materialCount

    self:AddLine(' ')
    self:AddLine('---------- 数量信息 ----------')
    self:AddDoubleLine('背银邮拍', bagCountStr .. ' / ' .. bankCountStr .. ' / ' .. mailCountStr .. ' / ' .. auctionCountStr)
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
    local materialCostPrice = XInfo.getItemInfoField(materialName, 'costprice', 0)
    local materialCostPriceStr = XUtils.priceToMoneyString(materialCostPrice)

    local profit = minPriceOther * XAPI.ProfitRate - materialCostPrice
    local profitStr = XUtils.priceToMoneyString(profit)
    if profit > 20000 then
        profitStr = XUI.Color_Great .. profitStr
    elseif profit > 10000 then
        profitStr = XUI.Color_Good .. profitStr
    elseif profit > 5000 then
        profitStr = XUI.Color_Fair .. profitStr
    elseif profit > 0 then
        profitStr = XUI.Color_Poor .. profitStr
    else
        profitStr = XUI.Color_Bad .. profitStr
    end

    local profitCur = minPriceOther * XAPI.ProfitRate - materialBuyoutPrice
    local profitCurStr = XUtils.priceToMoneyString(profitCur)
    if profitCur > 20000 then
        profitCurStr = XUI.Color_Great .. profitCurStr
    elseif profitCur > 10000 then
        profitCurStr = XUI.Color_Good .. profitCurStr
    elseif profitCur > 5000 then
        profitCurStr = XUI.Color_Fair .. profitCurStr
    elseif profitCur > 0 then
        profitCurStr = XUI.Color_Poor .. profitCurStr
    else
        profitCurStr = XUI.Color_Bad .. profitCurStr
    end

    self:AddLine(' ')
    self:AddLine('---------- 价格信息 ----------')
    self:AddDoubleLine('当前价格', minPriceOtherStr)
    self:AddDoubleLine('到手价格', XUI.Cyan .. XUtils.priceToMoneyString(minPriceOther * XAPI.ProfitRate))
    self:AddLine(' ')
    self:AddDoubleLine('材料均价', materialCostPriceStr)
    self:AddDoubleLine('最低售价', XUtils.priceToMoneyString(materialCostPrice / XAPI.ProfitRate))
    self:AddDoubleLine('综合利润', profitStr)
    self:AddLine(' ')
    self:AddDoubleLine('材料现价', materialBuyoutPriceStr)
    self:AddDoubleLine('最低售价', XUtils.priceToMoneyString(materialBuyoutPrice / XAPI.ProfitRate))
    self:AddDoubleLine('当前利润', profitCurStr)

    local dealRate = XInfo.getItemInfoField(itemName, 'dealrate', 99)
    local dealRateStr = XUI.getColor_DealRate(dealRate) .. dealRate
    local dealCount = XInfo.getItemInfoField(itemName, 'dealcount', 0)
    local dealCountStr = XUI.getColor_DealCount(dealCount) .. dealCount

    self:AddLine(' ')
    self:AddLine('---------- 交易信息 ----------')
    self:AddDoubleLine('几次成交一次', dealRateStr)
    self:AddDoubleLine('成交数量', dealCountStr)
    self:AddLine(' ')
end)
