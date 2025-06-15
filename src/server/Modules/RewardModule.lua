local RewardModule = {}

-- 거리에 따른 돈 계산 공식
function RewardModule.CalculateMoneyReward(distance)
    -- 기본 공식: 거리 1 스터드당 1골드, 최소 5골드 보장
    local baseMoney = math.max(math.floor(distance), 5)
    
    -- 거리 구간에 따른 보너스 지급
    local bonus = 0
    
    if distance >= 100 then
        bonus = bonus + 50 -- 100 스터드 이상 시 보너스 50골드
    end
    
    if distance >= 200 then
        bonus = bonus + 100 -- 200 스터드 이상 시 추가 보너스 100골드
    end
    
    if distance >= 300 then
        bonus = bonus + 200 -- 300 스터드 이상 시 추가 보너스 200골드
    end
    
    if distance >= 500 then
        bonus = bonus + 500 -- 500 스터드 이상 시 추가 보너스 500골드
    end
    
    return baseMoney + bonus
end

-- 거리에 따른 성취 등급 계산
function RewardModule.GetPerformanceGrade(distance)
    if distance >= 500 then
        return "전설적", Color3.new(1, 0.8, 0) -- 금색
    elseif distance >= 300 then
        return "뛰어남", Color3.new(0.8, 0.3, 1) -- 보라색
    elseif distance >= 200 then
        return "훌륭함", Color3.new(0.2, 0.8, 1) -- 파란색
    elseif distance >= 100 then
        return "좋음", Color3.new(0.2, 1, 0.2) -- 초록색
    elseif distance >= 50 then
        return "보통", Color3.new(1, 1, 0.2) -- 노란색
    else
        return "아쉬움", Color3.new(0.8, 0.8, 0.8) -- 회색
    end
end

-- 보상 지급 및 결과 데이터 생성
function RewardModule.ProcessGameResult(player, distance)
    local moneyReward = RewardModule.CalculateMoneyReward(distance)
    local grade, gradeColor = RewardModule.GetPerformanceGrade(distance)
    
    return {
        distance = distance,
        moneyReward = moneyReward,
        grade = grade,
        gradeColor = gradeColor,
        message = string.format("%.1f 스터드 날렸습니다! %d골드 획득!", distance, moneyReward)
    }
end

return RewardModule 