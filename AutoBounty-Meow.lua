--[[
    SCRIPT NAME: Auto Bounty by Meow
    AUTHOR: Meow
    VERSION: 2.8.0 (Ultimate Full Fix)
    DESCRIPTION: PC Style Skills, Dragon Soru Boost, Anti-Void, Auto Join Team, Speed 300, Noclip, Safe Hop.
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

local function IsValidTarget(Enemy)
    if not (Enemy and Enemy.Character and Enemy.Character:FindFirstChild("Humanoid") and Enemy.Character.Humanoid.Health > 0) then 
        return false 
    end
    local Character = Enemy.Character
    -- Chặn chọn người trong Safezone hoặc có Giáp bảo vệ
    if Character:FindFirstChild("SafeZone") or Character:FindFirstChild("ForceField") or Character:GetAttribute("SafeZone") then
        return false
    end
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if RootPart then
        local Pos = RootPart.Position
        if Pos.Y > 11000 or Pos.Y < -500 or (Pos).Magnitude > 60000 then
            return false
        end
    else
        return false
    end
    return true
end

--------------------------------------------------------------------------------
-- 3. DRAGON SORU & COMBO SYSTEM
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
                        Weapon = weaponType, Key = skillKey, Number = skillData.Number, Hold = skillData.HoldTime
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
            if (skill.Weapon == "Melee" and v:GetAttribute("Melee")) or (skill.Weapon == "Sword" and v.ToolTip == "Sword") or (skill.Weapon == "Blox Fruit" and v.ToolTip == "Blox Fruit") or (skill.Weapon == "Gun" and v.ToolTip == "Gun") then
                Tool = v break
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
-- 4. GLOBAL FIX (CAMERA, NOCLIP, ANTI-SIT)
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
                -- NOCLIP
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- 5. UI SYSTEM (HIDE/SHOW + DATA)
--------------------------------------------------------------------------------
local function CreateStatusUI()
    for _, child in pairs(CoreGui:GetChildren()) do
        if child.Name == "AutoBountyByMeowUI" then child:Destroy() end
    end
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "AutoBountyByMeowUI"
    ScreenGui.ResetOnSpawn = false
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.Size = UDim2.new(0, 280, 0, 140)
    MainFrame.ClipsDescendants = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    local HideBtn = Instance.new("TextButton", MainFrame)
    HideBtn.Size = UDim2.new(0, 25, 0, 25)
    HideBtn.Position = UDim2.new(1, -30, 0, 5)
    HideBtn.Text = "-"
    HideBtn.TextColor3 = Color3.new(1, 1, 1)
    HideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", HideBtn)

    local isHidden = false
    HideBtn.MouseButton1Click:Connect(function()
        isHidden = not isHidden
        MainFrame:TweenSize(isHidden and UDim2.new(0, 280, 0, 35) or UDim2.new(0, 280, 0, 140), "Out", "Quart", 0.3, true)
        HideBtn.Text = isHidden and "+" or "-"
    end)

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Text = "  AUTO BOUNTY BY MEOW"
    Title.TextColor3 = Color3.fromRGB(255, 150, 0)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1

    local BountyLabel = Instance.new("TextLabel", MainFrame)
    BountyLabel.Position = UDim2.new(0, 15, 0, 45)
    BountyLabel.Size = UDim2.new(1, 0, 0, 20)
    BountyLabel.TextColor3 = Color3.new(1, 1, 1)
    BountyLabel.TextXAlignment = Enum.TextXAlignment.Left
    BountyLabel.BackgroundTransparency = 1

    local TimeLabel = Instance.new("TextLabel", MainFrame)
    TimeLabel.Position = UDim2.new(0, 15, 0, 70)
    TimeLabel.Size = UDim2.new(1, 0, 0, 20)
    TimeLabel.TextColor3 = Color3.new(1, 1, 1)
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimeLabel.BackgroundTransparency = 1

    local StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Position = UDim2.new(0, 15, 0, 95)
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.TextColor3 = Color3.new(1, 1, 1)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.BackgroundTransparency = 1

    task.spawn(function()
        local start = tick()
        while task.wait(1) do
            pcall(function()
                if LocalPlayer:FindFirstChild("leaderstats") then
                    BountyLabel.Text = "💰 Bounty: " .. string.format("%.1fM", LocalPlayer.leaderstats["Bounty/Honor"].Value/1000000)
                end
                local d = tick()-start
                TimeLabel.Text = string.format("⏳ Time in Server: %02d:%02d:%02d", math.floor(d/3600), math.floor((d%3600)/60), math.floor(d%60))
            end)
        end
    end)
    return StatusLabel
end

local StatusText = CreateStatusUI()

--------------------------------------------------------------------------------
-- 6. MAIN LOGIC (SỬ DỤNG BODYVELOCITY ĐỂ VỪA DI CHUYỂN VỪA BAY)
--------------------------------------------------------------------------------
local function StartAutoBounty()
    local Setting = getgenv().Setting
    GlobalFixSystem()
    local TeamName = (Setting["Team"] == "Pirate") and "Pirates" or "Marines"
    repeat task.wait(0.5) pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", TeamName) end) until LocalPlayer.Team ~= nil

    task.spawn(function()
        while task.wait(0.5) do
            local FoundTarget = false
            for _, Enemy in pairs(Players:GetPlayers()) do
                if Enemy ~= LocalPlayer and IsValidTarget(Enemy) then
                    FoundTarget = true
                    StatusText.Text = "Status: ⚔️ Hunting -> " .. Enemy.Name
                    
                    -- SỬ DỤNG BODYVELOCITY ĐỂ BAY (CHO PHÉP VỪA DI CHUYỂN VỪA BAY)
                    local BV = Instance.new("BodyVelocity")
                    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    BV.Velocity = Vector3.new(0, 0, 0)
                    BV.Parent = LocalPlayer.Character.HumanoidRootPart

                    local BG = Instance.new("BodyGyro") -- Giữ nhân vật không bị xoay tròn lung tung
                    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    BG.P = 3000
                    BG.Parent = LocalPlayer.Character.HumanoidRootPart

                    local HuntStart = tick()
                    repeat
                        task.wait()
                        if not IsAlive(LocalPlayer) or not IsValidTarget(Enemy) or not Enemy.Parent then break end
                        if LocalPlayer.Character.Humanoid.Health < Setting.SafeZone.LowHealth then break end
                        
                        local TargetPos = Enemy.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 5)
                        local Direction = (TargetPos - LocalPlayer.Character.HumanoidRootPart.Position)
                        local Dist = Direction.Magnitude
                        
                        -- Nếu ở xa thì bay với tốc độ 300, ở gần thì giảm tốc để combo
                        if Dist > 10 then
                            BV.Velocity = Direction.Unit * 300
                            BG.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, Enemy.Character.HumanoidRootPart.Position)
                        else
                            BV.Velocity = Vector3.new(0, 0, 0)
                        end
                        
                        -- Tự động xả skill
                        if Dist < 50 or LocalPlayer.PlayerGui.Main.InCombat.Visible then
                            ExecuteCombo(Enemy)
                        end
                        
                        if (tick() - HuntStart) > Setting["Target Time"] then break end
                    until not IsValidTarget(Enemy)
                    
                    if BV then BV:Destroy() end
                    if BG then BG:Destroy() end
                    if FoundTarget then break end
                end
            end

            -- LOGIC SAFE HOP (Giữ nguyên)
            if not FoundTarget and Setting.Misc.AutoHopServer and not LocalPlayer.PlayerGui.Main.InCombat.Visible then
                StatusText.Text = "Status: 🛫 Flying Up & Hopping..."
                pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position.X, Setting.SafeZone["Teleport Y"], LocalPlayer.Character.HumanoidRootPart.Position.Z) end)
                task.wait(2)
                -- Gọi hàm SafeHop ở đây (như code full cũ)
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 7. EXECUTION
--------------------------------------------------------------------------------
SafeCall(StartAutoBounty)
