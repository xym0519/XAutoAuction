XSetting = {}
local moduleName = 'XSetting'

local printSetting = function(key, ...)
    print(XUI.Orange, key, XUI.Green, ...)
end

-- Normal Bag Count
if XSettingList['normalbagcount'] == nil then XSettingList['normalbagcount'] = 3 end
XSetting.getNormalBagCount = function()
    return XSettingList['normalbagcount']
end

XSetting.setNormalBagCount = function(value)
    XSettingList['normalbagcount'] = value
end

XSetting.printNormalBagCount = function()
    printSetting('NormalBagCount', XSettingList['normalbagcount'])
end

-- My Character List
if XSettingList['mycharacterlist'] == nil then XSettingList['mycharacterlist'] = {} end
XSetting.getMyCharacterList = function()
    return XSettingList['mycharacterlist']
end

XSetting.addMyCharacterList = function(value)
    table.insert(XSettingList['mycharacterlist'], value)
end

XSetting.delMyCharacterList = function(index)
    if #XSettingList['mycharacterlist'] < index then return end
    table.remove(XSettingList['mycharacterlist'], index)
end

XSetting.printMyCharacterList = function()
    xdebug.warn('MyCharacterList')
    for idx, name in ipairs(XSettingList['mycharacterlist']) do
        printSetting(idx, name)
    end
end

-- Partner List
if XSettingList['partnerlist'] == nil then XSettingList['partnerlist'] = {} end
XSetting.getPartnerList = function()
    return XSettingList['partnerlist']
end

XSetting.addPartnerList = function(value)
    table.insert(XSettingList['mycharacterlist'], value)
end

XSetting.delPartnerList = function(index)
    if #XSettingList['partnerlist'] < index then return end
    table.remove(XSettingList['partnerlist'], index)
end

XSetting.printPartnerList = function()
    xdebug.warn('PartnerList')
    for idx, name in ipairs(XSettingList['partnerlist']) do
        printSetting(idx, name)
    end
end

-- Default Mail Receiver
if XSettingList['defaultmailreceiver'] == nil then XSettingList['defaultmailreceiver'] = '' end
XSetting.getDefaultMailReceiver = function()
    return XSettingList['defaultmailreceiver']
end

XSetting.setDefaultMailReceiver = function(value)
    XSettingList['defaultmailreceiver'] = value
end

XSetting.printDefaultMailReceiver = function()
    printSetting('DefaultMailReceiver', XSettingList['defaultmailreceiver'])
end

-- Mail Receiver
if XSettingList['mailreceiver'] == nil then XSettingList['mailreceiver'] = {} end
XSetting.getMailReceiver = function()
    return XSettingList['mailreceiver']
end

XSetting.addMailReceiver = function(receiver, ...)
    local receiverItem = nil
    for _, item in ipairs(XSettingList['mailreceiver']) do
        if item['receiver'] == receiver then
            receiverItem = item
            break
        end
    end
    if receiverItem == nil then
        receiverItem = { receiver = receiver, list = {} }
        table.insert(XSettingList['mailreceiver'], receiverItem)
    end
    local itemList = { ... }
    for _, itemName in ipairs(itemList) do
111
    end
    -- table.insert(XSettingList['mycharacterlist'], value)
end

-- {
--     receiver = '默法',
--     list = { '萨隆邪铁矿石', '血石', '茶晶石', '太阳水晶', '黑玉', '玉髓石', '暗影水晶', '永恒之土', '土之结晶', '钴矿石', '冰冻宝珠' }
-- }
