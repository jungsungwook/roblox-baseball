local ServerScriptService = game:GetService("ServerScriptService")
local ItemDatabase = require(ServerScriptService:WaitForChild("Modules").ItemDatabase)

local ShopModule = {}

-- 상점에서 판매하는 아이템 ID 목록 (판매 순서 관리)
ShopModule.ShopItemIds = {
    1, -- 기본 배트
    2, -- 훈련용 글러브
    3, -- 슈퍼 배트
    4, -- 파워 신발
    5, -- 훈련복
    6  -- 전설의 배트
}

-- 상점에서 판매하는 아이템 목록 가져오기 (ItemDatabase에서 실제 데이터 조회)
function ShopModule.GetShopItems()
    local shopItems = {}
    for _, itemId in pairs(ShopModule.ShopItemIds) do
        local item = ItemDatabase.GetItem(itemId)
        if item then
            table.insert(shopItems, item)
        end
    end
    return shopItems
end

-- 특정 아이템 정보 가져오기 (ItemDatabase 위임)
function ShopModule.GetItemById(itemId)
    return ItemDatabase.GetItem(itemId)
end

-- 상점에 아이템 추가 (판매 목록에 추가)
function ShopModule.AddItemToShop(itemId)
    -- ItemDatabase에 해당 아이템이 존재하는지 확인
    if ItemDatabase.ItemExists(itemId) then
        -- 이미 상점에 있는지 확인
        for _, existingId in pairs(ShopModule.ShopItemIds) do
            if existingId == itemId then
                return false -- 이미 존재함
            end
        end
        table.insert(ShopModule.ShopItemIds, itemId)
        return true
    end
    return false
end

-- 상점에서 아이템 제거 (판매 목록에서 제거)
function ShopModule.RemoveItemFromShop(itemId)
    for i, existingId in pairs(ShopModule.ShopItemIds) do
        if existingId == itemId then
            table.remove(ShopModule.ShopItemIds, i)
            return true
        end
    end
    return false
end

-- 상점에서 판매 중인지 확인
function ShopModule.IsItemInShop(itemId)
    for _, existingId in pairs(ShopModule.ShopItemIds) do
        if existingId == itemId then
            return true
        end
    end
    return false
end

-- 상점 아이템을 카테고리별로 가져오기
function ShopModule.GetShopItemsByCategory(category)
    local categoryItems = {}
    for _, itemId in pairs(ShopModule.ShopItemIds) do
        local item = ItemDatabase.GetItem(itemId)
        if item and item.category == category then
            table.insert(categoryItems, item)
        end
    end
    return categoryItems
end

-- 상점 아이템을 희귀도별로 가져오기
function ShopModule.GetShopItemsByRarity(rarity)
    local rarityItems = {}
    for _, itemId in pairs(ShopModule.ShopItemIds) do
        local item = ItemDatabase.GetItem(itemId)
        if item and item.rarity == rarity then
            table.insert(rarityItems, item)
        end
    end
    return rarityItems
end

return ShopModule 