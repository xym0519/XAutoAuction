XSetting = {}
local moduleName = 'XSetting'

XSettingList = {}
local mainFrame
local initUI

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
    table.insert(XSettingList['partnerlistbuy'], value)
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
    table.insert(XSettingList['partnerlistsell'], value)
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
        xdebug.debug(receiver)
        for _, itemName in ipairs(itemList) do
            xdebug.warn('    ' .. itemName)
        end
    end
end

initUI = function()
    mainFrame = XUI.createFrame(moduleName .. '_mainFrame', 450, 150)
    mainFrame.title:SetText('系统设置')
    mainFrame:SetPoint('RIGHT', UIParent, 'RIGHT', -80, 0)
    mainFrame:Hide()
    tinsert(UISpecialFrames, mainFrame:GetName())

    local macroButton = XUI.createButton(mainFrame, 100, '初始化宏')
    macroButton:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 15, -30)
    macroButton:SetScript('OnClick', function()
        XUIConfirmDialog.show(moduleName, '确认', '确认初始化宏', function()
            if IsLeftShiftKeyDown() then
                XAPI.DeleteMacro('cls')
                XAPI.DeleteMacro('reload')
                XAPI.DeleteMacro('出售')
                XAPI.DeleteMacro('购买')
                XAPI.DeleteMacro('交易')
                XAPI.DeleteMacro('关闭')
                XAPI.DeleteMacro('刷新')
                XAPI.DeleteMacro('设置')
                XAPI.DeleteMacro('导出')
                XAPI.DeleteMacro('法1')
                XAPI.DeleteMacro('法2')
                XAPI.DeleteMacro('法3')
                XAPI.DeleteMacro('法4')
                XAPI.DeleteMacro('法5')
                XAPI.DeleteMacro('合土')
                XAPI.DeleteMacro('拆土1')
                XAPI.DeleteMacro('拆土2')
                XAPI.DeleteMacro('拆土3')
                XAPI.DeleteMacro('拆土4')
                XAPI.DeleteMacro('拆土5')
                XAPI.DeleteMacro('选矿')
            end

            if not XAPI.GetMacroInfo('cls') then
                XAPI.CreateMacro('cls', XAPI.Texture_QuestionMark, '/cls')
            end
            if not XAPI.GetMacroInfo('reload') then
                XAPI.CreateMacro('reload', XAPI.Texture_QuestionMark, '/reload')
            end

            if not XAPI.GetMacroInfo('出售') then
                XAPI.CreateMacro('出售', XAPI.Texture_QuestionMark,
                    "/xauctioncenter\n/xcraftqueue_close\n/xbuy_close\n/xjewwords_close\n/xminecenter_hide")
            end
            if not XAPI.GetMacroInfo('购买') then
                XAPI.CreateMacro('购买', XAPI.Texture_QuestionMark,
                    "/xauctioncenter_close\n/xcraftqueue_close\n/xbuy\n/xjewcount_show\n/xjewwords_close\n/xminecenter")
            end
            if not XAPI.GetMacroInfo('交易') then
                XAPI.CreateMacro('交易', XAPI.Texture_QuestionMark,
                    "/xauctioncenter_close\n/xcraftqueue_close\n/xbuy_close\n/xjewcount_close\n/xjewwords\n/xminecenter_hide")
            end
            if not XAPI.GetMacroInfo('关闭') then
                XAPI.CreateMacro('关闭', XAPI.Texture_QuestionMark,
                    "/xauctioncenter_close\n/xcraftqueue_close\n/xauctionhistory_close\n/xbuy_close\n/xjewcount_close\n/xjewwords_close\n/xminecenter_hide")
            end

            if not XAPI.GetMacroInfo('刷新') then
                XAPI.CreateMacro('刷新', XAPI.Texture_QuestionMark, "/xjewtool_refresh")
            end
            if not XAPI.GetMacroInfo('设置') then
                XAPI.CreateMacro('设置', XAPI.Texture_QuestionMark, "/xsetting")
            end
            if not XAPI.GetMacroInfo('导出') then
                XAPI.CreateMacro('导出', XAPI.Texture_QuestionMark, "/xjewtooldata_export")
            end

            if not XAPI.GetMacroInfo('法1') then
                XAPI.CreateMacro('法1', XAPI.Texture_QuestionMark, "/xjewtool_update")
            end
            if not XAPI.GetMacroInfo('法2') then
                XAPI.CreateMacro('法2', XAPI.Texture_QuestionMark, "/xjewtool_skill")
            end
            if not XAPI.GetMacroInfo('法3') then
                XAPI.CreateMacro('法3', XAPI.Texture_QuestionMark, "/xjewtool_cast")
            end
            if not XAPI.GetMacroInfo('法4') then
                XAPI.CreateMacro('法4', XAPI.Texture_QuestionMark, "/xjewtool_magic")
            end
            if not XAPI.GetMacroInfo('法5') then
                XAPI.CreateMacro('法5', XAPI.Texture_QuestionMark, "/xjewtool_fang")
            end

            if not XAPI.GetMacroInfo('合土') then
                XAPI.CreateMacro('合土', XAPI.Texture_QuestionMark, "/use 土之结晶")
            end
            if not XAPI.GetMacroInfo('拆土1') then
                XAPI.CreateMacro('拆土1', XAPI.Texture_QuestionMark, "/use 永恒之土\n/xjewtool_update")
            end
            if not XAPI.GetMacroInfo('拆土2') then
                XAPI.CreateMacro('拆土2', XAPI.Texture_QuestionMark, "/use 永恒之土\n/xjewtool_skill")
            end
            if not XAPI.GetMacroInfo('拆土3') then
                XAPI.CreateMacro('拆土3', XAPI.Texture_QuestionMark, "/use 永恒之土\n/xjewtool_cast")
            end
            if not XAPI.GetMacroInfo('拆土4') then
                XAPI.CreateMacro('拆土4', XAPI.Texture_QuestionMark, "/use 永恒之土\n/xjewtool_magic")
            end
            if not XAPI.GetMacroInfo('拆土5') then
                XAPI.CreateMacro('拆土5', XAPI.Texture_QuestionMark, "/use 永恒之土\n/xjewtool_fang")
            end

            if not XAPI.GetMacroInfo('选矿') then
                XAPI.CreateMacro('选矿', XAPI.Texture_QuestionMark, "/cast 选矿\n/use 萨隆邪铁矿石")
            end
        end)
    end)

    local normalBagCountButton = XUI.createButton(mainFrame, 100, '包裹数量')
    normalBagCountButton:SetPoint('TOPLEFT', macroButton, 'BOTTOMLEFT', 0, -5)
    normalBagCountButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            XUIInputDialog.show(moduleName, function() end,
                { { Name = '设置', Value = '/run XSetting.setNormalBagCount(3)' } })
        else
            XSetting.printNormalBagCount()
        end
    end)

    local myCharacterButton = XUI.createButton(mainFrame, 100, '我的角色')
    myCharacterButton:SetPoint('LEFT', normalBagCountButton, 'RIGHT', 5, 0)
    myCharacterButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            XUIInputDialog.show(moduleName, function() end,
                { { Name = '设置', Value = '/run XSetting.addMyCharacterList("")' } })
        else
            XSetting.printMyCharacterList()
        end
    end)

    local partnerBuyButton = XUI.createButton(mainFrame, 100, '合作方买')
    partnerBuyButton:SetPoint('LEFT', myCharacterButton, 'RIGHT', 5, 0)
    partnerBuyButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            XUIInputDialog.show(moduleName, function() end,
                { { Name = '设置', Value = '/run XSetting.addPartnerListBuy("")' } })
        else
            XSetting.printPartnerListBuy()
        end
    end)

    local partnerSellButton = XUI.createButton(mainFrame, 100, '合作方卖')
    partnerSellButton:SetPoint('LEFT', partnerBuyButton, 'RIGHT', 5, 0)
    partnerSellButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            XUIInputDialog.show(moduleName, function() end,
                { { Name = '设置', Value = '/run XSetting.addPartnerListSell("")' } })
        else
            XSetting.printPartnerListSell()
        end
    end)

    local defaultMailReceiverButton = XUI.createButton(mainFrame, 100, '默认收件人')
    defaultMailReceiverButton:SetPoint('TOPLEFT', normalBagCountButton, 'BOTTOMLEFT', 0, -5)
    defaultMailReceiverButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            XUIInputDialog.show(moduleName, function() end,
                { { Name = '设置', Value = '/run XSetting.setDefaultMailReceiver("")' } })
        else
            XSetting.printDefaultMailReceiver()
        end
    end)

    local mailReceiverButton = XUI.createButton(mainFrame, 100, '收件人')
    mailReceiverButton:SetPoint('LEFT', defaultMailReceiverButton, 'RIGHT', 5, 0)
    mailReceiverButton:SetScript('OnClick', function()
        if IsLeftShiftKeyDown() then
            XUIInputDialog.show(moduleName, function() end,
                { { Name = '设置', Value = '/run XSetting.addMailReceiver("i","u")' } })
        else
            XSetting.printMailReceiver()
        end
    end)
end

-- Events
XJewTool.registerEventCallback(moduleName, 'ADDON_LOADED', function()
    initUI()
end)

-- Commands
SlashCmdList['XSETTING'] = function()
    XUI.toggleVisible(mainFrame)
end
SLASH_XSETTING1 = '/xsetting'
