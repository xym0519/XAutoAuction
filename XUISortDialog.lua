XUISortDialog = {}
local moduleName = 'XUISortDialog'

-- Variable definition
local callback = nil
local sourceIndex = nil
local targetList = nil

-- Function implemention
local function onConfirm(data)
    if not callback then return end
    if not sourceIndex then return end
    if not targetList then return end
    if #targetList < 1 then return end

    local item = targetList[sourceIndex]
    if not item then return end

    local input = data[1].Value
    local targetIndex = tonumber(input)
    if not targetIndex then return end
    if targetIndex < 1 then return end
    if targetIndex > #targetList then return end

    table.remove(targetList, sourceIndex)
    table.insert(targetList, targetIndex, item)

    sourceIndex = nil
    targetList = nil
    callback()
    callback = nil
end

XUISortDialog.show = function(pkey, ptargetList, psourceIndex, pcallback, title)
    if XUIInputDialog.isVisible(pkey) then return end
    if not title then title = '排序' end

    targetList = ptargetList
    sourceIndex = psourceIndex
    callback = pcallback

    local data = { { Name = '排序', Value = psourceIndex } }
    XUIInputDialog.show(pkey, onConfirm, data, title)
end
