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
-- 5. UI SYSTEM (GIỮ NGUYÊN DỮ LIỆU + THÊM NÚT HIDE UI)
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

    -- NÚT HIDE UI
    local HideBtn = Instance.new("TextButton", MainFrame)
    HideBtn.Size = UDim2.new(0, 30, 0, 30)
    HideBtn.Position = UDim2.new(1, -35, 0, 5)
    HideBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    HideBtn.Text = "-"
    HideBtn.TextColor3 = Color3.new(1, 1, 1)
    HideBtn.Font = Enum.Font.GothamBold
    HideBtn.TextSize = 20
    Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 5)

    local isHidden = false
    HideBtn.MouseButton1Click:Connect(function()
        isHidden = not isHidden
        if isHidden then
            MainFrame:TweenSize(UDim2.new(0, 280, 0, 40), "Out", "Quart", 0.3, true)
            HideBtn.Text = "+"
        else
            MainFrame:TweenSize(UDim2.new(0, 280, 0, 140), "Out", "Quart", 0.3, true)
            HideBtn.Text = "-"
        end
    end)

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, -40, 0, 35)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "AUTO BOUNTY BY MEOW"
    Title.TextColor3 = Color3.fromRGB(255, 150, 0)
    Title.TextSize = 14
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

    -- Cập nhật dữ liệu liên tục
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
--------------------------------------------------------------------------------
-- 4. GLOBAL FIX SYSTEM (CAMERA & MOVEMENT)
--------------------------------------------------------------------------------
local function GlobalFixSystem()
    RunService.Stepped:Connect(function()
        pcall(function()
            if IsAlive(LocalPlayer) then
                -- FIX CAMERA
                if Camera.CameraType ~= Enum.CameraType.Custom then
                    Camera.CameraType = Enum.CameraType.Custom
                end
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
                
                -- ANTI-SIT
                if LocalPlayer.Character.Humanoid.Sit then 
                    LocalPlayer.Character.Humanoid.Sit = false 
                end

                -- NOCLIP: Cho phép đi xuyên mọi vật cản khi đang đi săn
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end

--------------------------------------------------------------------------------
-- 6. MAIN LOGIC (FIX LỖI COMBAT HOP + TELEPORT Y KHI HOP)
--------------------------------------------------------------------------------
local function StartAutoBounty()
    local Setting = getgenv().Setting
    GlobalFixSystem()

    local TeamName = (Setting["Team"] == "Pirate") and "Pirates" or "Marines"
    repeat 
        task.wait(0.5)
        SafeCall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", TeamName) end)
    until LocalPlayer.Team ~= nil

    task.spawn(function()
        while task.wait(1) do 
            local FoundTarget = false
            
            -- Quét tìm mục tiêu
            for _, Enemy in pairs(Players:GetPlayers()) do
                if Enemy ~= LocalPlayer and IsValidTarget(Enemy) then
                    FoundTarget = true
                    StatusText.Text = "Status: ⚔️ Hunting -> " .. Enemy.Name
                    
                    local BV = Instance.new("BodyVelocity")
                    BV.Velocity = Vector3.new(0, 0, 0)
                    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    BV.Parent = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                    local HuntStart = tick()
                    repeat
                        task.wait()
                        if not IsAlive(LocalPlayer) or not IsValidTarget(Enemy) or not Enemy.Parent then break end

                        if LocalPlayer.Character.Humanoid.Health < Setting.SafeZone.LowHealth then break end

                        local TargetCF = Enemy.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                        local Dist = (LocalPlayer.Character.HumanoidRootPart.Position - TargetCF.Position).Magnitude
                        TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(Dist/300, Enum.EasingStyle.Linear), {CFrame = TargetCF}):Play()

                        if Dist < 50 or LocalPlayer.PlayerGui.Main.InCombat.Visible then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, Enemy.Character.HumanoidRootPart.Position)
                            ExecuteCombo(Enemy)
                        end

                        if (tick() - HuntStart) > Setting["Target Time"] then break end
                    until not IsValidTarget(Enemy)
                    
                    if BV then BV:Destroy() end
                    if FoundTarget then break end
                end
            end

            -- LOGIC HOP SERVER + TELEPORT Y AN TOÀN
            if not FoundTarget and Setting.Misc.AutoHopServer then
                StatusText.Text = "Status: 🔍 No Targets. Checking Combat..."
                task.wait(3) -- Chờ combat ngắn
                
                if not LocalPlayer.PlayerGui.Main.InCombat.Visible then
                    -- TELEPORT Y: Bay lên cao trước khi thoát server
                    StatusText.Text = "Status: 🛫 Flying Up Before Hop..."
                    pcall(function()
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
                            LocalPlayer.Character.HumanoidRootPart.Position.X, 
                            Setting.SafeZone["Teleport Y"], 
                            LocalPlayer.Character.HumanoidRootPart.Position.Z
                        )
                    end)
                    task.wait(1.5) -- Đợi bay lên ổn định rồi mới Hop

                    StatusText.Text = "Status: 🌎 Finding New Server..."
                    
                    local function SafeHop()
                        local Http = game:GetService("HttpService")
                        local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
                        local Success, Result = pcall(function() return Http:JSONDecode(game:HttpGet(Api)) end)
                        
                        if Success and Result and Result.data then
                            for _, s in pairs(Result.data) do
                                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                                    return
                                end
                            end
                        end
                    end
                    SafeHop()
                else
                    StatusText.Text = "Status: 🛡️ In Combat. Stay here..."
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 7. EXECUTION
--------------------------------------------------------------------------------
SafeCall(StartAutoBounty)

