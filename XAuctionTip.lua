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

    self:AddLine('---------- 物品信息 ----------')
    local bagCount = XInfo.getBagItemCount(itemName)
    local bankCount = XInfo.getBankItemCount(itemName)
    if bagCount > 0 then
        self:AddDoubleLine('背包:', XUI.Green .. bagCount)
    else
        self:AddDoubleLine('背包:', XUI.Red .. 0)
    end
    if bankCount > 0 then
        self:AddDoubleLine('银行:', XUI.Green .. bankCount)
    else
        self:AddDoubleLine('银行:', XUI.Red .. 0)
    end

    local category = XInfo.getAuctionInfoField(itemName, 'category', '')
    if category == '珠宝' then
        local tradeSkillItem = XInfo.getTradeSkillItem(itemName)
        if tradeSkillItem then
            self:AddDoubleLine('配方:', XUI.Green .. '已学')
        else
            self:AddDoubleLine('配方:', XUI.Red .. '未学')
        end
    end
    local recipePrefix = '图鉴：'
    if XUtils.stringContains(itemName, recipePrefix) then
        local tItemName = string.sub(itemName, #recipePrefix + 1)
        local tradeSkillItem = XInfo.getTradeSkillItem(tItemName)
        if tradeSkillItem then
            self:AddDoubleLine('配方:', XUI.Green .. '已学')
        else
            self:AddDoubleLine('配方:', XUI.Red .. '未学')
        end
    end

    self:AddLine(XUI.Green .. '---------- 交易信息 ----------')
    local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
    local dealRateColor = XUI.getColor_DealRate(dealRate)

    local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)
    local dealCountColor = XUI.getColor_DealCount(dealCount)

    self:AddDoubleLine(dealRateColor .. '成交几率:', dealRateColor .. dealRate .. '次')
    self:AddDoubleLine(dealCountColor .. '成交次数:', dealCountColor .. dealCount .. '次')
    self:AddDoubleLine('制造价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'makeprice', 0)))
    self:AddDoubleLine('成本价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'costprice', 0)))
    self:AddDoubleLine('平均价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'scanprice', 0)))
    self:AddDoubleLine('最低价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'minscanprice', 0)))
    self:AddDoubleLine('最高价:',
        XUI.White .. XUtils.priceToMoneyString(XInfo.getAuctionInfoField(itemName, 'maxscanprice', 0)))

    self:AddLine(XUI.Green .. '---------- 实时信息 ----------')
    local autoAuctionItem = XAuctionCenter.getItem(itemName)
    local validCount = XAuctionCenter.getMyValidCount(itemName)
    if autoAuctionItem then
        self:AddDoubleLine('他最低价:', XUI.White .. XUtils.priceToMoneyString(autoAuctionItem['minpriceother']))
    end
    self:AddDoubleLine('我有效数:', XUI.White .. validCount)
    if autoAuctionItem then
        local materialName = XInfo.getMaterialName(itemName)
        if materialName then
            local materialBagCount = XInfo.getMaterialBagCount(itemName)
            local materialBankCount = XInfo.getMaterialBankCount(itemName)
            self:AddDoubleLine('原料数量:', XUI.White ..
                materialBagCount .. ' / ' .. materialBankCount)
            local buyItem = XAutoBuy.getItem(materialName)
            if buyItem then
                self:AddDoubleLine('原料Bid:', XUI.White .. XUtils.priceToMoneyString(buyItem['minprice']))
                self:AddDoubleLine('原料Buyout:', XUI.White .. XUtils.priceToMoneyString(buyItem['minbuyoutprice']))
                self:AddDoubleLine('扫描价格:', XUI.White .. XUtils.priceToMoneyString(buyItem['price']))
            end
            local wordItem = XJewWords.getItem(materialName)
            if wordItem then
                self:AddDoubleLine('喊话价格:', XUI.White .. XUtils.priceToMoneyString(tonumber(wordItem['price1']) * 10000))
            end
        end
    end

    self:AddLine('--------------------------------')
end)
