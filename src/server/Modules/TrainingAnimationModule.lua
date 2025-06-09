local TrainingAnimationModule = {}

-- 애니메이션 ID들 (추후 애니메이션 생성 시 여기에 ID 추가)
local ANIMATION_IDS = {
    BATTING_STANCE = nil, -- "rbxassetid://애니메이션ID" 형태로 추가
    SWING = nil,          -- "rbxassetid://애니메이션ID" 형태로 추가
    IDLE_TRAINING = nil   -- "rbxassetid://애니메이션ID" 형태로 추가
}

-- 현재 재생 중인 애니메이션 추적
local activeAnimations = {}

-- 애니메이션 로드 및 재생
function TrainingAnimationModule.PlayAnimation(character, animationType)
    if not character or not character:FindFirstChild("Humanoid") then
        warn("캐릭터 또는 Humanoid를 찾을 수 없습니다.")
        return nil
    end
    
    local animationId = ANIMATION_IDS[animationType]
    if not animationId then
        print("애니메이션 ID가 설정되지 않았습니다: " .. tostring(animationType))
        return nil
    end
    
    local humanoid = character.Humanoid
    local animator = humanoid:FindFirstChildOfClass("Animator")
    
    if not animator then
        warn("Animator를 찾을 수 없습니다.")
        return nil
    end
    
    -- 기존 애니메이션 정지
    TrainingAnimationModule.StopAnimation(character)
    
    -- 새 애니메이션 생성 및 로드
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    
    local animationTrack = animator:LoadAnimation(animation)
    
    -- 애니메이션 설정
    animationTrack.Looped = true -- 훈련 애니메이션은 반복
    animationTrack.Priority = Enum.AnimationPriority.Action
    
    -- 애니메이션 재생
    animationTrack:Play()
    
    -- 활성 애니메이션으로 등록
    activeAnimations[character] = animationTrack
    
    print("훈련 애니메이션이 시작되었습니다: " .. animationType)
    return animationTrack
end

-- 애니메이션 정지
function TrainingAnimationModule.StopAnimation(character)
    local animationTrack = activeAnimations[character]
    
    if animationTrack then
        animationTrack:Stop()
        activeAnimations[character] = nil
        print("훈련 애니메이션이 정지되었습니다.")
    end
end

-- 애니메이션 ID 설정 (애니메이션 생성 후 호출)
function TrainingAnimationModule.SetAnimationId(animationType, animationId)
    if ANIMATION_IDS[animationType] ~= nil then
        ANIMATION_IDS[animationType] = animationId
        print("애니메이션 ID가 설정되었습니다:", animationType, "->", animationId)
    else
        warn("존재하지 않는 애니메이션 타입입니다:", animationType)
    end
end

-- 현재 설정된 애니메이션 ID들 확인
function TrainingAnimationModule.GetAnimationIds()
    return ANIMATION_IDS
end

-- 애니메이션이 재생 중인지 확인
function TrainingAnimationModule.IsAnimationPlaying(character)
    return activeAnimations[character] ~= nil
end

-- 모든 애니메이션 정리 (서버 종료 시 또는 플레이어 퇴장 시)
function TrainingAnimationModule.CleanupAnimations()
    for character, animationTrack in pairs(activeAnimations) do
        if animationTrack then
            animationTrack:Stop()
        end
    end
    activeAnimations = {}
end

-- 특정 플레이어의 애니메이션 정리
function TrainingAnimationModule.CleanupPlayerAnimations(character)
    if activeAnimations[character] then
        activeAnimations[character]:Stop()
        activeAnimations[character] = nil
    end
end

return TrainingAnimationModule 