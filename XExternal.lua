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
    if mailType == XAPI.Postal_MailType_NonAHMail then return end

    if mailType == XAPI.Postal_MailType_AHOutbid then
        return
    elseif mailType == XAPI.Postal_MailType_AHWon then
        local invoiceType, itemName, playerName, bid, buyout, deposit, consignment,
        moneyDelay, etaHour, etaMin, count, commerceAuction = XAPI.GetInboxInvoiceInfo(mailIndex);
        if not invoiceType then return end

        if invoiceType == 'buyer' then XExternal.addBuyHistory(itemName, time(), bid / count, count) end
    elseif mailType == XAPI.Postal_MailType_AHCancelled then
        if msgSubject == nil then
            msgSubject = select(4, XAPI.GetInboxHeaderInfo(mailIndex))
        end
        local itemStr = string.match(msgSubject, gsub(XAPI.AUCTION_REMOVED_MAIL_SUBJECT, '%%s', '(.*)'))
        local itemName, count = getNameCount(itemStr)

        XExternal.addSellHistory(itemName, time(), false, 0, count)
    elseif mailType == XAPI.Postal_MailType_AHExpired then
        if msgSubject == nil then
            msgSubject = select(4, XAPI.GetInboxHeaderInfo(mailIndex))
        end
        local itemStr = string.match(msgSubject, gsub(XAPI.AUCTION_EXPIRED_MAIL_SUBJECT, '%%s', '(.*)'))
        local itemName, count = getNameCount(itemStr)

        XExternal.addSellHistory(itemName, time(), false, 0, count)
    elseif mailType == XAPI.Postal_MailType_AHSuccess then
        local invoiceType, itemName, playerName, bid, buyout, deposit, consignment,
        moneyDelay, etaHour, etaMin, count, commerceAuction = XAPI.GetInboxInvoiceInfo(mailIndex);
        if not invoiceType then return end

        if invoiceType == 'seller' then
            XExternal.addSellHistory(itemName, time(), true, bid / count, count)
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

XExternal.updateItemInfo = function(itemName, itemId, itemLink, category, class, vendorPrice, quality, level, icon)
    if not itemName then return end
    if not XItemUpdateList then return end
    if not XAuctionInfoList then return end

    if not itemId then itemId = -1 end
    if not itemLink then itemLink = '' end
    if not category then category = '' end
    if not class then class = '' end
    if not vendorPrice then vendorPrice = 0 end
    if not quality then quality = -1 end
    if not level then level = -1 end
    if not icon then icon = -1 end

    if XAuctionInfoList[itemName] then
        local auctionInfo = XAuctionInfoList[itemName]
        if auctionInfo.itemid and auctionInfo.itemid > 0 then
            if auctionInfo.itemlink and auctionInfo.itemlink ~= '' then
                if itemId and itemId > 0 then
                    if itemLink and itemLink ~= '' then
                        if auctionInfo.itemid == itemId
                            and auctionInfo.itemlink == itemLink
                            and auctionInfo.category == category
                            and auctionInfo.class == class
                            and auctionInfo.vendorprice == vendorPrice
                            and auctionInfo.quality == quality
                            and auctionInfo.level == level
                            and auctionInfo.icon == icon then
                            -- do nothing
                        else
                            auctionInfo.itemid = itemId
                            auctionInfo.itemlink = itemLink
                            auctionInfo.category = category
                            auctionInfo.class = class
                            auctionInfo.vendorprice = vendorPrice
                            auctionInfo.quality = quality
                            auctionInfo.level = level
                            auctionInfo.icon = icon

                            if XItemUpdateList[itemName] then
                                local updateItem = XItemUpdateList[itemName]
                                updateItem.itemid = itemId
                                updateItem.itemlink = itemLink
                                updateItem.category = category
                                updateItem.class = class
                                updateItem.vendorprice = vendorPrice
                                updateItem.quality = quality
                                updateItem.level = level
                                updateItem.icon = icon
                            else
                                XItemUpdateList[itemName] = {
                                    itemid = itemId,
                                    itemlink = itemLink,
                                    category = category,
                                    class = class,
                                    vendorprice = vendorPrice,
                                    quality = quality,
                                    level = level,
                                    icon = icon
                                }
                            end
                        end
                    else
                        if auctionInfo.itemid == itemId then
                            -- do nothing
                        else
                            auctionInfo.itemid = itemId
                            auctionInfo.itemlink = itemLink
                            auctionInfo.category = category
                            auctionInfo.class = class
                            auctionInfo.vendorprice = vendorPrice
                            auctionInfo.quality = quality
                            auctionInfo.level = level
                            auctionInfo.icon = icon

                            if XItemUpdateList[itemName] then
                                local updateItem = XItemUpdateList[itemName]
                                updateItem.itemid = itemId
                                updateItem.itemlink = itemLink
                                updateItem.category = category
                                updateItem.class = class
                                updateItem.vendorprice = vendorPrice
                                updateItem.quality = quality
                                updateItem.level = level
                                updateItem.icon = icon
                            else
                                XItemUpdateList[itemName] = {
                                    itemid = itemId,
                                    itemlink = itemLink,
                                    category = category,
                                    class = class,
                                    vendorprice = vendorPrice,
                                    quality = quality,
                                    level = level,
                                    icon = icon
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
                    auctionInfo.itemlink = itemLink
                    auctionInfo.category = category
                    auctionInfo.class = class
                    auctionInfo.vendorprice = vendorPrice
                    auctionInfo.quality = quality
                    auctionInfo.level = level
                    auctionInfo.icon = icon

                    if XItemUpdateList[itemName] then
                        local updateItem = XItemUpdateList[itemName]
                        updateItem.itemid = itemId
                        updateItem.itemlink = itemLink
                        updateItem.category = category
                        updateItem.class = class
                        updateItem.vendorprice = vendorPrice
                        updateItem.quality = quality
                        updateItem.level = level
                        updateItem.icon = icon
                    else
                        XItemUpdateList[itemName] = {
                            itemid = itemId,
                            itemlink = itemLink,
                            category = category,
                            class = class,
                            vendorprice = vendorPrice,
                            quality = quality,
                            level = level,
                            icon = icon
                        }
                    end
                else
                    if XItemUpdateList[itemName] then
                        local updateItem = XItemUpdateList[itemName]
                        updateItem.itemid = auctionInfo.itemid
                        updateItem.itemlink = itemLink
                        updateItem.category = category
                        updateItem.class = class
                        updateItem.vendorprice = vendorPrice
                        updateItem.quality = quality
                        updateItem.level = level
                        updateItem.icon = icon
                    else
                        XItemUpdateList[itemName] = {
                            itemid = auctionInfo.itemid,
                            itemlink = itemLink,
                            category = category,
                            class = class,
                            vendorprice = vendorPrice,
                            quality = quality,
                            level = level,
                            icon = icon
                        }
                    end
                end
            end
        else
            auctionInfo.itemid = itemId
            auctionInfo.itemlink = itemLink
            auctionInfo.category = category
            auctionInfo.class = class
            auctionInfo.vendorprice = vendorPrice
            auctionInfo.quality = quality
            auctionInfo.level = level
            auctionInfo.icon = icon

            if XItemUpdateList[itemName] then
                local updateItem = XItemUpdateList[itemName]
                updateItem.itemid = itemId
                updateItem.itemlink = itemLink
                updateItem.category = category
                updateItem.class = class
                updateItem.vendorprice = vendorPrice
                updateItem.quality = quality
                updateItem.level = level
                updateItem.icon = icon
            else
                XItemUpdateList[itemName] = {
                    itemid = itemId,
                    itemlink = itemLink,
                    category = category,
                    class = class,
                    vendorprice = vendorPrice,
                    quality = quality,
                    level = level,
                    icon = icon
                }
            end
        end
    else
        if itemId and itemId > 0 then
            if itemLink and itemLink ~= '' then
                if XItemUpdateList[itemName] then
                    local updateItem = XItemUpdateList[itemName]
                    updateItem.itemid = itemId
                    updateItem.itemlink = itemLink
                    updateItem.category = category
                    updateItem.class = class
                    updateItem.vendorprice = vendorPrice
                    updateItem.quality = quality
                    updateItem.level = level
                    updateItem.icon = icon
                else
                    XItemUpdateList[itemName] = {
                        itemid = itemId,
                        itemlink = itemLink,
                        category = category,
                        class = class,
                        vendorprice = vendorPrice,
                        quality = quality,
                        level = level,
                        icon = icon
                    }
                end
            else
                if XItemUpdateList[itemName] then
                    local updateItem = XItemUpdateList[itemName]
                    if updateItem.itemid == itemId then
                        -- do nothing
                    else
                        updateItem.itemid = itemId
                        updateItem.itemlink = itemLink
                        updateItem.category = category
                        updateItem.class = class
                        updateItem.vendorprice = vendorPrice
                        updateItem.quality = quality
                        updateItem.level = level
                        updateItem.icon = icon
                    end
                else
                    XItemUpdateList[itemName] = {
                        itemid = itemId,
                        itemlink = itemLink,
                        category = category,
                        class = class,
                        vendorprice = vendorPrice,
                        quality = quality,
                        level = level,
                        icon = icon
                    }
                end
            end
        else
            if XItemUpdateList[itemName] then
                -- do nothing
            else
                XItemUpdateList[itemName] = {
                    itemid = itemId,
                    itemlink = itemLink,
                    category = category,
                    class = class,
                    vendorprice = vendorPrice,
                    quality = quality,
                    level = level,
                    icon = icon
                }
            end
        end
    end
end
