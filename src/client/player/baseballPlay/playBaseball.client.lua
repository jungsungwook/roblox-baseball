local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local bindableEvent = ReplicatedStorage:WaitForChild("Bind"):WaitForChild("StandAtBatEvent")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StandAtBatEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("BaseBallEnimEvent")
local Pp
local target_arrow
local target_bowler
local moveConnection
local inputConnection
local isMoving = false
local arrowSpeed = 1
local ballClone
local PhysicsService = game:GetService("PhysicsService")
local StartBaseBallEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("StartBaseBallEvent")
local EndBaseBallEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("EndBaseBallEvent")
local BreakBaseBallEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("BreakBaseBallEvent")
local TransitionEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("TransitionRemoteEvent")
local TeleportService = game:GetService("TeleportService")
local gameEnded = false -- 게임 종료 여부를 전역으로 추적

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

local function showLoadingScreen(show, message)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local existingScreen = playerGui:FindFirstChild("LoadingScreen")
    
    if show then
        if existingScreen then
            existingScreen:Destroy()
        end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "LoadingScreen"
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 10 -- 다른 GUI보다 앞에 표시
        screenGui.Parent = playerGui
        
        -- 배경 블러 효과 (어두운 배경 + 반투명)
        local background = Instance.new("Frame")
        background.Name = "Background"
        background.Size = UDim2.new(1, 0, 1, 0)
        background.BackgroundColor3 = Color3.new(0.05, 0.05, 0.08) -- 어두운 청색 계열
        background.BackgroundTransparency = 1  -- 시작은 투명하게 설정
        background.BorderSizePixel = 0
        background.Parent = screenGui
        
        -- 블러 효과를 위한 블러 프레임
        local blurEffect = Instance.new("Frame")
        blurEffect.Name = "BlurEffect"
        blurEffect.Size = UDim2.new(1, 0, 1, 0)
        blurEffect.BackgroundTransparency = 1
        blurEffect.BackgroundColor3 = Color3.new(1, 1, 1)
        blurEffect.BorderSizePixel = 0
        blurEffect.ZIndex = 0
        blurEffect.Parent = screenGui
        
        -- 중앙 콘텐츠 패널
        local contentPanel = Instance.new("Frame")
        contentPanel.Name = "ContentPanel"
        contentPanel.Size = UDim2.new(0.5, 0, 0.3, 0)
        contentPanel.Position = UDim2.new(0.25, 0, 0.35, 0)
        contentPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
        contentPanel.BackgroundTransparency = 1 -- 시작은 투명하게, 애니메이션으로 불투명해짐
        contentPanel.BorderSizePixel = 0
        contentPanel.Parent = screenGui
        
        -- 콘텐츠 패널에 그라데이션 효과 추가
        local uiGradient = Instance.new("UIGradient")
        uiGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.2, 0.3)),
            ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.2))
        })
        uiGradient.Rotation = 45
        uiGradient.Parent = contentPanel
        
        -- 콘텐츠 패널에 둥근 모서리 효과 추가
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 12)
        uiCorner.Parent = contentPanel
        
        -- 로고 이미지 (야구공 이미지)
        local logoImage = Instance.new("ImageLabel")
        logoImage.Name = "LogoImage"
        logoImage.Size = UDim2.new(0.2, 0, 0.4, 0)
        logoImage.Position = UDim2.new(0.4, 0, 0.1, 0)
        logoImage.BackgroundTransparency = 1
        logoImage.Image = "rbxassetid://15489576404" -- 야구공 이미지 (적절한 이미지 ID로 변경 필요)
        logoImage.ImageTransparency = 1
        logoImage.Parent = contentPanel
        
        -- 로딩 텍스트
        local loadingText = Instance.new("TextLabel")
        loadingText.Name = "LoadingText"
        loadingText.Size = UDim2.new(0.8, 0, 0.2, 0)
        loadingText.Position = UDim2.new(0.1, 0, 0.6, 0)
        loadingText.BackgroundTransparency = 1
        loadingText.TextColor3 = Color3.new(1, 1, 1)
        loadingText.TextSize = 24
        loadingText.Font = Enum.Font.GothamBold
        loadingText.Text = message or "로딩 중..."
        loadingText.TextTransparency = 1
        loadingText.Parent = contentPanel
        
        -- 진행 바 배경
        local progressBarBg = Instance.new("Frame")
        progressBarBg.Name = "ProgressBarBg"
        progressBarBg.Size = UDim2.new(0.8, 0, 0.08, 0)
        progressBarBg.Position = UDim2.new(0.1, 0, 0.85, 0)
        progressBarBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.25)
        progressBarBg.BackgroundTransparency = 1
        progressBarBg.BorderSizePixel = 0
        progressBarBg.Parent = contentPanel
        
        -- 진행 바 배경에 둥근 모서리 효과 추가
        local progressBarCorner = Instance.new("UICorner")
        progressBarCorner.CornerRadius = UDim.new(0, 6)
        progressBarCorner.Parent = progressBarBg
        
        -- 진행 바 채우기
        local progressBarFill = Instance.new("Frame")
        progressBarFill.Name = "ProgressBarFill"
        progressBarFill.Size = UDim2.new(0, 0, 1, 0) -- 시작은 0 너비
        progressBarFill.BackgroundColor3 = Color3.new(0.3, 0.7, 1) -- 파란색 계열
        progressBarFill.BackgroundTransparency = 1
        progressBarFill.BorderSizePixel = 0
        progressBarFill.Parent = progressBarBg
        
        -- 진행 바 채우기에 둥근 모서리 효과 추가
        local progressFillCorner = Instance.new("UICorner")
        progressFillCorner.CornerRadius = UDim.new(0, 6)
        progressFillCorner.Parent = progressBarFill
        
        -- 진행 바 채우기에 그라데이션 효과 추가
        local progressGradient = Instance.new("UIGradient")
        progressGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0.3, 0.7, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0.5, 0.8, 1))
        })
        progressGradient.Parent = progressBarFill
        
        -- 애니메이션 효과를 위한 함수
        local function animateUI()
            -- 배경 페이드 인 (완전 불투명하게 설정)
            local bgTween = TweenService:Create(background, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0
            })
            bgTween:Play()
            
            -- 콘텐츠 패널 페이드 인 (완전 불투명하게 설정)
            local panelTween = TweenService:Create(contentPanel, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0,
                Position = UDim2.new(0.25, 0, 0.35, 0)
            })
            panelTween:Play()
            
            -- 로고 애니메이션
            local logoTween = TweenService:Create(logoImage, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                ImageTransparency = 0,
                Position = UDim2.new(0.4, 0, 0.1, 0)
            })
            logoTween:Play()
            
            -- 텍스트 페이드 인
            local textTween = TweenService:Create(loadingText, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0
            })
            textTween:Play()
            
            -- 진행 바 배경 페이드 인
            local barBgTween = TweenService:Create(progressBarBg, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.2
            })
            barBgTween:Play()
            
            -- 진행 바 채우기 페이드 인
            local barFillTween = TweenService:Create(progressBarFill, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0
            })
            barFillTween:Play()
            
            -- 진행 바 애니메이션
            spawn(function()
                for i = 0, 100, 1 do
                    progressBarFill.Size = UDim2.new(i/100, 0, 1, 0)
                    wait(0.025) -- 전체 애니메이션 시간 조절
                end
            end)
            
            -- 로고 회전 애니메이션
            spawn(function()
                local rotationTweenInfo = TweenInfo.new(
                    2, -- 회전 시간
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.InOut,
                    -1, -- 무한 반복
                    true -- 왕복 (앞뒤로 회전)
                )
                
                local rotationGoal = {}
                rotationGoal.Rotation = 10 -- 10도 회전
                
                local rotationTween = TweenService:Create(logoImage, rotationTweenInfo, rotationGoal)
                rotationTween:Play()
            end)
        end
        
        -- UI 애니메이션 실행
        animateUI()
        
        return screenGui
    else
        if existingScreen then
            -- 페이드 아웃 효과를 위한 함수
            local function animateOut()
                -- 배경 페이드 아웃
                local bgTween = TweenService:Create(existingScreen.Background, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    BackgroundTransparency = 1
                })
                bgTween:Play()
                
                -- 콘텐츠 패널 페이드 아웃
                if existingScreen:FindFirstChild("ContentPanel") then
                    local contentPanel = existingScreen.ContentPanel
                    local panelTween = TweenService:Create(contentPanel, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0.25, 0, 0.4, 0)
                    })
                    panelTween:Play()
                    
                    -- 로고 페이드 아웃
                    if contentPanel:FindFirstChild("LogoImage") then
                        local logoTween = TweenService:Create(contentPanel.LogoImage, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                            ImageTransparency = 1
                        })
                        logoTween:Play()
                    end
                    
                    -- 텍스트 페이드 아웃
                    if contentPanel:FindFirstChild("LoadingText") then
                        local textTween = TweenService:Create(contentPanel.LoadingText, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                            TextTransparency = 1
                        })
                        textTween:Play()
                    end
                    
                    -- 진행 바 페이드 아웃
                    if contentPanel:FindFirstChild("ProgressBarBg") then
                        local barBgTween = TweenService:Create(contentPanel.ProgressBarBg, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                            BackgroundTransparency = 1
                        })
                        barBgTween:Play()
                        
                        if contentPanel.ProgressBarBg:FindFirstChild("ProgressBarFill") then
                            local barFillTween = TweenService:Create(contentPanel.ProgressBarBg.ProgressBarFill, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                BackgroundTransparency = 1
                            })
                            barFillTween:Play()
                        end
                    end
                end
            end
            
            -- 페이드 아웃 애니메이션 실행
            animateOut()
            
            -- 애니메이션 완료 후 GUI 제거
            wait(0.8)
            existingScreen:Destroy()
        end
    end
end

local function showOtherPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = player.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("MeshPart") then
                        part.Transparency = 0
                    elseif part:IsA("Decal") then
                        part.Transparency = 0
                    end
                end
            end
        end
    end
end

local function setNoCollision(character, state)
    if state then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                PhysicsService:SetPartCollisionGroup(part, "NoCollision")
            end
        end
    else
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                PhysicsService:SetPartCollisionGroup(part, "Players")
            end
        end
    end
end

local function UserControl(active)
    local player = Players.LocalPlayer
    local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
    local controls = require(playerModule):GetControls()

    if active then
        controls:Enable()
    else
        controls:Disable()
    end
end

local function resetCamera()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
    camera.CFrame = CFrame.new(0, 0, 0)
end

local function removeGui()
    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local existingGui = playerGui:FindFirstChild("BaseballPlayScreenGui")
    if existingGui then
        existingGui:Destroy()
    end

    -- 모든 연결 해제
    if moveConnection then
        moveConnection:Disconnect()
        moveConnection = nil
    end

    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end

    isMoving = false
end

local checkpoints = {10, 100, 1000, 2000, 3000, 5000, 10000} -- 거리 지점 설정
local placedCheckpoints = {} -- 중복 생성을 방지
local function createCheckpoints(startPosition, launchDirection, maxDistance)
    local function calculateHeight(d, maxDistance)
        local t = d / maxDistance -- 현재 거리의 진행률 (0~1)
        return math.sin(t * math.pi) * (maxDistance * 0.25)
    end

    for _, checkpoint in ipairs(checkpoints) do
        if checkpoint <= maxDistance then
            -- 정확한 높이 계산
            local checkpointHeight = calculateHeight(checkpoint, maxDistance)

            -- 체크포인트 마커 생성
            local marker = Instance.new("Part")
            marker.Name = tostring(checkpoint) .. " Studs"
            marker.Size = Vector3.new(1, 50000, 50000) -- 크기 설정
            marker.Transparency = 1
            marker.CFrame = CFrame.new(startPosition + launchDirection * checkpoint + Vector3.new(0, checkpointHeight, 0))
            -- -45도 회전
            marker.CFrame = marker.CFrame * CFrame.Angles(0, math.rad(-45), 0)
            marker.Position = startPosition + launchDirection * checkpoint + Vector3.new(0, checkpointHeight, 0)
            marker.Anchored = true
            marker.CanCollide = false
            marker.Parent = workspace

            local decal = Instance.new("Decal")
            decal.Texture = "rbxassetid://106213091335281" -- 체크포인트 이미지
            decal.Face = Enum.NormalId.Left
            decal.Transparency = 0.5
            decal.Parent = marker

            placedCheckpoints[checkpoint] = true
        end
    end
end

local function removeCheckpoints()
    for _, checkpoint in ipairs(checkpoints) do
        if placedCheckpoints[checkpoint] then
            local marker = workspace:FindFirstChild(tostring(checkpoint) .. " Studs")
            if marker then
                marker:Destroy()
            end
        end
    end
end

local function launchBall(launchDirection, startPosition, maxDistance, animationTime)
    -- ReplicatedStorage > BaseballLaunchScreenGui 를 복제하여 UI 생성
    local guiClone = ReplicatedStorage:WaitForChild("BaseballLaunchScreenGui"):Clone()
    guiClone.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    local guiText = guiClone:WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("TextLabel")
    local leaveButton = guiClone:WaitForChild("LeaveFrame"):WaitForChild("TextButton")
    
    -- 스폰 위치 안전하게 가져오기
    local spawnPos
    if Pp and Pp.Parent and Pp.Parent:FindFirstChild("StandABat_Pos") then
        spawnPos = Pp.Parent:FindFirstChild("StandABat_Pos")
    else
        -- 기본 스폰 위치 찾기 (ProximityPrompt 찾기)
        local proximityPrompt = findProximityPrompt(workspace)
        if proximityPrompt and proximityPrompt.Parent and proximityPrompt.Parent:FindFirstChild("StandABat_Pos") then
            spawnPos = proximityPrompt.Parent:FindFirstChild("StandABat_Pos")
        else
            -- 기본 스폰 위치를 찾을 수 없는 경우 기본 스폰 위치 사용
            spawnPos = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("StandABat_Pos")
            if not spawnPos then
                -- 최후의 수단으로 원점 사용
                spawnPos = Instance.new("Part")
                spawnPos.CFrame = CFrame.new(0, 10, 0)
                spawnPos.Anchored = true
                spawnPos.CanCollide = true
                spawnPos.Parent = workspace
                spawnPos.Name = "EmergencySpawnLocation"
            end
        end
    end

    -- 시작 시간 저장
    local startTime = tick()

    -- alpha를 공유 변수로 선언
    local alpha = 0
    local alphaDistance = 0

    local distance = 0 

    -- 빠른 구간(70%)과 느린 구간(30%) 설정
    local fastDistance = maxDistance * 0.7
    local slowDistance = maxDistance - fastDistance

    -- 빠른 구간과 느린 구간의 시간 비율 설정 (예: 빠른 구간은 전체 시간의 30%, 느린 구간은 전체 시간의 70%)
    local fastTimeRatio = 0.3
    local slowTimeRatio = 0.7

    -- 빠른 구간과 느린 구간의 실제 시간 계산
    local fastTime = animationTime * fastTimeRatio
    local slowTime = animationTime * slowTimeRatio

    createCheckpoints(startPosition, launchDirection, maxDistance)

    -- 애니메이션 루프
    local animationConnection
    animationConnection = RunService.Heartbeat:Connect(function()
        local elapsedTime = tick() - startTime
        alpha = math.min(elapsedTime / animationTime, 1)

        if alpha <= fastTimeRatio then
            -- 빠른 구간 (0~80% 거리까지)
            local fastAlpha = alpha / fastTimeRatio -- 0~1 사이로 정규화
            alphaDistance = fastAlpha * fastDistance -- 빠른 구간 거리만큼 이동
        else
            -- 느린 구간 (80%~100%)
            local slowAlpha = (alpha - fastTimeRatio) / slowTimeRatio -- 0~1 사이로 정규화
            slowAlpha = math.clamp(slowAlpha, 0, 1)
    
            -- easing 효과 추가 (부드러운 감속)
            local easedSlowAlpha = math.sin(slowAlpha * math.pi * 0.5) -- ease-out 효과
    
            alphaDistance = fastDistance + easedSlowAlpha * slowDistance
        end

        -- 포물선 궤적 계산
        local height = math.sin(alpha * math.pi) * maxDistance * 0.25
        distance = alphaDistance -- 현재 이동한 거리 표시용으로 사용
        guiText.Text = string.format("%.2f Studs", distance)

        -- 새로운 위치 계산
        local newPosition = startPosition + launchDirection * alphaDistance + Vector3.new(0, height, 0)

        -- 공의 위치 업데이트
        ballClone.CFrame = CFrame.new(newPosition)

        -- 애니메이션 종료 조건
        if alpha >= 1 then
            animationConnection:Disconnect()
        end
    end)

    -- 카메라 및 캐릭터 처리 (기존 코드와 동일)
    Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    local character = game.Players.LocalPlayer.Character
    setNoCollision(character, true)

    for _, part in pairs(character:GetDescendants()) do
        if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("MeshPart") then
            part.Transparency = 1
        elseif part:IsA("Decal") then
            part.Transparency = 1
        end
    end

    -- 플레이어 위치를 공과 동기화
    local characterSync
    local bounced = false
    
    characterSync = RunService.Heartbeat:Connect(function()
        -- 게임이 이미 종료된 경우 아무것도 하지 않음
        if gameEnded then
            return
        end
        
        if alpha >= 1 then
            -- 게임 종료 플래그 설정
            gameEnded = true
            
            -- 플레이어 캐릭터는 공이 떨어지는 동안 현재 위치에 고정
            character:WaitForChild("HumanoidRootPart").Anchored = true
            
            -- 공의 최종 위치 계산 및 플레이어 고정
            local finalPosition = Vector3.new(
                ballClone.Position.X,
                math.max(3, ballClone.Position.Y),
                ballClone.Position.Z
            )
            character:SetPrimaryPartCFrame(CFrame.new(finalPosition))
            
            -- 공에 물리효과 적용 (앵커 해제, 충돌 활성화)
            ballClone.Anchored = false
            ballClone.CanCollide = true
            
            -- 공에 질량 및 중력 설정 추가
            ballClone.CustomPhysicalProperties = PhysicalProperties.new(
                1, -- 밀도
                0.3, -- 마찰
                0.5, -- 탄성
                1, -- 무게
                100 -- 마찰무게
            )
            
            -- 공에 초기 속도를 주어 더 자연스럽게 낙하하도록 설정
            local initialVelocity = Vector3.new(0, -10, 0)  -- 초기 속도는 아래쪽으로 설정
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
            bodyVelocity.Velocity = initialVelocity
            bodyVelocity.P = 1250
            bodyVelocity.Parent = ballClone
            
            -- 0.2초 후 BodyVelocity 제거하여 자연스러운 물리효과 적용
            delay(0.2, function()
                if bodyVelocity and bodyVelocity.Parent then
                    bodyVelocity:Destroy()
                end
            end)
            
            -- 카메라를 플레이어 위치에 고정하되 공을 바라보도록 설정
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            
            -- 공이 바닥에 닿을 때까지 대기 (최대 3초)
            local startWaitTime = tick()
            local ballLanded = false
            
            -- 공이 바닥에 닿는 동안 카메라가 공을 따라가도록 설정
            local cameraFollowBall = RunService.RenderStepped:Connect(function()
                if ballClone and ballClone.Parent then
                    -- 카메라 위치 설정 (공 뒤쪽 약간 위에서 공을 내려다보는 각도)
                    local offset = Vector3.new(-5, 5, -5) -- 공의 뒤쪽 위에서 보는 위치
                    local cameraPos = ballClone.Position + offset
                    workspace.CurrentCamera.CFrame = CFrame.lookAt(cameraPos, ballClone.Position)
                end
            end)
            
            -- 공이 바닥에 닿는 것을 감지하는 함수
            local touchedGround = false
            local touchConn = ballClone.Touched:Connect(function(part)
                if not touchedGround and part:IsA("BasePart") and part.Name == "Baseplate" or part.Name:find("Ground") or part.Name:find("Floor") then
                    touchedGround = true
                    
                    -- 효과음 재생
                    local sound = Instance.new("Sound")
                    sound.SoundId = "rbxassetid://9125573021" -- 공이 바닥에 닿는 효과음
                    sound.Volume = 1
                    sound.Parent = ballClone
                    sound:Play()
                    
                    -- 땅에 부딪히는 파티클 효과
                    local hitEffect = Instance.new("ParticleEmitter")
                    hitEffect.Color = ColorSequence.new(Color3.new(0.8, 0.8, 0.8))
                    hitEffect.Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.1),
                        NumberSequenceKeypoint.new(1, 0.5)
                    })
                    hitEffect.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    hitEffect.Speed = NumberRange.new(5, 10)
                    hitEffect.Lifetime = NumberRange.new(0.5, 1)
                    hitEffect.SpreadAngle = Vector2.new(0, 180)
                    hitEffect.Acceleration = Vector3.new(0, -10, 0)
                    hitEffect.Rate = 100
                    hitEffect.Rotation = NumberRange.new(0, 360)
                    hitEffect.RotSpeed = NumberRange.new(-90, 90)
                    hitEffect.Parent = ballClone
                    
                    -- 0.2초 동안만 파티클 방출 후 중지
                    delay(0.2, function()
                        hitEffect.Enabled = false
                    end)
                end
            end)
            
            -- 공이 바닥에 닿을 때까지 대기하는 루프
            local maxWaitTime = 3 -- 최대 3초까지만 대기
            while (tick() - startWaitTime < maxWaitTime) and not ballLanded do
                if ballClone.Position.Y <= 0.5 then
                    ballLanded = true
                end
                wait(0.1)
            end
            
            -- 카메라 팔로우 연결 해제
            if cameraFollowBall then
                cameraFollowBall:Disconnect()
            end
            
            -- 터치 이벤트 연결 해제
            if touchConn then
                touchConn:Disconnect()
            end
            
            -- 추가 대기시간 (공이 바닥에 닿은 후 잠시 더 지켜볼 수 있도록)
            wait(1)
            
            -- 로딩 화면 표시
            local loadingScreen = showLoadingScreen(true, "목적지로 이동 중...")
            wait(0.7)  -- 로딩 화면이 완전히 표시될 때까지 대기
            
            -- 공 제거 및 체크포인트 제거
            if ballClone and ballClone.Parent then
                -- 바디 벨로시티가 아직 있다면 제거
                local bv = ballClone:FindFirstChild("BodyVelocity")
                if bv then bv:Destroy() end
                
                ballClone:Destroy()
                ballClone = nil
            end
            
            -- workspace에서 HitBaseball이나 ThrownBaseball 이름을 가진 모든 공을 찾아 제거
            local hitBall = workspace:FindFirstChild("HitBaseball")
            if hitBall then
                hitBall:Destroy()
            end
            
            local thrownBall = workspace:FindFirstChild("ThrownBaseball")
            if thrownBall then
                thrownBall:Destroy()
            end
            
            removeCheckpoints()
            
            -- 스폰 지점으로 텔레포트 시작
            local camera = workspace.CurrentCamera
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = spawnPos.CFrame
            
            -- 텔레포트 과정 시작
            wait(0.5)
            
            -- 1단계: 먼저 캐릭터를 원점 근처로 이동
            character:SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
            wait(0.5)
            
            -- 2단계: 텔레포트 전 추가 대기 시간
            wait(1.5)
            
            -- 3단계: 최종 목적지로 이동
            character:SetPrimaryPartCFrame(spawnPos.CFrame)
            wait(0.3)
            
            EndBaseBallEvent:FireServer()
            
            -- 캐릭터 위치를 원래대로 복원
            setNoCollision(character, false)
            for _, part in pairs(character:GetDescendants()) do
                if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("MeshPart") then
                    part.Transparency = 0
                elseif part:IsA("Decal") then
                    part.Transparency = 0
                end
            end

            if guiClone then
                guiClone:Destroy()
            end
            
            resetCamera()
            UserControl(true)
            
            -- Pp가 존재하고 유효한지 확인
            if Pp and typeof(Pp) == "Instance" and Pp:IsA("ProximityPrompt") then
                Pp.Enabled = true
            end
            
            character:WaitForChild("HumanoidRootPart").Anchored = false
            
            -- 로딩 화면 제거
            showLoadingScreen(false)
            
            characterSync:Disconnect()
        else 
            -- 게임 진행 중 (공이 날아가는 중)
            if ballClone and character and character.PrimaryPart and not gameEnded then
                -- 공의 위치를 따라가되 Y 좌표가 0 이하로 내려가지 않도록 방지
                local ballPos = ballClone.Position
                local safeY = math.max(ballPos.Y, 3)  -- 바닥보다 충분히 위에 위치하도록
                local safePosition = Vector3.new(ballPos.X, safeY, ballPos.Z)
                
                -- 캐릭터 위치 갱신
                character:SetPrimaryPartCFrame(CFrame.new(safePosition))
            end
        end
    end)

    -- 버튼 클릭 이벤트 설정
    leaveButton.MouseButton1Click:Connect(function()
        -- 게임 종료 플래그 설정 (공을 더 이상 따라가지 않도록)
        gameEnded = true
        
        -- 플레이어를 현재 위치에 고정
        character:WaitForChild("HumanoidRootPart").Anchored = true
        
        -- 현재 위치 안전하게 유지 (Y좌표가 바닥보다 위에 있도록)
        if character and character.PrimaryPart then
            local currentPos = character.PrimaryPart.Position
            local safePosition = Vector3.new(currentPos.X, math.max(currentPos.Y, 3), currentPos.Z)
            character:SetPrimaryPartCFrame(CFrame.new(safePosition))
        end
        
        -- 로딩 화면 표시
        local loadingScreen = showLoadingScreen(true, "스폰 위치로 이동 중...")
        wait(0.7) -- 로딩 화면이 완전히 표시될 때까지 대기
        
        -- 연결 해제 및 정리
        if characterSync then
            characterSync:Disconnect()
            characterSync = nil
        end
        
        if animationConnection then
            animationConnection:Disconnect()
            animationConnection = nil
        end
        
        -- GUI 정리
        if guiClone then
            guiClone:Destroy()
        end
        
        -- 공 제거 (모든 가능한 공을 확인하고 삭제)
        if ballClone and ballClone.Parent then
            ballClone:Destroy()
            ballClone = nil
        end
        
        -- workspace에서 HitBaseball이나 ThrownBaseball 이름을 가진 모든 공을 찾아 제거
        local hitBall = workspace:FindFirstChild("HitBaseball")
        if hitBall then
            hitBall:Destroy()
        end
        
        local thrownBall = workspace:FindFirstChild("ThrownBaseball")
        if thrownBall then
            thrownBall:Destroy()
        end
        
        -- 체크포인트 패널 제거
        removeCheckpoints()

        -- 캐릭터 투명도 복원
        setNoCollision(character, false)
        for _, part in pairs(character:GetDescendants()) do
            if (part:IsA("BasePart") and part.Name ~= "HumanoidRootPart") or part:IsA("MeshPart") then
                part.Transparency = 0
            elseif part:IsA("Decal") then
                part.Transparency = 0
            end
        end

        -- 카메라 및 컨트롤 설정
        resetCamera()
        UserControl(true)
        
        -- Pp가 존재하고 유효한지 확인
        if Pp and typeof(Pp) == "Instance" and Pp:IsA("ProximityPrompt") then
            Pp.Enabled = true
        end
        
        -- 안전한 스폰 위치 찾기
        local spawnPos
        if Pp and Pp.Parent and Pp.Parent:FindFirstChild("StandABat_Pos") then
            spawnPos = Pp.Parent:FindFirstChild("StandABat_Pos")
        else
            local proximityPrompt = findProximityPrompt(workspace)
            if proximityPrompt and proximityPrompt.Parent and proximityPrompt.Parent:FindFirstChild("StandABat_Pos") then
                spawnPos = proximityPrompt.Parent:FindFirstChild("StandABat_Pos")
            else
                spawnPos = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("StandABat_Pos")
                if not spawnPos then
                    spawnPos = Instance.new("Part")
                    spawnPos.CFrame = CFrame.new(0, 10, 0)
                    spawnPos.Anchored = true
                    spawnPos.CanCollide = true
                    spawnPos.Parent = workspace
                    spawnPos.Name = "EmergencySpawnLocation"
                end
            end
        end
        
        -- 단계적 텔레포트 실행
        -- 1단계: 원점으로 이동
        character:SetPrimaryPartCFrame(CFrame.new(0, 10, 0))
        wait(0.5)
        
        -- 2단계: 추가 대기 시간
        wait(1.5)
        
        -- 3단계: 최종 목적지로 이동
        character:SetPrimaryPartCFrame(spawnPos.CFrame)
        wait(0.3)
        
        -- 플레이어의 위치 고정 해제
        character:WaitForChild("HumanoidRootPart").Anchored = false
        
        -- 로딩 화면 제거
        showLoadingScreen(false)
    end)
end

local function hit(arrowX)
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://133858936023889"
    local dance = character:WaitForChild("Humanoid"):LoadAnimation(anim)
    
    local hitMarkerConnection
    local SwingEndMarkerConnection
    local batPosConnection
    hitMarkerConnection = dance:GetMarkerReachedSignal("Hit"):Connect(function()
        dance:AdjustSpeed(0.01)
        wait(0.01)
        showOtherPlayers()
        
        -- 이전에 던져진 공 제거
        if workspace:FindFirstChild("ThrownBaseball") then
            workspace:WaitForChild("ThrownBaseball"):Destroy()
        end
        
        -- 이전에 맞은 공이 있다면 제거
        if workspace:FindFirstChild("HitBaseball") then
            workspace:FindFirstChild("HitBaseball"):Destroy()
        end
        
        -- 새 공 생성
        ballClone = ReplicatedStorage:WaitForChild("Baseball"):Clone()
        ballClone.Name = "HitBaseball"
        ballClone.Parent = workspace
        
        local bat = character:FindFirstChild("BaseballBat")
        if bat and bat:FindFirstChild("bat") and bat.bat:FindFirstChild("hitat_1") then
            local hitPoint = bat.bat.hitat_1
            ballClone.Position = hitPoint.WorldPosition

            -- 공이 배트를 계속 따라다니도록 RunService 업데이트
            batPosConnection = RunService.Heartbeat:Connect(function()
                if ballClone and hitPoint then
                    ballClone.Position = hitPoint.WorldPosition
                else
                    batPosConnection:Disconnect()
                end
            end)
        end

        hitMarkerConnection:Disconnect()
    end)

    SwingEndMarkerConnection = dance:GetMarkerReachedSignal("SwingEnd"):Connect(function()
        if batPosConnection then
            batPosConnection:Disconnect()
        end
        dance:AdjustSpeed(1)
        SwingEndMarkerConnection:Disconnect()
        -- 발사 방향 계산
        local launchDirection = (target_bowler:GetPivot().Position - ballClone.Position).Unit
        launchDirection = Vector3.new(launchDirection.X, launchDirection.Y * 0.5 + 0.3, launchDirection.Z).Unit

        -- 시작 위치 저장
        local startPosition = ballClone.Position

        StartBaseBallEvent:FireServer(
            launchDirection,
            startPosition,
            1-arrowX
        )
    end)

    local camera = workspace.CurrentCamera

    local cameraPos = Pp.Parent:FindFirstChild("CameraPos_2")
    if cameraPos then
        local fovValue = cameraPos:FindFirstChild("FieldOfView")
        local targetFOV = fovValue and fovValue:IsA("NumberValue") and fovValue.Value or 70
        local targetCFrame = CFrame.lookAt(cameraPos.CFrame.Position, character:WaitForChild("BaseballBat").Handle.Position)

        local tweenInfo = TweenInfo.new(
            0.5, -- 애니메이션 지속 시간 (초)
            Enum.EasingStyle.Quad, -- 애니메이션 스타일
            Enum.EasingDirection.Out -- 애니메이션 방향
        )

        local cameraTween = TweenService:Create(camera, tweenInfo, {
            CFrame = targetCFrame,
            FieldOfView = targetFOV
        })
        
        cameraTween:Play()
    end
    
    dance:Play()
end

local function createPlayGui()
    removeGui() -- GUI 중복 생성 방지

    local guiClone = ReplicatedStorage:WaitForChild("BaseballPlayScreenGui"):Clone()
    guiClone.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    local frame = guiClone:WaitForChild("Frame")

    local function createZone(color, size, position)
        local zone = Instance.new("Frame")
        zone.Size = size
        zone.Position = position
        zone.BackgroundColor3 = color
        zone.BorderSizePixel = 0
        zone.Parent = frame
        return zone
    end

    createZone(Color3.new(1, 0, 0), UDim2.new(0.02, 0, 1, 0), UDim2.new(0, 0, 0, 0))
    createZone(Color3.new(0, 1, 0), UDim2.new(0.2, 0, 1, 0), UDim2.new(0.02, 0, 0, 0))
    createZone(Color3.new(1, 0.5, 0), UDim2.new(0.2, 0, 1, 0), UDim2.new(0.22, 0, 0, 0))
    createZone(Color3.new(1, 0, 0), UDim2.new(0.2, 0, 1, 0), UDim2.new(0.42, 0, 0, 0))
    createZone(Color3.new(1, 0, 0), UDim2.new(0.2, 0, 1, 0), UDim2.new(0.62, 0, 0, 0))
    createZone(Color3.new(1, 0, 0), UDim2.new(0.2, 0, 1, 0), UDim2.new(0.82, 0, 0, 0))

    local arrow = Instance.new("Frame")
    arrow.Size = UDim2.new(0.01, 0, 1.2, 0)
    arrow.Position = UDim2.new(1, 0, -0.1, 0)
    arrow.BackgroundColor3 = Color3.new(1, 1, 1)
    arrow.BorderSizePixel = 0
    arrow.Parent = frame

    return arrow
end

local function moveArrow(arrow)
    isMoving = true
    local startTime = tick()

    moveConnection = RunService.Heartbeat:Connect(function()
        if not isMoving then
            moveConnection:Disconnect()
            moveConnection = nil
            return
        end

        local elapsedTime = tick() - startTime
        local progress = (elapsedTime % arrowSpeed) / arrowSpeed
        arrow.Position = UDim2.new(0.98 - progress * 0.98, 0, -0.1, 0)

        if arrow.Position.X.Scale < 0.02 then
            isMoving = false
            removeGui()
            
            -- 게임 종료 플래그 설정
            gameEnded = true
            
            -- 플레이어 현재 위치 고정
            local character = Players.LocalPlayer.Character
            if character and character.PrimaryPart then
                character.PrimaryPart.Anchored = true
                
                -- 현재 위치 안전하게 유지
                local currentPos = character.PrimaryPart.Position
                local safePosition = Vector3.new(currentPos.X, math.max(currentPos.Y, 3), currentPos.Z)
                character:SetPrimaryPartCFrame(CFrame.new(safePosition))
            end
            
            -- 로딩 화면 표시
            local loadingScreen = showLoadingScreen(true, "스폰 위치로 이동 중...")
            -- 로딩 화면이 완전히 표시될 때까지 잠시 대기
            wait(0.7)
            
            -- 체크포인트 패널 제거
            removeCheckpoints()
            
            resetCamera()
            UserControl(true)
            setNoCollision(Players.LocalPlayer.Character, false)
            
            -- Pp가 존재하고 유효한지 확인
            if Pp and typeof(Pp) == "Instance" and Pp:IsA("ProximityPrompt") then
                Pp.Enabled = true
            end
            
            showOtherPlayers()

            local RetireBaseBallEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("RetireBaseBallEvent")
            RetireBaseBallEvent:FireServer()
            
            -- 약간의 대기 후 로딩 화면 제거
            wait(1)
            showLoadingScreen(false)
        end
    end)
end

local function runPlayGui(arrow)
    isMoving = true
    moveArrow(arrow)

    local function checkTiming()
        local arrowX = arrow.Position.X.Scale
        if arrowX < 0.22 and arrowX >= 0.02 then
            return true
        elseif arrowX > 0.22 and arrowX <= 0.42 then
            return true
        else
            return false
        end
    end

    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end

    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Space and not gameProcessed then
            local success = checkTiming()
            
            isMoving = false
            removeGui()

            if inputConnection then
                inputConnection:Disconnect()
                inputConnection = nil
            end
            hit(arrow.Position.X.Scale)
        end
    end)
end

local function launchPart(startPosition, direction, speed)
    runPlayGui(target_arrow)

    local part = ReplicatedStorage:WaitForChild("Baseball"):Clone()
    part.Name = "ThrownBaseball"
    part.Position = startPosition
    part.Anchored = true
    part.CanCollide = false
    part.Parent = workspace

    local velocity = direction.Unit * speed
    local gravity = Vector3.new(0, -9.8, 0)
    local elapsedTime = 0

    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsedTime = elapsedTime + dt
        local displacement = velocity * elapsedTime + 0.5 * gravity * elapsedTime^2
        part.Position = startPosition + displacement
        velocity = velocity + gravity * dt

        if part.Position.Y <= 0 then
            part.Position = Vector3.new(part.Position.X, 0, part.Position.Z)
            part:Destroy()
            target_bowler:WaitForChild("Baseball").Handle.Transparency = 0
            connection:Disconnect()
        end
    end)
end

StartBaseBallEvent.OnClientEvent:Connect(function(ballName, launchDirection, startPosition, maxDistance, animationTime)
    local ball = workspace:FindFirstChild(ballName)
    ball.Transparency = 1
    launchBall(launchDirection, startPosition, maxDistance, animationTime)
end)


bindableEvent.Event:Connect(function(bowler, ProximityPrompt)
    -- 게임 종료 플래그 초기화
    gameEnded = false
    
    -- 이전 게임의 공이 남아있는지 확인하고 제거
    local existingBall = workspace:FindFirstChild("HitBaseball")
    if existingBall then
        existingBall:Destroy()
    end
    
    -- 투구된 공도 확인하고 제거
    local thrownBall = workspace:FindFirstChild("ThrownBaseball")
    if thrownBall then
        thrownBall:Destroy()
    end
    
    StandAtBatEvent:FireServer()
    -- local player = Players.LocalPlayer
    -- local character = player.Character or player.CharacterAdded:Wait()
    -- local batClone = ReplicatedStorage:WaitForChild("BaseballBat"):Clone()
    -- batClone.Parent = character
    -- character:WaitForChild("Humanoid"):EquipTool(batClone)

    target_bowler = bowler
    Pp = ProximityPrompt
    removeGui()
    target_arrow = createPlayGui()

    UserControl(false)
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    local cameraPos = ProximityPrompt.Parent:FindFirstChild("CameraPos_1")

    if cameraPos then
        local fovValue = cameraPos:FindFirstChild("FieldOfView")
        workspace.CurrentCamera.FieldOfView = fovValue and fovValue:IsA("NumberValue") and fovValue.Value or 70
        workspace.CurrentCamera.CFrame = CFrame.lookAt(cameraPos.CFrame.Position, bowler:GetPivot().Position)
    end

    wait(1)

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://106740046458787"
    local dance = bowler:WaitForChild("Humanoid"):LoadAnimation(anim)

    local markerConnection
    markerConnection = dance:GetMarkerReachedSignal("Throw"):Connect(function()
        bowler:WaitForChild("Baseball").Handle.Transparency = 1
        local angle = math.rad(134)
        local direction = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), angle) * Vector3.new(1, 0.5, 0)
        launchPart(bowler:GetPivot().Position, direction, 40)
    end)

    dance:Play()
    dance.Stopped:Wait()
    markerConnection:Disconnect()
end)