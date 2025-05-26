local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bindableEvent = Instance.new("BindableEvent")
bindableEvent.Name = "StandAtBatEvent"
bindableEvent.Parent = ReplicatedStorage:WaitForChild("Bind")
local hideConnection

local function hideCharacterAndTools(character)
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 1
            elseif part:IsA("Tool") then
                for _, toolPart in ipairs(part:GetDescendants()) do
                    if toolPart:IsA("BasePart") or toolPart:IsA("Decal") or toolPart:IsA("Texture") then
                        toolPart.Transparency = 1
                    end
                end
            end
        end
    end
end

local function showCharacterAndTools(character)
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 0
            elseif part:IsA("Tool") then
                for _, toolPart in ipairs(part:GetDescendants()) do
                    if toolPart:IsA("BasePart") or toolPart:IsA("Decal") or toolPart:IsA("Texture") then
                        toolPart.Transparency = 0
                    end
                end
            end
        end
    end
end

local function findProximityPrompt(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("ProximityPrompt") and child.Name == "StandABat_ProximityPrompt" then
            return child
        end
        local result = findProximityPrompt(child)
        if result then return result end
    end
    return nil
end

local function waitForProximityPrompt()
    local cnt = 0
    while true do
        cnt = cnt + 1
        if cnt > 10 then
            warn("ProximityPrompt을 찾을 수 없습니다.")
            return
        end
        local ProximityPrompt = findProximityPrompt(game.Workspace)
        if ProximityPrompt then
            return ProximityPrompt
        end
        wait(1)  -- 1초마다 재시도
    end
end

local ProximityPrompt = waitForProximityPrompt()

ProximityPrompt.Triggered:Connect(function(player)
    if player == LocalPlayer then
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= LocalPlayer then
                hideCharacterAndTools(otherPlayer.Character)
            end
        end
        player.Character:SetPrimaryPartCFrame(ProximityPrompt.Parent:FindFirstChild("StandABat_Pos").CFrame)
        ProximityPrompt.Enabled = false
        local bowler
        if ProximityPrompt.Parent:FindFirstChild("TargetBowler") then
            bowler = ProximityPrompt.Parent:FindFirstChild("TargetBowler").Value
        end
        bindableEvent:Fire(bowler, ProximityPrompt)
    end
end)