local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "StartBaseBallEvent"
RemoteEvent.Parent = ReplicatedStorage:WaitForChild("Remote")

local RemoteEvent2 = Instance.new("RemoteEvent")
RemoteEvent2.Name = "RetireBaseBallEvent"
RemoteEvent2.Parent = ReplicatedStorage:WaitForChild("Remote")

local lastDistance = {}
local lastDistBindable = ReplicatedStorage:WaitForChild("Bind"):WaitForChild("LastDistBindable")
-- 각 플레이어별 애니메이션 연결 관리
local playerAnimationConnections = {}
-- 글로벌 변수로 등록
_G.playerAnimationConnections = playerAnimationConnections
_G.lastDistance = lastDistance -- 거리 데이터도 글로벌로 공유

lastDistBindable.Event:Connect(function(player, breaked)
    
end)

local PlayerDataModule = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Player").PlayerDataModule)

RemoteEvent.OnServerEvent:Connect(function(player, launchDirection, startPosition, arrowX)
    --- 이전에 생성된 공이 있다면 모두 제거
    local oldBall = workspace:FindFirstChild("Baseball_"..player.UserId)
    if oldBall then
        oldBall:Destroy()
    end
    
    --- HitBaseball 이름으로 된 공 찾아서 제거 (클라이언트에서 생성된 공)
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "HitBaseball" or obj.Name == "ThrownBaseball" then
            obj:Destroy()
        end
    end
    
    --- player 캐릭터 안에 있는 BaseballBat 파트를 삭제
    local character = player.Character or player.CharacterAdded:Wait()
    local baseballBat = character:FindFirstChild("BaseballBat")
    if baseballBat then
        baseballBat:Destroy()
    end
    
    local finalPower = PlayerDataModule.GetFinalPower(player)
    local playerData = PlayerDataModule.GetPlayerData(player)
    print(string.format("[파워 계산] %s - 기본 파워: %d, 파워 배수: %d%%, 최종 파워: %.1f", 
        player.Name, playerData.Power or 1, playerData.PowerMultiplier or 0, finalPower))
    
    -- arrowX 디버깅
    print(string.format("[arrowX 디버깅] %s - 받은 arrowX 값: %.3f", player.Name, arrowX))
    
    -- arrowX가 0이면 최소값 보장 (완전히 실패하지 않도록)
    local effectiveArrowX = math.max(arrowX, 0.1) -- 최소 10% 보장
    
    -- 최종 파워에 따른 최대 거리 계산 (예: 1 파워 = 0.1 스터드)
    local maxDistance = finalPower * 0.1 * effectiveArrowX
    print(string.format("[거리 계산] %s - 최종 거리: %.2f 스터드 (파워: %.1f × 0.1 × arrowX: %.3f)", 
        player.Name, maxDistance, finalPower, effectiveArrowX))
    
    lastDistance[player] = maxDistance
    -- 애니메이션 시간 계산 
    local weight = 100
    -- 애니메이션 시간 설정 (최소 1초, 최대 30초)
    local animationTime = math.clamp(maxDistance / weight, 1, 30)

    -- 빠른 구간(80%)과 느린 구간(20%) 설정
    local fastDistance = maxDistance * 0.8
    local slowDistance = maxDistance - fastDistance

    -- 빠른 구간과 느린 구간의 시간 비율 설정 (예: 빠른 구간은 전체 시간의 60%, 느린 구간은 전체 시간의 40%)
    local fastTimeRatio = 0.8
    local slowTimeRatio = 0.2

    -- 빠른 구간과 느린 구간의 실제 시간 계산
    local fastTime = animationTime * fastTimeRatio
    local slowTime = animationTime * slowTimeRatio

    local ballClone = ReplicatedStorage:WaitForChild("Baseball"):Clone()
    ballClone.Parent = workspace
    ballClone.Name = "Baseball_"..player.UserId
    local startTime = tick()
    local alpha = 0
    local character = player.Character or player.CharacterAdded:Wait()
    for _, part in pairs(character:GetDescendants()) do
        if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("MeshPart") then
            part.Transparency = 1
        elseif part:IsA("Decal") then
            part.Transparency = 1
        end
    end

    RemoteEvent:FireClient(player, "Baseball_"..player.UserId, launchDirection, startPosition, maxDistance, animationTime)

    -- 기존 연결 제거
    if playerAnimationConnections[player] then
        playerAnimationConnections[player]:Disconnect()
        playerAnimationConnections[player] = nil
    end

    local animationConnection
    animationConnection = RunService.Heartbeat:Connect(function()
        local elapsedTime = tick() - startTime
        alpha = math.min(elapsedTime / animationTime, 1)

        -- 포물선 궤적 계산
        local height = math.sin(alpha * math.pi) * maxDistance * 0.25
        local distance = alpha * maxDistance

        -- 새로운 위치 계산
        local newPosition = startPosition + launchDirection * distance + Vector3.new(0, height, 0)

        -- 공의 위치 업데이트
        ballClone.CFrame = CFrame.new(newPosition)

        -- 애니메이션 종료 조건
        if alpha >= 1 then
            animationConnection:Disconnect()
            playerAnimationConnections[player] = nil
        end
    end)
    
    -- 플레이어별 애니메이션 연결 저장
    playerAnimationConnections[player] = animationConnection
end)

RemoteEvent2.OnServerEvent:Connect(function(player)
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- 애니메이션 연결 정리
    if playerAnimationConnections[player] then
        playerAnimationConnections[player]:Disconnect()
        playerAnimationConnections[player] = nil
    end
    
    -- 이전에 생성된 공 제거
    local ballClone = workspace:FindFirstChild("Baseball_"..player.UserId)
    if ballClone then
        ballClone:Destroy()
    end
    
    -- HitBaseball 이름으로 된 공 찾아서 제거 (클라이언트에서 생성된 공)
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "HitBaseball" or obj.Name == "ThrownBaseball" then
            obj:Destroy()
        end
    end
    
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

    local baseballBat = character:FindFirstChild("BaseballBat")
    if baseballBat then
        baseballBat:Destroy()
    end
    
    -- 자동 타임아웃 시 보상 없이 종료
    print(string.format("[자동 타임아웃] %s - 보상 없이 게임 종료", player.Name))
    
    -- 거리 데이터 초기화
    lastDistance[player] = nil
end)