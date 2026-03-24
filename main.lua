-- Hyun Hub v2 | LocalScript
-- StarterGui hoac StarterPlayerScripts

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local RS                = game:GetService("ReplicatedStorage")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")

-- ================================================
-- WORLD
-- ================================================
local W1 = game.PlaceId==2753915549 or game.PlaceId==85211729168715
local W2 = game.PlaceId==4442272183 or game.PlaceId==79091703265657
local W3 = game.PlaceId==7449423635 or game.PlaceId==100117331123089

-- ================================================
-- STATE
-- ================================================
local State = {
    FarmLevel   = false,
    FarmBone    = false,
    FarmKata    = false,
    IsFarming   = false,
    BringMob    = true,
    AcceptQuest = false,
    Noclip      = true,
    AntiAFK     = false,
    AutoV3      = false,
    AutoV4      = false,
    AutoKen     = false,
    AutoBones   = false,
    DualNext    = {},
    ChooseWP    = "Melee",
    FlySpeed    = 300,
    CurrentMob  = nil,
}

-- ================================================
-- HELPERS
-- ================================================
local function Char()   return LP.Character end
local function Root()
    local c = Char(); if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end
local function Alive(m)
    if not m or not m.Parent then return false end
    local h = m:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

-- ================================================
-- NOCLIP
-- ================================================
RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local c = Char(); if not c then return end
    for _,v in pairs(c:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = false end
    end
end)

-- ================================================
-- ANTI AFK (builtin)
-- ================================================
LP.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

task.spawn(function()
    while true do
        task.wait(55)
        if not State.AntiAFK then continue end
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true,"W",false,game)
            task.wait(0.1)
            VIM:SendKeyEvent(false,"W",false,game)
        end)
    end
end)

-- ================================================
-- FLY / HOVER (BodyVelocity de tween di chuyen duoc)
-- ================================================
local flyBV = nil
local function StartHover()
    local c = Char(); if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if flyBV and flyBV.Parent == hrp then return end
    if flyBV then flyBV:Destroy() end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBV.Velocity  = Vector3.new(0,0,0)
    flyBV.Parent    = hrp
end
local function StopHover()
    if flyBV then flyBV:Destroy(); flyBV=nil end
end
-- Giu player o tren khong khi farming (velocity 0 = hover)
RunService.Heartbeat:Connect(function()
    if not State.IsFarming then return end
    if flyBV and flyBV.Parent then
        -- Chi set 0 khi khong co tween dang chay
        if not activeTween then
            flyBV.Velocity = Vector3.new(0,0,0)
        end
    else
        pcall(StartHover)
    end
end)

-- ================================================
-- AUTO BUSO (luon bat khi farming)
-- ================================================
task.spawn(function()
    while true do
        task.wait(1)
        if not State.IsFarming then continue end
        pcall(function()
            local c = Char(); if not c then return end
            if not c:FindFirstChild("HasBuso") and not c:FindFirstChild("Buso") then
                RS.Remotes.CommF_:InvokeServer("Buso")
            end
        end)
    end
end)

-- ================================================
-- AUTO V3 / V4 / KEN
-- ================================================
task.spawn(function()
    while true do
        task.wait(0.05)
        if not State.AutoV3 then continue end
        pcall(function() RS.Remotes.CommE:FireServer("ActivateAbility") end)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if not State.AutoV4 then continue end
        pcall(function()
            local c = Char(); if not c then return end
            local re = c:FindFirstChild("RaceEnergy")
            if re and re.Value == 1 then
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(true,"Y",false,game)
                task.wait(0.05)
                VIM:SendKeyEvent(false,"Y",false,game)
            end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not State.AutoKen then continue end
        pcall(function()
            local c = Char(); if not c then return end
            if not c:FindFirstChild("HasKen") and not c:FindFirstChild("Instinct") then
                RS.Remotes.CommF_:InvokeServer("Instinct")
            end
        end)
    end
end)

-- ================================================
-- AUTO BONES
-- ================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if not State.AutoBones then continue end
        pcall(function()
            local bones = LP.Data.Bones.Value
            if bones >= 50 then
                RS.Remotes.CommF_:InvokeServer("Bones","Check")
                RS.Remotes.CommF_:InvokeServer("Bones","Buy",1)
            end
        end)
    end
end)

-- ================================================
-- SIMULATION RADIUS (luon bat)
-- ================================================
task.spawn(function()
    while true do
        task.wait(2)
        if not State.IsFarming then continue end
        pcall(function() sethiddenproperty(LP,"SimulationRadius",math.huge) end)
    end
end)

-- ================================================
-- FAST ATTACK (luon bat - da muc tieu)
-- ================================================
local _Combat, _RA, _RH, _FAinit = nil,nil,nil,false
task.spawn(function()
    while true do
        task.wait(0.05)
        -- Init remotes mot lan
        if not _FAinit then
            _FAinit = true
            pcall(function() _Combat = RS.Remotes.Combat end)
            pcall(function()
                local N = RS.Modules.Net
                _RA = N:FindFirstChild("RE/RegisterAttack")
                _RH = N:FindFirstChild("RE/RegisterHit")
            end)
        end
        local c = Char(); if not c then continue end
        local root = c:FindFirstChild("HumanoidRootPart"); if not root then continue end

        -- Scan TAT CA enemy trong 150 studs (tang range + khong gioi han so luong)
        local list = {}
        pcall(function()
            for _,v in pairs(workspace.Enemies:GetChildren()) do
                local h = v:FindFirstChildOfClass("Humanoid")
                local r = v:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0
                and (root.Position-r.Position).Magnitude <= 150 then
                    table.insert(list, v)
                end
            end
        end)
        if #list == 0 then continue end

        -- Cach 1: Combat:FireServer cho TUNG enemy (da muc tieu thuc su)
        if _Combat then
            for _,e in ipairs(list) do
                pcall(function() _Combat:FireServer(e) end)
            end
        end

        -- Cach 2: RegisterAttack + RegisterHit voi danh sach TAT CA target
        if _RA and _RH then
            local tool = c:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function()
                    for _=1,5 do _RA:FireServer(0) end
                    -- Truyen tat ca target vao args[2]
                    local first = list[1]:FindFirstChild("HumanoidRootPart")
                    if not first then return end
                    local args = {[1]=first, [2]={}}
                    for i,v in ipairs(list) do
                        local r = v:FindFirstChild("HumanoidRootPart")
                        if r then args[2][i] = {v, r} end
                    end
                    for _=1,5 do _RH:FireServer(unpack(args)) end
                end)
            end
        end

        -- Cach 3: Blox Fruit - nham vao tung mob gan nhat
        local tool = c:FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip == "Blox Fruit" then
            pcall(function()
                local rem = tool:FindFirstChild("LeftClickRemote"); if not rem then return end
                -- Fire theo huong cua tung mob de hit nhieu con
                for _,e in ipairs(list) do
                    local r = e:FindFirstChild("HumanoidRootPart"); if not r then continue end
                    local dir = (r.Position-root.Position).Unit
                    for _=1,3 do rem:FireServer(dir,1) end
                end
            end)
        end
    end
end)

-- ================================================
-- BRING MOB (luon chay, chi active khi bat)
-- ================================================
task.spawn(function()
    while true do
        task.wait(0.2)
        if not State.BringMob or not State.IsFarming then continue end
        local mob = State.CurrentMob
        if not mob or not Alive(mob) then continue end
        local mr = mob:FindFirstChild("HumanoidRootPart"); if not mr then continue end
        local tPos = mr.Position
        pcall(function()
            for _,v in pairs(workspace.Enemies:GetChildren()) do
                if v == mob then continue end
                local h = v:FindFirstChildOfClass("Humanoid")
                local r = v:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 and v.Name == mob.Name then
                    local d = (r.Position-tPos).Magnitude
                    if d > 3 and d <= 350 then
                        r.CFrame = mr.CFrame
                        r.Velocity = Vector3.new(0,0,0)
                        pcall(function() sethiddenproperty(LP,"SimulationRadius",math.huge) end)
                    end
                end
            end
        end)
    end
end)

-- ================================================
-- WEAPON SELECT
-- ================================================
local function SelectWeapon()
    pcall(function()
        local c = Char(); if not c then return end
        local bp = LP.Backpack
        local tipMap = {Melee="Melee",Sword="Sword",Gun="Gun",["Blox Fruit"]="Blox Fruit"}
        local want = tipMap[State.ChooseWP] or "Melee"
        for _,v in pairs(bp:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip == want then
                c.Humanoid:EquipTool(v); return
            end
        end
    end)
end

-- ================================================
-- ATTACK
-- ================================================
local function Attack(enemy)
    if not Alive(enemy) then return end
    pcall(function()
        SelectWeapon()
        RS.Remotes.Combat:FireServer(enemy)
    end)
end

-- ================================================
-- NEAREST ENEMY
-- ================================================
local function Nearest(names)
    local root = Root(); if not root then return nil end
    local best, bd = nil, math.huge
    pcall(function()
        for _,v in pairs(workspace.Enemies:GetChildren()) do
            if not Alive(v) then continue end
            local r = v:FindFirstChild("HumanoidRootPart"); if not r then continue end
            local match = false
            if type(names)=="table" then
                for _,n in pairs(names) do if v.Name==n then match=true;break end end
            else match = v.Name==names end
            if match then
                local d = (root.Position-r.Position).Magnitude
                if d < bd then bd=d; best=v end
            end
        end
    end)
    return best
end

-- ================================================
-- FARM CFRAME
-- ================================================
local function FarmCF(mob)
    local r = mob and mob:FindFirstChild("HumanoidRootPart")
    if not r then return nil end
    local p = r.Position
    return CFrame.new(Vector3.new(p.X, p.Y+16, p.Z))
end

-- ================================================
-- TWEEN + INTERMEDIATE ISLAND SYSTEM
-- ================================================
local Islands = {}
if W1 then
    Islands = {
        {pos=Vector3.new(-4607,872,-1667), name="Sky2"},
        {pos=Vector3.new(61163,5,1819),    name="Fishman"},
        {pos=Vector3.new(3864,5,-1926),    name="Whirlpool"},
        {pos=Vector3.new(-7894,5545,-380), name="Sky3"},
    }
elseif W2 then
    Islands = {
        {pos=Vector3.new(-6505,75,-126),  name="GhostGate"},
        {pos=Vector3.new(923,120,32852),  name="GhostShip"},
        {pos=Vector3.new(-287,280,597),   name="Flamingo"},
        {pos=Vector3.new(2284,45,908),    name="FlamingoRoom"},
    }
elseif W3 then
    Islands = {
        {pos=Vector3.new(5655,1013,-317),   name="HouseHydra"},
        {pos=Vector3.new(-12465,459,-7561), name="Mansion"},
        {pos=Vector3.new(-5083,371,-3177),  name="CastleSea"},
        {pos=Vector3.new(-16269,25,1374),   name="SubmarineGate"},
    }
end

local lastInterTele = 0
local activeTween   = nil

-- Tween muat den vi tri, cho den khi gan (blocking trong task.spawn)
local function TweenTo(targetPos, speed)
    local root = Root(); if not root then return end
    speed = speed or 300
    -- Cancel tween cu
    if activeTween then activeTween:Cancel(); activeTween=nil end
    -- Xu ly chenh lech Y lon (teleport Y truoc)
    local dy = math.abs(targetPos.Y - root.Position.Y)
    if dy > 300 then
        root.CFrame = CFrame.new(root.Position.X, targetPos.Y, root.Position.Z)
        task.wait(0.3)
    end
    local dist = (root.Position - targetPos).Magnitude
    if dist < 1 then return end
    local t = TweenService:Create(root,
        TweenInfo.new(dist/speed, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(targetPos)}
    )
    activeTween = t
    t:Play()
    -- Cho tween xong hoac timeout
    local deadline = tick() + dist/speed + 2
    repeat task.wait(0.1) until
        (not activeTween) or
        tick() > deadline or
        (Root() and (Root().Position-targetPos).Magnitude < 8)
    if activeTween then activeTween:Cancel(); activeTween=nil end
end

-- Di chuyen den dich, tu dong dung dao trung gian neu qua xa
-- Sau khi den dao trung gian: respawn BodyVelocity de game ko keo nguoi choi ve dao cu
local function MoveTo(targetPos, _yOff, speed)
    local root = Root(); if not root then return end
    speed = speed or State.FlySpeed or 300

    local pXZ  = Vector2.new(root.Position.X, root.Position.Z)
    local dXZ  = Vector2.new(targetPos.X, targetPos.Z)
    local dist = (pXZ-dXZ).Magnitude

    -- Chi dung dao trung gian neu xa > 3000 studs va da qua 5s
    if dist > 3000 and tick()-lastInterTele > 5 then
        local best, bd = nil, math.huge
        for _,isl in ipairs(Islands) do
            local islXZ = Vector2.new(isl.pos.X, isl.pos.Z)
            local d = (islXZ-dXZ).Magnitude
            -- Dao trung gian chi hop le neu no gan dich hon player hien tai
            if d < bd and d < dist then bd=d; best=isl end
        end
        if best then
            lastInterTele = tick()
            print("[HyunHub] Dao trung gian: "..best.name)
            -- Tween den dao trung gian
            TweenTo(Vector3.new(best.pos.X, math.max(best.pos.Y+5,30), best.pos.Z), speed)
            -- RESET: tat BodyVelocity 1 frame de game khong keo ve dao cu
            local c = Char()
            if c then
                for _,v in pairs(c:GetDescendants()) do
                    if v:IsA("BodyVelocity") or v:IsA("BodyPosition") then
                        v.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
            task.wait(0.2)
        end
    end

    -- Tween den dich chinh
    local safeY = targetPos.Y < 0 and targetPos.Y or math.max(targetPos.Y, 5)
    TweenTo(Vector3.new(targetPos.X, safeY, targetPos.Z), speed)
end

-- ================================================
-- QUEST DATA
-- ================================================
local function QuestData()
    local lv = 1
    pcall(function() lv = LP.Data.Level.Value end)

    local Mon,Qdata,Qname,NameMon,PosM,PosQ

    if W1 then
        if     lv<=9   then Mon="Bandit";Qdata=1;Qname="BanditQuest1";NameMon="Bandit";PosQ=Vector3.new(1045,27,1560);PosM=Vector3.new(1045,27,1560)
        elseif lv<=14  then Mon="Monkey";Qdata=1;Qname="JungleQuest";NameMon="Monkey";PosQ=Vector3.new(-1598,35,153);PosM=Vector3.new(-1448,67,11)
        elseif lv<=29  then Mon="Gorilla";Qdata=2;Qname="JungleQuest";NameMon="Gorilla";PosQ=Vector3.new(-1598,35,153);PosM=Vector3.new(-1129,40,-525)
        elseif lv<=39  then Mon="Pirate";Qdata=1;Qname="BuggyQuest1";NameMon="Pirate";PosQ=Vector3.new(-1141,4,3831);PosM=Vector3.new(-1103,13,3896)
        elseif lv<=59  then Mon="Brute";Qdata=2;Qname="BuggyQuest1";NameMon="Brute";PosQ=Vector3.new(-1141,4,3831);PosM=Vector3.new(-1140,14,4322)
        elseif lv<=74  then Mon="Desert Bandit";Qdata=1;Qname="DesertQuest";NameMon="Desert Bandit";PosQ=Vector3.new(894,5,4392);PosM=Vector3.new(924,6,4481)
        elseif lv<=89  then Mon="Desert Officer";Qdata=2;Qname="DesertQuest";NameMon="Desert Officer";PosQ=Vector3.new(894,5,4392);PosM=Vector3.new(1608,8,4371)
        elseif lv<=99  then Mon="Snow Bandit";Qdata=1;Qname="SnowQuest";NameMon="Snow Bandit";PosQ=Vector3.new(1389,88,-1298);PosM=Vector3.new(1354,87,-1393)
        elseif lv<=119 then Mon="Snowman";Qdata=2;Qname="SnowQuest";NameMon="Snowman";PosQ=Vector3.new(1389,88,-1298);PosM=Vector3.new(1200,144,-1550)
        elseif lv<=149 then Mon="Chief Petty Officer";Qdata=1;Qname="MarineQuest2";NameMon="Chief Petty Officer";PosQ=Vector3.new(-2784,14,2220);PosM=Vector3.new(-2982,9,2592)
        elseif lv<=199 then Mon="Military Soldier";Qdata=1;Qname="MagmaQuest";NameMon="Military Soldier";PosQ=Vector3.new(-5411,11,8454);PosM=Vector3.new(-5411,11,8454)
        elseif lv<=249 then Mon="Fishman Warrior";Qdata=1;Qname="FishmanQuest";NameMon="Fishman Warrior";PosQ=Vector3.new(60878,18,1543);PosM=Vector3.new(60878,18,1543)
        elseif lv<=349 then Mon="Sky Bandit";Qdata=1;Qname="SkyQuest";NameMon="Sky Bandit";PosQ=Vector3.new(-4953,295,-2899);PosM=Vector3.new(-4953,295,-2899)
        elseif lv<=449 then Mon="Prisoner";Qdata=1;Qname="PrisonerQuest";NameMon="Prisoner";PosQ=Vector3.new(5098,-0,474);PosM=Vector3.new(5098,-0,474)
        elseif lv<=549 then Mon="Toga Warrior";Qdata=1;Qname="ColosseumQuest";NameMon="Toga Warrior";PosQ=Vector3.new(-1820,51,-2740);PosM=Vector3.new(-1820,51,-2740)
        else            Mon="Royal Squad";Qdata=1;Qname="SkyExp2Quest";NameMon="Royal Squad";PosQ=Vector3.new(-7624,5658,-1467);PosM=Vector3.new(-7624,5658,-1467)
        end
    elseif W2 then
        if     lv<=849  then Mon="Raider";Qdata=1;Qname="Area1Quest";NameMon="Raider";PosQ=Vector3.new(-728,52,2345);PosM=Vector3.new(-728,52,2345)
        elseif lv<=924  then Mon="Zombie";Qdata=1;Qname="ZombieQuest";NameMon="Zombie";PosQ=Vector3.new(-5657,78,-928);PosM=Vector3.new(-5657,78,-928)
        elseif lv<=999  then Mon="Snow Trooper";Qdata=1;Qname="SnowMountainQuest";NameMon="Snow Trooper";PosQ=Vector3.new(549,427,-5563);PosM=Vector3.new(549,427,-5563)
        elseif lv<=1149 then Mon="Lab Subordinate";Qdata=1;Qname="IceSideQuest";NameMon="Lab Subordinate";PosQ=Vector3.new(-5707,15,-4513);PosM=Vector3.new(-5707,15,-4513)
        elseif lv<=1249 then Mon="Magma Ninja";Qdata=1;Qname="FireSideQuest";NameMon="Magma Ninja";PosQ=Vector3.new(-5428,15,-5299);PosM=Vector3.new(-5449,76,-5808)
        elseif lv<=1349 then Mon="Ship Deckhand";Qdata=1;Qname="ShipQuest1";NameMon="Ship Deckhand";PosQ=Vector3.new(1037,125,32911);PosM=Vector3.new(1212,150,33059)
        elseif lv<=1424 then Mon="Arctic Warrior";Qdata=1;Qname="FrostQuest";NameMon="Arctic Warrior";PosQ=Vector3.new(5667,26,-6486);PosM=Vector3.new(5966,62,-6179)
        else             Mon="Sea Soldier";Qdata=1;Qname="ForgottenQuest";NameMon="Sea Soldier";PosQ=Vector3.new(-3054,235,-10142);PosM=Vector3.new(-3028,64,-9775)
        end
    elseif W3 then
        if     lv<=1574 then Mon="Pirate Millionaire";Qdata=1;Qname="PiratePortQuest";NameMon="Pirate Millionaire";PosQ=Vector3.new(-290,42,5581);PosM=Vector3.new(-246,47,5584)
        elseif lv<=1699 then Mon="Dragon Crew Warrior";Qdata=1;Qname="DragonCrewQuest";NameMon="Dragon Crew Warrior";PosQ=Vector3.new(6737,127,-712);PosM=Vector3.new(6709,52,-1139)
        elseif lv<=1799 then Mon="Marine Commodore";Qdata=1;Qname="MarineTreeIsland";NameMon="Marine Commodore";PosQ=Vector3.new(2482,74,-6788);PosM=Vector3.new(2519,109,-7633)
        elseif lv<=1924 then Mon="Reborn Skeleton";Qdata=1;Qname="HauntedQuest1";NameMon="Reborn Skeleton";PosQ=Vector3.new(-8900,165,6100);PosM=Vector3.new(-8763,165,6159)
        elseif lv<=1999 then Mon="Demonic Soul";Qdata=2;Qname="HauntedQuest2";NameMon="Demonic Soul";PosQ=Vector3.new(-9516,172,6078);PosM=Vector3.new(-9505,172,6158)
        elseif lv<=2099 then Mon="Peanut Scout";Qdata=1;Qname="NutsIslandQuest";NameMon="Peanut Scout";PosQ=Vector3.new(-2104,38,-10194);PosM=Vector3.new(-2143,47,-10029)
        elseif lv<=2199 then Mon="Ice Cream Chef";Qdata=1;Qname="IceCreamIslandQuest";NameMon="Ice Cream Chef";PosQ=Vector3.new(-820,65,-10965);PosM=Vector3.new(-872,65,-10919)
        elseif lv<=2299 then Mon="Cookie Crafter";Qdata=1;Qname="CakeQuest1";NameMon="Cookie Crafter";PosQ=Vector3.new(-2021,37,-12028);PosM=Vector3.new(-2374,37,-12125)
        elseif lv<=2399 then Mon="Baking Staff";Qdata=1;Qname="CakeQuest2";NameMon="Baking Staff";PosQ=Vector3.new(-1927,37,-12842);PosM=Vector3.new(-1887,77,-12998)
        elseif lv<=2499 then Mon="Isle Outlaw";Qdata=1;Qname="TikiQuest1";NameMon="Isle Outlaw";PosQ=Vector3.new(-16548,55,-172);PosM=Vector3.new(-16479,226,-300)
        elseif lv<=2599 then Mon="Sun-kissed Warrior";Qdata=1;Qname="TikiQuest2";NameMon="kissed Warrior";PosQ=Vector3.new(-16538,55,1049);PosM=Vector3.new(-16347,64,984)
        elseif lv<=2699 then Mon="Serpent Hunter";Qdata=1;Qname="TikiQuest3";NameMon="Serpent Hunter";PosQ=Vector3.new(-16668,105,1568);PosM=Vector3.new(-16645,163,1352)
        else             Mon="High Disciple";Qdata=1;Qname="SubmergedQuest3";NameMon="High Disciple";PosQ=Vector3.new(9640,-1992,9613);PosM=Vector3.new(9750,-1966,9753)
        end
    else
        Mon="Bandit";Qdata=1;Qname="BanditQuest1";NameMon="Bandit"
        PosQ=Vector3.new(1045,27,1560);PosM=Vector3.new(1045,27,1560)
    end
    return Mon,Qdata,Qname,NameMon,PosM,PosQ
end

-- ================================================
-- QUEST UI
-- ================================================
local function GetQuestUI()
    local ok, res = pcall(function()
        local main = PG:FindFirstChild("Main"); if not main then return nil end
        return main:FindFirstChild("Quest")
    end)
    return ok and res or nil
end

local function QuestVisible()
    local q = GetQuestUI()
    return q and q.Visible or false
end

local function QuestTitle()
    local q = GetQuestUI()
    if not q or not q.Visible then return "" end
    local ok, t = pcall(function() return q.Container.QuestTitle.Title.Text end)
    return ok and t or ""
end

local function AcceptQuest(qname, qdata)
    pcall(function() RS.Remotes.CommF_:InvokeServer("StartQuest", qname, qdata) end)
end

local function AbandonQuest()
    pcall(function() RS.Remotes.CommF_:InvokeServer("AbandonQuest") end)
end

-- ================================================
-- FARM LEVEL
-- ================================================
local farmThread = nil

local function StopFarmLevel()
    State.FarmLevel = false
    State.IsFarming = false
    State.CurrentMob = nil
    if farmThread then pcall(task.cancel, farmThread); farmThread = nil end
end

local function StartFarmLevel()
    StartHover()
    StopFarmLevel()
    State.FarmLevel = true
    State.IsFarming = true

    farmThread = task.spawn(function()
        local prevVisible = false
        local prevQname   = ""

        while State.FarmLevel do
            task.wait(0.15)

            local root = Root()
            if not root then task.wait(1); continue end

            local Mon,Qdata,Qname,NameMon,PosM,PosQ = QuestData()
            if not Mon then task.wait(0.5); continue end

            -- Submerged
            if W3 and PosQ.Y < -100 and root.Position.Y > -100 then
                local sg = Vector3.new(-16269,25,1374)
                if (root.Position-sg).Magnitude > 200 then
                    MoveTo(sg, 5); task.wait(1)
                else
                    pcall(function()
                        RS.Modules.Net["RF/SubmarineWorkerSpeak"]:InvokeServer("TravelToSubmergedIsland")
                    end)
                    task.wait(5)
                end
                continue
            end

            local curVisible = QuestVisible()

            -- Flip dual state
            if prevVisible and not curVisible and prevQname == Qname then
                State.DualNext[Qname] = (State.DualNext[Qname] == 1) and 2 or 1
            end
            prevVisible = curVisible
            prevQname   = Qname

            -- Chua co quest → nhan quest
            if not curVisible then
                local skip = false
                if Qname=="HauntedQuest1" or Qname=="HauntedQuest2"
                or Qname=="CakeQuest1"    or Qname=="CakeQuest2"
                or Qname=="TikiQuest1"    or Qname=="TikiQuest2" or Qname=="TikiQuest3" then
                    skip = not State.AcceptQuest
                end
                if not skip then
                    MoveTo(PosQ, 3)
                    task.wait(0.5)
                    local qd = Qdata
                    if State.DualNext[Qname] == 1 then qd = 1 end
                    AcceptQuest(Qname, qd)
                    task.wait(0.5)
                end
                continue
            end

            -- Co quest → xac dinh mob
            local title     = QuestTitle()
            local activeMon = Mon

            if title ~= "" and not string.find(title, NameMon) then
                AbandonQuest(); task.wait(0.5); continue
            end

            -- Tim mob
            local enemy = Nearest(activeMon)
            State.CurrentMob = enemy

            if enemy then
                if Alive(enemy) then
                    local cf = FarmCF(enemy)
                    if cf then root.CFrame = cf end
                    Attack(enemy)
                end
            else
                State.CurrentMob = nil
                -- Teleport ve spawn zone
                MoveTo(PosM, 5)
                task.wait(0.8)
            end
        end
    end)
end

-- ================================================
-- FARM BONE
-- ================================================
local boneThread = nil
local BoneQ   = Vector3.new(-9516,172,6078)
local BonePos = Vector3.new(-9495,453,5977)
local BonesMobs = {"Reborn Skeleton","Living Zombie","Demonic Soul","Posessed Mummy"}

local function StopFarmBone()
    State.FarmBone  = false
    State.IsFarming = false
    State.CurrentMob = nil
    if boneThread then pcall(task.cancel, boneThread); boneThread = nil end
end

local function StartFarmBone()
    StartHover()
    StopFarmBone()
    State.FarmBone  = true
    State.IsFarming = true

    boneThread = task.spawn(function()
        while State.FarmBone do
            task.wait(0.15)
            local root = Root(); if not root then task.wait(1); continue end
            local enemy = Nearest(BonesMobs)
            State.CurrentMob = enemy
            if enemy then
                if State.AcceptQuest and not QuestVisible() then
                    MoveTo(BoneQ, 3); task.wait(0.5)
                    local qs = {{"HauntedQuest2",2},{"HauntedQuest2",1},{"HauntedQuest1",1},{"HauntedQuest1",2}}
                    local q = qs[math.random(1,4)]
                    AcceptQuest(q[1], q[2]); task.wait(0.5)
                    continue
                end
                if Alive(enemy) then
                    local cf = FarmCF(enemy)
                    if cf then root.CFrame = cf end
                    Attack(enemy)
                end
            else
                State.CurrentMob = nil
                MoveTo(BonePos, 5); task.wait(0.8)
            end
        end
    end)
end

-- ================================================
-- FARM KATA
-- ================================================
local kataThread = nil
local CakeQ     = Vector3.new(-1927,37,-12842)
local CakePos   = Vector3.new(-2077,252,-12373)
local CakeMirror= Vector3.new(-2151,149,-12404)
local CakeMobs  = {"Cookie Crafter","Cake Guard","Baking Staff","Head Baker"}

local function StopFarmKata()
    State.FarmKata  = false
    State.IsFarming = false
    State.CurrentMob = nil
    if kataThread then pcall(task.cancel, kataThread); kataThread = nil end
end

local function StartFarmKata()
    StartHover()
    StopFarmKata()
    State.FarmKata  = true
    State.IsFarming = true

    kataThread = task.spawn(function()
        local mirrorDone = false
        local mirrorTime = 0
        while State.FarmKata do
            task.wait(0.15)
            local root = Root(); if not root then task.wait(1); continue end

            local cakeMap   = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("CakeLoaf")
            local bigMirror = cakeMap and cakeMap:FindFirstChild("BigMirror")

            if not bigMirror or not bigMirror:FindFirstChild("Other") then
                MoveTo(CakePos, 5); task.wait(0.5); continue
            end

            local prince = Nearest("Cake Prince")

            if bigMirror.Other.Transparency == 0 or prince then
                State.CurrentMob = prince
                if prince and Alive(prince) then
                    mirrorDone = false
                    local cf = FarmCF(prince)
                    if cf then root.CFrame = cf end
                    Attack(prince)
                else
                    if not mirrorDone then
                        mirrorDone = true; mirrorTime = tick()
                        MoveTo(CakeMirror, 5)
                    elseif tick()-mirrorTime < 1 then
                        -- wait
                    end
                end
            else
                local mob = Nearest(CakeMobs)
                State.CurrentMob = mob
                if mob then
                    if State.AcceptQuest and not QuestVisible() then
                        MoveTo(CakeQ, 3); task.wait(0.5)
                        local qs = {{"CakeQuest2",2},{"CakeQuest2",1},{"CakeQuest1",1},{"CakeQuest1",2}}
                        local q = qs[math.random(1,4)]
                        AcceptQuest(q[1], q[2]); task.wait(0.5)
                        continue
                    end
                    if Alive(mob) then
                        local cf = FarmCF(mob)
                        if cf then root.CFrame = cf end
                        Attack(mob)
                    end
                else
                    State.CurrentMob = nil
                    MoveTo(CakePos, 5); task.wait(0.8)
                end
            end
        end
    end)
end

local function StopAll()
    StopFarmLevel(); StopFarmBone(); StopFarmKata()
    StopHover()
    if activeTween then activeTween:Cancel(); activeTween=nil end
end

-- ================================================
-- FIGHTING STYLE SHOP
-- ================================================
local WorldKey = W1 and "w1" or W2 and "w2" or "w3"
local FSData = {
    {n="Black Leg",      w1=Vector3.new(-984,17,3990),       w2=Vector3.new(-4753,37,-4853),   w3=Vector3.new(-5050,374,-3183),  fn="BuyBlackLeg"},
    {n="Electro",        w1=Vector3.new(-5383,17,-2149),      w2=Vector3.new(-4960,39,-4663),   w3=Vector3.new(-5000,317,-3201),  fn="BuyElectro"},
    {n="Fishman Karate", w1=Vector3.new(61586,23,987),        w2=Vector3.new(-4870,37,-4769),   w3=Vector3.new(-5026,375,-3196),  fn="BuyFishmanKarate"},
    {n="Dragon Claw",    w1=nil,                               w2=Vector3.new(695,189,654),      w3=Vector3.new(-4983,374,-3213),  fn="DragonClaw"},
    {n="Superhuman",     w1=nil,                               w2=Vector3.new(1380,250,-5188),   w3=Vector3.new(-5007,374,-3203),  fn="BuySuperhuman"},
    {n="Death Step",     w1=nil,                               w2=Vector3.new(6352,300,-6762),   w3=Vector3.new(-5002,318,-3225),  fn="BuyDeathStep"},
    {n="Sharkman Karate",w1=nil,                               w2=Vector3.new(-2604,242,-10318), w3=Vector3.new(-4969,317,-3226),  fn="BuySharkmanKarate"},
    {n="Electric Claw",  w1=nil, w2=nil,                                                          w3=Vector3.new(-10373,334,-10136),fn="BuyElectricClaw"},
    {n="Dragon Talon",   w1=nil, w2=nil,                                                          w3=Vector3.new(5659,1214,859),    fn="BuyDragonTalon"},
    {n="Godhuman",       w1=nil, w2=nil,                                                          w3=Vector3.new(-13771,337,-9881), fn="BuyGodhuman"},
    {n="Sanguine Art",   w1=nil, w2=nil,                                                          w3=Vector3.new(-16517,26,-185),   fn="BuySanguineArt"},
}

local function BuyFS(style, subL, ibox, ACCENT, RED, DIM)
    local pos = style[WorldKey]
    if not pos then
        subL.Text="Khong co o world nay"; subL.TextColor3=RED; return
    end
    subL.Text="Dang di..."; subL.TextColor3=ACCENT
    task.spawn(function()
        local wasIdle = not State.IsFarming
        if wasIdle then State.IsFarming=true end
        MoveTo(pos, 5)
        task.wait(0.5)
        local root = Root()
        if root and (root.Position-pos).Magnitude <= 200 then
            task.wait(0.3)
            if style.fn == "DragonClaw" then
                pcall(function() RS.Remotes.CommF_:InvokeServer("BlackbeardReward","DragonClaw","2") end)
            else
                pcall(function() RS.Remotes.CommF_:InvokeServer(style.fn) end)
            end
            subL.Text="Da mua!"; subL.TextColor3=Color3.fromRGB(50,200,100)
        else
            subL.Text="That bai"; subL.TextColor3=RED
        end
        task.wait(2)
        subL.Text="Bam de mua"; subL.TextColor3=Color3.fromRGB(90,100,115)
        if ibox then ibox.BackgroundColor3=Color3.fromRGB(45,50,60) end
        if wasIdle and not State.IsFarming then State.IsFarming=false end
    end)
end

-- ================================================
-- UI
-- ================================================
local BG      = Color3.fromRGB(17,19,22)
local BAR     = Color3.fromRGB(13,15,18)
local CARD    = Color3.fromRGB(26,29,34)
local CARD_HL = Color3.fromRGB(16,32,58)
local ACCENT  = Color3.fromRGB(59,143,245)
local RED     = Color3.fromRGB(220,55,55)
local WHITE   = Color3.fromRGB(255,255,255)
local MUTED   = Color3.fromRGB(90,100,115)
local DIM     = Color3.fromRGB(45,50,60)
local TOFF    = Color3.fromRGB(40,44,52)

local function Tw(o,g,t,s,d)
    TweenService:Create(o,TweenInfo.new(t or .2,s or Enum.EasingStyle.Quart,d or Enum.EasingDirection.Out),g):Play()
end
local function Cr(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 8) end
local function St(p,c,tr,th) local s=Instance.new("UIStroke",p);s.Color=c or WHITE;s.Transparency=tr or .9;s.Thickness=th or 1 end
local function Pd(p,t,l,r,b)
    local u=Instance.new("UIPadding",p)
    u.PaddingTop=UDim.new(0,t or 0);u.PaddingLeft=UDim.new(0,l or 0)
    u.PaddingRight=UDim.new(0,r or 0);u.PaddingBottom=UDim.new(0,b or 0)
end
local function DragF(win,bar)
    local drag,ds,sp=false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;sp=win.Position end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- GUI
local GUI = Instance.new("ScreenGui",PG)
GUI.Name="HyunHub";GUI.ResetOnSpawn=false;GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

local Win = Instance.new("Frame",GUI)
Win.Size=UDim2.new(0,700,0,420);Win.Position=UDim2.new(0.5,-350,0.5,-210)
Win.BackgroundColor3=BG;Win.BorderSizePixel=0;Win.ClipsDescendants=true
Cr(Win,12);St(Win,WHITE,.92,1)

local TBar = Instance.new("Frame",Win)
TBar.Size=UDim2.new(1,0,0,46);TBar.BackgroundColor3=BAR;TBar.BorderSizePixel=0;TBar.ZIndex=10
Cr(TBar,12);St(TBar,WHITE,.93,1)
do local f=Instance.new("Frame",TBar);f.Size=UDim2.new(1,0,0,14);f.Position=UDim2.new(0,0,1,-14);f.BackgroundColor3=BAR;f.BorderSizePixel=0;f.ZIndex=11 end
DragF(Win,TBar)

local Logo=Instance.new("TextLabel",TBar)
Logo.Size=UDim2.new(0,90,1,0);Logo.Position=UDim2.new(0,14,0,0);Logo.BackgroundTransparency=1
Logo.Text="Hyun Hub";Logo.TextColor3=WHITE;Logo.TextSize=15;Logo.Font=Enum.Font.GothamBold
Logo.TextXAlignment=Enum.TextXAlignment.Left;Logo.ZIndex=12

local Bdg=Instance.new("Frame",TBar);Bdg.Size=UDim2.new(0,70,0,18);Bdg.Position=UDim2.new(0,108,0.5,-9)
Bdg.BackgroundColor3=Color3.fromRGB(18,32,52);Bdg.BorderSizePixel=0;Bdg.ZIndex=12;Cr(Bdg,4);St(Bdg,ACCENT,.45,1)
local BL=Instance.new("TextLabel",Bdg);BL.Size=UDim2.new(1,0,1,0);BL.BackgroundTransparency=1
BL.Text="v2.0 BETA";BL.TextColor3=ACCENT;BL.TextSize=9;BL.Font=Enum.Font.GothamBold;BL.ZIndex=13

local function TBtn(txt,x)
    local b=Instance.new("TextButton",TBar)
    b.Size=UDim2.new(0,22,0,22);b.Position=UDim2.new(1,x,0.5,-11);b.BackgroundTransparency=1
    b.Text=txt;b.TextColor3=MUTED;b.TextSize=13;b.Font=Enum.Font.GothamBold;b.ZIndex=13
    b.MouseEnter:Connect(function() b.TextColor3=WHITE end)
    b.MouseLeave:Connect(function() b.TextColor3=MUTED end)
    return b
end
local MinBtn=TBtn("_",-52);local CloseBtn=TBtn("X",-28)
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3=RED end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3=MUTED end)
local mini=false
MinBtn.MouseButton1Click:Connect(function()
    mini=not mini
    Tw(Win,{Size=mini and UDim2.new(0,700,0,46) or UDim2.new(0,700,0,420)},.25)
end)
CloseBtn.MouseButton1Click:Connect(function()
    StopAll();Tw(Win,{Size=UDim2.new(0,700,0,0)},.2)
    task.delay(.22,function() GUI:Destroy() end)
end)

-- Sidebar
local Side=Instance.new("Frame",Win)
Side.Size=UDim2.new(0,190,1,-46);Side.Position=UDim2.new(0,0,0,46)
Side.BackgroundColor3=BAR;Side.BorderSizePixel=0;Side.ZIndex=5
Cr(Side,12);St(Side,WHITE,.93,1)
do local f=Instance.new("Frame",Side);f.Size=UDim2.new(1,0,0,14);f.BackgroundColor3=BAR;f.BorderSizePixel=0;f.ZIndex=6 end
do local f=Instance.new("Frame",Side);f.Size=UDim2.new(0,14,1,0);f.Position=UDim2.new(1,-14,0,0);f.BackgroundColor3=BAR;f.BorderSizePixel=0;f.ZIndex=6 end

local function SecL(txt,y)
    local l=Instance.new("TextLabel",Side)
    l.Size=UDim2.new(1,-18,0,18);l.Position=UDim2.new(0,18,0,y);l.BackgroundTransparency=1
    l.Text=txt;l.TextColor3=MUTED;l.TextSize=9;l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left;l.ZIndex=7
end
local function SideBtn(lbl,active,y)
    local it=Instance.new("TextButton",Side)
    it.Size=UDim2.new(1,0,0,36);it.Position=UDim2.new(0,0,0,y)
    it.BackgroundColor3=active and Color3.fromRGB(18,38,68) or BAR
    it.BackgroundTransparency=active and 0 or 1
    it.BorderSizePixel=0;it.Text="";it.ZIndex=7
    local ab=Instance.new("Frame",it);ab.Name="AB";ab.Size=UDim2.new(0,3,1,-8);ab.Position=UDim2.new(0,0,0,4)
    ab.BackgroundColor3=ACCENT;ab.BorderSizePixel=0;ab.ZIndex=8;ab.Visible=active
    local tl=Instance.new("TextLabel",it);tl.Name="TL";tl.Size=UDim2.new(1,-16,1,0);tl.Position=UDim2.new(0,16,0,0)
    tl.BackgroundTransparency=1;tl.Text=lbl;tl.TextColor3=active and WHITE or MUTED
    tl.TextSize=12;tl.Font=Enum.Font.GothamSemibold;tl.TextXAlignment=Enum.TextXAlignment.Left;tl.ZIndex=8
    it.MouseEnter:Connect(function() if not active then it.BackgroundTransparency=.9 end end)
    it.MouseLeave:Connect(function() if not active then it.BackgroundTransparency=1 end end)
    return it
end

SecL("FARMING",18)
local sG=SideBtn("General",true,44)
local sC=SideBtn("Configuration",false,82)
SecL("VAT PHAM",128)
local sSt=SideBtn("Stack Farming",false,152)
local sIt=SideBtn("Item Farming",false,190)
local sSh=SideBtn("Shop",false,228)
local sAB=SideBtn("Anti Ban",false,266)

-- Tab holder
local TH=Instance.new("Frame",Win)
TH.Size=UDim2.new(1,-190,1,-46);TH.Position=UDim2.new(0,190,0,46)
TH.BackgroundTransparency=1;TH.BorderSizePixel=0;TH.ZIndex=5

local function MkTab(n)
    local t=Instance.new("ScrollingFrame",TH)
    t.Name=n;t.Size=UDim2.new(1,0,1,0);t.BackgroundTransparency=1
    t.BorderSizePixel=0;t.ScrollBarThickness=3
    t.ScrollBarImageColor3=Color3.fromRGB(60,70,85)
    t.CanvasSize=UDim2.new(0,0,0,0);t.AutomaticCanvasSize=Enum.AutomaticSize.Y
    t.ZIndex=5;t.Visible=false;Pd(t,22,22,22,22)
    return t
end

local TG=MkTab("G");TG.Visible=true
local TC=MkTab("C")
local TSt=MkTab("St")
local TIt=MkTab("It")
local TSh=MkTab("Sh")
local TAB=MkTab("AB")

local TABS  = {TG,TC,TSt,TIt,TSh,TAB}
local SITMS = {sG,sC,sSt,sIt,sSh,sAB}

local function Switch(idx)
    for i,t in ipairs(TABS) do t.Visible=(i==idx) end
    for i,it in ipairs(SITMS) do
        local on=(i==idx)
        it.BackgroundColor3=on and Color3.fromRGB(18,38,68) or BAR
        it.BackgroundTransparency=on and 0 or 1
        local ab=it:FindFirstChild("AB");if ab then ab.Visible=on end
        local tl=it:FindFirstChild("TL");if tl then tl.TextColor3=on and WHITE or MUTED end
    end
end
sG.MouseButton1Click:Connect(function()  Switch(1) end)
sC.MouseButton1Click:Connect(function()  Switch(2) end)
sSt.MouseButton1Click:Connect(function() Switch(3) end)
sIt.MouseButton1Click:Connect(function() Switch(4) end)
sSh.MouseButton1Click:Connect(function() Switch(5) end)
sAB.MouseButton1Click:Connect(function() Switch(6) end)

-- Card constants
local CW=230;local CH=80;local CG=10;local CY=58

local function MkToggle(p,on,z)
    local bg=Instance.new("Frame",p)
    bg.Size=UDim2.new(0,38,0,22);bg.BackgroundColor3=on and ACCENT or TOFF
    bg.BorderSizePixel=0;bg.ZIndex=z or 8;Cr(bg,11)
    local k=Instance.new("Frame",bg)
    k.Size=UDim2.new(0,16,0,16)
    k.Position=on and UDim2.new(0,19,0,3) or UDim2.new(0,3,0,3)
    k.BackgroundColor3=WHITE;k.BorderSizePixel=0;k.ZIndex=(z or 8)+1;Cr(k,8)
    return bg,k
end
local function AnimToggle(bg,k,s)
    Tw(bg,{BackgroundColor3=s and ACCENT or TOFF},.2)
    Tw(k,{Position=s and UDim2.new(0,19,0,3) or UDim2.new(0,3,0,3)},.2,Enum.EasingStyle.Back)
end

local function Card(parent,col,row,title,sub,defOn,cb)
    local xO=col*(CW+CG);local yO=CY+row*(CH+CG);local on=defOn==true
    local card=Instance.new("Frame",parent)
    card.Size=UDim2.new(0,CW,0,CH);card.Position=UDim2.new(0,xO,0,yO)
    card.BackgroundColor3=on and CARD_HL or CARD;card.BorderSizePixel=0;card.ZIndex=6;Cr(card,10)
    local stk=Instance.new("UIStroke",card);stk.Color=on and ACCENT or WHITE;stk.Transparency=on and .5 or .92;stk.Thickness=1
    local ibox=Instance.new("Frame",card);ibox.Size=UDim2.new(0,42,0,42);ibox.Position=UDim2.new(0,14,0.5,-21)
    ibox.BackgroundColor3=on and ACCENT or DIM;ibox.BorderSizePixel=0;ibox.ZIndex=7;Cr(ibox,10)
    if not on then St(ibox,WHITE,.9,1) end
    local ttl=Instance.new("TextLabel",card);ttl.Size=UDim2.new(1,-76,0,18);ttl.Position=UDim2.new(0,66,0,15)
    ttl.BackgroundTransparency=1;ttl.Text=title;ttl.TextColor3=WHITE
    ttl.TextSize=13;ttl.Font=Enum.Font.GothamSemibold;ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.ZIndex=7
    local sl=Instance.new("TextLabel",card);sl.Size=UDim2.new(1,-76,0,14);sl.Position=UDim2.new(0,66,0,35)
    sl.BackgroundTransparency=1;sl.Text=sub;sl.TextColor3=MUTED
    sl.TextSize=10;sl.Font=Enum.Font.GothamBold;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=7
    local tbg,knob=MkToggle(card,on,8);tbg.Position=UDim2.new(1,-50,0.5,-11)
    local hov=Instance.new("TextButton",card)
    hov.Size=UDim2.new(1,0,1,0);hov.BackgroundTransparency=1;hov.Text="";hov.ZIndex=9
    hov.MouseButton1Click:Connect(function()
        on=not on;AnimToggle(tbg,knob,on)
        Tw(card,{BackgroundColor3=on and CARD_HL or CARD},.2)
        Tw(stk,{Color=on and ACCENT or WHITE,Transparency=on and .5 or .92},.2)
        Tw(ibox,{BackgroundColor3=on and ACCENT or DIM},.2)
        sl.Text=on and "ACTIVE" or "DISABLE";sl.TextColor3=on and ACCENT or MUTED
        if cb then cb(on) end
    end)
    hov.MouseEnter:Connect(function() Tw(card,{BackgroundColor3=on and Color3.fromRGB(18,42,72) or Color3.fromRGB(30,34,40)},.15) end)
    hov.MouseLeave:Connect(function() Tw(card,{BackgroundColor3=on and CARD_HL or CARD},.15) end)
end

local function TabHead(parent,title,sub)
    local tl=Instance.new("TextLabel",parent);tl.Size=UDim2.new(1,0,0,34);tl.BackgroundTransparency=1
    tl.Text=title;tl.TextColor3=WHITE;tl.TextSize=26;tl.Font=Enum.Font.GothamBold;tl.TextXAlignment=Enum.TextXAlignment.Left;tl.ZIndex=6
    local sl=Instance.new("TextLabel",parent);sl.Size=UDim2.new(1,0,0,16);sl.Position=UDim2.new(0,0,0,34);sl.BackgroundTransparency=1
    sl.Text=sub;sl.TextColor3=MUTED;sl.TextSize=11;sl.Font=Enum.Font.Gotham;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=6
end

-- ================================================
-- TAB GENERAL
-- ================================================

-- Title (Y=0)
do
    local tl=Instance.new("TextLabel",TG);tl.Size=UDim2.new(1,0,0,28);tl.Position=UDim2.new(0,0,0,0)
    tl.BackgroundTransparency=1;tl.Text="General";tl.TextColor3=WHITE
    tl.TextSize=24;tl.Font=Enum.Font.GothamBold;tl.TextXAlignment=Enum.TextXAlignment.Left;tl.ZIndex=6
end

-- ================================================
-- TAB GENERAL
-- ================================================

-- Title (Y=0)
do
    local tl=Instance.new("TextLabel",TG);tl.Size=UDim2.new(1,0,0,28);tl.Position=UDim2.new(0,0,0,0)
    tl.BackgroundTransparency=1;tl.Text="General";tl.TextColor3=WHITE
    tl.TextSize=24;tl.Font=Enum.Font.GothamBold;tl.TextXAlignment=Enum.TextXAlignment.Left;tl.ZIndex=6
end

-- ================================================
-- DISCORD INVITE CARD (nam trong TG, Y=32)
-- ================================================
do
    local CARD_W = CW*2 + CG  -- full width (2 columns)
    local CARD_H = 110
    local DISCORD_Y = 32

    local card = Instance.new("Frame", TG)
    card.Name = "DiscordCard"
    card.Size = UDim2.new(0, CARD_W, 0, CARD_H)
    card.Position = UDim2.new(0, 0, 0, DISCORD_Y)
    card.BackgroundColor3 = Color3.fromRGB(22, 25, 31)
    card.BorderSizePixel = 0
    card.ZIndex = 6
    card.ClipsDescendants = true
    Cr(card, 12)
    St(card, Color3.fromRGB(88, 101, 242), 0.55, 1)

    -- Gradient overlay phia tren (tao hieu ung banner)
    local bannerGrad = Instance.new("Frame", card)
    bannerGrad.Size = UDim2.new(1, 0, 0, 44)
    bannerGrad.Position = UDim2.new(0, 0, 0, 0)
    bannerGrad.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    bannerGrad.BorderSizePixel = 0
    bannerGrad.ZIndex = 7
    local bannerGradObj = Instance.new("UIGradient", bannerGrad)
    bannerGradObj.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 65, 160))
    }
    bannerGradObj.Rotation = 30
    -- Round chi goc tren
    local bgCr = Instance.new("UICorner", bannerGrad)
    bgCr.CornerRadius = UDim.new(0, 12)
    -- Che goc duoi cua banner
    local bannerFill = Instance.new("Frame", bannerGrad)
    bannerFill.Size = UDim2.new(1, 0, 0, 14)
    bannerFill.Position = UDim2.new(0, 0, 1, -14)
    bannerFill.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    bannerFill.BorderSizePixel = 0
    bannerFill.ZIndex = 7

    -- Discord icon tren banner
    local discIcon = Instance.new("TextLabel", bannerGrad)
    discIcon.Size = UDim2.new(0, 30, 0, 30)
    discIcon.Position = UDim2.new(0, 14, 0.5, -15)
    discIcon.BackgroundTransparency = 1
    discIcon.Text = "🎮"
    discIcon.TextSize = 22
    discIcon.ZIndex = 8
    discIcon.Font = Enum.Font.GothamBold

    local bannerTitle = Instance.new("TextLabel", bannerGrad)
    bannerTitle.Size = UDim2.new(1, -60, 1, 0)
    bannerTitle.Position = UDim2.new(0, 48, 0, 0)
    bannerTitle.BackgroundTransparency = 1
    bannerTitle.Text = "Hyun Hub | Community"
    bannerTitle.TextColor3 = WHITE
    bannerTitle.TextSize = 14
    bannerTitle.Font = Enum.Font.GothamBold
    bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
    bannerTitle.ZIndex = 8

    -- Online badge tren banner
    local onlineBadge = Instance.new("Frame", bannerGrad)
    onlineBadge.Size = UDim2.new(0, 75, 0, 18)
    onlineBadge.Position = UDim2.new(1, -90, 0.5, -9)
    onlineBadge.BackgroundColor3 = Color3.fromRGB(35, 45, 90)
    onlineBadge.BorderSizePixel = 0
    onlineBadge.ZIndex = 8
    Cr(onlineBadge, 4)
    local onlineDot = Instance.new("Frame", onlineBadge)
    onlineDot.Size = UDim2.new(0, 6, 0, 6)
    onlineDot.Position = UDim2.new(0, 6, 0.5, -3)
    onlineDot.BackgroundColor3 = Color3.fromRGB(87, 242, 135)
    onlineDot.BorderSizePixel = 0
    onlineDot.ZIndex = 9
    Cr(onlineDot, 3)
    local onlineTxt = Instance.new("TextLabel", onlineBadge)
    onlineTxt.Size = UDim2.new(1, -18, 1, 0)
    onlineTxt.Position = UDim2.new(0, 16, 0, 0)
    onlineTxt.BackgroundTransparency = 1
    onlineTxt.Text = "Online"
    onlineTxt.TextColor3 = Color3.fromRGB(87, 242, 135)
    onlineTxt.TextSize = 9
    onlineTxt.Font = Enum.Font.GothamBold
    onlineTxt.ZIndex = 9

    -- Phan noi dung duoi banner
    local contentFrame = Instance.new("Frame", card)
    contentFrame.Size = UDim2.new(1, 0, 0, CARD_H - 44)
    contentFrame.Position = UDim2.new(0, 0, 0, 44)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 7

    local descText = Instance.new("TextLabel", contentFrame)
    descText.Size = UDim2.new(1, -130, 1, 0)
    descText.Position = UDim2.new(0, 16, 0, 0)
    descText.BackgroundTransparency = 1
    descText.Text = "Script Free, Fast Update, Fast Support.\nJoin de nhan thong bao cap nhat moi nhat!"
    descText.TextColor3 = Color3.fromRGB(160, 170, 185)
    descText.TextSize = 11
    descText.Font = Enum.Font.Gotham
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.TextYAlignment = Enum.TextYAlignment.Center
    descText.TextWrapped = true
    descText.ZIndex = 8

    -- JOIN button
    local joinBtn = Instance.new("TextButton", contentFrame)
    joinBtn.Size = UDim2.new(0, 90, 0, 34)
    joinBtn.Position = UDim2.new(1, -106, 0.5, -17)
    joinBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    joinBtn.BorderSizePixel = 0
    joinBtn.Text = ""
    joinBtn.ZIndex = 8
    Cr(joinBtn, 8)

    local joinTxt = Instance.new("TextLabel", joinBtn)
    joinTxt.Size = UDim2.new(1, 0, 1, 0)
    joinTxt.BackgroundTransparency = 1
    joinTxt.Text = "Join"
    joinTxt.TextColor3 = WHITE
    joinTxt.TextSize = 13
    joinTxt.Font = Enum.Font.GothamBold
    joinTxt.ZIndex = 9

    -- Hover & click
    joinBtn.MouseEnter:Connect(function()
        Tw(joinBtn, {BackgroundColor3 = Color3.fromRGB(108, 121, 255)}, 0.15)
    end)
    joinBtn.MouseLeave:Connect(function()
        Tw(joinBtn, {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}, 0.15)
    end)
    joinBtn.MouseButton1Click:Connect(function()
        -- Flash animation
        Tw(joinBtn, {BackgroundColor3 = Color3.fromRGB(67, 181, 129)}, 0.1)
        joinTxt.Text = "Copied!"
        pcall(function() setclipboard("https://discord.gg/yourlink") end)
        task.delay(1.5, function()
            joinTxt.Text = "Join"
            Tw(joinBtn, {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}, 0.2)
        end)
    end)

    -- Card hover
    card.MouseEnter:Connect(function()
        Tw(card, {BackgroundColor3 = Color3.fromRGB(28, 31, 38)}, 0.15)
    end)
    card.MouseLeave:Connect(function()
        Tw(card, {BackgroundColor3 = Color3.fromRGB(22, 25, 31)}, 0.15)
    end)
end

-- Section label "Farming Toggle"
do
    local lbl=Instance.new("TextLabel",TG);lbl.Size=UDim2.new(1,0,0,14)
    lbl.Position=UDim2.new(0,0,0,32+110+8);lbl.BackgroundTransparency=1
    lbl.Text="Farming Toggle";lbl.TextColor3=MUTED
    lbl.TextSize=10;lbl.Font=Enum.Font.GothamBold;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.ZIndex=6
end

-- Cards bat dau sau Discord card + label
local TG_Y = 32+110+8+18  -- title(32) + discord(110) + gap(8) + label(18)


-- Farm Level (col=0 row=0)
do
    local col,row=0,0;local xO=col*(CW+CG);local yO=TG_Y+row*(CH+CG);local on=false
    local card=Instance.new("Frame",TG);card.Size=UDim2.new(0,CW,0,CH);card.Position=UDim2.new(0,xO,0,yO)
    card.BackgroundColor3=CARD;card.BorderSizePixel=0;card.ZIndex=6;Cr(card,10)
    local stk=Instance.new("UIStroke",card);stk.Color=WHITE;stk.Transparency=.92;stk.Thickness=1
    local ibox=Instance.new("Frame",card);ibox.Size=UDim2.new(0,42,0,42);ibox.Position=UDim2.new(0,14,0.5,-21)
    ibox.BackgroundColor3=DIM;ibox.BorderSizePixel=0;ibox.ZIndex=7;Cr(ibox,10);St(ibox,WHITE,.9,1)
    local ttl=Instance.new("TextLabel",card);ttl.Size=UDim2.new(1,-76,0,18);ttl.Position=UDim2.new(0,66,0,15)
    ttl.BackgroundTransparency=1;ttl.Text="Farm Level";ttl.TextColor3=WHITE
    ttl.TextSize=13;ttl.Font=Enum.Font.GothamSemibold;ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.ZIndex=7
    local sl=Instance.new("TextLabel",card);sl.Size=UDim2.new(1,-76,0,14);sl.Position=UDim2.new(0,66,0,35)
    sl.BackgroundTransparency=1;sl.Text="DISABLE";sl.TextColor3=MUTED
    sl.TextSize=10;sl.Font=Enum.Font.GothamBold;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=7
    local tbg,knob=MkToggle(card,on,8);tbg.Position=UDim2.new(1,-50,0.5,-11)
    local hov=Instance.new("TextButton",card);hov.Size=UDim2.new(1,0,1,0);hov.BackgroundTransparency=1;hov.Text="";hov.ZIndex=9
    hov.MouseButton1Click:Connect(function()
        on=not on;AnimToggle(tbg,knob,on)
        Tw(card,{BackgroundColor3=on and CARD_HL or CARD},.2)
        Tw(stk,{Color=on and ACCENT or WHITE,Transparency=on and .5 or .92},.2)
        Tw(ibox,{BackgroundColor3=on and ACCENT or DIM},.2)
        sl.Text=on and "ACTIVE" or "DISABLE";sl.TextColor3=on and ACCENT or MUTED
        if on then StopAll();StartFarmLevel() else StopFarmLevel() end
    end)
    hov.MouseEnter:Connect(function() Tw(card,{BackgroundColor3=on and Color3.fromRGB(18,42,72) or Color3.fromRGB(30,34,40)},.15) end)
    hov.MouseLeave:Connect(function() Tw(card,{BackgroundColor3=on and CARD_HL or CARD},.15) end)
end

-- Accept Quest (col=1 row=0)
do
    local col,row=1,0;local xO=col*(CW+CG);local yO=TG_Y+row*(CH+CG);local on=false
    local card=Instance.new("Frame",TG);card.Size=UDim2.new(0,CW,0,CH);card.Position=UDim2.new(0,xO,0,yO)
    card.BackgroundColor3=CARD;card.BorderSizePixel=0;card.ZIndex=6;Cr(card,10)
    local stk=Instance.new("UIStroke",card);stk.Color=WHITE;stk.Transparency=.92;stk.Thickness=1
    local ibox=Instance.new("Frame",card);ibox.Size=UDim2.new(0,42,0,42);ibox.Position=UDim2.new(0,14,0.5,-21)
    ibox.BackgroundColor3=DIM;ibox.BorderSizePixel=0;ibox.ZIndex=7;Cr(ibox,10);St(ibox,WHITE,.9,1)
    local ttl=Instance.new("TextLabel",card);ttl.Size=UDim2.new(1,-76,0,18);ttl.Position=UDim2.new(0,66,0,15)
    ttl.BackgroundTransparency=1;ttl.Text="Accept Quest";ttl.TextColor3=WHITE
    ttl.TextSize=13;ttl.Font=Enum.Font.GothamSemibold;ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.ZIndex=7
    local sl=Instance.new("TextLabel",card);sl.Size=UDim2.new(1,-76,0,14);sl.Position=UDim2.new(0,66,0,35)
    sl.BackgroundTransparency=1;sl.Text="DISABLE";sl.TextColor3=MUTED
    sl.TextSize=10;sl.Font=Enum.Font.GothamBold;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=7
    local tbg,knob=MkToggle(card,on,8);tbg.Position=UDim2.new(1,-50,0.5,-11)
    local hov=Instance.new("TextButton",card);hov.Size=UDim2.new(1,0,1,0);hov.BackgroundTransparency=1;hov.Text="";hov.ZIndex=9
    hov.MouseButton1Click:Connect(function()
        on=not on;AnimToggle(tbg,knob,on)
        Tw(card,{BackgroundColor3=on and CARD_HL or CARD},.2)
        Tw(stk,{Color=on and ACCENT or WHITE,Transparency=on and .5 or .92},.2)
        Tw(ibox,{BackgroundColor3=on and ACCENT or DIM},.2)
        sl.Text=on and "ACTIVE" or "DISABLE";sl.TextColor3=on and ACCENT or MUTED
        State.AcceptQuest=on
    end)
    hov.MouseEnter:Connect(function() Tw(card,{BackgroundColor3=on and Color3.fromRGB(18,42,72) or Color3.fromRGB(30,34,40)},.15) end)
    hov.MouseLeave:Connect(function() Tw(card,{BackgroundColor3=on and CARD_HL or CARD},.15) end)
end

-- Method Farm dropdown (col=0 row=1)
do
    local FMETHODS = {"Farm Bone","Farm Katakuri"}
    local fmIdx = 1; local fmOn = false
    local isOpen = false

    local xO=0; local yO=TG_Y+(CH+CG)
    local card=Instance.new("Frame",TG)
    card.Size=UDim2.new(0,CW,0,CH);card.Position=UDim2.new(0,xO,0,yO)
    card.BackgroundColor3=CARD;card.BorderSizePixel=0;card.ZIndex=6;Cr(card,10)
    local cst=Instance.new("UIStroke",card);cst.Color=WHITE;cst.Transparency=.92;cst.Thickness=1
    local ibox=Instance.new("Frame",card);ibox.Size=UDim2.new(0,42,0,42);ibox.Position=UDim2.new(0,14,0.5,-21)
    ibox.BackgroundColor3=DIM;ibox.BorderSizePixel=0;ibox.ZIndex=7;Cr(ibox,10);St(ibox,WHITE,.9,1)
    local ttl=Instance.new("TextLabel",card);ttl.Size=UDim2.new(1,-76,0,18);ttl.Position=UDim2.new(0,66,0,15)
    ttl.BackgroundTransparency=1;ttl.Text="Method Farm";ttl.TextColor3=WHITE
    ttl.TextSize=13;ttl.Font=Enum.Font.GothamSemibold;ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.ZIndex=7
    local sl=Instance.new("TextLabel",card);sl.Size=UDim2.new(1,-76,0,14);sl.Position=UDim2.new(0,66,0,35)
    sl.BackgroundTransparency=1;sl.Text=FMETHODS[fmIdx];sl.TextColor3=ACCENT
    sl.TextSize=10;sl.Font=Enum.Font.GothamBold;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=7
    local arr=Instance.new("TextButton",card);arr.Size=UDim2.new(0,30,0,30);arr.Position=UDim2.new(1,-40,0.5,-15)
    arr.BackgroundColor3=DIM;arr.BorderSizePixel=0;arr.Text="v";arr.TextColor3=MUTED
    arr.TextSize=12;arr.Font=Enum.Font.GothamBold;arr.ZIndex=10;Cr(arr,6)
    arr.MouseEnter:Connect(function() Tw(arr,{BackgroundColor3=Color3.fromRGB(65,70,82)},.15) end)
    arr.MouseLeave:Connect(function() Tw(arr,{BackgroundColor3=DIM},.15) end)

    local menuH=#FMETHODS*34+8
    local menu=Instance.new("Frame",TG)
    menu.Size=UDim2.new(0,CW,0,0);menu.Position=UDim2.new(0,xO,0,TG_Y+(CH+CG)+CH+4)
    menu.BackgroundColor3=Color3.fromRGB(20,24,30);menu.BorderSizePixel=0
    menu.ZIndex=50;menu.ClipsDescendants=true;Cr(menu,8);St(menu,ACCENT,.7,1)
    for i,m in ipairs(FMETHODS) do
        local row=Instance.new("TextButton",menu)
        row.Size=UDim2.new(1,-8,0,28);row.Position=UDim2.new(0,4,0,4+(i-1)*34)
        row.BackgroundColor3=Color3.fromRGB(28,32,40);row.BackgroundTransparency=1
        row.BorderSizePixel=0;row.Text=m;row.TextColor3=i==fmIdx and ACCENT or WHITE
        row.TextSize=12;row.Font=Enum.Font.GothamBold;row.ZIndex=51;Cr(row,6)
        row.MouseEnter:Connect(function() Tw(row,{BackgroundTransparency=0},.12) end)
        row.MouseLeave:Connect(function() Tw(row,{BackgroundTransparency=1},.12) end)
        row.MouseButton1Click:Connect(function()
            if fmOn then
                if fmIdx==1 then StopFarmBone() else StopFarmKata() end
                fmOn=false
            end
            fmIdx=i; sl.Text=FMETHODS[i]
            for _,c in ipairs(menu:GetChildren()) do
                if c:IsA("TextButton") then c.TextColor3=WHITE end
            end
            row.TextColor3=ACCENT; isOpen=false
            Tw(menu,{Size=UDim2.new(0,CW,0,0)},.15); Tw(arr,{Rotation=0},.15)
        end)
    end
    local function TogMenu()
        isOpen=not isOpen
        if isOpen then Tw(menu,{Size=UDim2.new(0,CW,0,menuH)},.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out);Tw(arr,{Rotation=180},.2)
        else Tw(menu,{Size=UDim2.new(0,CW,0,0)},.15);Tw(arr,{Rotation=0},.15) end
    end
    arr.MouseButton1Click:Connect(TogMenu)
    local hov=Instance.new("TextButton",card);hov.Size=UDim2.new(1,-50,1,0);hov.BackgroundTransparency=1;hov.Text="";hov.ZIndex=9
    hov.MouseButton1Click:Connect(TogMenu)
    hov.MouseEnter:Connect(function() Tw(card,{BackgroundColor3=Color3.fromRGB(30,34,40)},.15) end)
    hov.MouseLeave:Connect(function() Tw(card,{BackgroundColor3=CARD},.15) end)
end

-- Start Farm (col=1 row=1)
do
    local xO=CW+CG; local yO=TG_Y+(CH+CG); local on=false
    local card=Instance.new("Frame",TG)
    card.Size=UDim2.new(0,CW,0,CH);card.Position=UDim2.new(0,xO,0,yO)
    card.BackgroundColor3=CARD;card.BorderSizePixel=0;card.ZIndex=6;Cr(card,10)
    local stk=Instance.new("UIStroke",card);stk.Color=WHITE;stk.Transparency=.92;stk.Thickness=1
    local ibox=Instance.new("Frame",card);ibox.Size=UDim2.new(0,42,0,42);ibox.Position=UDim2.new(0,14,0.5,-21)
    ibox.BackgroundColor3=DIM;ibox.BorderSizePixel=0;ibox.ZIndex=7;Cr(ibox,10);St(ibox,WHITE,.9,1)
    local ttl=Instance.new("TextLabel",card);ttl.Size=UDim2.new(1,-76,0,18);ttl.Position=UDim2.new(0,66,0,15)
    ttl.BackgroundTransparency=1;ttl.Text="Start Farm";ttl.TextColor3=WHITE
    ttl.TextSize=13;ttl.Font=Enum.Font.GothamSemibold;ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.ZIndex=7
    local sl=Instance.new("TextLabel",card);sl.Size=UDim2.new(1,-76,0,14);sl.Position=UDim2.new(0,66,0,35)
    sl.BackgroundTransparency=1;sl.Text="DISABLE";sl.TextColor3=MUTED
    sl.TextSize=10;sl.Font=Enum.Font.GothamBold;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=7
    local tbg,knob=MkToggle(card,false,8);tbg.Position=UDim2.new(1,-50,0.5,-11)
    local hov=Instance.new("TextButton",card)
    hov.Size=UDim2.new(1,0,1,0);hov.BackgroundTransparency=1;hov.Text="";hov.ZIndex=9
    hov.MouseButton1Click:Connect(function()
        on=not on; AnimToggle(tbg,knob,on)
        Tw(card,{BackgroundColor3=on and CARD_HL or CARD},.2)
        Tw(stk,{Color=on and ACCENT or WHITE,Transparency=on and .5 or .92},.2)
        Tw(ibox,{BackgroundColor3=on and ACCENT or DIM},.2)
        sl.Text=on and "ACTIVE" or "DISABLE"; sl.TextColor3=on and ACCENT or MUTED
        if on then
            StopAll()
            -- dung Farm Bone hoac Kata tu dropdown
            local FMETHODS={"Farm Bone","Farm Katakuri"}
            -- Doc fmIdx tu closure - dung bien global tam
            if _G._HyunFmIdx == 1 then StartFarmBone()
            else StartFarmKata() end
        else
            StopFarmBone(); StopFarmKata()
        end
    end)
    hov.MouseEnter:Connect(function() Tw(card,{BackgroundColor3=on and Color3.fromRGB(18,42,72) or Color3.fromRGB(30,34,40)},.15) end)
    hov.MouseLeave:Connect(function() Tw(card,{BackgroundColor3=on and CARD_HL or CARD},.15) end)
end
_G._HyunFmIdx = 1  -- default Farm Bone

-- ================================================
-- TAB CONFIGURATION
-- ================================================
TabHead(TC,"Configuration","Settings")

do
    local METHODS = {"Melee","Sword","Blox Fruit","Gun"}
    local mIdx = 1; local isOpen = false

    local card=Instance.new("Frame",TC)
    card.Size=UDim2.new(0,CW,0,CH);card.Position=UDim2.new(0,0,0,CY)
    card.BackgroundColor3=CARD;card.BorderSizePixel=0;card.ZIndex=6;Cr(card,10)
    local cst=Instance.new("UIStroke",card);cst.Color=ACCENT;cst.Transparency=.5;cst.Thickness=1
    local ibox=Instance.new("Frame",card);ibox.Size=UDim2.new(0,42,0,42);ibox.Position=UDim2.new(0,14,0.5,-21)
    ibox.BackgroundColor3=ACCENT;ibox.BorderSizePixel=0;ibox.ZIndex=7;Cr(ibox,10)
    local ttl=Instance.new("TextLabel",card);ttl.Size=UDim2.new(1,-76,0,18);ttl.Position=UDim2.new(0,66,0,15)
    ttl.BackgroundTransparency=1;ttl.Text="Farm Method";ttl.TextColor3=WHITE
    ttl.TextSize=13;ttl.Font=Enum.Font.GothamSemibold;ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.ZIndex=7
    local sl=Instance.new("TextLabel",card);sl.Size=UDim2.new(1,-76,0,14);sl.Position=UDim2.new(0,66,0,35)
    sl.BackgroundTransparency=1;sl.Text=METHODS[mIdx];sl.TextColor3=ACCENT
    sl.TextSize=10;sl.Font=Enum.Font.GothamBold;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=7
    local arr=Instance.new("TextButton",card);arr.Size=UDim2.new(0,28,0,28);arr.Position=UDim2.new(1,-40,0.5,-14)
    arr.BackgroundColor3=DIM;arr.BorderSizePixel=0;arr.Text="v";arr.TextColor3=MUTED
    arr.TextSize=12;arr.Font=Enum.Font.GothamBold;arr.ZIndex=10;Cr(arr,6)
    arr.MouseEnter:Connect(function() Tw(arr,{BackgroundColor3=Color3.fromRGB(65,70,82)},.15) end)
    arr.MouseLeave:Connect(function() Tw(arr,{BackgroundColor3=DIM},.15) end)
    local menuH=#METHODS*34+8
    local menu=Instance.new("Frame",TC)
    menu.Size=UDim2.new(0,CW,0,0);menu.Position=UDim2.new(0,0,0,CY+CH+6)
    menu.BackgroundColor3=Color3.fromRGB(20,24,30);menu.BorderSizePixel=0
    menu.ZIndex=30;menu.ClipsDescendants=true;Cr(menu,8);St(menu,ACCENT,.7,1)
    for i,m in ipairs(METHODS) do
        local row=Instance.new("TextButton",menu)
        row.Size=UDim2.new(1,-8,0,28);row.Position=UDim2.new(0,4,0,4+(i-1)*34)
        row.BackgroundColor3=Color3.fromRGB(28,32,40);row.BackgroundTransparency=1
        row.BorderSizePixel=0;row.Text=m;row.TextColor3=i==mIdx and ACCENT or WHITE
        row.TextSize=12;row.Font=Enum.Font.GothamBold;row.ZIndex=31;Cr(row,6)
        row.MouseEnter:Connect(function() Tw(row,{BackgroundTransparency=0},.12) end)
        row.MouseLeave:Connect(function() Tw(row,{BackgroundTransparency=1},.12) end)
        row.MouseButton1Click:Connect(function()
            mIdx=i; State.ChooseWP=METHODS[i]; sl.Text=METHODS[i]
            for _,c in ipairs(menu:GetChildren()) do if c:IsA("TextButton") then c.TextColor3=WHITE end end
            row.TextColor3=ACCENT; isOpen=false
            Tw(menu,{Size=UDim2.new(0,CW,0,0)},.15); Tw(arr,{Rotation=0},.15)
        end)
    end
    local function TM()
        isOpen=not isOpen
        if isOpen then Tw(menu,{Size=UDim2.new(0,CW,0,menuH)},.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out);Tw(arr,{Rotation=180},.2)
        else Tw(menu,{Size=UDim2.new(0,CW,0,0)},.15);Tw(arr,{Rotation=0},.15) end
    end
    arr.MouseButton1Click:Connect(TM)
    local hov=Instance.new("TextButton",card);hov.Size=UDim2.new(1,-50,1,0);hov.BackgroundTransparency=1;hov.Text="";hov.ZIndex=9
    hov.MouseButton1Click:Connect(TM)
    hov.MouseEnter:Connect(function() Tw(card,{BackgroundColor3=Color3.fromRGB(30,34,40)},.15) end)
    hov.MouseLeave:Connect(function() Tw(card,{BackgroundColor3=CARD},.15) end)
end

Card(TC,1,0,"Bring Mob","DISABLE",false,function(on) State.BringMob=on end)
Card(TC,0,1,"No Clip","DISABLE",false,function(on) State.Noclip=on end)
Card(TC,1,1,"Auto V3","DISABLE",false,function(on) State.AutoV3=on end)
Card(TC,0,2,"Auto V4","DISABLE",false,function(on) State.AutoV4=on end)
Card(TC,1,2,"Auto Ken","DISABLE",false,function(on) State.AutoKen=on end)

-- ================================================
-- TAB STACK / ITEM (placeholder)
-- ================================================
TabHead(TSt,"Stack Farming","Coming soon...")
TabHead(TIt,"Item Farming","Coming soon...")

-- ================================================
-- TAB SHOP
-- ================================================
TabHead(TSh,"Shop","Mua & nang cap")

Card(TSh,0,0,"Reset Stats","Dat lai chi so",false,function(on)
    if on then pcall(function() RS.Remotes.CommF_:InvokeServer("ResetStats") end) end
end)
Card(TSh,1,0,"Auto Bones","DISABLE",false,function(on) State.AutoBones=on end)

local fsLbl=Instance.new("TextLabel",TSh)
fsLbl.Size=UDim2.new(1,0,0,14);fsLbl.Position=UDim2.new(0,0,0,CY+(CH+CG))
fsLbl.BackgroundTransparency=1;fsLbl.Text="FIGHTING STYLE";fsLbl.TextColor3=MUTED
fsLbl.TextSize=9;fsLbl.Font=Enum.Font.GothamBold;fsLbl.TextXAlignment=Enum.TextXAlignment.Left;fsLbl.ZIndex=6

local FS_Y = CY+(CH+CG)+18
for idx,style in ipairs(FSData) do
    local col=(idx-1)%2; local row=math.floor((idx-1)/2)
    local xO=col*(CW+CG); local yO=FS_Y+row*(CH+CG)
    local hasPos = style[WorldKey] ~= nil

    local card=Instance.new("Frame",TSh)
    card.Size=UDim2.new(0,CW,0,CH);card.Position=UDim2.new(0,xO,0,yO)
    card.BackgroundColor3=CARD;card.BorderSizePixel=0;card.ZIndex=6;Cr(card,10)
    St(card,WHITE,hasPos and .92 or .97,1)
    local ibox=Instance.new("Frame",card);ibox.Size=UDim2.new(0,42,0,42);ibox.Position=UDim2.new(0,14,0.5,-21)
    ibox.BackgroundColor3=DIM;ibox.BorderSizePixel=0;ibox.ZIndex=7;Cr(ibox,10);St(ibox,WHITE,.9,1)
    local ttl=Instance.new("TextLabel",card);ttl.Size=UDim2.new(1,-76,0,18);ttl.Position=UDim2.new(0,66,0,15)
    ttl.BackgroundTransparency=1;ttl.Text=style.n;ttl.TextColor3=hasPos and WHITE or MUTED
    ttl.TextSize=12;ttl.Font=Enum.Font.GothamBold;ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.ZIndex=7
    local sl=Instance.new("TextLabel",card);sl.Size=UDim2.new(1,-76,0,14);sl.Position=UDim2.new(0,66,0,35)
    sl.BackgroundTransparency=1;sl.Text=hasPos and "Bam de mua" or "Khong co o world nay"
    sl.TextColor3=MUTED;sl.TextSize=10;sl.Font=Enum.Font.GothamBold;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=7

    if hasPos then
        local hov=Instance.new("TextButton",card);hov.Size=UDim2.new(1,0,1,0);hov.BackgroundTransparency=1;hov.Text="";hov.ZIndex=9
        hov.MouseButton1Click:Connect(function() BuyFS(style,sl,ibox,ACCENT,RED,DIM) end)
        hov.MouseEnter:Connect(function() Tw(card,{BackgroundColor3=Color3.fromRGB(30,34,40)},.15) end)
        hov.MouseLeave:Connect(function() Tw(card,{BackgroundColor3=CARD},.15) end)
    end
end

-- ================================================
-- TAB ANTI BAN
-- ================================================
TabHead(TAB,"Anti Ban","Chong ban & bao ve")

Card(TAB,0,0,"Anti AFK","DISABLE",false,function(on) State.AntiAFK=on end)
Card(TAB,1,0,"No Clip","DISABLE",false,function(on) State.Noclip=on end)

-- Info: Anti Detection (luon bat)
do
    local function InfoCard(parent,col,row,title,sub)
        local xO=col*(CW+CG); local yO=CY+row*(CH+CG)
        local card=Instance.new("Frame",parent)
        card.Size=UDim2.new(0,CW,0,CH);card.Position=UDim2.new(0,xO,0,yO)
        card.BackgroundColor3=CARD_HL;card.BorderSizePixel=0;card.ZIndex=6;Cr(card,10)
        St(card,ACCENT,.5,1)
        local ibox=Instance.new("Frame",card);ibox.Size=UDim2.new(0,42,0,42);ibox.Position=UDim2.new(0,14,0.5,-21)
        ibox.BackgroundColor3=ACCENT;ibox.BorderSizePixel=0;ibox.ZIndex=7;Cr(ibox,10)
        local ttl=Instance.new("TextLabel",card);ttl.Size=UDim2.new(1,-76,0,18);ttl.Position=UDim2.new(0,66,0,15)
        ttl.BackgroundTransparency=1;ttl.Text=title;ttl.TextColor3=WHITE
        ttl.TextSize=13;ttl.Font=Enum.Font.GothamBold;ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.ZIndex=7
        local sl=Instance.new("TextLabel",card);sl.Size=UDim2.new(1,-76,0,14);sl.Position=UDim2.new(0,66,0,35)
        sl.BackgroundTransparency=1;sl.Text=sub;sl.TextColor3=ACCENT
        sl.TextSize=10;sl.Font=Enum.Font.GothamBold;sl.TextXAlignment=Enum.TextXAlignment.Left;sl.ZIndex=7
    end
    InfoCard(TAB,0,1,"Anti Detection","ACTIVE - Luon bat")
    InfoCard(TAB,1,1,"Sim Radius","ACTIVE - Luon bat")
    InfoCard(TAB,0,2,"Auto Buso Haki","ACTIVE - Luon bat")
end

-- ================================================
-- OPEN ANIMATION
-- ================================================
Win.Size=UDim2.new(0,700,0,0)
task.wait(0.05)
Tw(Win,{Size=UDim2.new(0,700,0,420)},.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
print("[HyunHub v2] Loaded | World:",W1 and "1" or W2 and "2" or W3 and "3" or "?")
