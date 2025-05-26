local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local collisionGroupName = "Players"
local NO_COLLISION_GROUP_NAME = "NoCollision"

-- 충돌 그룹이 존재하는지 확인하는 함수
local function doesCollisionGroupExist(groupName)
    for _, name in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
        if name == groupName then
            return true
        end
    end
    return false
end

-- 충돌 그룹이 없으면 새로 등록
if not doesCollisionGroupExist(collisionGroupName) then
    PhysicsService:RegisterCollisionGroup(collisionGroupName)
end

if not doesCollisionGroupExist(NO_COLLISION_GROUP_NAME) then
    PhysicsService:RegisterCollisionGroup(NO_COLLISION_GROUP_NAME)
end

-- 같은 그룹 내의 충돌을 비활성화
PhysicsService:CollisionGroupSetCollidable(collisionGroupName, collisionGroupName, false)
PhysicsService:CollisionGroupSetCollidable(NO_COLLISION_GROUP_NAME, "Default", false)

-- 플레이어 캐릭터의 모든 파츠에 충돌 그룹 적용
local function setCollisionGroup(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = collisionGroupName -- 최신 방식
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(setCollisionGroup)
end)

-- 이미 존재하는 플레이어의 캐릭터에도 적용
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        setCollisionGroup(player.Character)
    end
end
