XExternal = {}
local moduleName = 'XExternal'

local function getNameCount(str)
    local NamePattern = '(.*) %((.*)%)'
    local itemName, count = string.match(str, NamePattern)

    -- 如果没有匹配到数量，即数量默认为1
    if not itemName then
        itemName = string.trim(str)
        count = 1
    else
        count = tonumber(count) -- 确保数量被转换为数字
    end
    return itemName, count
end

-- AH Mail
XExternal.processMail = function(mailIndex, mailType, msgSubject)
    if mailType == 'NonAHMail' then return end

    if mailType == 'AHOutbid' then
        return
    elseif mailType == 'AHWon' then
        local invoiceType, itemName, playerName, bid, buyout, deposit, consignment,
        moneyDelay, etaHour, etaMin, count, commerceAuction = GetInboxInvoiceInfo(mailIndex);
        if not invoiceType then return end

        if invoiceType == 'buyer' then XExternal.addBuyHistory(itemName, time(), bid / count, count) end
    elseif mailType == 'AHCancelled' then
        if msgSubject == nil then
            msgSubject = select(4, GetInboxHeaderInfo(mailIndex))
        end
        local itemStr = string.match(msgSubject, gsub(AUCTION_REMOVED_MAIL_SUBJECT, '%%s', '(.*)'))
        local itemName, count = getNameCount(itemStr)

        XExternal.addSellHistory(itemName, time(), false, 0, count)
    elseif mailType == 'AHExpired' then
        if msgSubject == nil then
            msgSubject = select(4, GetInboxHeaderInfo(mailIndex))
        end
        local itemStr = string.match(msgSubject, gsub(AUCTION_EXPIRED_MAIL_SUBJECT, '%%s', '(.*)'))
        local itemName, count = getNameCount(itemStr)

        XExternal.addSellHistory(itemName, time(), false, 0, count)
    elseif mailType == 'AHSuccess' then
        local invoiceType, itemName, playerName, bid, buyout, deposit, consignment,
        moneyDelay, etaHour, etaMin, count, commerceAuction = GetInboxInvoiceInfo(mailIndex);
        if not invoiceType then return end

        if invoiceType == 'seller' then
            XExternal.addSellHistory(itemName, time(), true, bid / count, count)

            XAuctionHistory.addItem(itemName)
        end
    end
end

XExternal.addBuyHistory = function(itemName, time, price, count)
    if XBuyList then
        table.insert(XBuyList, { itemname = itemName, time = time, price = price, count = count })
        XExternal.addScanHistory(itemName, time, price)
    end
end

XExternal.addSellHistory = function(itemName, time, isSuccess, price, count)
    if XSellList then
        table.insert(XSellList, { itemname = itemName, time = time, issuccess = isSuccess, price = price, count = count })
        XExternal.addScanHistory(itemName, time, price)
    end
end

XExternal.addScanHistory = function(itemName, time, price)
    if XScanList then
        if XScanList[itemName] then
            local item = XScanList[itemName]
            local list = item['list']
            if item['timestamp'] + 300 < time then
                table.insert(list, { time = time, price = price })
                item['timestamp'] = time
            else
                if list[#list]['price'] > price then
                    list[#list]['price'] = price
                end
            end
        else
            local auctionInfo = XInfo.getAuctionInfo(itemName)
            local item = {}
            item.timestamp = time;
            item.list = { { time = time, price = price } }

            if auctionInfo then
                item.vendorprice = auctionInfo.vendorprice
                item.category = auctionInfo.category
                item.class = auctionInfo.class
            end

            local _, _, _, _, _, itemType, itemSubType, _, _, _, vendorPrice = GetItemInfo(itemName)
            item.vendorprice = vendorPrice
            item.category = itemType
            item.class = itemSubType

            XScanList[itemName] = item
        end
    end
end
