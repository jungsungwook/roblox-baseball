local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestPlayerData = ReplicatedStorage.Remote.RequestPlayerData

local PlayerDataModule = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Player").PlayerDataModule)

Players.PlayerAdded:Connect(function(player)
    -- 플레이어가 들어오면 데이터 로드하기
    local data = PlayerDataModule.LoadData(player)
    
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then -- 플레이어가 게임을 나갔을 때
            PlayerDataModule.SaveData(player)
        end
    end)
end)

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message == "!power" then
            local data = PlayerDataModule.GetPlayerData(player)
            if data then
                data.Power = data.Power + 10
                PlayerDataModule.SetPlayerData(player, data)
                print(player.Name .. "의 힘 스탯이 10 증가했습니다. 현재 힘 스탯:", data.Power)
            end
        end
    end)
end)