XAPI = {}

-- 常量
-- 背包槽位数量
XAPI.NUM_BAG_SLOTS = NUM_BAG_SLOTS
-- 银行槽位数量
XAPI.NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS

-- 拍卖取消提示
XAPI.AUCTION_REMOVED_MAIL_SUBJECT = AUCTION_REMOVED_MAIL_SUBJECT
-- 拍卖超期提示
XAPI.AUCTION_EXPIRED_MAIL_SUBJECT = AUCTION_EXPIRED_MAIL_SUBJECT

-- 界面 & 操作
-- 清除鼠标选中物体
-- https://wowpedia.fandom.com/wiki/API_ClearCursor
XAPI.ClearCursor = function()
    ClearCursor()
end

-- 创建界面元素
-- https://wowpedia.fandom.com/wiki/API_CreateFrame
-- Arguments: (frameType [, name, parent, template, id])
--   frameType: string - Type of the frame; e.g. "Frame" or "Button".
--   name: string? - Globally accessible name to assign to the frame, or nil for an anonymous frame.
--   parent: Frame? - Parent object to assign to the frame, or nil to be parentless; cannot be a string. Can also be set with Region:SetParent()
--   template: string? - Comma-delimited list of virtual XML templates to inherit; see also a complete list of FrameXML templates.
--   id: number? - ID to assign to the frame. Can also be set with Frame:SetID()
-- Returns:
--   frame: Frame - The created Frame object or one of the other frame type objects.
XAPI.CreateFrame = function(...)
    return CreateFrame(...)
end

-- 下拉框相关方法
-- https://wowpedia.fandom.com/wiki/Using_UIDropDownMenu
-- 初始化
-- Arguments: (uiDropDown, callback)
XAPI.UIDropDownMenu_Initialize = function(...)
    return UIDropDownMenu_Initialize(...)
end
-- 创建选项
XAPI.UIDropDownMenu_CreateInfo = function()
    return UIDropDownMenu_CreateInfo()
end
-- 添加选项
-- Arguments: (uiDropDown, config)
XAPI.UIDropDownMenu_AddButton = function(...)
    return UIDropDownMenu_AddButton(...)
end
-- 设置宽度
-- Arguments: (uiDropDown, width)
XAPI.UIDropDownMenu_SetWidth = function(...)
    return UIDropDownMenu_SetWidth(...)
end
-- 设置文本对齐方式
-- Arguments: (uiDropDown, align)
XAPI.UIDropDownMenu_JustifyText = function(...)
    return UIDropDownMenu_JustifyText(...)
end
-- 设置文本
-- Arguments: (uiDropDown, text)
XAPI.UIDropDownMenu_SetText = function(...)
    return UIDropDownMenu_SetText(...)
end
-- 获取文本
-- Arguments: (uiDropDown)
XAPI.UIDropDownMenu_GetText = function(...)
    return UIDropDownMenu_GetText(...)
end

-- 拍卖行窗口是否打开
XAPI.IsAuctionFrameOpen = function()
    return not (not AuctionFrame or not AuctionFrame:IsVisible())
end

-- 发送聊天消息
-- Arguments: (msg [, chatType, languageID, target])
--   msg: string - The message to be sent. Large messages are truncated to max 255 characters, and only valid chat message characters are permitted.
--   chatType: string? - The type of message to be sent, e.g. "PARTY". If omitted, this defaults to "SAY"
--     "SAY": /s, /say: Chat message to nearby players
--     "EMOTE": /e, /emote: Custom text emote to nearby players (See DoEmote for normal emotes)
--     "YELL": /y, /yell: Chat message to far away players
--     "PARTY": /p, /party: Chat message to party members
--     "RAID": /ra, /raid: Chat message to raid members
--     "RAID_WARNING": /rw	: Audible warning message to raid members
--     "INSTANCE_CHAT": /i, /instance: Chat message to the instance group (Dungeon finder / Battlegrounds / Arena)
--     "GUILD": /g, /guild: Chat message to guild members
--     "OFFICER": /o, /officer: Chat message to guild officers
--     "WHISPER": /w, /whisper /t, /tell: Whisper to a specific other player, use player name as target argument
--     "CHANNEL": /1, /2: Chat message to a specific global/custom chat channel, use channel number as target argument
--     "AFK": /afk: Not a real channel; Sets your AFK message. Send an empty message to clear AFK status.
--     "DND": /dnd: Not a real channel; Sets your DND message. Send an empty message to clear DND status.
--     "VOICE_TEXT": Sends text-to-speech to the in-game voice chat.
--   languageID: number? - The languageID used for the message. Only works with chatTypes "SAY" and "YELL", and only if not in a group. If omitted the default language will be used: Orcish for the Horde and Common for the Alliance, as returned by GetDefaultLanguage()
--   target: string|number? - The player name or channel number receiving the message for "WHISPER" or "CHANNEL" chatTypes.
XAPI.SendChatMessage = function(...)
    return SendChatMessage(...)
end

-- 物品
-- 获取物品信息(联网)
-- https://wowpedia.fandom.com/wiki/API_GetItemInfo
-- Arguments: (item)
--   item: number|string : Item ID, Link or Name
--     Accepts any valid item ID but returns nil if the item is not cached yet.
--     Accepts an item link, or in item:%d format.
--     Accepts a localized item name but this requires the item to be or have been in the player's inventory (bags/bank) for that session.
-- Returns:
--   1. itemName: string - The localized name of the item.
--   2. itemLink: string : ItemLink - The localized link of the item.
--   3. itemQuality: Enum.ItemQuality🔗 - The quality of the item, e.g. 2 for Uncommon and 3 for Rare quality items.
--   4. itemLevel: number - The base item level, not including upgrades. See GetDetailedItemLevelInfo() for getting the actual item level.
--   5. itemMinLevel: number - The minimum level required to use the item, or 0 if there is no level requirement.
--   6. itemType: string : ItemType - The localized type name of the item: Armor, Weapon, Quest, etc.
--   7. itemSubType: string : ItemType - The localized sub-type name of the item: Bows, Guns, Staves, etc.
--   8. itemStackCount: number - The max amount of an item per stack, e.g. 200 for Runecloth.
--   9. itemEquipLoc: string : ItemEquipLoc - The inventory equipment location in which the item may be equipped e.g. "INVTYPE_HEAD", or an empty string if it cannot be equipped.
--   10. itemTexture: number : FileID - The texture for the item icon.
--   11. sellPrice: number - The vendor price in copper, or 0 for items that cannot be sold.
--   12. classID: number : ItemType - The numeric ID of itemType
--   13. subclassID: number : ItemType - The numeric ID of itemSubType
--   14. bindType: number : LE_ITEM_BIND - When the item becomes soulbound, e.g. 1 for Bind on Pickup items.
--   15. expacID: number : LE_EXPANSION - The related Expansion, e.g. 8 for Shadowlands. On Classic this appears to be always 254.
--   16. setID: number? : ItemSetID - For example 761 for Inv helmet 67 [Red Winter Hat] (itemID 21524).
--   17. isCraftingReagent: boolean - Whether the item can be used as a crafting reagent.
XAPI.GetItemInfo = function(...)
    return GetItemInfo(...)
end

-- 获取物品信息(本地)
-- https://wowpedia.fandom.com/wiki/API_GetItemInfoInstant
-- Arguments: (item)
--   item: number|string : Item ID, Link or Name
--     Accepts any valid item ID but returns nil if the item is not cached yet.
--     Accepts an item link, or in item:%d format.
--     Accepts a localized item name but this requires the item to be or have been in the player's inventory (bags/bank) for that session.
-- Returns:
--   1. itemID: number - ID of the item.
--   2. itemType: string : ItemType - The localized type name of the item: Armor, Weapon, Quest, etc.
--   3. itemSubType: string : ItemType - The localized sub-type name of the item: Bows, Guns, Staves, etc.
--   4. itemEquipLoc: string : ItemEquipLoc - The inventory equipment location in which the item may be equipped e.g. "INVTYPE_HEAD", or an empty string if it cannot be equipped.
--   5. icon: number : FileID - The texture for the item icon.
--   6. classID: number : ItemType - The numeric ID of itemType
--   7. subclassID: number : ItemType - The numeric ID of itemSubType
XAPI.GetItemInfoInstant = function(...)
    return GetItemInfoInstant(...)
end

-- 创建ItemLocationMixin
-- https://wowpedia.fandom.com/wiki/ItemLocationMixin
-- Arguments: (bagID, slotIndex)
-- Returns:
--   ItemLocationMixin
XAPI.ItemLocation_CreateFromBagAndSlot = function(...)
    return ItemLocation:CreateFromBagAndSlot(...)
end

-- 判定物品是否存在
-- https://wowpedia.fandom.com/wiki/API_C_Item.DoesItemExist
-- Arguments: (emptiableItemLocation)
--   emptiableItemLocation: ItemLocationMixin
-- Returns:
--   itemExists: boolean
XAPI.C_Item_DoesItemExist = function(...)
    return C_Item.DoesItemExist(...)
end

-- 判定物品是否存在
-- https://wowpedia.fandom.com/wiki/API_C_Item.DoesItemExist
-- Arguments: (itemInfo)
--   itemInfo: number|string : Item ID, Link or Name
-- Returns:
--   itemExists: boolean
XAPI.C_Item_DoesItemExistByID = function(...)
    return C_Item.DoesItemExistByID(...)
end

-- 锁定物品
-- https://wowpedia.fandom.com/wiki/API_C_Item.LockItem
-- Arguments: (itemLocation)
--   itemLocation: ItemLocationMixin
XAPI.C_Item_LockItem = function(...)
    return C_Item.LockItem(...)
end

-- 锁定物品
-- https://wowpedia.fandom.com/wiki/API_C_Item.LockItem
-- Arguments: (itemGUID)
--   itemGUID: string
XAPI.C_Item_LockItemByGUID = function(...)
    return C_Item.LockItemByGUID(...)
end

-- 解锁物品
-- https://wowpedia.fandom.com/wiki/API_C_Item.UnlockItem
-- Arguments: (itemLocation)
--   itemLocation: ItemLocationMixin
XAPI.C_Item_UnlockItem = function(...)
    return C_Item.UnlockItem(...)
end

-- 解锁物品
-- https://wowpedia.fandom.com/wiki/API_C_Item.UnlockItem
-- Arguments: (itemGUID)
--   itemGUID: string
XAPI.C_Item_UnlockItemByGUID = function(...)
    return C_Item.UnlockItemByGUID(...)
end

-- 容器
-- 选中物品
-- https://wowpedia.fandom.com/wiki/API_C_Container.PickupContainerItem
-- Arguments: (bagId, slotIndex)
--   bagId: number
--   slotIndex: number
XAPI.C_Container_PickupContainerItem = function(...)
    C_Container.PickupContainerItem(...)
end

-- 获取容器内槽位数量
-- https://wowpedia.fandom.com/wiki/API_C_Container.GetContainerNumSlots
-- Arguments: (containerIndex)
--   containerIndex: number
-- Returns:
--   numSlots: number
XAPI.C_Container_GetContainerNumSlots = function(...)
    return C_Container.GetContainerNumSlots(...)
end

-- 获取容器中物品信息
-- https://wowpedia.fandom.com/wiki/API_C_Container.GetContainerItemInfo
-- Arguments: (containerIndex, slotIndex)
--   containerIndex: number
--   slotIndex: number
-- Returns:
--   containerInfo: ContainerItemInfo? - Returns nil if the container slot is empty.
--     itemName="炫光森林翡翠",
--     hasLoot=false,
--     hyperlink="|[炫光森林翡翠]|",
--     iconFileID=237213,
--     hasNoValue=false,
--     isLocked=false,
--     itemID=40094,
--     isBound=false,
--     stackCount=1,
--     isFiltered=false,
--     isReadable=false,
--     quality=3
XAPI.C_Container_GetContainerItemInfo = function(...)
    return C_Container.GetContainerItemInfo(...)
end

-- 拍卖
-- https://wowpedia.fandom.com/wiki/API_GetNumAuctionItems
-- Arguments: (string type)
--   type: One of the following:
--     "list" - Items up for auction, the "Browse" tab in the dialog.
--     "bidder" - Items the player has bid on, the "Bids" tab in the dialog.
--     "owner" - Items the player has up for auction, the "Auctions" tab in the dialog.
-- Returns:
--   1. batch: The size of the batch being viewed, 50 for a page view.
--   2. count: The total number of items in the query.
XAPI.GetNumAuctionItems = function(...)
    return GetNumAuctionItems(...)
end

-- Arguments: (string type, int index)
-- Returns:
--   1. itemName
--   2. icon
--   3. stackCount
--   6. level
--   8. bidStart
--   9. bidIncrease
--   10. buyoutPrice
--   11. bidPrice
--   12. isMine
--   14. owner
--   16. saleStatus: 1-sold 0-unsold
--   17. itemId
XAPI.GetAuctionItemInfo = function(...)
    return GetAuctionItemInfo(...)
end

-- https://wowpedia.fandom.com/wiki/API_GetAuctionItemTimeLeft
-- Argumenets: (String type, Number index)
--   type: string - One of the following:
--     "list" - An item up for auction, the "Browse" tab in the dialog.
--     "bidder" - An item the player has bid on, the "Bids" tab in the dialog.
--     "owner" - An item the player has up for auction, the "Auctions" tab in the dialog.
--   index: number - The index of the item in the list to retrieve info from (normally 1-50, inclusive)
-- Returns:
-- 1. timeleft number - number between 1 and 4
--   1 - short (less than 30 minutes)
--   2 - medium (30 minutes - 2 hours)
--   3 - long (2 - 12 hours)
--   4 - very long (more than 12 hours)
XAPI.GetAuctionItemTimeLeft = function(...)
    return GetAuctionItemTimeLeft(...)
end


-- 将选中物品放入拍卖槽中
-- https://wowpedia.fandom.com/wiki/API_ClickAuctionSellItemButton
XAPI.ClickAuctionSellItemButton = function()
    ClickAuctionSellItemButton()
end

-- 获取拍卖槽中的物品信息
-- https://wowpedia.fandom.com/wiki/API_GetAuctionSellItemInfo
-- Returns:
--   1. itemName
--   2. texture
--   3. count
--   4. quality
--   5. canUse
--   6. price
--   7. pricePerUnit
--   8. stackCount
--   9. totalCount
--   10. itemID
XAPI.GetAuctionSellItemInfo = function()
    return GetAuctionSellItemInfo()
end

-- 开始拍卖
-- https://wowpedia.fandom.com/wiki/API_PostAuction
-- Arguments: (minBid, buyoutPrice, runTime, stackSize, numStacks)
--   minBid: number - The minimum bid price for this auction in copper.
--   buyoutPrice: number - The buyout price for this auction in copper.
--   runTime: number - The duration for which the auction should be posted. See details for more information.
--     1 - 12 hours
--     2 - 24 hours
--     3 - 48 hours
--   stackSize: number - The size of each stack to be posted.
--   numStacks: number - The number of stacks to post.
XAPI.PostAuction = function(...)
    PostAuction(...)
end

-- 取消拍卖
-- Arguments: (index)
--   index: index on the "owner" list
XAPI.CancelAuction = function(...)
    CancelAuction(...)
end

-- 检查是否可以发送查询请求
-- https://wowpedia.fandom.com/wiki/API_CanSendAuctionQuery
-- Returns:
--   canQuery: boolean - True if a normal auction house query can be made
--   canQueryAll: boolean - True if a full ("getall") auction house query can be made (added in 2.3)
XAPI.CanSendAuctionQuery = function()
    return CanSendAuctionQuery()
end

-- 发送查询请求(异步)
-- https://wowpedia.fandom.com/wiki/API_QueryAuctionItems
-- Arguments: (text, minLevel, maxLevel, page, usable, rarity, getAll, exactMatch, filterData)
--   text: string - A part of the item's name, or an empty string; limited to 63 bytes.
--   minLevel: number? - Minimum usable level requirement for items
--   maxLevel: number? - Maximum usable level requirement for items
--   page: number - What page in the auctionhouse this shows up. Note that pages start at 0.
--   usable: boolean - Restricts items to those usable by the current character.
--   rarity: Enum.ItemQuality? - Restricts the quality of the items found.
--   getAll: boolean - Download the entire auction house as one single page; see other details below.
--   exactMatch: boolean - Will only items whose whole name is the same as searchString be found.
--   filterData: table?
--     classID: number: ItemType
--     subClassID: number?: Depends on the ItemType
--     inventoryType: Enum.InventoryType?
XAPI.QueryAuctionItems = function(...)
    return QueryAuctionItems(...)
end

-- 竞拍
-- https://wowpedia.fandom.com/wiki/API_PlaceAuctionBid
-- Arguments: (type, index, bid)
--   type: One of the following:
--     "list" - Items up for auction, the "Browse" tab in the dialog.
--     "bidder" - Items the player has bid on, the "Bids" tab in the dialog.
--     "owner" - Items the player has up for auction, the "Auctions" tab in the dialog.
--   index: The index of the item in the list to bid on (normally 1-50, inclusive)
--   bid: The amount of money to bid in copper.
XAPI.PlaceAuctionBid = function(...)
    return PlaceAuctionBid(...)
end

-- 商业技能
-- 获取当前打开的商业技能类型
-- https://wowpedia.fandom.com/wiki/API_GetTradeSkillLine
-- Returns:
--   tradeskillName: string - Name of the current tradeskill
--   currentLevel: number - Current skill level in the current tradeskill
--   maxLevel: number - Current maximum skill level for the current tradeskill (based on Journeyman, Expert etc.)
--   skillLineModifier: number - Skill modifier from racial abilities etc.
XAPI.GetTradeSkillLine = function()
    return GetTradeSkillLine()
end

-- 获取商业技能已学会的配方数量
-- https://wowpedia.fandom.com/wiki/API_GetNumTradeSkills
-- Returns:
--   numSkills: number - The number of trade skills which are available (including headers)
XAPI.GetNumTradeSkills = function()
    return GetNumTradeSkills()
end

-- 获取商业技能产物物品信息
-- https://wowpedia.fandom.com/wiki/API_GetTradeSkillItemLink
-- Arguments: (skillId)
--   skillId: number - The Id specifying which trade skill's link to get. Trade Skill window must be open for this to work. Indexes start at 1 which is the general category of the tradeskill, if you have selected a sub-group of trade skills then 1 will be the name of that sub-group.
-- Returns:
--   link: string - An item link string (color coded with href) which can be included in chat messages to represent the item which the trade skill creates.
XAPI.GetTradeSkillItemLink = function(...)
    return GetTradeSkillItemLink(...)
end

-- 获取商业技能信息
-- https://wowpedia.fandom.com/wiki/API_GetTradeSkillInfo
-- Arguments: (skillIndex)
--   skillIndex: number - The id of the skill you want to query.
-- Returns:
--   1. skillName: string - The name of the skill, e.g. "Copper Breastplate" or "Daggers", if the skillIndex references to a heading.
--   2. skillType: string - "header", if the skillIndex references to a heading; "subheader", if the skillINdex references a subheader for things like the cooking specialties; or a string indicating the difficulty to craft the item ("trivial", "easy", "medium", "optimal", "difficult").
--   3. numAvailable: number - The number of items the player can craft with his available trade goods.
XAPI.GetTradeSkillInfo = function(...)
    return GetTradeSkillInfo(...)
end

-- 使用商业技能制造物品
-- https://wowpedia.fandom.com/wiki/API_DoTradeSkill
-- Arguments: (index, repeat)
--   index: number - The index of the tradeskill recipe.
--   repeat: number - The number of times to repeat the creation of the specified recipe.
XAPI.DoTradeSkill = function(...)
    DoTradeSkill(...)
end

-- 邮件
-- 获取邮件账单信息
-- https://wowpedia.fandom.com/wiki/API_GetInboxInvoiceInfo
-- Arguments: (index)
--   index: number - The index of the message, starting from 1.
-- Returns:
--   1. invoiceType: string? - One of "buyer", "seller" or "seller_temp_invoice"; or nil if there is no invoice.
--   2. itemName: string? - The name of the item sold/bought, or nil if there is no invoice.
--   3. playerName: string? - The player that sold/bought the item, or nil if there were multiple buyers/sellers involved. Will also return nil if there is no invoice.
--   4. bid: number - The amount of money bid on the item.
--   5. buyout: number - The amount of money set as buyout for the auction.
--   6. deposit: number - The amount paid as deposit for the auction.
--   7. consignment: number - The fee charged by the auction house for selling your consignment.
--   8. moneyDelay
--   9. etaHour
--   10. etaMin
--   11. count: number - item count
--   12. commerceAuction
XAPI.GetInboxInvoiceInfo = function(...)
    return GetInboxInvoiceInfo(...)
end

-- 获取邮件摘要信息
-- https://wowpedia.fandom.com/wiki/API_GetInboxHeaderInfo
-- Arguments: (index)
--   index: number - the index of the message (ascending from 1).
-- Returns:
--   1. packageIcon: string - texture path for package icon if it contains a package (nil otherwise).
--   2. stationeryIcon: string - texture path for mail message icon.
--   3. sender: string - name of the player who sent the message.
--   4. subject: string - the message subject.
--   5. money: number - The amount of money attached.
--   6. CODAmount: number - The amount of COD payment required to receive the package.
--   7. daysLeft: number - The number of days (fractional) before the message expires.
--   8. hasItem: number - Either the number of attachments or nil if no items are present. Note that items that have been taken from the mailbox continue to occupy empty slots, but hasItem is the total number of items remaining in the mailbox. Use ATTACHMENTS_MAX_RECEIVE for the total number of attachments rather than this.
--   9. wasRead: boolean - 1 if the mail has been read, nil otherwise. Using GetInboxText() marks an item as read.
--   10. wasReturned: boolean - 1 if the mail was returned, nil otherwise.
--   11. textCreated: boolean - 1 if a letter object has been created from this mail, nil otherwise.
--   12. canReply: boolean - 1 if this letter can be replied to, nil otherwise.
--   13. isGM: boolean - 1 if this letter was sent by a GameMaster.
XAPI.GetInboxHeaderInfo = function(...)
    return GetInboxHeaderInfo(...)
end

-- 角色
-- 获取角色名称
-- https://wowpedia.fandom.com/wiki/API_UnitName
-- Arguments: (unit)
--   unit: string : UnitId - For example "mouseover" or "player" or "target"
-- Returns:
--   name: string? - The name of the unit and realm with an interposing space, e.g. Thegnome DarkmoonFaire. Returns nil nil if the unit doesn't exist, e.g. the player has no unit selected.
--   realm: string? - The normalized realm the unit is from, e.g. "DarkmoonFaire". Returns nil if the unit is from the same realm.
XAPI.UnitName = function(...)
    return UnitName(...)
end