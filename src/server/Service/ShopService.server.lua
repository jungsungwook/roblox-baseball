local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 모듈 로드
local PlayerDataModule = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Player").PlayerDataModule)
local ShopModule = require(ServerScriptService:WaitForChild("Modules").ShopModule)
local ItemDatabase = require(ServerScriptService:WaitForChild("Modules").ItemDatabase)

-- RemoteEvent 생성
local ShopRemoteEvent = Instance.new("RemoteEvent")
ShopRemoteEvent.Name = "ShopRemoteEvent"
ShopRemoteEvent.Parent = ReplicatedStorage:WaitForChild("Remote")

local InventoryRemoteEvent = Instance.new("RemoteEvent")
InventoryRemoteEvent.Name = "InventoryRemoteEvent"
InventoryRemoteEvent.Parent = ReplicatedStorage:WaitForChild("Remote")

-- 상점 ProximityPrompt 처리
ProximityPromptService.PromptTriggered:Connect(function(proximityPrompt, player)
    if proximityPrompt.Name == "ProximityPrompt" and proximityPrompt.Parent.Name == "ShopProximity" then
        -- 상점 UI 열기
        local shopItems = ShopModule.GetShopItems()
        local playerData = PlayerDataModule.GetPlayerData(player)
        
        -- Inventory가 없으면 빈 테이블로 초기화
        if not playerData.Inventory then
            playerData.Inventory = {}
            PlayerDataModule.SetPlayerData(player, playerData)
        end
        
        ShopRemoteEvent:FireClient(player, "OpenShop", shopItems, playerData.Inventory)
    end
end)

-- 아이템 구매 처리
ShopRemoteEvent.OnServerEvent:Connect(function(player, action, itemId)
    if action == "BuyItem" then
        local playerData = PlayerDataModule.GetPlayerData(player)
        local item = ItemDatabase.GetItem(itemId)
        
        if not item then
            warn("존재하지 않는 아이템: " .. tostring(itemId))
            return
        end
        
        -- 상점에서 판매하는 아이템인지 확인
        if not ShopModule.IsItemInShop(itemId) then
            warn("상점에서 판매하지 않는 아이템: " .. tostring(itemId))
            ShopRemoteEvent:FireClient(player, "PurchaseResult", false, "이 아이템은 현재 판매하지 않습니다.")
            return
        end
        
        -- 이미 구매한 아이템인지 확인
        if playerData.Inventory then
            for _, ownedItemId in pairs(playerData.Inventory) do
                if ownedItemId == itemId then
                    ShopRemoteEvent:FireClient(player, "PurchaseResult", false, "이미 구매한 아이템입니다.")
                    return
                end
            end
        else
            playerData.Inventory = {}
        end
        
        -- 돈이 충분한지 확인 (문자열을 숫자로 변환)
        local playerMoney = tonumber(playerData.Money) or 0
        local itemPrice = tonumber(item.price) or 0
        
        if playerMoney < itemPrice then
            ShopRemoteEvent:FireClient(player, "PurchaseResult", false, "돈이 부족합니다.")
            return
        end
        
        -- 아이템 구매 처리 (숫자로 변환하여 계산)
        playerData.Money = playerMoney - itemPrice
        
        -- PowerMultiplier 적용 (퍼센테이지 누적)
        if not playerData.PowerMultiplier then
            playerData.PowerMultiplier = 0
        end
        playerData.PowerMultiplier = (tonumber(playerData.PowerMultiplier) or 0) + (tonumber(item.stats.PowerMultiplier) or 0)
        
        -- TrainingMultiplier가 없으면 기본값으로 초기화 (숫자로 변환)
        if not playerData.TrainingMultiplier then
            playerData.TrainingMultiplier = 1
        end
        playerData.TrainingMultiplier = (tonumber(playerData.TrainingMultiplier) or 1) + (tonumber(item.stats.TrainingMultiplier) or 0)
        
        -- Inventory가 없으면 빈 테이블로 초기화
        if not playerData.Inventory then
            playerData.Inventory = {}
        end
        table.insert(playerData.Inventory, itemId)
        
        -- 데이터 업데이트
        PlayerDataModule.SetPlayerData(player, playerData)
        
        -- 구매 성공 알림
        ShopRemoteEvent:FireClient(player, "PurchaseResult", true, "아이템을 성공적으로 구매했습니다!")
        
        print(player.Name .. "이(가) " .. item.name .. "을(를) 구매했습니다.")
    end
end)

-- 인벤토리 요청 처리
InventoryRemoteEvent.OnServerEvent:Connect(function(player, action)
    if action == "GetInventory" then
        local playerData = PlayerDataModule.GetPlayerData(player)
        local inventoryItems = {}
        
        print(string.format("[인벤토리 디버그] %s의 인벤토리: %s", player.Name, game:GetService("HttpService"):JSONEncode(playerData.Inventory or {})))
        
        -- 플레이어가 소유한 아이템들의 정보 수집
        if playerData.Inventory then
            for _, itemId in pairs(playerData.Inventory) do
                local item = ItemDatabase.GetItem(itemId)
                print(string.format("[인벤토리 디버그] 아이템 ID %d 조회 결과: %s", itemId, item and "찾음" or "없음"))
                if item then
                    print(string.format("[인벤토리 디버그] 아이템 정보: %s", game:GetService("HttpService"):JSONEncode(item)))
                    table.insert(inventoryItems, item)
                else
                    warn(string.format("[인벤토리 오류] 아이템 ID %d를 ItemDatabase에서 찾을 수 없습니다!", itemId))
                end
            end
        else
            -- Inventory가 없으면 빈 테이블로 초기화
            playerData.Inventory = {}
            PlayerDataModule.SetPlayerData(player, playerData)
        end
        
        print(string.format("[인벤토리 디버그] %s에게 전송할 아이템 개수: %d", player.Name, #inventoryItems))
        InventoryRemoteEvent:FireClient(player, "InventoryData", inventoryItems)
    end
end) 