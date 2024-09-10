XAuctionItemToolTip = {}
XAuctionItemToolTip.Show = function(frame, anchor)
    if IsShiftKeyDown() then
        GameTooltip:SetOwner(frame, anchor)
        GameTooltip:AddLine('----------')
        GameTooltip:AddDoubleLine('key', 'value')

        GameTooltip:Show()
    end
end
