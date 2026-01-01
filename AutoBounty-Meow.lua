--[[
    SCRIPT NAME: Auto Bounty by Meow
    AUTHOR: Meow
    VERSION: 2.5.0 (Ultimate Speed & Dragon Boost)
    DESCRIPTION: PC Style Skills, Dragon Soru Boost, Anti-Void, Auto Join Team, Speed 350.
]]

--------------------------------------------------------------------------------
-- 1. SERVICES & VARIABLES
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--------------------------------------------------------------------------------
-- 2. SAFETY & UTILITY FUNCTIONS
--------------------------------------------------------------------------------
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[Auto Bounty Error]: " .. tostring(result))
    end
    return success, result
end

local function IsAlive(plr)
    if plr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("HumanoidRootPart") then
        if plr.Character.Humanoid.Health > 0 then
            return true
        end
    end
    return false
end

-- FIX: Bộ lọc nới lỏng để bot bay ngay lập tức
local function IsValidTarget(Enemy)
    if not IsAlive(Enemy) then return false end
    
    local Character = Enemy.Character
    -- 1. Check Safezone/ForceField
    if Character:FindFirstChild("SafeZone") or Character:FindFirstChild("ForceField") then
        return false
    end
    
    -- 2. Check tọa độ (Chống bay ra hư vô)
    local RootPos = Character.HumanoidRootPart.Position
    if RootPos.Y > 11000 or RootPos.Y < -500 or (RootPos).Magnitude > 60000 then
        return false
    end

    return true
end

--------------------------------------------------------------------------------
-- 3. DRAGON SORU & COMBO SYSTEM (FIX KHÔNG DÙNG CHIÊU)
--------------------------------------------------------------------------------
local function DragonSoruBoost(enemyPart)
    pcall(function()
        if not IsAlive(LocalPlayer) then return end
        local Root = LocalPlayer.Character.HumanoidRootPart
        Root.CFrame = CFrame.new(Root.Position, enemyPart.Position)
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        
        Root.CFrame = enemyPart.CFrame
    end)
end

local function ExecuteCombo(Enemy)
    local Setting = getgenv().Setting
    local ComboList = {}

    for weaponType, data in pairs(Setting.Weapons) do
        if data.Enable then
            for skillKey, skillData in pairs(data.Skills) do
                if skillData.Enable then
                    table.insert(ComboList, {
                        Weapon = weaponType,
                        Key = skillKey,
                        Number = skillData.Number,
                        Hold = skillData.HoldTime
                    })
                end
            end
        end
    end

    table.sort(ComboList, function(a, b) return a.Number < b.Number end)

    for _, skill in pairs(ComboList) do
        if not IsValidTarget(Enemy) then break end
        
        DragonSoruBoost(Enemy.Character.HumanoidRootPart)

        local Tool = nil
        for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
            if (skill.Weapon == "Melee" and v:GetAttribute("Melee")) or 
               (skill.Weapon == "Sword" and v.ToolTip == "Sword") or
               (skill.Weapon == "Blox Fruit" and v.ToolTip == "Blox Fruit") or
               (skill.Weapon == "Gun" and v.ToolTip == "Gun") then
                Tool = v
                break
            end
        end

        if Tool then
            if not LocalPlayer.Character:FindFirstChild(Tool.Name) then
                LocalPlayer.Character.Humanoid:EquipTool(Tool)
            end
            VirtualInputManager:SendKeyEvent(true, skill.Key, false, game)
            if skill.Hold > 0 then task.wait(skill.Hold) end
            VirtualInputManager:SendKeyEvent(false, skill.Key, false, game)
        end
        task.wait(0.05)
    end
    
    if Setting["Method Click"]["Click Melee"] then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

--------------------------------------------------------------------------------
-- 4. GLOBAL FIX SYSTEM (CAMERA & MOVEMENT)
--------------------------------------------------------------------------------
local function GlobalFixSystem()
    RunService.Stepped:Connect(function()
        pcall(function()
            if IsAlive(LocalPlayer) then
                if Camera.CameraType ~= Enum.CameraType.Custom then
                    Camera.CameraType = Enum.CameraType.Custom
                end
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
                if LocalPlayer.Character.Humanoid.Sit then LocalPlayer.Character.Humanoid.Sit = false end
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- 5. UI SYSTEM (GIỮ NGUYÊN DỮ LIỆU)
--------------------------------------------------------------------------------
local function CreateStatusUI()
    for _, child in pairs(CoreGui:GetChildren()) do
        if child.Name == "AutoBountyByMeowUI" then child:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "AutoBountyByMeowUI"
    
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.Size = UDim2.new(0, 280, 0, 140)
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "  AUTO BOUNTY BY MEOW"
    Title.TextColor3 = Color3.fromRGB(255, 150, 0)
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1

    local function CreateLabel(y)
        local l = Instance.new("TextLabel", MainFrame)
        l.Position = UDim2.new(0, 15, 0, y)
        l.Size = UDim2.new(1, -30, 0, 25)
        l.Font = Enum.Font.GothamSemibold
        l.TextColor3 = Color3.new(1, 1, 1)
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.BackgroundTransparency = 1
        return l
    end

    local BountyLabel = CreateLabel(45)
    local TimeLabel = CreateLabel(70)
    local StatusLabel = CreateLabel(95)

    task.spawn(function()
        local start = tick()
        while task.wait(1) do
            pcall(function()
                if LocalPlayer:FindFirstChild("leaderstats") then
                    BountyLabel.Text = "💰 Bounty: " .. string.format("%.1fM", LocalPlayer.leaderstats["Bounty/Honor"].Value/1000000)
                end
                local d = tick()-start
                TimeLabel.Text = string.format("⏳ Server Time: %02d:%02d", d/60, d%60)
            end)
        end
    end)
    return StatusLabel
end

local StatusText = CreateStatusUI()

--------------------------------------------------------------------------------
-- 6. MAIN LOGIC (START HUNT - SPEED 300 & FIX FLIGHT)
--------------------------------------------------------------------------------
local function StartAutoBounty()
    local Setting = getgenv().Setting
    GlobalFixSystem()

    -- Tự động chọn phe để kích hoạt kỹ năng
    local TeamName = (Setting["Team"] == "Pirate") and "Pirates" or "Marines"
    repeat 
        task.wait(0.5)
        SafeCall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", TeamName) end)
    until LocalPlayer.Team ~= nil

    task.spawn(function()
        while task.wait(0.5) do
            local FoundTarget = false
            -- Lấy danh sách người chơi và bắt đầu quét mục tiêu
            local AllPlayers = Players:GetPlayers()
            
            for _, Enemy in pairs(AllPlayers) do
                -- Kiểm tra nếu mục tiêu hợp lệ (đã fix không chọn người trong Safezone ở hàm IsValidTarget)
                if Enemy ~= LocalPlayer and IsValidTarget(Enemy) then
                    FoundTarget = true
                    StatusText.Text = "Status: ⚔️ Hunting -> " .. Enemy.Name
                    local HuntStart = tick()
                    
                    repeat
                        task.wait()
                        -- Dừng săn nếu mình chết hoặc địch vào Safezone/thoát game
                        if not IsAlive(LocalPlayer) or not IsValidTarget(Enemy) or not Enemy.Parent then break end

                        -- LOGIC HỒI MÁU (Nếu bạn bật SafeZone Healing trong Setting)
                        if LocalPlayer.Character.Humanoid.Health < Setting.SafeZone.LowHealth then
                            StatusText.Text = "Status: 🏥 Healing..."
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position.X, Setting.SafeZone["Teleport Y"], LocalPlayer.Character.HumanoidRootPart.Position.Z)
                            repeat task.wait(0.5) until LocalPlayer.Character.Humanoid.Health >= Setting.SafeZone.MaxHealth
                            break 
                        end

                        -- DI CHUYỂN ÁP SÁT VỚI TỐC ĐỘ 300 (FIX LỖI KHÔNG BAY)
                        local TargetCF = Enemy.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                        local Dist = (LocalPlayer.Character.HumanoidRootPart.Position - TargetCF.Position).Magnitude
                        
                        -- Ép Tween chạy liên tục mỗi Frame để bot không bao giờ bị khựng
                        TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(Dist/300, Enum.EasingStyle.Linear), {CFrame = TargetCF}):Play()

                        -- Bật Haki nếu chưa bật
                        if not LocalPlayer.Character:FindFirstChild("HasBuso") then 
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") 
                        end
                        
                        -- Tự động tung chiêu khi khoảng cách đủ gần
                        if Dist < 40 or LocalPlayer.PlayerGui.Main.InCombat.Visible then
                            -- Bật tộc V3/V4 nếu có trong Setting
                            if Setting["Race V3"].Enable then VirtualInputManager:SendKeyEvent(true, "T", false, game) end
                            if Setting["Race V4"].Enable and LocalPlayer.PlayerGui.Main.Awakening.Gauge.Size.X.Scale >= 1 then 
                                VirtualInputManager:SendKeyEvent(true, "Y", false, game) 
                            end
                            
                            -- Thực hiện Combo kỹ năng và Dragon Soru
                            ExecuteCombo(Enemy)
                        end

                        -- Chống kẹt một mục tiêu quá lâu (Target Time)
                        if (tick() - HuntStart) > Setting["Target Time"] then break end
                    until not IsValidTarget(Enemy)
                    
                    if FoundTarget then break end -- Sau khi xong 1 người thì quay lại quét danh sách mới
                end
            end

            -- TỰ ĐỘNG ĐỔI SERVER NẾU KHÔNG CÒN AI ĐỂ SĂN
            if not FoundTarget and Setting.Misc.AutoHopServer and not LocalPlayer.PlayerGui.Main.InCombat.Visible then
                StatusText.Text = "Status: 🌎 No Targets. Hopping..."
                SafeCall(function()
                    local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
                    for _, s in pairs(Servers.data) do
                        if s.playing < s.maxPlayers and s.id ~= game.JobId then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                            break
                        end
                    end
                end)
                task.wait(5)
            end
        end
    end)
end


--------------------------------------------------------------------------------
-- 7. EXECUTION
--------------------------------------------------------------------------------
SafeCall(StartAutoBounty)

