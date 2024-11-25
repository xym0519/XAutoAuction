XSetting = {}
XSettingList = {
    normalbagcount = 3,
    mycharacterlist = {},
    partnerlistbuy = {},
    partnerlistsell = {},
    defaultmailreceiver = '',
    mailreceiver = {}
}
local moduleName = 'XSetting'

local printSetting = function(key, ...)
    print(XUI.Orange, key, XUI.Green, ...)
end

local initSetting = function(key)
    if XSettingList[key] ~= nil then return end
    local defaultValue = nil
    if key == 'normalbagcount' then
        defaultValue = 3
    elseif XUtils.inArray(key, {
            'mycharacterlist',
            'partnerlistbuy',
            'partnerlistsell',
            'mailreceiver' }) then
        defaultValue = {}
    elseif key == 'defaultmailreceiver' then
        defaultValue = ''
    end
    XSettingList[key] = defaultValue
end

-- Normal Bag Count
XSetting.getNormalBagCount = function()
    initSetting('normalbagcount')
    return XSettingList['normalbagcount']
end

XSetting.setNormalBagCount = function(value)
    initSetting('normalbagcount')
    XSettingList['normalbagcount'] = value
end

XSetting.printNormalBagCount = function()
    initSetting('normalbagcount')
    printSetting('NormalBagCount', XSettingList['normalbagcount'])
end

-- My Character List
-- XInfo.characterList = { '暗影肌', '阿肌', '咖喱贼' }
XSetting.getMyCharacterList = function()
    initSetting('mycharacterlist')
    return XSettingList['mycharacterlist']
end

XSetting.addMyCharacterList = function(value)
    initSetting('mycharacterlist')
    table.insert(XSettingList['mycharacterlist'], value)
end

XSetting.delMyCharacterList = function(index)
    initSetting('mycharacterlist')
    if #XSettingList['mycharacterlist'] < index then return end
    table.remove(XSettingList['mycharacterlist'], index)
end

XSetting.printMyCharacterList = function()
    initSetting('mycharacterlist')
    xdebug.warn('MyCharacterList')
    for idx, name in ipairs(XSettingList['mycharacterlist']) do
        printSetting(idx, name)
    end
end

-- Partner List Sell
-- XInfo.partnerList = { '嘿丶小十六', '京城顽主', '小灬白龙', '暗影肌', '奔波丶霸' }
XSetting.getPartnerListBuy = function()
    initSetting('partnerlistbuy')
    return XSettingList['partnerlistbuy']
end

XSetting.addPartnerListBuy = function(value)
    initSetting('partnerlistbuy')
    table.insert(XSettingList['mycharacterlistbuy'], value)
end

XSetting.delPartnerListBuy = function(index)
    initSetting('partnerlistbuy')
    if #XSettingList['partnerlistbuy'] < index then return end
    table.remove(XSettingList['partnerlistbuy'], index)
end

XSetting.printPartnerListBuy = function()
    initSetting('partnerlistbuy')
    xdebug.warn('PartnerListBuy')
    for idx, name in ipairs(XSettingList['partnerlistbuy']) do
        printSetting(idx, name)
    end
end

-- Partner List Sell
XSetting.getPartnerListSell = function()
    initSetting('partnerlistsell')
    return XSettingList['partnerlistsell']
end

XSetting.addPartnerListSell = function(value)
    initSetting('partnerlistsell')
    table.insert(XSettingList['mycharacterlistsell'], value)
end

XSetting.delPartnerListSell = function(index)
    initSetting('partnerlistsell')
    if #XSettingList['partnerlistsell'] < index then return end
    table.remove(XSettingList['partnerlistsell'], index)
end

XSetting.printPartnerListSell = function()
    initSetting('partnerlistsell')
    xdebug.warn('PartnerListSell')
    for idx, name in ipairs(XSettingList['partnerlistsell']) do
        printSetting(idx, name)
    end
end

-- Default Mail Receiver
XSetting.getDefaultMailReceiver = function()
    initSetting('defaultmailreceiver')
    return XSettingList['defaultmailreceiver']
end

XSetting.setDefaultMailReceiver = function(value)
    initSetting('defaultmailreceiver')
    XSettingList['defaultmailreceiver'] = value
end

XSetting.printDefaultMailReceiver = function()
    initSetting('defaultmailreceiver')
    printSetting('DefaultMailReceiver', XSettingList['defaultmailreceiver'])
end

-- Mail Receiver
XSetting.getMailReceiver = function(itemName)
    initSetting('mailreceiver')
    local receiver = XSettingList['mailreceiver'][itemName]
    if receiver == nil then
        receiver = XSetting.getDefaultMailReceiver()
    end
    return receiver
end

XSetting.addMailReceiver = function(receiver, ...)
    initSetting('mailreceiver')
    local itemList = { ... }
    for _, itemName in ipairs(itemList) do
        XSettingList['mailreceiver'][itemName] = receiver
    end
end

XSetting.delMailReceiver = function(itemName)
    initSetting('mailreceiver')
    XSettingList['mailreceiver'][itemName] = nil
end

XSetting.printMailReceiver = function()
    initSetting('mailreceiver')
    xdebug.warn('MailReceiver')
    local list = {}
    for itemName, receiver in pairs(XSettingList['mailreceiver']) do
        if list[receiver] == nil then
            list[receiver] = {}
        end
        if not XUtils.inArray(itemName, list[receiver]) then
            tinsert(list[receiver], itemName)
        end
    end
    for receiver, itemList in pairs(list) do
        xdebug.warn(receiver)
        for _, itemName in ipairs(itemList) do
            xdebug.warn('    ' .. itemName)
        end
    end
end

-- {
--     receiver = '默法',
--     list = { '萨隆邪铁矿石', '血石', '茶晶石', '太阳水晶', '黑玉', '玉髓石', '暗影水晶', '永恒之土', '土之结晶', '钴矿石', '冰冻宝珠' }
-- }

-- local dft_mineReceiver = '阿肌'
-- local dft_mineReceiverList = {
--     {
--         receiver = '默法',
--         list = { '萨隆邪铁矿石', '血石', '茶晶石', '太阳水晶', '黑玉', '玉髓石', '暗影水晶', '永恒之土', '土之结晶', '钴矿石', '冰冻宝珠' }
--     }
-- }
-- local dft_rubbishReceiver = '默无'

-- local dft_rubbishList = {
--     { itemname = '裂纹森林翡翠', materialcount = 0 },
--     { itemname = '充能暗影水晶', materialcount = 0 },
--     { itemname = '烈日石戒', materialcount = 0 },
--     { itemname = '血石指环', materialcount = 0 },
--     { itemname = '坚硬黑玉', materialcount = 0 },
--     -- { itemname = '风暴天蓝石', materialcount = 20 },
--     { itemname = '水晶玉髓石项圈', materialcount = 0 },
--     -- { itemname = '水晶茶晶石项链', materialcount = 0 },
-- }
