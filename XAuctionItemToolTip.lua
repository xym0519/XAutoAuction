XAuctionItemToolTip = {}
XAuctionItemToolTip.Show = function(itemName, frame, anchor, sections)
    if IsShiftKeyDown() then
        local item = XAuctionCenter.getItem(itemName)
        if not item then return end
        if not sections then sections = { 1, 2, 3, 4 } end

        local minPriceOther = item['minpriceother']
        local basePrice = item['baseprice']
        local materialCount = XInfo.getMaterialTotalCount(itemName)
        local materialPrice = XInfo.getMaterialPrice(itemName)
        local materialCostPrice = XInfo.getAuctionInfoField(itemName, 'costprice', 0)
        local stackCount = item['stackcount']
        local lowerCount = item['lowercount']
        local vendorPrice = XInfo.getAuctionInfoField(itemName, 'vendorPrice', 0)

        local bagCount = XInfo.getBagItemCount(itemName)
        local bankCount = XInfo.getBankItemCount(itemName)
        local mailCount = XInfo.getMailItemCount(itemName)

        local auctionCount = #item['mylist']
        local validCount = #item['myvalidlist']
        local allCount = bagCount + bankCount + mailCount + auctionCount

        local auctionCount2 = XInfo.getAuctionItemCount(itemName)

        local dealRate = XInfo.getAuctionInfoField(itemName, 'dealrate', 99)
        local dealCount = XInfo.getAuctionInfoField(itemName, 'dealcount', 0)

        local updateTimeStr = XUtils.formatTime(item['updatetime'])

        GameTooltip:SetOwner(frame, anchor)
        GameTooltip:AddLine(itemName .. ' (' .. updateTimeStr .. ')')

        if XUtils.inArray(1, sections) then
            GameTooltip:AddLine('----------')
            GameTooltip:AddDoubleLine('背包数量', bagCount)
            GameTooltip:AddDoubleLine('银行数量', bankCount)
            GameTooltip:AddDoubleLine('邮件数量', mailCount)
            GameTooltip:AddDoubleLine('全部数量', allCount)
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
            local costPrice = materialCostPrice;
            if costPrice < materialPrice then
                costPrice = materialPrice
            end
            local tprice = minPriceOther * 0.95 - costPrice - vendorPrice * 0.3
            local tpriceStr = XUtils.priceToMoneyString(minPriceOther * 0.95)
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
            GameTooltip:AddDoubleLine('材料现价', XUtils.priceToMoneyString(materialPrice))
        end

        GameTooltip:Show()
    end
end
