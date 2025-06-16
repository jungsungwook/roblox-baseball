local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- PlayerDataModule 가져오기
local PlayerDataModule = require(script.Parent.Modules.Player.PlayerDataModule)
local TrainingAnimationModule = require(script.Parent.Modules.TrainingAnimationModule)

-- 원격 이벤트 생성
local TrainingRemoteEvents = Instance.new("Folder")
TrainingRemoteEvents.Name = "TrainingRemote"
TrainingRemoteEvents.Parent = ReplicatedStorage

local StartTrainingEvent = Instance.new("RemoteEvent")
StartTrainingEvent.Name = "StartTraining"
StartTrainingEvent.Parent = TrainingRemoteEvents

local EndTrainingEvent = Instance.new("RemoteEvent")
EndTrainingEvent.Name = "EndTraining"
EndTrainingEvent.Parent = TrainingRemoteEvents

local DisableMovementEvent = Instance.new("RemoteEvent")
DisableMovementEvent.Name = "DisableMovement"
DisableMovementEvent.Parent = TrainingRemoteEvents

-- 훈련 중인 플레이어들 추적
local trainingPlayers = {}

-- 배트 생성 함수
local function createBaseballBat(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return nil
    end
    
    -- 기존 배트 제거
    local existingBat = character:FindFirstChild("BaseballBat")
    if existingBat then
        existingBat:Destroy()
    end
    
    -- ReplicatedStorage에서 배트 복제
    local baseballBat = ReplicatedStorage:FindFirstChild("BaseballBat")
    if not baseballBat then
        warn("ReplicatedStorage에서 BaseballBat을 찾을 수 없습니다!")
        return nil
    end
    
    local batClone = baseballBat:Clone()
    batClone.Parent = character
    
    -- 도구로 장착
    humanoid:EquipTool(batClone)
    
    print("배트가 " .. character.Name .. "에게 장착되었습니다.")
    return batClone
end

-- 배트 제거 함수
local function removeBaseballBat(character)
    local bat = character:FindFirstChild("BaseballBat")
    if bat then
        bat:Destroy()
        print("배트가 " .. character.Name .. "에서 제거되었습니다.")
    end
end

-- 스윙 애니메이션 재생 함수 (일회성)
local function playSwingAnimation(character)
    if not character or not character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = character.Humanoid
    local animator = humanoid:FindFirstChildOfClass("Animator")
    
    if not animator then
        warn("Animator를 찾을 수 없습니다.")
        return
    end
    
    -- 야구 게임에서 사용하는 스윙 애니메이션 ID (실제 게임에서 가져옴)
    local swingAnimationId = "rbxassetid://133858936023889" -- playBaseball.client.lua에서 가져온 스윙 애니메이션
    
    -- 애니메이션 생성 및 로드
    local animation = Instance.new("Animation")
    animation.AnimationId = swingAnimationId
    
    local animationTrack = animator:LoadAnimation(animation)
    
    -- 애니메이션 설정
    animationTrack.Looped = false -- 스윙은 일회성
    animationTrack.Priority = Enum.AnimationPriority.Action
    
    -- 애니메이션 재생
    animationTrack:Play()
    
    -- 애니메이션 종료 후 자동 정리
    animationTrack.Ended:Connect(function()
        animationTrack:Destroy()
    end)
    
    print("스윙 애니메이션이 재생되었습니다: " .. character.Name)
end

-- 훈련장 찾기 및 프롬프트 설정
local function setupTrainingCages()
    for _, battingCage in pairs(Workspace:GetChildren()) do
        if battingCage.Name == "BattingCage" and battingCage:IsA("Model") then
            local trainMachine = battingCage:FindFirstChild("TrainMachine")
            local holdPos = battingCage:FindFirstChild("hold_pos")
            
            if trainMachine and holdPos then
                local interactPrompt = trainMachine:FindFirstChild("Interact_train")
                
                if interactPrompt and interactPrompt:IsA("ProximityPrompt") then
                    -- 프롬프트 상호작용 연결
                    interactPrompt.Triggered:Connect(function(player)
                        startTraining(player, battingCage, holdPos, trainMachine)
                    end)
                end
            end
        end
    end
end

-- 훈련 시작
function startTraining(player, battingCage, holdPos, trainMachine)
    if trainingPlayers[player.UserId] then
        return -- 이미 훈련 중
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    -- 훈련 중인 플레이어의 프롬프트 비활성화
    local interactPrompt = trainMachine:FindFirstChild("Interact_train")
    if interactPrompt then
        interactPrompt.Enabled = false
    end
    
    -- 훈련 상태 설정
    trainingPlayers[player.UserId] = {
        battingCage = battingCage,
        holdPos = holdPos,
        trainMachine = trainMachine,
        character = character,
        powerIncreaseTimer = 0,
        baseballLaunchTimer = 0,
        animationTrack = nil, -- 추후 애니메이션 추가용
        bat = nil, -- 배트 참조
        swingAnimationTimer = 0 -- 스윙 애니메이션 타이머
    }
    
    -- 배트 생성 및 장착
    local bat = createBaseballBat(character)
    if bat then
        trainingPlayers[player.UserId].bat = bat
    end
    
    -- 훈련 애니메이션 시작 (애니메이션이 설정되어 있을 경우)
    local animationTrack = TrainingAnimationModule.PlayAnimation(character, "BATTING_STANCE")
    if animationTrack then
        trainingPlayers[player.UserId].animationTrack = animationTrack
    end
    
    -- 플레이어 위치 고정 (Y축 오프셋 추가하여 바닥에 묻히지 않도록)
    local humanoidRootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    local hipHeight = humanoid and humanoid.HipHeight or 0
    
    -- HumanoidRootPart의 크기를 고려한 오프셋 계산
    local rootPartSize = humanoidRootPart.Size
    local yOffset = rootPartSize.Y / 2 + hipHeight + 0.5 -- 추가 여유 공간
    
    -- 캐릭터 방향을 180도 회전시켜서 애니메이션과 맞춤
    local rotatedCFrame = holdPos.CFrame * CFrame.Angles(0, math.pi, 0) -- Y축 기준 180도 회전
    
    -- 타석에서 살짝 뒤쪽으로 이동 (회전된 방향 기준으로 뒤로 2스터드)
    local backwardOffset = rotatedCFrame.LookVector * -2 -- LookVector의 반대 방향으로 2스터드
    local finalPosition = rotatedCFrame.Position + backwardOffset + Vector3.new(0, yOffset, 0)
    
    humanoidRootPart.CFrame = CFrame.new(finalPosition, finalPosition + rotatedCFrame.LookVector)
    humanoidRootPart.Anchored = true
    
    -- 클라이언트에 움직임 제한 및 UI 표시 요청
    DisableMovementEvent:FireClient(player, true)
    StartTrainingEvent:FireClient(player)
    
    print(player.Name .. "이(가) 훈련을 시작했습니다.")
end

-- 훈련 종료
function endTraining(player)
    local trainingData = trainingPlayers[player.UserId]
    if not trainingData then
        return
    end
    
    local character = trainingData.character
    if character and character:FindFirstChild("HumanoidRootPart") then
        -- 위치 고정 해제
        character.HumanoidRootPart.Anchored = false
        
        -- 애니메이션 정지
        TrainingAnimationModule.StopAnimation(character)
        if trainingData.animationTrack then
            trainingData.animationTrack:Stop()
        end
        
        -- 배트 제거
        removeBaseballBat(character)
    end
    
    -- 프롬프트 다시 활성화
    local interactPrompt = trainingData.trainMachine:FindFirstChild("Interact_train")
    if interactPrompt then
        interactPrompt.Enabled = true
    end
    
    -- 클라이언트에 움직임 제한 해제 및 UI 제거 요청
    DisableMovementEvent:FireClient(player, false)
    EndTrainingEvent:FireClient(player)
    
    -- 훈련 상태 제거
    trainingPlayers[player.UserId] = nil
    
    print(player.Name .. "이(가) 훈련을 종료했습니다.")
end

-- 야구공 발사
local function launchBaseball(trainMachine, targetPosition)
    local baseball = ReplicatedStorage:FindFirstChild("Baseball")
    if not baseball then
        warn("ReplicatedStorage에서 Baseball을 찾을 수 없습니다!")
        return
    end
    
    local ballClone = baseball:Clone()
    ballClone.Parent = Workspace
    ballClone.CFrame = trainMachine.CFrame + trainMachine.CFrame.LookVector * 2
    
    -- 타겟 위치로 던지기
    local direction = (targetPosition - ballClone.Position).Unit
    local distance = (targetPosition - ballClone.Position).Magnitude
    
    -- 트윈으로 부드러운 이동
    local tweenInfo = TweenInfo.new(
        math.min(distance * 0.02, 2), -- 최대 2초
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(ballClone, tweenInfo, {
        Position = targetPosition
    })
    
    tween:Play()
    
    -- 공 제거 (3초 후)
    game:GetService("Debris"):AddItem(ballClone, 3)
end

-- 훈련 루프 (매 프레임 실행)
RunService.Heartbeat:Connect(function(deltaTime)
    for userId, trainingData in pairs(trainingPlayers) do
        local player = Players:GetPlayerByUserId(userId)
        if not player or not player.Character then
            trainingPlayers[userId] = nil
            continue
        end
        
        -- 파워 증가 타이머 (5초마다)
        trainingData.powerIncreaseTimer = trainingData.powerIncreaseTimer + deltaTime
        if trainingData.powerIncreaseTimer >= 5 then
            trainingData.powerIncreaseTimer = 0
            
            -- 파워 스탯 증가 (TrainingMultiplier 적용)
            local playerData = PlayerDataModule.GetPlayerData(player)
            if playerData then
                local basePowerIncrease = 1
                local trainingMultiplier = tonumber(playerData.TrainingMultiplier) or 1
                local actualIncrease = math.floor(basePowerIncrease * trainingMultiplier)
                
                -- 최소 1은 보장
                actualIncrease = math.max(actualIncrease, 1)
                
                playerData.Power = (tonumber(playerData.Power) or 0) + actualIncrease
                PlayerDataModule.SetPlayerData(player, playerData)
                
                if trainingMultiplier > 1 then
                    print(string.format("%s의 파워가 %d 증가했습니다! (기본: %d × 훈련 효율: %.1fx = %d) 현재 파워: %d", 
                        player.Name, actualIncrease, basePowerIncrease, trainingMultiplier, actualIncrease, tonumber(playerData.Power) or 0))
                else
                    print(string.format("%s의 파워가 %d 증가했습니다! 현재 파워: %d", 
                        player.Name, actualIncrease, tonumber(playerData.Power) or 0))
                end
            end
        end
        
        -- 야구공 발사 타이머 (2초마다 발사)
        trainingData.baseballLaunchTimer = trainingData.baseballLaunchTimer + deltaTime
        if trainingData.baseballLaunchTimer >= 2 then
            trainingData.baseballLaunchTimer = 0
            
            local character = trainingData.character
            if character and character:FindFirstChild("HumanoidRootPart") then
                launchBaseball(trainingData.trainMachine, character.HumanoidRootPart.Position)
            else
                -- 캐릭터가 없으면 훈련 종료 (리스폰 등의 경우)
                endTraining(player)
            end
        end
        
        -- 스윙 애니메이션 타이머 (3초마다 스윙 애니메이션 재생)
        trainingData.swingAnimationTimer = trainingData.swingAnimationTimer + deltaTime
        if trainingData.swingAnimationTimer >= 3 then
            trainingData.swingAnimationTimer = 0
            
            local character = trainingData.character
            if character then
                -- 스윙 애니메이션 재생 (일회성)
                playSwingAnimation(character)
            end
        end
    end
end)

-- 클라이언트에서 훈련 종료 요청 처리
EndTrainingEvent.OnServerEvent:Connect(function(player)
    endTraining(player)
end)

-- 플레이어가 나갈 때 훈련 상태 정리
Players.PlayerRemoving:Connect(function(player)
    if trainingPlayers[player.UserId] then
        local trainingData = trainingPlayers[player.UserId]
        if trainingData.character then
            TrainingAnimationModule.CleanupPlayerAnimations(trainingData.character)
            removeBaseballBat(trainingData.character)
        end
        
        -- 프롬프트 다시 활성화
        local interactPrompt = trainingData.trainMachine:FindFirstChild("Interact_train")
        if interactPrompt then
            interactPrompt.Enabled = true
        end
        
        trainingPlayers[player.UserId] = nil
    end
end)

-- 게임 시작 시 훈련장 설정
setupTrainingCages()

-- 플레이어 캐릭터 변경 시 훈련 상태 정리
Players.PlayerAdded:Connect(function(player)
    player.CharacterRemoving:Connect(function(character)
        if trainingPlayers[player.UserId] then
            local trainingData = trainingPlayers[player.UserId]
            
            -- 프롬프트 다시 활성화
            local interactPrompt = trainingData.trainMachine:FindFirstChild("Interact_train")
            if interactPrompt then
                interactPrompt.Enabled = true
            end
            
            -- 애니메이션 정리
            TrainingAnimationModule.CleanupPlayerAnimations(character)
            
            -- 배트 제거
            removeBaseballBat(character)
            
            -- 클라이언트 정리
            DisableMovementEvent:FireClient(player, false)
            EndTrainingEvent:FireClient(player)
            
            -- 훈련 상태 제거
            trainingPlayers[player.UserId] = nil
            
            print(player.Name .. "이(가) 캐릭터 변경으로 인해 훈련이 종료되었습니다.")
        end
    end)
end)

-- 새로운 훈련장이 추가될 경우를 대비한 이벤트
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "BattingCage" and child:IsA("Model") then
        wait(1) -- 모든 자식 요소가 로드될 때까지 대기
        local trainMachine = child:FindFirstChild("TrainMachine")
        local holdPos = child:FindFirstChild("hold_pos")
        
        if trainMachine and holdPos then
            local interactPrompt = trainMachine:FindFirstChild("Interact_train")
            
            if interactPrompt and interactPrompt:IsA("ProximityPrompt") then
                interactPrompt.Triggered:Connect(function(player)
                    startTraining(player, child, holdPos, trainMachine)
                end)
            end
        end
    end
end) 