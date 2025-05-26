local Players = game:GetService("Players")

local function makeInvincible(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge
end

local function ignoreDamage(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.HealthChanged:Connect(function(health)
        if health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        makeInvincible(character)
        ignoreDamage(character)
    end)
end

-- 기존 플레이어에 대해 적용
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- 새로 참여하는 플레이어에 대해 적용
Players.PlayerAdded:Connect(onPlayerAdded)
