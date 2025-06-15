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
                -- 훈련 가중치 적용 (기본 10 + 가중치 적용)
                local basePowerGain = 10
                local actualPowerGain = basePowerGain * data.TrainingMultiplier
                data.Power = data.Power + actualPowerGain
                PlayerDataModule.SetPlayerData(player, data)
                print(player.Name .. "의 훈련 완료! 힘 스탯이 " .. actualPowerGain .. " 증가했습니다. (가중치: " .. data.TrainingMultiplier .. "x) 현재 힘 스탯:", data.Power)
            end
        elseif message == "!money" then
            -- 테스트용 돈 지급 명령어
            local data = PlayerDataModule.GetPlayerData(player)
            if data then
                data.Money = data.Money + 100
                PlayerDataModule.SetPlayerData(player, data)
                print(player.Name .. "의 돈이 100 증가했습니다. 현재 돈:", data.Money)
            end
        end
    end)
end)