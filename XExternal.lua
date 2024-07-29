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
        moneyDelay, etaHour, etaMin, count, commerceAuction = XAPI.GetInboxInvoiceInfo(mailIndex);
        if not invoiceType then return end

        if invoiceType == 'buyer' then XExternal.addBuyHistory(itemName, time(), bid / count, count) end
    elseif mailType == 'AHCancelled' then
        if msgSubject == nil then
            msgSubject = select(4, XAPI.GetInboxHeaderInfo(mailIndex))
        end
        local itemStr = string.match(msgSubject, gsub(XAPI.AUCTION_REMOVED_MAIL_SUBJECT, '%%s', '(.*)'))
        local itemName, count = getNameCount(itemStr)

        XExternal.addSellHistory(itemName, time(), false, 0, count)
    elseif mailType == 'AHExpired' then
        if msgSubject == nil then
            msgSubject = select(4, XAPI.GetInboxHeaderInfo(mailIndex))
        end
        local itemStr = string.match(msgSubject, gsub(XAPI.AUCTION_EXPIRED_MAIL_SUBJECT, '%%s', '(.*)'))
        local itemName, count = getNameCount(itemStr)

        XExternal.addSellHistory(itemName, time(), false, 0, count)
    elseif mailType == 'AHSuccess' then
        local invoiceType, itemName, playerName, bid, buyout, deposit, consignment,
        moneyDelay, etaHour, etaMin, count, commerceAuction = XAPI.GetInboxInvoiceInfo(mailIndex);
        if not invoiceType then return end

        if invoiceType == 'seller' then
            XExternal.addSellHistory(itemName, time(), true, bid / count, count)

            XAuctionHistory.addItem(itemName)
        end
    end
end

XExternal.addBuyHistory = function(itemName, time, price, count)
    if not XBuyList then return end

    table.insert(XBuyList, { itemname = itemName, time = time, price = price, count = count })
    XExternal.addScanHistory(itemName, time, price)
end

XExternal.addSellHistory = function(itemName, time, isSuccess, price, count)
    if not XSellList then return end

    table.insert(XSellList, { itemname = itemName, time = time, issuccess = isSuccess, price = price, count = count })
    XExternal.addScanHistory(itemName, time, price)
end

XExternal.addScanHistory = function(itemName, time, price)
    if XScanList then
        if XScanList[itemName] then
            local item = XScanList[itemName]
            local list = item['list']

            if not list then list = {} end

            if price and price > 0 then
                if item['timestamp'] + 300 < time then
                    table.insert(list, { time = time, price = price })
                    item['timestamp'] = time
                else
                    if #list <= 0 then
                        table.insert(list, { time = time, price = price })
                    else
                        if list[#list]['price'] > price then
                            list[#list]['price'] = price
                        end
                    end
                end
            end
        else
            local item = {}
            item.timestamp = time
            if price and price > 0 then
                item.list = { { time = time, price = price } }
            else
                item.list = {}
            end

            XScanList[itemName] = item
        end
    end
end

XExternal.updateItemInfo = function(itemName, itemId, category, class, vendorPrice)
    if not itemName then return end
    if not XItemUpdateList then return end
    if not XAuctionInfoList then return end

    if not itemId then itemId = -1 end
    if not category then category = '' end
    if not class then class = '' end
    if not vendorPrice then vendorPrice = 0 end

    if XAuctionInfoList[itemName] then
        local auctionInfo = XAuctionInfoList[itemName]
        if auctionInfo.itemid and auctionInfo.itemid > 0 then
            if auctionInfo.category and auctionInfo.category ~= '' then
                if itemId and itemId > 0 then
                    if category and category ~= '' then
                        if auctionInfo.itemid == itemId
                            and auctionInfo.category == category
                            and auctionInfo.class == class
                            and auctionInfo.vendorprice == vendorPrice then
                            -- do nothing
                        else
                            auctionInfo.itemid = itemId
                            auctionInfo.category = category
                            auctionInfo.class = class
                            auctionInfo.vendorprice = vendorPrice

                            if XItemUpdateList[itemName] then
                                local updateItem = XItemUpdateList[itemName]
                                updateItem.itemid = itemId
                                updateItem.category = category
                                updateItem.class = class
                                updateItem.vendorprice = vendorPrice
                            else
                                XItemUpdateList[itemName] = {
                                    itemid = itemId,
                                    category = category,
                                    class = class,
                                    vendorprice = vendorPrice
                                }
                            end
                        end
                    else
                        if auctionInfo.itemid == itemId then
                            -- do nothing
                        else
                            auctionInfo.itemid = itemId
                            auctionInfo.category = category
                            auctionInfo.class = class
                            auctionInfo.vendorprice = vendorPrice

                            if XItemUpdateList[itemName] then
                                local updateItem = XItemUpdateList[itemName]
                                updateItem.itemid = itemId
                                updateItem.category = category
                                updateItem.class = class
                                updateItem.vendorprice = vendorPrice
                            else
                                XItemUpdateList[itemName] = {
                                    itemid = itemId,
                                    category = category,
                                    class = class,
                                    vendorprice = vendorPrice
                                }
                            end
                        end
                    end
                else
                    -- do nothing
                end
            else
                if itemId and itemId > 0 then
                    auctionInfo.itemid = itemId
                    auctionInfo.category = category
                    auctionInfo.class = class
                    auctionInfo.vendorprice = vendorPrice

                    if XItemUpdateList[itemName] then
                        local updateItem = XItemUpdateList[itemName]
                        updateItem.itemid = itemId
                        updateItem.category = category
                        updateItem.class = class
                        updateItem.vendorprice = vendorPrice
                    else
                        XItemUpdateList[itemName] = {
                            itemid = itemId,
                            category = category,
                            class = class,
                            vendorprice = vendorPrice
                        }
                    end
                else
                    if XItemUpdateList[itemName] then
                        local updateItem = XItemUpdateList[itemName]
                        updateItem.itemid = auctionInfo.itemid
                        updateItem.category = category
                        updateItem.class = class
                        updateItem.vendorprice = vendorPrice
                    else
                        XItemUpdateList[itemName] = {
                            itemid = auctionInfo.itemid,
                            category = category,
                            class = class,
                            vendorprice = vendorPrice
                        }
                    end
                end
            end
        else
            auctionInfo.itemid = itemId
            auctionInfo.category = category
            auctionInfo.class = class
            auctionInfo.vendorprice = vendorPrice

            if XItemUpdateList[itemName] then
                local updateItem = XItemUpdateList[itemName]
                updateItem.itemid = itemId
                updateItem.category = category
                updateItem.class = class
                updateItem.vendorprice = vendorPrice
            else
                XItemUpdateList[itemName] = {
                    itemid = itemId,
                    category = category,
                    class = class,
                    vendorprice = vendorPrice
                }
            end
        end
    else
        if itemId and itemId > 0 then
            if category and category ~= '' then
                if XItemUpdateList[itemName] then
                    local updateItem = XItemUpdateList[itemName]
                    updateItem.itemid = itemId
                    updateItem.category = category
                    updateItem.class = class
                    updateItem.vendorprice = vendorPrice
                else
                    XItemUpdateList[itemName] = {
                        itemid = itemId,
                        category = category,
                        class = class,
                        vendorprice = vendorPrice
                    }
                end
            else
                if XItemUpdateList[itemName] then
                    local updateItem = XItemUpdateList[itemName]
                    if updateItem.itemid == itemId then
                        -- do nothing
                    else
                        updateItem.itemid = itemId
                        updateItem.category = category
                        updateItem.class = class
                        updateItem.vendorprice = vendorPrice
                    end
                else
                    XItemUpdateList[itemName] = {
                        itemid = itemId,
                        category = category,
                        class = class,
                        vendorprice = vendorPrice
                    }
                end
            end
        else
            if XItemUpdateList[itemName] then
                -- do nothing
            else
                XItemUpdateList[itemName] = {
                    itemid = itemId,
                    category = category,
                    class = class,
                    vendorprice = vendorPrice
                }
            end
        end
    end
end
