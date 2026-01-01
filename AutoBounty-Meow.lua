--[[
    SCRIPT NAME: Auto Bounty by Meow (ULTIMATE EDITION)
    FEATURES: Tween 300, Noclip, Aim Lock, Smart Time Hunting, Super Hop.
]]

--------------------------------------------------------------------------------
-- 1. SERVICES & GLOBAL VARIABLES
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

--------------------------------------------------------------------------------
-- 2. UTILITY FUNCTIONS
--------------------------------------------------------------------------------
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success, result
end

local function IsAlive(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild("HumanoidRootPart")
end

local function IsValidTarget(Enemy)
    if not IsAlive(Enemy) then return false end
    
    -- Lọc Level +/- 400
    local MyLevel = LocalPlayer.Data.Level.Value
    local EnemyLevel = Enemy.Data.Level.Value
    if math.abs(MyLevel - EnemyLevel) > 400 then return false end

    local Character = Enemy.Character
    if Character:FindFirstChild("SafeZone") or Character:FindFirstChild("ForceField") or Character:GetAttribute("SafeZone") then
        return false
    end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if RootPart then
        local Pos = RootPart.Position
        if Pos.Y > 11000 or Pos.Y < -500 then return false end
    else
        return false
    end
    return true
end

--------------------------------------------------------------------------------
-- 3. COMBAT SYSTEM (DRAGON SORU + CONFIG COMBO)
--------------------------------------------------------------------------------
local function DragonSoruBoost(enemyPart)
    pcall(function()
        if not IsAlive(LocalPlayer) then return end
        local Root = LocalPlayer.Character.HumanoidRootPart
        Root.CFrame = CFrame.new(Root.Position, enemyPart.Position)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
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
                        Weapon = weaponType, Key = skillKey, 
                        Number = skillData.Number or 0, Hold = skillData.HoldTime or 0
                    })
                end
            end
        end
    end
    table.sort(ComboList, function(a, b) return a.Number < b.Number end)

    for _, skill in pairs(ComboList) do
        if not IsValidTarget(Enemy) or not LocalPlayer.PlayerGui.Main.InCombat.Visible then break end
        DragonSoruBoost(Enemy.Character.HumanoidRootPart)
        
        local Tool = nil
        for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
            if (skill.Weapon == "Melee" and v:GetAttribute("Melee")) or (skill.Weapon == "Sword" and v.ToolTip == "Sword") or (skill.Weapon == "Blox Fruit" and v.ToolTip == "Blox Fruit") or (skill.Weapon == "Gun" and v.ToolTip == "Gun") then
                Tool = v break
            end
        end
        if not Tool then Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool") end

        if Tool then
            if not LocalPlayer.Character:FindFirstChild(Tool.Name) then LocalPlayer.Character.Humanoid:EquipTool(Tool) end
            VirtualInputManager:SendKeyEvent(true, skill.Key, false, game)
            if skill.Hold > 0 then task.wait(skill.Hold) end
            VirtualInputManager:SendKeyEvent(false, skill.Key, false, game)
            task.wait(0.15)
        end
    end
    if Setting["Method Click"]["Click Melee"] then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.1)
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
                if Camera.CameraType ~= Enum.CameraType.Custom then Camera.CameraType = Enum.CameraType.Custom end
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
                if LocalPlayer.Character.Humanoid.Sit then LocalPlayer.Character.Humanoid.Sit = false end
                -- NOCLIP (ÉP BUỘC CHO TWEEN)
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- 5. UI SYSTEM (DATA + HIDE BUTTON)
--------------------------------------------------------------------------------
local function CreateStatusUI()
    for _, v in pairs(CoreGui:GetChildren()) do if v.Name == "MeowUI" then v:Destroy() end end
    local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "MeowUI"
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 280, 0, 140); MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); MainFrame.ClipsDescendants = true
    Instance.new("UICorner", MainFrame)

    local HideBtn = Instance.new("TextButton", MainFrame)
    HideBtn.Size = UDim2.new(0, 25, 0, 25); HideBtn.Position = UDim2.new(1, -30, 0, 5)
    HideBtn.Text = "-"; HideBtn.TextColor3 = Color3.new(1,1,1); HideBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    
    local isHidden = false
    HideBtn.MouseButton1Click:Connect(function()
        isHidden = not isHidden
        MainFrame:TweenSize(isHidden and UDim2.new(0, 280, 0, 35) or UDim2.new(0, 280, 0, 140), "Out", "Quart", 0.3, true)
        HideBtn.Text = isHidden and "+" or "-"
    end)

    local StatusLabel = Instance.new("TextLabel", MainFrame)
    StatusLabel.Size = UDim2.new(1, -20, 0, 30); StatusLabel.Position = UDim2.new(0, 10, 0, 95)
    StatusLabel.TextColor3 = Color3.new(1,1,1); StatusLabel.BackgroundTransparency = 1; StatusLabel.TextXAlignment = "Left"
    StatusLabel.Text = "Status: Initializing..."

    return StatusLabel
end
local StatusText = CreateStatusUI()

--------------------------------------------------------------------------------
-- 6. MAIN LOGIC (SMART HUNTING SYSTEM)
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
                    local HuntStart = tick()
                    local CheckPVPStart = nil
                    local CombatExtended = false
                    
                    local BV = Instance.new("BodyVelocity", LocalPlayer.Character.HumanoidRootPart)
                    BV.Velocity, BV.MaxForce = Vector3.new(0,0,0), Vector3.new(9e9,9e9,9e9)

                    repeat
                        task.wait()
                        if not IsAlive(LocalPlayer) or not IsValidTarget(Enemy) then break end
                        local Root = LocalPlayer.Character.HumanoidRootPart
                        local EnemyRoot = Enemy.Character.HumanoidRootPart
                        local Dist = (Root.Position - EnemyRoot.Position).Magnitude
                        local InCombat = LocalPlayer.PlayerGui.Main.InCombat.Visible

                        -- LOGIC THỜI GIAN (60S APPROACH | 20S CHECK | 2P30S COMBAT)
                        if Dist > 100 and not CheckPVPStart then
                            if (tick() - HuntStart) > 60 then break end
                            StatusText.Text = "Status: ⚔️ Approaching -> "..Enemy.Name
                        elseif Dist <= 100 and not CheckPVPStart then
                            CheckPVPStart = tick()
                            StatusText.Text = "Status: 🛡️ Checking PVP (20s)..."
                        end

                        if CheckPVPStart and not CombatExtended then
                            if InCombat then
                                CombatExtended = true
                                HuntStart = tick() -- Bắt đầu tính 2p30s
                                StatusText.Text = "Status: 🔴 Fighting -> "..Enemy.Name
                            elseif (tick() - CheckPVPStart) > 20 then break end
                        end

                        if CombatExtended and (tick() - HuntStart) > 150 then break end

                        -- DI CHUYỂN TWEEN 300
                        TweenService:Create(Root, TweenInfo.new(Dist/300, Enum.EasingStyle.Linear), {CFrame = EnemyRoot.CFrame * CFrame.new(0, 5, 2)}):Play()

                        -- AIM LOCK & BUFF
                        if Dist < 100 then
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, EnemyRoot.Position)
                            Root.CFrame = CFrame.new(Root.Position, EnemyRoot.Position)
                            if not LocalPlayer.Character:FindFirstChild("HasBuso") then ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end
                            VirtualInputManager:SendKeyEvent(true, "T", false, game)
                            if LocalPlayer.PlayerGui.Main.Awakening.Gauge.Size.X.Scale >= 1 then VirtualInputManager:SendKeyEvent(true, "Y", false, game) end
                            ExecuteCombo(Enemy)
                        end
                    until not IsValidTarget(Enemy)
                    if BV then BV:Destroy() end
                    break
                end
            end

            -- SUPER HOP SERVER
            if not FoundTarget and Setting.Misc.AutoHopServer then
                StatusText.Text = "Status: 🛫 Waiting Combat to Hop..."
                repeat
                    pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position.X, Setting.SafeZone["Teleport Y"], LocalPlayer.Character.HumanoidRootPart.Position.Z) end)
                    task.wait(1)
                until not LocalPlayer.PlayerGui.Main.InCombat.Visible
                
                local function SuperHop()
                    local Api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
                    local s, r = pcall(function() return HttpService:JSONDecode(game:HttpGet(Api)) end)
                    if s and r.data then
                        local list = r.data
                        for i = #list, 2, -1 do local j = math.random(i) list[i], list[j] = list[j], list[i] end
                        for _, srv in pairs(list) do
                            if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                                task.wait(5)
                            end
                        end
                    end
                end
                SuperHop()
            end
        end
    end)
end

SafeCall(StartAutoBounty)

