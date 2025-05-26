local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local lastDistBindable = ReplicatedStorage:WaitForChild("Bind"):WaitForChild("LastDistBindable")

-- 애니메이션 연결 변수 참조 (StartBaseBall.server.lua에서 정의)
local playerAnimationConnections = _G.playerAnimationConnections or {}

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "EndBaseBallEvent"
RemoteEvent.Parent = ReplicatedStorage:WaitForChild("Remote")

local RemoteEvent2 = Instance.new("RemoteEvent")
RemoteEvent2.Name = "BreakBaseBallEvent"
RemoteEvent2.Parent = ReplicatedStorage:WaitForChild("Remote")

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

    lastDistBindable:Fire(player, true)
end)