XAuctionItemToolTip = {}
XAuctionItemToolTip.Show = function(itemName, frame, anchor, sections)
    if IsShiftKeyDown() then
        local item = XAuctionCenter.getItem(itemName)
        if not item then return end
        if not sections then sections = { 1, 2, 3, 4 } end

        local stackCount = item['stackcount']

        local bagCount = XInfo.getBagItemCount(itemName)
        local bagCountStr = XUI.getColor_BagCount(bagCount) .. bagCount
        local bankCount = XInfo.getBankItemCount(itemName)
        local bankCountStr = XUI.getColor_BagCount(bankCount) .. bankCount
        local mailCount = XInfo.getMailItemCount(itemName)
        local mailCountStr = XUI.getColor_BagCount(mailCount) .. mailCount
        local auctionCount = XInfo.getAuctionItemCount(itemName)
        local auctionCountStr = XUI.getColor_AuctionStackCount(auctionCount, stackCount) .. auctionCount

        local minPriceOther = item['minpriceother']
        local basePrice = item['baseprice']
        local materialName = XInfo.getMaterialName(itemName)
        local materialCount = XInfo.getMaterialTotalCount(itemName)
        local materialBuyoutPrice = XAutoBuy.getItemField(materialName, 'minbuyoutprice', 9999999)
        local materialCostPrice = XInfo.getAuctionInfoField(materialName, 'costprice', 0)
        local lowerCount = item['lowercount']
        local vendorPrice = XInfo.getAuctionInfoField(itemName, 'vendorPrice', 0)

        local validCount = #item['myvalidlist']
        local allCount = bagCount + bankCount + mailCount


        local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
        local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)

        local updateTimeStr = XUtils.formatTime(item['updatetime'])

        GameTooltip:SetOwner(frame, anchor)
        GameTooltip:AddLine(itemName .. ' (' .. updateTimeStr .. ')')

        if XUtils.inArray(1, sections) then
            GameTooltip:AddLine('----------库存数量----------')
            GameTooltip:AddDoubleLine('背包', bagCountStr)
            GameTooltip:AddDoubleLine('银行', bankCountStr)
            GameTooltip:AddDoubleLine('邮件', mailCountStr)
            GameTooltip:AddDoubleLine('全部数量', allCount)
            GameTooltip:AddDoubleLine('材料数量', materialCount)
            GameTooltip:AddDoubleLine('出售数量', stackCount)
        end

        if XUtils.inArray(2, sections) then
            GameTooltip:AddLine('----------')
            GameTooltip:AddDoubleLine('有效数量', validCount)
            GameTooltip:AddDoubleLine('拍卖数量', auctionCount2)
            GameTooltip:AddDoubleLine('低于基准价格', lowerCount)
        end

        if XUtils.inArray(3, sections) then
            GameTooltip:AddLine('----------')
            GameTooltip:AddDoubleLine('几次成交一次', dealRate)
            GameTooltip:AddDoubleLine('成交数量', dealCount)
        end

        if XUtils.inArray(4, sections) then
            local costPrice = materialCostPrice;
            if costPrice < materialBuyoutPrice then
                costPrice = materialBuyoutPrice
            end
            local tprice = minPriceOther * XAPI.ProfitRate - costPrice - vendorPrice * XAPI.FeeRate
            local tpriceStr = XUtils.priceToMoneyString(minPriceOther * XAPI.ProfitRate)
            local subPrice = tprice - basePrice
            if subPrice <= 0 then
                tpriceStr = XUI.Red .. tpriceStr
            elseif subPrice <= basePrice * 0.05 then
                tpriceStr = XUI.Yellow .. tpriceStr
            elseif subPrice <= basePrice * 0.1 then
                tpriceStr = XUI.Green .. tpriceStr
            else
                tpriceStr = XUI.Cyan .. tpriceStr
            end

            GameTooltip:AddLine('----------')
            GameTooltip:AddDoubleLine('当前价格', XUtils.priceToMoneyString(minPriceOther))
            GameTooltip:AddDoubleLine('到手价', tpriceStr)
            GameTooltip:AddDoubleLine('基准价格', XUtils.priceToMoneyString(basePrice))
            GameTooltip:AddDoubleLine('材料均价', XUtils.priceToMoneyString(materialCostPrice))
            GameTooltip:AddDoubleLine('材料现价', XUtils.priceToMoneyString(materialBuyoutPrice))
        end

        GameTooltip:Show()
    end
end
