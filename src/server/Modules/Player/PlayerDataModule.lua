local DataStoreService = game:GetService("DataStoreService")
local playerDataStore = DataStoreService:GetDataStore("PlayerStats")
local MainGuiEvent = game.ReplicatedStorage:WaitForChild("Remote"):WaitForChild("MainGuiRemoteEvent")
local PlayerDataModule = {}

-- 모든 서버 스크립트가 공유할 데이터 테이블
PlayerDataModule.PlayerStats = {}

local DEFAULT_DATA = {
    Money = 10, -- 기본 돈
    Power = 1,   -- 기본 힘 스탯
}

-- 데이터 불러오기 (플레이어가 접속할 때 사용)
function PlayerDataModule.LoadData(player)
    local success, data = pcall(function()
        return playerDataStore:GetAsync(player.UserId)
    end)

    if success and data then
        PlayerDataModule.PlayerStats[player.UserId] = data
    else
        PlayerDataModule.PlayerStats[player.UserId] = DEFAULT_DATA
    end
    MainGuiEvent:FireClient(player, PlayerDataModule.PlayerStats[player.UserId].Money, PlayerDataModule.PlayerStats[player.UserId].Power)
    return PlayerDataModule.PlayerStats[player.UserId]
end

-- 데이터 저장하기 (플레이어가 나갈 때 사용)
function PlayerDataModule.SaveData(player)
    local data = PlayerDataModule.PlayerStats[player.UserId]
    if not data then
        warn("저장할 데이터가 없습니다: " .. player.Name)
        return
    end
    MainGuiEvent:FireClient(player, data.Money, data.Power)
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

-- 플레이어 데이터 가져오기 (서버 스크립트 간 공유용)
function PlayerDataModule.GetPlayerData(player)
    MainGuiEvent:FireClient(player, PlayerDataModule.PlayerStats[player.UserId].Money, PlayerDataModule.PlayerStats[player.UserId].Power)
    return PlayerDataModule.PlayerStats[player.UserId]
end

-- 플레이어 데이터 설정하기 (서버 스크립트 간 공유용)
function PlayerDataModule.SetPlayerData(player, newData)
    PlayerDataModule.PlayerStats[player.UserId] = newData
    MainGuiEvent:FireClient(player, newData.Money, newData.Power)
end

return PlayerDataModule
