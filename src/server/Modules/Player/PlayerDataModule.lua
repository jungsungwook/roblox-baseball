local DataStoreService = game:GetService("DataStoreService")
local playerDataStore = DataStoreService:GetDataStore("PlayerStats")
local MainGuiEvent = game.ReplicatedStorage:WaitForChild("Remote"):WaitForChild("MainGuiRemoteEvent")
local PlayerDataModule = {}

-- 모든 서버 스크립트가 공유할 데이터 테이블
PlayerDataModule.PlayerStats = {}

local DEFAULT_DATA = {
    Money = 0, -- 기본 돈
    Power = 100,   -- 기본 힘 스탯 (DB에 저장되는 실제 스탯)
    PowerMultiplier = 0, -- 파워 보너스 퍼센테이지 (아이템으로 얻는 보너스)
    TrainingMultiplier = 1, -- 기본 훈련 가중치
    Inventory = {}, -- 구매한 아이템들
    BestDistance = 0, -- 최장 거리 기록
}

-- 깊은 복사 함수
local function deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- 데이터 불러오기 (플레이어가 접속할 때 사용)
function PlayerDataModule.LoadData(player)
    local success, data = pcall(function()
        return playerDataStore:GetAsync(player.UserId)
    end)

    if success and data then
        -- 기존 데이터에 새로운 필드들이 없을 경우 기본값으로 보완
        if not data.TrainingMultiplier then
            data.TrainingMultiplier = DEFAULT_DATA.TrainingMultiplier
        end
        if not data.PowerMultiplier then
            data.PowerMultiplier = DEFAULT_DATA.PowerMultiplier
        end
        if not data.Inventory then
            data.Inventory = deepCopy(DEFAULT_DATA.Inventory) -- 깊은 복사
        end
        if not data.BestDistance then
            data.BestDistance = DEFAULT_DATA.BestDistance
        end
        PlayerDataModule.PlayerStats[player.UserId] = data
    else
        -- 기본 데이터를 깊은 복사로 생성
        PlayerDataModule.PlayerStats[player.UserId] = deepCopy(DEFAULT_DATA)
    end
    local playerData = PlayerDataModule.PlayerStats[player.UserId]
    local finalPower = PlayerDataModule.CalculateFinalPower(playerData)
    
    -- 리더보드 설정
    PlayerDataModule.CreateLeaderboard(player, playerData)
    
    MainGuiEvent:FireClient(player, playerData.Money, finalPower, playerData.TrainingMultiplier)
    return playerData
end

-- 리더보드 생성/업데이트
function PlayerDataModule.CreateLeaderboard(player, playerData)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    -- 돈 스탯
    local moneyValue = leaderstats:FindFirstChild("골드")
    if not moneyValue then
        moneyValue = Instance.new("IntValue")
        moneyValue.Name = "골드"
        moneyValue.Parent = leaderstats
    end
    moneyValue.Value = playerData.Money
    
    -- 파워 스탯
    local powerValue = leaderstats:FindFirstChild("파워")
    if not powerValue then
        powerValue = Instance.new("IntValue")
        powerValue.Name = "파워"
        powerValue.Parent = leaderstats
    end
    powerValue.Value = PlayerDataModule.CalculateFinalPower(playerData)
end

-- 리더보드 업데이트
function PlayerDataModule.UpdateLeaderboard(player)
    if not PlayerDataModule.PlayerStats[player.UserId] then return end
    local playerData = PlayerDataModule.PlayerStats[player.UserId]
    PlayerDataModule.CreateLeaderboard(player, playerData)
end

-- 데이터 저장하기 (플레이어가 나갈 때 사용)
function PlayerDataModule.SaveData(player)
    local data = PlayerDataModule.PlayerStats[player.UserId]
    if not data then
        warn("저장할 데이터가 없습니다: " .. player.Name)
        return
    end
    
    local success, err = pcall(function()
        playerDataStore:SetAsync(player.UserId, data)
    end)

    if not success then
        warn("데이터 저장 실패:", err)
    else
        print(player.Name .. "의 데이터 저장 성공")
    end

    -- 메모리에서 제거
    PlayerDataModule.PlayerStats[player.UserId] = nil
end

-- 플레이어 데이터 가져오기 (서버 스크립트 간 공유용) - GUI 업데이트 제거
function PlayerDataModule.GetPlayerData(player)
    return PlayerDataModule.PlayerStats[player.UserId]
end

-- 플레이어 데이터 설정하기 (서버 스크립트 간 공유용)
function PlayerDataModule.SetPlayerData(player, newData)
    PlayerDataModule.PlayerStats[player.UserId] = newData
    local finalPower = PlayerDataModule.GetFinalPower(player)
    
    -- 리더보드 업데이트
    PlayerDataModule.UpdateLeaderboard(player)
    
    MainGuiEvent:FireClient(player, newData.Money, finalPower, newData.TrainingMultiplier)
end

-- 플레이어에게 돈 추가하기
function PlayerDataModule.AddMoney(player, amount)
    local playerData = PlayerDataModule.PlayerStats[player.UserId]
    if not playerData then
        warn("플레이어 데이터를 찾을 수 없습니다: " .. player.Name)
        return false
    end
    
    if type(amount) ~= "number" or amount < 0 then
        warn("잘못된 금액입니다: " .. tostring(amount))
        return false
    end
    
    playerData.Money = playerData.Money + amount
    local finalPower = PlayerDataModule.GetFinalPower(player)
    
    -- 리더보드 업데이트
    PlayerDataModule.UpdateLeaderboard(player)
    
    MainGuiEvent:FireClient(player, playerData.Money, finalPower, playerData.TrainingMultiplier)
    return true
end

-- 최장 거리 기록 업데이트
function PlayerDataModule.UpdateBestDistance(player, distance)
    local playerData = PlayerDataModule.PlayerStats[player.UserId]
    if not playerData then
        warn("플레이어 데이터를 찾을 수 없습니다: " .. player.Name)
        return false
    end
    
    if type(distance) ~= "number" or distance < 0 then
        warn("잘못된 거리입니다: " .. tostring(distance))
        return false
    end
    
    -- 기존 기록보다 좋은 경우에만 업데이트
    if distance > playerData.BestDistance then
        playerData.BestDistance = distance
        print(player.Name .. "의 최장 거리 기록 갱신: " .. distance .. " 스터드")
        return true
    end
    
    return false
end

-- 최종 파워 계산 (DB 파워 + 아이템 보너스)
function PlayerDataModule.GetFinalPower(player)
    local playerData = PlayerDataModule.PlayerStats[player.UserId]
    if not playerData then
        warn("플레이어 데이터를 찾을 수 없습니다: " .. player.Name)
        return 1 -- 기본값 반환
    end
    
    local basePower = playerData.Power or 1
    local powerMultiplier = playerData.PowerMultiplier or 0
    
    -- 최종 파워 = 기본 파워 * (1 + 보너스 퍼센테이지 / 100)
    local finalPower = basePower * (1 + powerMultiplier / 100)
    
    return finalPower
end

-- 특정 데이터로 최종 파워 계산 (데이터가 직접 주어질 때)
function PlayerDataModule.CalculateFinalPower(playerData)
    if not playerData then
        return 1
    end
    
    local basePower = playerData.Power or 1
    local powerMultiplier = playerData.PowerMultiplier or 0
    
    -- 최종 파워 = 기본 파워 * (1 + 보너스 퍼센테이지 / 100)
    local finalPower = basePower * (1 + powerMultiplier / 100)
    
    return finalPower
end

return PlayerDataModule
