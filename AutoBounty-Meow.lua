--[[
    SCRIPT NAME: Auto Bounty by Meow
    AUTHOR: Meow
    VERSION: 1.5.0 (Stable/Robust)
    DESCRIPTION: Fully optimized auto bounty hunter with Anti-Sus, Auto Haki, Auto Race V3/V4, Safezone logic.
]]

--------------------------------------------------------------------------------
-- 1. SERVICES & VARIABLES (KHỞI TẠO DỊCH VỤ)
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Đợi game load hoàn toàn
if not game:IsLoaded() then
    game.Loaded:Wait()
end

--------------------------------------------------------------------------------
-- 2. SAFETY FUNCTIONS (HÀM BẢO VỆ)
--------------------------------------------------------------------------------
-- Hàm thực thi an toàn (tránh crash script)
local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[Auto Bounty Error]: " .. tostring(result))
    end
    return success, result
end

-- Hàm kiểm tra nhân vật sống
local function IsAlive(plr)
    if plr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("HumanoidRootPart") then
        if plr.Character.Humanoid.Health > 0 then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- 3. UI SYSTEM (GIAO DIỆN TRẠNG THÁI CHI TIẾT)
--------------------------------------------------------------------------------
local function CreateStatusUI()
    -- Xóa UI cũ nếu có để tránh trùng lặp
    for _, child in pairs(CoreGui:GetChildren()) do
        if child.Name == "AutoBountyByMeowUI" then
            child:Destroy()
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoBountyByMeowUI"
    ScreenGui.Parent = CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.Size = UDim2.new(0, 300, 0, 150)
    
    -- Thêm bo góc cho đẹp
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = MainFrame
    TitleLabel.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- Màu cam
    TitleLabel.BackgroundTransparency = 0.8
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "  AUTO BOUNTY BY MEOW"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleLabel

    -- Hàm tạo dòng thông tin
    local function CreateInfoLabel(name, yPos, defaultText)
        local Label = Instance.new("TextLabel")
        Label.Name = name
        Label.Parent = MainFrame
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 10, 0, yPos)
        Label.Size = UDim2.new(1, -20, 0, 25)
        Label.Font = Enum.Font.GothamSemibold
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Text = defaultText
        return Label
    end

    local BountyLabel = CreateInfoLabel("BountyLabel", 40, "Bounty: Loading...")
    local TimeLabel = CreateInfoLabel("TimeLabel", 70, "Time in Server: 00:00")
    local StatusLabel = CreateInfoLabel("StatusLabel", 100, "Status: Idle")

    -- Logic cập nhật UI
    task.spawn(function()
        local startTime = tick()
        while task.wait(1) do
            SafeCall(function()
                -- Cập nhật Bounty
                if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Bounty/Honor") then
                    local val = LocalPlayer.leaderstats["Bounty/Honor"].Value
                    BountyLabel.Text = "💰 Current Bounty: " .. string.format("%.1fM", val / 1000000)
                end
                
                -- Cập nhật Thời gian
                local currentTime = tick() - startTime
                local minutes = math.floor(currentTime / 60)
                local seconds = math.floor(currentTime % 60)
                TimeLabel.Text = string.format("⏳ Time in Server: %02d:%02d", minutes, seconds)
            end)
        end
    end)

    return StatusLabel
end

local StatusText = CreateStatusUI()

--------------------------------------------------------------------------------
-- 4. COMBAT SUPPORT FUNCTIONS (HỖ TRỢ CHIẾN ĐẤU)
--------------------------------------------------------------------------------

-- Tự động bật Haki (Vũ trang & Quan sát)
local function AutoActivateHaki()
    SafeCall(function()
        if not IsAlive(LocalPlayer) then return end
        
        -- Bật Buso Haki (Vũ trang)
        if not LocalPlayer.Character:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end

        -- Bật Ken Haki (Quan sát) - Dùng phím E
        if not LocalPlayer.Character:FindFirstChild("KenHaki") then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

-- Tự động bật Tộc (Race V3 / V4)
local function AutoActivateRace()
    SafeCall(function()
        if not IsAlive(LocalPlayer) then return end
        local Setting = getgenv().Setting

        -- Chỉ bật khi đang trong trạng thái In Combat
        if LocalPlayer.PlayerGui.Main.InCombat.Visible and Setting["Race V4"].Enable then
            
            -- 1. Luôn spam phím T để kích hoạt Skill V3 (Buff giáp/dmg)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
            
            -- 2. Kiểm tra thanh nộ để kích hoạt V4 (Phím Y)
            local AwakeningUI = LocalPlayer.PlayerGui.Main.Awakening
            if AwakeningUI and AwakeningUI.Gauge.Size.X.Scale >= 1 then
                StatusText.Text = "Status: 🔥 Activating Race V4 (Y)!"
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
            end
        end
    end)
end

-- Fix lỗi di chuyển bất thường (Anti-Sus)
local function ActivateAntiSus()
    RunService.Stepped:Connect(function()
        SafeCall(function()
            if IsAlive(LocalPlayer) then
                -- Ép nhân vật di chuyển nhẹ về phía trước để Server ghi nhận input sạch
                LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, -1), true)
            end
        end)
    end)
end

-- Hàm bay (Tween) đến mục tiêu
local function TweenToPosition(targetCFrame)
    if not IsAlive(LocalPlayer) then return end
    
    local RootPart = LocalPlayer.Character.HumanoidRootPart
    local Distance = (RootPart.Position - targetCFrame.Position).Magnitude
    
    -- Tốc độ bay: 300 stud/s (Có thể chỉnh chậm lại nếu hay bị kick)
    local Speed = 300 
    local TweenInfoData = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    
    local Tween = TweenService:Create(RootPart, TweenInfoData, {CFrame = targetCFrame})
    Tween:Play()
    
    -- Nếu gần đến nơi (dưới 10 stud) thì hủy tween để combat
    return Tween
end

-- Hàm Né Skill (Dodge)
local function PerformDodge(targetPlayer)
    if not IsAlive(LocalPlayer) or not IsAlive(targetPlayer) then return end
    
    SafeCall(function()
        local RootPart = LocalPlayer.Character.HumanoidRootPart
        -- Vọt lên trời 500m
        RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 500, 0)
        task.wait(0.2) 
        -- Hạ xuống ngay sau lưng địch
        if IsAlive(targetPlayer) then
            RootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end)
end

--------------------------------------------------------------------------------
-- 5. MAIN LOGIC (LOGIC CHÍNH)
--------------------------------------------------------------------------------

local function StartAutoBounty()
    local Setting = getgenv().Setting
    
    -- 1. Vào Team
    local TeamName = (Setting["Team"] == "Pirate") and "Pirates" or "Marines"
    StatusText.Text = "Status: Joining Team " .. TeamName .. "..."
    
    repeat 
        task.wait(0.5)
        SafeCall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", TeamName)
        end)
    until LocalPlayer.Team ~= nil

    -- 2. Kích hoạt hệ thống hỗ trợ
    ActivateAntiSus()
    
    -- 3. Vòng lặp săn mồi chính
    task.spawn(function()
        while task.wait(0.5) do
            local FoundTarget = false
            
            -- Duyệt qua tất cả người chơi
            for _, Enemy in pairs(Players:GetPlayers()) do
                -- Điều kiện lọc: Khác phe (hoặc không check phe), có nhân vật, không phải mình
                if Enemy ~= LocalPlayer and IsAlive(Enemy) then
                    
                    -- Check Sea Level (Không đánh người mới lv 0)
                    local EnemySea = Enemy:GetAttribute("SeaLevel") or 1
                    
                    -- Check SafeZone (Không đánh người đang trong vùng an toàn)
                    local IsInSafeZone = Enemy.Character:FindFirstChild("SafeZone") or Enemy.Character:FindFirstChild("ForceField")

                    if EnemySea > 0 and not IsInSafeZone then
                        
                        FoundTarget = true
                        StatusText.Text = "Status: ⚔️ Locked Target: " .. Enemy.Name
                        StatusText.TextColor3 = Color3.fromRGB(255, 0, 0)

                        -- Các biến kiểm soát trận đấu
                        local StartHuntTime = tick()      -- Thời điểm bắt đầu tiếp cận
                        local StartCombatTime = 0         -- Thời điểm bắt đầu đánh nhau thật (In Combat)
                        local CombatActive = false        -- Đã vào combat chưa
                        local LastDodgeTime = tick()      -- Thời điểm né chiêu cuối cùng

                        -- VÒNG LẶP TẤN CÔNG (HUNTING LOOP)
                        repeat
                            task.wait() -- Chạy nhanh nhất có thể theo FPS
                            
                            -- Kiểm tra điều kiện thoát vòng lặp
                            if not IsAlive(LocalPlayer) or not IsAlive(Enemy) or Enemy.Character:FindFirstChild("SafeZone") then 
                                break 
                            end

                            -- A. LOGIC HỒI MÁU (SAFEZONE RETREAT)
                            if LocalPlayer.Character.Humanoid.Health < Setting.SafeZone.LowHealth then
                                StatusText.Text = "Status: 🏥 Low Health! Retreating to SafeZone..."
                                StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
                                
                                local SafePos = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position.X, Setting.SafeZone["Teleport Y"], LocalPlayer.Character.HumanoidRootPart.Position.Z)
                                LocalPlayer.Character.HumanoidRootPart.CFrame = SafePos
                                
                                -- Đứng yên đợi hồi máu
                                repeat task.wait(0.5) until LocalPlayer.Character.Humanoid.Health >= Setting.SafeZone.MaxHealth
                                StatusText.Text = "Status: ⚔️ Re-engaging Target..."
                            end

                            -- B. DI CHUYỂN & TẤN CÔNG
                            -- Luôn bật Haki & Race
                            AutoActivateHaki()
                            AutoActivateRace()
                            
                            -- Bay đến đối thủ (Sau lưng 3 stud)
                            local TargetPos = Enemy.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                            local Tween = TweenToPosition(TargetPos)
                            
                            -- Nếu gần thì hủy tween để đánh cho mượt
                            if (LocalPlayer.Character.HumanoidRootPart.Position - TargetPos.Position).Magnitude < 10 then
                                if Tween then Tween:Cancel() end
                                LocalPlayer.Character.HumanoidRootPart.CFrame = TargetPos
                            end
                            
                            -- C. NÉ CHIÊU (DODGE)
                            if Setting["Dodge Skill Player"] and (tick() - LastDodgeTime > 5) then
                                PerformDodge(Enemy)
                                LastDodgeTime = tick()
                            end

                            -- D. KIỂM SOÁT THỜI GIAN (LOGIC 20S & 2P30S)
                            local IsInCombatUI = LocalPlayer.PlayerGui.Main.InCombat.Visible

                            if not CombatActive then
                                -- Giai đoạn chưa vào Combat
                                if IsInCombatUI then
                                    CombatActive = true
                                    StartCombatTime = tick()
                                    StatusText.Text = "Status: 🔥 In Combat with " .. Enemy.Name
                                elseif (tick() - StartHuntTime) > Setting["Target Time"] then
                                    StatusText.Text = "Status: ⚠️ 20s Timeout (No PvP). Skipping..."
                                    break -- Thoát vòng lặp để tìm người khác
                                end
                            else
                                -- Giai đoạn đang Combat
                                if (tick() - StartCombatTime) > 150 then -- 150 giây = 2 phút 30
                                    StatusText.Text = "Status: ⌛ Fight too long! Skipping..."
                                    break
                                end
                            end

                        until not IsAlive(Enemy) or not IsAlive(LocalPlayer)
                        
                        -- Nếu địch chết hoặc mất tích
                        StatusText.Text = "Status: ✅ Target Elimination / Lost."
                        task.wait(1)
                    end
                end
                
                -- Nếu đã tìm thấy và xử lý xong 1 người, break ra vòng ngoài để quét lại từ đầu
                if FoundTarget then break end
            end

            -- LOGIC HOP SERVER (KHI KHÔNG TÌM THẤY AI)
            if not FoundTarget and Setting.Misc.AutoHopServer then
                -- Chỉ hop khi AN TOÀN (không In Combat)
                if not LocalPlayer.PlayerGui.Main.InCombat.Visible then
                    StatusText.Text = "Status: 🌎 Server Empty/Done. Hopping..."
                    StatusText.TextColor3 = Color3.fromRGB(0, 255, 255)
                    
                    -- Đoạn code Hop Server (Sử dụng API Roblox)
                    SafeCall(function()
                        local PlaceId = game.PlaceId
                        local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
                        for _, Server in pairs(Servers.data) do
                            if Server.playing < Server.maxPlayers and Server.id ~= game.JobId then
                                game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
                                break
                            end
                        end
                    end)
                    task.wait(5) -- Đợi teleport
                else
                    StatusText.Text = "Status: 🚫 Waiting for Combat End to Hop..."
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 6. EXECUTION (THỰC THI)
--------------------------------------------------------------------------------
SafeCall(StartAutoBounty)
