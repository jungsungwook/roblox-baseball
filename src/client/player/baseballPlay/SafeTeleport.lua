local SafeTeleport = {}

-- 조작 강제 활성화 함수
function SafeTeleport.forceEnableControls()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    -- PlayerModule을 통한 조작 활성화
    spawn(function()
        local success, err = pcall(function()
            local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
            local controls = require(playerModule):GetControls()
            controls:Enable()
            print("[SafeTeleport] 플레이어 조작 강제 활성화")
        end)
        
        if not success then
            warn("[SafeTeleport] 조작 활성화 실패:", err)
        end
    end)
    
    -- StarterGui 설정 복원
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
end

-- 캐릭터 죽음 방지 함수
function SafeTeleport.preventDeath(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        -- 체력을 최대로 설정
        humanoid.Health = humanoid.MaxHealth
        
        -- 죽음 방지 연결
        local deathConnection
        deathConnection = humanoid.Died:Connect(function()
            warn("[SafeTeleport] 캐릭터 죽음 감지, 응급 처치 실행!")
            
            -- 즉시 리스폰 또는 체력 복구
            if humanoid.Parent then
                humanoid.Health = humanoid.MaxHealth
                
                -- 안전한 위치로 즉시 이동
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    humanoidRootPart.Anchored = true
                    character:SetPrimaryPartCFrame(CFrame.new(0, 50, 0)) -- 매우 높은 위치
                    wait(0.5)
                    humanoidRootPart.Anchored = false
                end
            end
            
            deathConnection:Disconnect()
        end)
        
        -- 5초 후 연결 해제
        spawn(function()
            wait(5)
            if deathConnection then 
                deathConnection:Disconnect() 
            end 
        end)
    end
end

-- 안전한 스폰 위치 찾기
function SafeTeleport.findSafeSpawnPosition(Pp)
    local spawnPos
    
    -- 1순위: Pp 관련 스폰 위치
    if Pp and Pp.Parent and Pp.Parent:FindFirstChild("StandABat_Pos") then
        spawnPos = Pp.Parent:FindFirstChild("StandABat_Pos")
    end
    
    -- 2순위: workspace에서 ProximityPrompt 찾기
    if not spawnPos then
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
        
        local proximityPrompt = findProximityPrompt(workspace)
        if proximityPrompt and proximityPrompt.Parent and proximityPrompt.Parent:FindFirstChild("StandABat_Pos") then
            spawnPos = proximityPrompt.Parent:FindFirstChild("StandABat_Pos")
        end
    end
    
    -- 3순위: 기본 스폰 위치들
    if not spawnPos then
        spawnPos = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("StandABat_Pos")
    end
    
    -- 4순위: 비상 스폰 위치 생성
    if not spawnPos then
        spawnPos = Instance.new("Part")
        spawnPos.CFrame = CFrame.new(0, 20, 0) -- 더 높은 위치로 설정
        spawnPos.Anchored = true
        spawnPos.CanCollide = true
        spawnPos.Transparency = 1 -- 보이지 않게
        spawnPos.Size = Vector3.new(10, 1, 10) -- 더 큰 플랫폼
        spawnPos.Parent = workspace
        spawnPos.Name = "EmergencySpawnLocation"
        print("[경고] 비상 스폰 위치를 생성했습니다.")
    end
    
    return spawnPos
end

-- 안전한 CFrame 생성 (Y 좌표 보정)
function SafeTeleport.createSafeCFrame(originalCFrame, minY)
    minY = minY or 15 -- 기본 최소 높이를 15로 증가
    local pos = originalCFrame.Position
    local safeY = math.max(pos.Y, minY)
    
    -- Y 좌표만 조정하고 회전은 유지
    return CFrame.new(pos.X, safeY, pos.Z) * (originalCFrame - originalCFrame.Position)
end

-- 안전한 텔레포트 실행
function SafeTeleport.safeTeleport(character, targetCFrame, callback)
    if not character or not character.PrimaryPart then
        warn("[SafeTeleport] 유효하지 않은 캐릭터입니다.")
        if callback then callback(false) end
        return
    end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    
    -- 캐릭터 상태 안정화
    humanoidRootPart.Anchored = true
    humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    humanoid.PlatformStand = false
    humanoid.Sit = false
    
    -- 죽음 방지 활성화
    SafeTeleport.preventDeath(character)
    
    -- 안전한 CFrame 생성 (더 높은 Y 좌표 사용)
    local safeCFrame = SafeTeleport.createSafeCFrame(targetCFrame, 15)
    
    -- 단계적 텔레포트
    spawn(function()
        -- 1단계: 안전한 중간 지점으로 이동 (Y=20)
        local intermediateCFrame = CFrame.new(0, 20, 0)
        character:SetPrimaryPartCFrame(intermediateCFrame)
        wait(0.5)
        
        -- 2단계: 목표 위치로 이동 (더 높은 Y 좌표)
        character:SetPrimaryPartCFrame(safeCFrame)
        wait(0.5)
        
        -- 3단계: 위치 검증 및 다중 보정
        local maxAttempts = 3
        for attempt = 1, maxAttempts do
            local currentPos = humanoidRootPart.Position
            if currentPos.Y < 10 then
                warn(string.format("[SafeTeleport] 위험한 Y 좌표 감지: %.2f, 보정 시도 %d/%d", currentPos.Y, attempt, maxAttempts))
                local correctedCFrame = CFrame.new(currentPos.X, 20, currentPos.Z)
                character:SetPrimaryPartCFrame(correctedCFrame)
                wait(0.3)
            else
                break
            end
        end
        
                 -- 4단계: 제한적 안전 모니터링 (텔레포트 직후만)
         local safetyConnection
         local monitoringTime = 0
         local maxMonitoringTime = 2 -- 2초로 단축
         local emergencyCount = 0
         local maxEmergencies = 2 -- 최대 2회 응급구조
         
         safetyConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
             monitoringTime = monitoringTime + dt
             
             if humanoidRootPart and humanoidRootPart.Parent and emergencyCount < maxEmergencies then
                 local currentY = humanoidRootPart.Position.Y
                 
                 -- Y 좌표가 5 이하로 떨어지면 즉시 구조 (제한적)
                 if currentY < 5 then
                     emergencyCount = emergencyCount + 1
                     warn(string.format("[SafeTeleport] 응급 구조 실행! Y 좌표: %.2f (횟수: %d/%d)", currentY, emergencyCount, maxEmergencies))
                     humanoidRootPart.Anchored = true
                     humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                     local emergencyPos = humanoidRootPart.Position
                     character:SetPrimaryPartCFrame(CFrame.new(emergencyPos.X, 15, emergencyPos.Z))
                     wait(0.1)
                 end
             end
             
             -- 모니터링 시간 초과, 응급구조 한계 도달, 또는 캐릭터가 사라진 경우 종료
             if monitoringTime >= maxMonitoringTime or emergencyCount >= maxEmergencies or not humanoidRootPart or not humanoidRootPart.Parent then
                 if safetyConnection then
                     safetyConnection:Disconnect()
                     safetyConnection = nil
                 end
             end
         end)
        
                 -- 5단계: 안전 확인 후 고정 해제
         wait(0.5) -- 안정화 시간 단축
         
         -- 모니터링 시스템 완전 정리
         if safetyConnection then
             safetyConnection:Disconnect()
             safetyConnection = nil
         end
         
         if humanoidRootPart and humanoidRootPart.Parent then
             local finalY = humanoidRootPart.Position.Y
             
             -- 안전 여부와 관계없이 일정 시간 후 무조건 해제
             if finalY >= 8 then
                 print(string.format("[SafeTeleport] 안전하게 텔레포트 완료. 최종 Y 좌표: %.2f", finalY))
             else
                 warn(string.format("[SafeTeleport] 안전하지 않은 위치지만 강제 해제. Y 좌표: %.2f", finalY))
             end
             
             -- 무조건 Anchored 해제
             humanoidRootPart.Anchored = false
             
             -- 캐릭터 상태 완전 정리
             humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
             humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
             humanoid.PlatformStand = false
             humanoid.Sit = false
             
             -- 조작 강제 활성화
             SafeTeleport.forceEnableControls()
         end
        
        -- 콜백 실행
        if callback then callback(true) end
    end)
end

return SafeTeleport 