local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local lastDistBindable = ReplicatedStorage:WaitForChild("Bind"):WaitForChild("LastDistBindable")

-- 애니메이션 연결 변수 참조 (StartBaseBall.server.lua에서 정의)
local playerAnimationConnections = _G.playerAnimationConnections or {}
local lastDistance = _G.lastDistance or {}

-- 게임 결과 데이터 저장 (글로벌 변수 사용)
if not _G.gameResults then
    _G.gameResults = {}
end
local gameResults = _G.gameResults

-- 모듈 로드
local PlayerDataModule = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Player").PlayerDataModule)
local RewardModule = require(ServerScriptService:WaitForChild("Modules").RewardModule)
local CustomLeaderboardModule = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Player").CustomLeaderboardModule)

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "EndBaseBallEvent"
RemoteEvent.Parent = ReplicatedStorage:WaitForChild("Remote")

local RemoteEvent2 = Instance.new("RemoteEvent")
RemoteEvent2.Name = "BreakBaseBallEvent"
RemoteEvent2.Parent = ReplicatedStorage:WaitForChild("Remote")

local GameResultEvent = Instance.new("RemoteEvent")
GameResultEvent.Name = "GameResultEvent"
GameResultEvent.Parent = ReplicatedStorage:WaitForChild("Remote")

local RequestGameResultEvent = Instance.new("RemoteEvent")
RequestGameResultEvent.Name = "RequestGameResultEvent"
RequestGameResultEvent.Parent = ReplicatedStorage:WaitForChild("Remote")

RemoteEvent.OnServerEvent:Connect(function(player)
    -- 애니메이션 연결 정리
    if playerAnimationConnections[player] then
        playerAnimationConnections[player]:Disconnect()
        playerAnimationConnections[player] = nil
    end
    
    -- 서버에서 생성한 공 제거
    local ballClone = workspace:FindFirstChild("Baseball_"..player.UserId)
    if ballClone then
        ballClone:Destroy()
    end
    
    -- 클라이언트에서 생성된 공들도 모두 제거
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "HitBaseball" or obj.Name == "ThrownBaseball" then
            obj:Destroy()
        end
    end
    
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- 캐릭터 상태 안정화
    if character.PrimaryPart then
        character.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
        character.PrimaryPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    
    for _, part in pairs(character:GetDescendants()) do
        if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("MeshPart") then
            part.Transparency = 0
        elseif part:IsA("Decal") then
            part.Transparency = 0
        end
    end

    -- 서버에서 계산된 거리 사용 (보안상 안전)
    local playerDistance = lastDistance[player] or 0
    print(string.format("[게임 종료] %s - 서버 계산 거리: %.2f 스터드", player.Name, playerDistance))
    
    if playerDistance > 0 then
        local gameResult = RewardModule.ProcessGameResult(player, playerDistance)
        print(string.format("[게임 결과 생성] %s - 결과 데이터: %s", player.Name, game:GetService("HttpService"):JSONEncode(gameResult)))
        
        -- 플레이어 데이터에 돈 추가
        local success = PlayerDataModule.AddMoney(player, gameResult.moneyReward)
        
        -- 최장 거리 기록 업데이트
        local isNewRecord = PlayerDataModule.UpdateBestDistance(player, playerDistance)
        if isNewRecord then
            print(string.format("[새 기록] %s의 최장 거리 기록 갱신: %.1f 스터드", player.Name, playerDistance))
            -- 커스텀 리더보드에 기록 업데이트 알림
            CustomLeaderboardModule.OnPlayerRecordUpdated(player, playerDistance)
        else
            local playerData = PlayerDataModule.GetPlayerData(player)
            local currentBest = playerData and playerData.BestDistance or 0
            print(string.format("[기록 유지] %s - 현재 기록: %.1f, 기존 최고: %.1f", 
                player.Name, playerDistance, currentBest))
        end
        
        if success then
            -- 게임 결과를 저장해두고 클라이언트가 요청할 때까지 대기
            gameResults[player] = gameResult
            print(string.format("[게임 결과 저장] %s: %.1f 스터드, %d골드 지급", player.Name, playerDistance, gameResult.moneyReward))
        else
            print(string.format("[오류] %s의 돈 지급에 실패했습니다.", player.Name))
        end
    else
        print(string.format("[게임 결과 없음] %s - 거리가 0 이하입니다: %.2f", player.Name, playerDistance))
    end
    
    -- 거리 데이터 초기화
    lastDistance[player] = nil

    lastDistBindable:Fire(player, false)
end)

RemoteEvent2.OnServerEvent:Connect(function(player)
    -- 애니메이션 연결 정리
    if playerAnimationConnections[player] then
        playerAnimationConnections[player]:Disconnect()
        playerAnimationConnections[player] = nil
    end
    
    -- 서버에서 생성한 공 제거
    local ballClone = workspace:FindFirstChild("Baseball_"..player.UserId)
    if ballClone then
        ballClone:Destroy()
    end
    
    -- 클라이언트에서 생성된 공들도 모두 제거
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "HitBaseball" or obj.Name == "ThrownBaseball" then
            obj:Destroy()
        end
    end
    
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- 캐릭터 상태 안정화
    if character.PrimaryPart then
        character.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
        character.PrimaryPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    
    for _, part in pairs(character:GetDescendants()) do
        if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("MeshPart") then
            part.Transparency = 0
        elseif part:IsA("Decal") then
            part.Transparency = 0
        end
    end

    -- 거리에 따른 돈 지급 처리 (Break된 경우에도 보상 지급)
    local playerDistance = lastDistance[player] or 0
    print(string.format("[게임 중단] %s - 서버 계산 거리: %.2f 스터드", player.Name, playerDistance))
    
    if playerDistance > 0 then
        -- Break된 경우 보상을 50% 감소
        local originalReward = RewardModule.CalculateMoneyReward(playerDistance)
        local reducedReward = math.floor(originalReward * 0.5)
        
        local gameResult = {
            distance = playerDistance,
            moneyReward = reducedReward,
            grade = "중단됨",
            gradeColor = Color3.new(1, 0.5, 0), -- 주황색
            message = string.format("게임이 중단되었습니다. %.1f 스터드, %d골드 획득!", playerDistance, reducedReward)
        }
        
        -- 플레이어 데이터에 돈 추가
        local success = PlayerDataModule.AddMoney(player, gameResult.moneyReward)
        
        -- 최장 거리 기록 업데이트 (중단된 경우에도 기록은 갱신)
        local isNewRecord = PlayerDataModule.UpdateBestDistance(player, playerDistance)
        if isNewRecord then
            print(string.format("[새 기록 - 중단] %s의 최장 거리 기록 갱신: %.1f 스터드", player.Name, playerDistance))
            -- 커스텀 리더보드에 기록 업데이트 알림
            CustomLeaderboardModule.OnPlayerRecordUpdated(player, playerDistance)
        else
            local playerData = PlayerDataModule.GetPlayerData(player)
            local currentBest = playerData and playerData.BestDistance or 0
            print(string.format("[기록 유지 - 중단] %s - 현재 기록: %.1f, 기존 최고: %.1f", 
                player.Name, playerDistance, currentBest))
        end
        
        if success then
            -- 게임 결과를 저장해두고 클라이언트가 요청할 때까지 대기
            gameResults[player] = gameResult
            print(string.format("[게임 중단] %s: %.1f 스터드, %d골드 지급 (50% 감소)", player.Name, playerDistance, gameResult.moneyReward))
        else
            print(string.format("[오류] %s의 돈 지급에 실패했습니다.", player.Name))
        end
    end
    
    -- 거리 데이터 초기화
    lastDistance[player] = nil

    lastDistBindable:Fire(player, true)
end)

-- 클라이언트가 게임 결과를 요청할 때 처리
RequestGameResultEvent.OnServerEvent:Connect(function(player)
    print(string.format("[게임 결과 요청] %s가 결과를 요청했습니다.", player.Name))
    
    local gameResult = gameResults[player]
    if gameResult then
        -- 게임 결과 전송
        GameResultEvent:FireClient(player, gameResult)
        -- 전송 후 데이터 정리
        gameResults[player] = nil
        print(string.format("[게임 결과 전송] %s에게 결과 UI 전송", player.Name))
    else
        -- 현재 저장된 게임 결과들을 출력
        local storedResults = {}
        for p, result in pairs(gameResults) do
            table.insert(storedResults, p.Name)
        end
        print(string.format("[경고] %s의 게임 결과 데이터가 없습니다. 현재 저장된 결과: [%s]", player.Name, table.concat(storedResults, ", ")))
    end
end)

-- 플레이어가 나갈 때 데이터 정리
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if gameResults[player] then
        gameResults[player] = nil
    end
end)