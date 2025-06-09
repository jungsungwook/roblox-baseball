-- 애니메이션 설정 스크립트
-- 애니메이션이 생성되면 이곳에서 ID를 설정하세요

local TrainingAnimationModule = require(script.Parent.Modules.TrainingAnimationModule)

--[[
애니메이션을 추가하려면 아래 주석을 해제하고 실제 애니메이션 ID로 교체하세요.

예시:
TrainingAnimationModule.SetAnimationId("BATTING_STANCE", "rbxassetid://123456789")
TrainingAnimationModule.SetAnimationId("SWING", "rbxassetid://987654321") 
TrainingAnimationModule.SetAnimationId("IDLE_TRAINING", "rbxassetid://111222333")

애니메이션 타입들:
- BATTING_STANCE: 타석에서 대기하는 자세
- SWING: 배트를 휘두르는 동작 (현재는 게임 플레이용 스윙 애니메이션을 직접 사용)
- IDLE_TRAINING: 훈련 중 기본 자세

주의: 스윙 애니메이션은 현재 게임 플레이에서 사용하는 애니메이션(rbxassetid://133858936023889)을 
직접 사용하고 있으므로 별도로 설정할 필요가 없습니다.
--]]

-- 현재 설정된 애니메이션 ID들 출력
print("=== 훈련 시스템 애니메이션 설정 ===")
local animationIds = TrainingAnimationModule.GetAnimationIds()
for animationType, animationId in pairs(animationIds) do
    if animationId then
        print(animationType .. ": " .. animationId)
    else
        print(animationType .. ": 설정되지 않음")
    end
end
print("================================")

--[[
사용법:
1. Roblox Studio에서 애니메이션을 생성합니다.
2. 애니메이션을 Roblox에 업로드하고 Asset ID를 받습니다.
3. 위의 주석 처리된 코드를 해제하고 실제 ID로 교체합니다.
4. 게임을 실행하면 훈련 시 해당 애니메이션이 재생됩니다.
--]] 