local ItemDatabase = {}

-- 모든 게임 아이템 정보
ItemDatabase.Items = {
    [1] = {
        id = 1,
        name = "기본 배트",
        description = "파워를 5% 올려주는 기본 배트",
        price = 50,
        image = "rbxassetid://115202682945867", -- 이미지 ID를 나중에 교체
        category = "weapon", -- 아이템 카테고리
        rarity = "common", -- 희귀도
        stats = {
            PowerMultiplier = 5, -- 5% 증가
            TrainingMultiplier = 0
        }
    },
    [2] = {
        id = 2, 
        name = "훈련용 글러브",
        description = "훈련 효율을 2배로 만들어주는 글러브",
        price = 100,
        image = "rbxassetid://137739384308151", -- 이미지 ID를 나중에 교체
        category = "equipment",
        rarity = "common",
        stats = {
            PowerMultiplier = 0,
            TrainingMultiplier = 2
        }
    },
    [3] = {
        id = 3,
        name = "슈퍼 배트",
        description = "파워를 15% 올려주고 훈련 효율도 1.5배로 만들어주는 고급 배트",
        price = 250,
        image = "rbxassetid://108702786344316", -- 이미지 ID를 나중에 교체
        category = "weapon",
        rarity = "rare",
        stats = {
            PowerMultiplier = 15, -- 15% 증가
            TrainingMultiplier = 1.5
        }
    },
    [4] = {
        id = 4,
        name = "파워 신발",
        description = "파워를 10% 올려주는 신발",
        price = 120,
        image = "rbxassetid://76771089787140", -- 이미지 ID를 나중에 교체
        category = "equipment",
        rarity = "common",
        stats = {
            PowerMultiplier = 10, -- 10% 증가
            TrainingMultiplier = 0
        }
    },
    [5] = {
        id = 5,
        name = "훈련복",
        description = "훈련 효율을 3배로 만들어주는 전용 훈련복",
        price = 300,
        image = "rbxassetid://99494305435613", -- 이미지 ID를 나중에 교체
        category = "clothing",
        rarity = "epic",
        stats = {
            PowerMultiplier = 0,
            TrainingMultiplier = 3
        }
    },
    [6] = {
        id = 6,
        name = "전설의 배트",
        description = "파워를 25% 올려주고 훈련 효율을 5배로 만들어주는 전설적인 배트",
        price = 500,
        image = "rbxassetid://95845770030281", -- 이미지 ID를 나중에 교체
        category = "weapon",
        rarity = "legendary",
        stats = {
            PowerMultiplier = 25, -- 25% 증가
            TrainingMultiplier = 5
        }
    }
}

-- 특정 아이템 정보 가져오기
function ItemDatabase.GetItem(itemId)
    return ItemDatabase.Items[itemId]
end

-- 모든 아이템 정보 가져오기
function ItemDatabase.GetAllItems()
    local itemList = {}
    for itemId, itemData in pairs(ItemDatabase.Items) do
        table.insert(itemList, itemData)
    end
    return itemList
end

-- 카테고리별 아이템 가져오기
function ItemDatabase.GetItemsByCategory(category)
    local categoryItems = {}
    for itemId, itemData in pairs(ItemDatabase.Items) do
        if itemData.category == category then
            table.insert(categoryItems, itemData)
        end
    end
    return categoryItems
end

-- 희귀도별 아이템 가져오기
function ItemDatabase.GetItemsByRarity(rarity)
    local rarityItems = {}
    for itemId, itemData in pairs(ItemDatabase.Items) do
        if itemData.rarity == rarity then
            table.insert(rarityItems, itemData)
        end
    end
    return rarityItems
end

-- 가격 범위별 아이템 가져오기
function ItemDatabase.GetItemsByPriceRange(minPrice, maxPrice)
    local priceRangeItems = {}
    for itemId, itemData in pairs(ItemDatabase.Items) do
        if itemData.price >= minPrice and itemData.price <= maxPrice then
            table.insert(priceRangeItems, itemData)
        end
    end
    return priceRangeItems
end

-- 아이템 존재 여부 확인
function ItemDatabase.ItemExists(itemId)
    return ItemDatabase.Items[itemId] ~= nil
end

-- 새 아이템 추가 (동적 추가용)
function ItemDatabase.AddItem(itemData)
    if itemData.id then
        ItemDatabase.Items[itemData.id] = itemData
        return true
    end
    return false
end

-- 아이템 제거 (동적 제거용)
function ItemDatabase.RemoveItem(itemId)
    if ItemDatabase.Items[itemId] then
        ItemDatabase.Items[itemId] = nil
        return true
    end
    return false
end

-- 아이템 업데이트 (동적 수정용)
function ItemDatabase.UpdateItem(itemId, newData)
    if ItemDatabase.Items[itemId] then
        for key, value in pairs(newData) do
            ItemDatabase.Items[itemId][key] = value
        end
        return true
    end
    return false
end

return ItemDatabase 