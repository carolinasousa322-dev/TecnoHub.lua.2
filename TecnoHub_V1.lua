--[[
=====================================================================
  TECNO HUB V1  |  Blox Fruits  |  Delta Executor (mobile)
=====================================================================
  Abas: Main, Settings, Farm, Local Player, States And ESP,
        Fruits And Raids, Shop, Misc, Credito

  IMPORTANTE (leia):
  * Este script NAO foi testado dentro do jogo por quem o escreveu.
    O Blox Fruits atualiza com frequencia; nomes de remotes, quests e
    coordenadas podem mudar. Os pontos mais sujeitos a mudanca estao
    marcados com [DADO DO JOGO] nos comentarios.
  * Funcoes marcadas [EXPERIMENTAL] podem nao funcionar em todas as
    versoes do jogo. A interface avisa isso.
  * NAO inclui Fast Attack nem Bring Mob (dependem de internos do
    jogo / propriedades ocultas que nao podem ser garantidos).
  * Usar scripts em jogos Roblox viola os Termos de Uso e pode
    resultar em banimento. Use por sua conta e risco.

  SECOES:
   0. Instancia unica
   1. Servicos
   2. Config e Estado
   3. Dados do jogo (quests, bosses)
   4. Utilitarios
   5. Motor de Farm
   6. Servicos de fundo (noclip, anti-AFK, etc.)
   7. Biblioteca de UI
   8. Montagem da janela
   9. Abas
  10. Inicializacao
=====================================================================
]]

------------------------------------------------------------------
-- SECAO 0: INSTANCIA UNICA (descarrega versao anterior)
------------------------------------------------------------------
local Env = (getgenv and getgenv()) or _G
if Env.TecnoHubUnload then
    pcall(Env.TecnoHubUnload)
end

------------------------------------------------------------------
-- SECAO 1: SERVICOS
------------------------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local Workspace         = game:GetService("Workspace")
local StatsService      = game:GetService("Stats")

local VIM -- VirtualInputManager (pode nao estar disponivel em todo executor)
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------
-- SECAO 2: CONFIG E ESTADO
------------------------------------------------------------------
local HUB_NAME    = "TECNO HUB"
local HUB_VERSION = "V1"

local Config = {
    -- Combate
    Weapon       = "Melee",   -- Melee / Sword / Gun / Blox Fruit
    MasteryWeapon = "Sword",  -- usado no Mastery Farm
    TweenSpeed   = 200,       -- studs por segundo (valores altos aumentam risco)
    Height       = 15,        -- altura acima do inimigo
    SnapDistance = 70,        -- abaixo disso, move direto (sem tween)
    AutoHaki     = true,
    AutoEquip    = true,
    AutoClick    = true,
    AntiAFK      = true,
    -- Alvos escolhidos
    Boss         = nil,
    MaterialMob  = nil,
    -- Local Player
    WalkSpeedOn  = false, WalkSpeed = 32,
    JumpOn       = false, JumpPower = 70,
    InfJump      = false,
    Noclip       = false,
}

local State = {
    Running      = true,
    Farm         = nil,       -- nome do farm ativo (apenas um por vez)
    Status       = "Idle",
    Tween        = nil,
    LastQuestTry = 0,
    LastHaki     = 0,
    SkillIndex   = 0,
    Skills       = { Z = true, X = true, C = false, V = false, F = false },
}

local SKILL_KEYS = { "Z", "X", "C", "V", "F" }

local Connections = {}
local function track(conn)
    Connections[#Connections + 1] = conn
    return conn
end

local ScreenGui -- definido na secao 8

------------------------------------------------------------------
-- SECAO 3: DADOS DO JOGO  [DADO DO JOGO]
-- Nomes de quests, mobs, bosses e coordenadas vieram da memoria do
-- autor e PRECISAM ser conferidos no jogo. Edite livremente.
------------------------------------------------------------------
local SEAS = { [2753915549] = 1, [4442272183] = 2, [7449423635] = 3 }
local Sea = SEAS[game.PlaceId] -- nil se for outro lugar

-- Quests do Primeiro Mar (niveis 1-374). Outros mares: sem dados.
local QUEST_DATA = {
    { min = 1,   max = 9,   mob = "Bandit",             name = "BanditQuest1",   index = 1, npc = CFrame.new(1059.37, 15.45, 1550.42) },
    { min = 10,  max = 14,  mob = "Monkey",             name = "JungleQuest",    index = 1, npc = CFrame.new(-1598.09, 35.55, 153.38) },
    { min = 15,  max = 29,  mob = "Gorilla",            name = "JungleQuest",    index = 2, npc = CFrame.new(-1598.09, 35.55, 153.38) },
    { min = 30,  max = 39,  mob = "Pirate",             name = "BuggyQuest1",    index = 1, npc = CFrame.new(-1141.07, 4.10, 3831.55) },
    { min = 40,  max = 59,  mob = "Brute",              name = "BuggyQuest1",    index = 2, npc = CFrame.new(-1141.07, 4.10, 3831.55) },
    { min = 60,  max = 74,  mob = "Desert Bandit",      name = "DesertQuest",    index = 1, npc = CFrame.new(894.49, 5.14, 4392.43) },
    { min = 75,  max = 89,  mob = "Desert Officer",     name = "DesertQuest",    index = 2, npc = CFrame.new(894.49, 5.14, 4392.43) },
    { min = 90,  max = 99,  mob = "Snow Bandit",        name = "SnowQuest",      index = 1, npc = CFrame.new(1389.74, 87.28, -1298.91) },
    { min = 100, max = 119, mob = "Snowman",            name = "SnowQuest",      index = 2, npc = CFrame.new(1389.74, 87.28, -1298.91) },
    { min = 120, max = 149, mob = "Chief Petty Officer",name = "MarineQuest2",   index = 1, npc = CFrame.new(-5039.59, 24.20, 4324.68) },
    { min = 150, max = 174, mob = "Sky Bandit",         name = "SkyQuest",       index = 1, npc = CFrame.new(-4839.53, 716.37, -2619.44) },
    { min = 175, max = 189, mob = "Dark Master",        name = "SkyQuest",       index = 2, npc = CFrame.new(-4839.53, 716.37, -2619.44) },
    { min = 190, max = 209, mob = "Prisoner",           name = "PrisonerQuest",  index = 1, npc = CFrame.new(5308.93, 1.66, 475.12) },
    { min = 210, max = 249, mob = "Dangerous Prisoner", name = "PrisonerQuest",  index = 2, npc = CFrame.new(5308.93, 1.66, 475.12) },
    { min = 250, max = 274, mob = "Toga Warrior",       name = "ColosseumQuest", index = 1, npc = CFrame.new(-1580.05, 6.35, -2986.48) },
    { min = 275, max = 299, mob = "Gladiator",          name = "ColosseumQuest", index = 2, npc = CFrame.new(-1580.05, 6.35, -2986.48) },
    { min = 300, max = 324, mob = "Military Soldier",   name = "MagmaQuest",     index = 1, npc = CFrame.new(-5313.37, 10.95, 8515.29) },
    { min = 325, max = 374, mob = "Military Spy",       name = "MagmaQuest",     index = 2, npc = CFrame.new(-5313.37, 10.95, 8515.29) },
}

-- Bosses por mar (nomes como aparecem em Workspace.Enemies quando spawnados)
local BOSSES = {
    [1] = { "The Gorilla King", "Bobby", "Yeti", "Mob Leader", "Vice Admiral", "Warden",
            "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God",
            "Cyborg", "Saber Expert" },
    [2] = { "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral", "Awakened Ice Admiral",
            "Tide Keeper", "Order", "Darkbeard", "Cursed Captain" },
    [3] = { "Stone", "Island Empress", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate",
            "Longma", "Soul Reaper", "Cake Queen" },
}
local BossList = BOSSES[Sea] or {}
Config.Boss = BossList[1]

-- Nomes usados pelo Sea Events [EXPERIMENTAL]
local SEA_NAMES = { PirateBrigade = true, PirateBasic = true, FishBoat = true,
                    Terrorshark = true, Piranha = true }

------------------------------------------------------------------
-- SECAO 4: UTILITARIOS
------------------------------------------------------------------
local function getChar() return LocalPlayer.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getData(name, default)
    local d = LocalPlayer:FindFirstChild("Data")
    local v = d and d:FindFirstChild(name)
    return v and v.Value or default
end
local function getLevel() return getData("Level", 1) end

-- Atualizadores de texto de status (labels registradas pela UI)
local StatusLabels = {}
local function setStatus(msg)
    if State.Status == msg then return end
    State.Status = msg
    for _, l in ipairs(StatusLabels) do
        l.Text = "Status: " .. msg
    end
end

local function commF()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    return r and r:FindFirstChild("CommF_")
end

local function enemyFolder() return Workspace:FindFirstChild("Enemies") end

local function isAlive(m)
    if not (m and m.Parent) then return false end
    local h = m:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0 and m:FindFirstChild("HumanoidRootPart") ~= nil
end

-- Tenta ler o nivel do inimigo no DisplayName ("Bandit [Lv. 5]")
local function enemyLevel(m)
    local h = m:FindFirstChildOfClass("Humanoid")
    if h then
        local n = h.DisplayName:match("Lv%.%s*(%d+)")
        return n and tonumber(n) or nil
    end
end

-- Escolhe o melhor inimigo vivo segundo um filtro; prefere proximos e
-- com nivel mais perto do nivel do jogador (sem ultrapassa-lo).
local function pickEnemy(filter, refLevel)
    local folder, root = enemyFolder(), getRoot()
    if not (folder and root) then return nil end
    local best, bestScore
    for _, m in ipairs(folder:GetChildren()) do
        if isAlive(m) then
            local lv = enemyLevel(m)
            if filter(m, lv) then
                local score = (m.HumanoidRootPart.Position - root.Position).Magnitude
                if lv and refLevel then
                    score = score + math.max(0, refLevel - lv) * 15
                end
                if not bestScore or score < bestScore then
                    best, bestScore = m, score
                end
            end
        end
    end
    return best
end

local function findEnemyByName(name)
    local folder = enemyFolder()
    if not folder or not name then return nil end
    for _, m in ipairs(folder:GetChildren()) do
        if m.Name == name and isAlive(m) then return m end
    end
end

local function enemyNames()
    local seen, list = {}, {}
    local folder = enemyFolder()
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if isAlive(m) and not seen[m.Name] then
                seen[m.Name] = true
                list[#list + 1] = m.Name
            end
        end
    end
    table.sort(list)
    return list
end

local function questForLevel(lvl)
    if Sea ~= 1 then return nil end
    for _, q in ipairs(QUEST_DATA) do
        if lvl >= q.min and lvl <= q.max then return q end
    end
end

-- true / false / nil (nil = nao foi possivel descobrir)
local function questActive()
    local ok, res = pcall(function()
        return LocalPlayer.PlayerGui.Main.Quest.Visible
    end)
    if ok then return res end
    return nil
end

-- Movimento: tween para longe, teleporte direto para perto.
local function travelTo(cf, mode)
    local root = getRoot()
    if not root then return end
    local dist = (root.Position - cf.Position).Magnitude
    if dist <= Config.SnapDistance then
        root.CFrame = cf
        return
    end
    local tween = TweenService:Create(root,
        TweenInfo.new(dist / Config.TweenSpeed, Enum.EasingStyle.Linear),
        { CFrame = cf })
    local done = false
    local conn = tween.Completed:Connect(function() done = true end)
    State.Tween = tween
    tween:Play()
    while not done and State.Running and State.Farm == mode and getRoot() do
        task.wait(0.05)
    end
    if not done then pcall(function() tween:Cancel() end) end
    conn:Disconnect()
    State.Tween = nil
end

-- Combate
local function pressKey(name)
    if not VIM then return false end
    local kc = Enum.KeyCode[name]
    pcall(function()
        VIM:SendKeyEvent(true, kc, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, kc, false, game)
    end)
    return true
end

local function useNextSkill()
    for _ = 1, #SKILL_KEYS do
        State.SkillIndex = State.SkillIndex % #SKILL_KEYS + 1
        local k = SKILL_KEYS[State.SkillIndex]
        if State.Skills[k] then
            pressKey(k)
            return
        end
    end
end

local function attack()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(1280, 672))
    end)
    local c = getChar()
    local tool = c and c:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
end

local function equipByTip(tip)
    local c, hum = getChar(), getHum()
    if not (c and hum) then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == tip then return t end -- ja equipada
    end
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == tip then
            hum:EquipTool(t)
            return t
        end
    end
end

-- [DADO DO JOGO] remote "Buso" ativa o Haki de Armamento
local function ensureHaki()
    if os.clock() - State.LastHaki < 3 then return end
    State.LastHaki = os.clock()
    local c = getChar()
    if c and not c:FindFirstChild("HasBuso") then
        local r = commF()
        if r then pcall(function() r:InvokeServer("Buso") end) end
    end
end

local function prepCombat(tip)
    if Config.AutoHaki then ensureHaki() end
    if Config.AutoEquip then equipByTip(tip or Config.Weapon) end
end

local function hoverAndAttack(model, mode)
    local pos = model:GetPivot().Position
    local cf = CFrame.new(pos + Vector3.new(0, Config.Height, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
    travelTo(cf, mode)
    if State.Farm ~= mode then return end
    if Config.AutoClick then attack() end
end

------------------------------------------------------------------
-- SECAO 5: MOTOR DE FARM (um modo ativo por vez)
------------------------------------------------------------------
local Farm = {}

-- Level Farm: mata inimigos compativeis com seu nivel, sem aceitar quest.
Farm.Level = function()
    local lvl = getLevel()
    local target = pickEnemy(function(_, mlvl) return (not mlvl) or mlvl <= lvl end, lvl)
    if not target then
        local q = questForLevel(lvl)
        if q then
            setStatus("Level: indo para area de " .. q.mob)
            travelTo(q.npc, "Level")
        else
            setStatus("Level: nenhum inimigo carregado")
        end
        return
    end
    setStatus("Level: " .. target.Name)
    prepCombat()
    hoverAndAttack(target, "Level")
end

-- Quest Farm: aceita a quest do seu nivel e mata o mob dela (Mar 1).
Farm.Quest = function()
    if Sea ~= 1 then
        setStatus("Quest: dados disponiveis so no Mar 1")
        return
    end
    local lvl = getLevel()
    local q = questForLevel(lvl)
    if not q then
        setStatus("Quest: sem dados para o nivel " .. lvl)
        return
    end
    if questActive() ~= true and os.clock() - State.LastQuestTry > 8 then
        setStatus("Quest: aceitando " .. q.name)
        travelTo(q.npc, "Quest")
        if State.Farm ~= "Quest" then return end
        local r = commF()
        if r then pcall(function() r:InvokeServer("StartQuest", q.name, q.index) end) end
        State.LastQuestTry = os.clock()
        task.wait(0.5)
    end
    local target = pickEnemy(function(m) return m.Name == q.mob end, lvl)
    if not target then
        setStatus("Quest: aguardando " .. q.mob)
        travelTo(q.npc, "Quest")
        return
    end
    setStatus("Quest: " .. q.mob)
    prepCombat()
    hoverAndAttack(target, "Quest")
end

-- Boss Farm: ataca o boss escolhido se ele estiver spawnado.
Farm.Boss = function()
    if not Config.Boss then setStatus("Boss: nenhum boss escolhido") return end
    local boss = findEnemyByName(Config.Boss)
    if not boss then
        setStatus("Boss: " .. Config.Boss .. " nao esta spawnado")
        return
    end
    setStatus("Boss: " .. boss.Name)
    prepCombat()
    hoverAndAttack(boss, "Boss")
end

-- Mastery Farm: farm normal usando a arma escolhida (Melee/Sword/Gun).
Farm.Mastery = function()
    local lvl = getLevel()
    local target = pickEnemy(function(_, mlvl) return (not mlvl) or mlvl <= lvl end, lvl)
    if not target then setStatus("Mastery: nenhum inimigo carregado") return end
    setStatus("Mastery (" .. Config.MasteryWeapon .. "): " .. target.Name)
    prepCombat(Config.MasteryWeapon)
    hoverAndAttack(target, "Mastery")
end

-- Fruit Mastery Farm: equipa a Blox Fruit e usa as skills marcadas.
Farm.FruitMastery = function()
    if not VIM then setStatus("Fruit Mastery: executor sem VirtualInputManager") return end
    local lvl = getLevel()
    local target = pickEnemy(function(_, mlvl) return (not mlvl) or mlvl <= lvl end, lvl)
    if not target then setStatus("Fruit Mastery: nenhum inimigo carregado") return end
    setStatus("Fruit Mastery: " .. target.Name)
    prepCombat("Blox Fruit")
    local pos = target:GetPivot().Position
    travelTo(CFrame.new(pos + Vector3.new(0, Config.Height, 0)) * CFrame.Angles(math.rad(-90), 0, 0), "FruitMastery")
    if State.Farm ~= "FruitMastery" then return end
    useNextSkill()
    task.wait(0.15)
end

-- Material Farm: farma um tipo de inimigo escolhido (o drop depende do jogo).
Farm.Material = function()
    if not Config.MaterialMob then setStatus("Material: escolha um inimigo") return end
    local target = pickEnemy(function(m) return m.Name == Config.MaterialMob end, nil)
    if not target then
        setStatus("Material: " .. Config.MaterialMob .. " nao carregado")
        return
    end
    setStatus("Material: " .. target.Name)
    prepCombat()
    hoverAndAttack(target, "Material")
end

-- Chest Farm: coleta o bau mais proximo. [DADO DO JOGO] tag "_ChestTagged"
local function listChests()
    local list = {}
    local ok, tagged = pcall(function() return CollectionService:GetTagged("_ChestTagged") end)
    if ok then
        for _, c in ipairs(tagged) do
            if c:IsDescendantOf(Workspace) then list[#list + 1] = c end
        end
    end
    if #list == 0 then -- plano B: nomes Chest1/Chest2/Chest3 direto no Workspace
        for _, c in ipairs(Workspace:GetChildren()) do
            if c.Name:match("^Chest%d") then list[#list + 1] = c end
        end
    end
    return list
end

Farm.Chest = function()
    local root = getRoot()
    if not root then return end
    local best, bestDist
    for _, c in ipairs(listChests()) do
        local ok, pivot = pcall(function() return c:GetPivot() end)
        if ok then
            local d = (pivot.Position - root.Position).Magnitude
            if not bestDist or d < bestDist then best, bestDist = pivot, d end
        end
    end
    if not best then setStatus("Chest: nenhum bau encontrado") task.wait(1) return end
    setStatus("Chest: coletando (" .. math.floor(bestDist) .. " studs)")
    travelTo(best, "Chest")
    task.wait(0.3)
end

-- Observation Farm [EXPERIMENTAL]: fica perto de inimigos com a
-- Observation (tecla E) ligada, sem atacar, para desviar dos golpes.
-- Nao ha como confirmar o progresso por aqui; acompanhe no jogo.
Farm.Observation = function()
    local lvl = getLevel()
    local target = pickEnemy(function(_, mlvl) return (not mlvl) or mlvl <= lvl end, lvl)
    if not target then setStatus("Observation: nenhum inimigo carregado") return end
    setStatus("Observation [EXP]: perto de " .. target.Name)
    local pos = target:GetPivot().Position
    travelTo(CFrame.new(pos + Vector3.new(4, 0, 0)), "Observation")
end

-- Sea Events Farm [EXPERIMENTAL]: ataca Sea Beasts/barcos se existirem.
local function seaTargets()
    local list = {}
    local sb = Workspace:FindFirstChild("SeaBeasts")
    if sb then
        for _, m in ipairs(sb:GetChildren()) do
            if m:IsA("Model") then
                local h = m:FindFirstChildOfClass("Humanoid")
                if not h or h.Health > 0 then list[#list + 1] = m end
            end
        end
    end
    local f = enemyFolder()
    if f then
        for _, m in ipairs(f:GetChildren()) do
            if SEA_NAMES[m.Name] and isAlive(m) then list[#list + 1] = m end
        end
    end
    return list
end

Farm.SeaEvents = function()
    if Sea == 1 then setStatus("Sea Events: indisponivel no Mar 1") task.wait(1) return end
    local root = getRoot()
    if not root then return end
    local best, bestDist
    for _, m in ipairs(seaTargets()) do
        local d = (m:GetPivot().Position - root.Position).Magnitude
        if not bestDist or d < bestDist then best, bestDist = m, d end
    end
    if not best then setStatus("Sea Events [EXP]: nenhum alvo encontrado") task.wait(1) return end
    setStatus("Sea Events [EXP]: " .. best.Name)
    prepCombat()
    hoverAndAttack(best, "SeaEvents")
    useNextSkill()
end

-- Controle: apenas um farm ativo por vez
local FarmToggles = {}

local function setFarm(name, on)
    if on then
        State.Farm = name
        for n, t in pairs(FarmToggles) do
            if n ~= name and t.Get() then t.Set(false, true) end
        end
        if name == "Observation" then pressKey("E") end
    elseif State.Farm == name then
        State.Farm = nil
        if State.Tween then pcall(function() State.Tween:Cancel() end) end
        setStatus("Idle")
    end
end

local function stopAllFarms()
    for _, t in pairs(FarmToggles) do t.Set(false, true) end
    State.Farm = nil
    if State.Tween then pcall(function() State.Tween:Cancel() end) end
    setStatus("Idle")
end

-- Loop principal (cada passo protegido por pcall)
task.spawn(function()
    while State.Running do
        local mode = State.Farm
        if mode and Farm[mode] and getRoot() then
            local ok, err = pcall(Farm[mode])
            if not ok then
                setStatus("Erro: " .. tostring(err))
                task.wait(1)
            end
            task.wait(0.05)
        else
            task.wait(0.3)
        end
    end
end)

------------------------------------------------------------------
-- SECAO 6: SERVICOS DE FUNDO
------------------------------------------------------------------
local fps, frames, t0 = 60, 0, os.clock()

-- Noclip (durante farm ou quando ligado manualmente)
track(RunService.Stepped:Connect(function()
    if not (State.Farm or Config.Noclip) then return end
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetChildren()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end))

track(RunService.Heartbeat:Connect(function()
    frames = frames + 1
    if os.clock() - t0 >= 1 then
        fps, frames, t0 = frames, 0, os.clock()
    end
    local root = getRoot()
    if State.Farm and root then
        root.AssemblyLinearVelocity = Vector3.zero -- evita cair durante farm
    end
    local hum = getHum()
    if hum then
        if Config.WalkSpeedOn then hum.WalkSpeed = Config.WalkSpeed end
        if Config.JumpOn then
            hum.UseJumpPower = true
            hum.JumpPower = Config.JumpPower
        end
    end
end))

track(UserInputService.JumpRequest:Connect(function()
    if Config.InfJump then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

track(LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

------------------------------------------------------------------
-- SECAO 7: BIBLIOTECA DE UI
------------------------------------------------------------------
local Theme = {
    Bg     = Color3.fromRGB(20, 22, 30),
    Top    = Color3.fromRGB(28, 31, 42),
    Side   = Color3.fromRGB(24, 27, 37),
    Item   = Color3.fromRGB(34, 38, 52),
    Accent = Color3.fromRGB(0, 190, 160),
    Off    = Color3.fromRGB(70, 75, 95),
    Text   = Color3.fromRGB(235, 238, 245),
    Sub    = Color3.fromRGB(150, 158, 180),
    Warn   = Color3.fromRGB(255, 190, 80),
}

local layoutCounter = 0
local function nextOrder()
    layoutCounter = layoutCounter + 1
    return layoutCounter
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o)
end

local UI = {}

function UI.Section(page, text)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text,
        TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(),
    }, page)
end

function UI.Label(page, text, color)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = text, TextWrapped = true,
        TextColor3 = color or Theme.Sub, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = nextOrder(),
    }, page)
end

function UI.Button(page, text, callback)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Item, Text = text,
        TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12,
        AutoButtonColor = true, TextWrapped = true, LayoutOrder = nextOrder(),
    }, page)
    corner(b)
    if callback then b.Activated:Connect(callback) end
    return b
end

function UI.Toggle(page, text, default, callback)
    local state = default and true or false
    local row = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Item, Text = "",
        AutoButtonColor = false, LayoutOrder = nextOrder(),
    }, page)
    corner(row)
    new("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track_ = new("Frame", {
        Size = UDim2.fromOffset(38, 18), Position = UDim2.new(1, -46, 0.5, -9),
        BackgroundColor3 = Theme.Off,
    }, row)
    corner(track_, 9)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, track_)
    corner(knob, 7)

    local obj = {}
    local function render()
        track_.BackgroundColor3 = state and Theme.Accent or Theme.Off
        knob.Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
    end
    function obj.Get() return state end
    function obj.Set(v, silent)
        state = v and true or false
        render()
        if not silent and callback then task.spawn(callback, state) end
    end
    row.Activated:Connect(function() obj.Set(not state) end)
    render()
    return obj
end

function UI.Stepper(page, text, min, max, step, default, callback)
    local value = default
    local function round(v) return math.floor(v * 100 + 0.5) / 100 end
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Item, LayoutOrder = nextOrder(),
    }, page)
    corner(row)
    new("TextLabel", {
        Size = UDim2.new(1, -112, 1, 0), Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local function mk(txt, x)
        local b = new("TextButton", {
            Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, x, 0.5, -12),
            BackgroundColor3 = Theme.Off, Text = txt, TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold, TextSize = 14,
        }, row)
        corner(b, 5)
        return b
    end
    local minus, plus = mk("-", -104), mk("+", -32)
    local val = new("TextLabel", {
        Size = UDim2.fromOffset(40, 24), Position = UDim2.new(1, -74, 0.5, -12),
        BackgroundTransparency = 1, Text = tostring(value), TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold, TextSize = 12,
    }, row)
    local obj = {}
    local function set(v)
        value = math.clamp(round(v), min, max)
        val.Text = tostring(value)
        if callback then callback(value) end
    end
    minus.Activated:Connect(function() set(value - step) end)
    plus.Activated:Connect(function() set(value + step) end)
    function obj.Get() return value end
    return obj
end

function UI.Cycle(page, text, getOptions, default, callback)
    local value = default
    local btn = UI.Button(page, "", nil)
    local obj = {}
    local function render() btn.Text = text .. ": " .. tostring(value or "none") end
    btn.Activated:Connect(function()
        local opts = getOptions()
        if #opts == 0 then
            value = nil
        else
            local idx = table.find(opts, value) or 0
            value = opts[idx % #opts + 1]
        end
        render()
        if callback then callback(value) end
    end)
    function obj.Get() return value end
    render()
    return obj
end

function UI.Dialog(page, msg)
    local box = new("Frame", {
        Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = Theme.Item, LayoutOrder = nextOrder(),
    }, page)
    corner(box, 8)
    new("UIStroke", { Color = Theme.Warn, Thickness = 1 }, box)
    new("TextLabel", {
        Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5),
        BackgroundTransparency = 1, Text = msg, TextWrapped = true, TextColor3 = Theme.Warn,
        Font = Enum.Font.GothamBold, TextSize = 14,
    }, box)
end

-- Arrastar (mouse e toque). Retorna funcao que informa se houve arraste.
local function makeDraggable(handle, target)
    local dragging, startInput, startPos, moved = false, nil, nil, false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            startInput, startPos = input.Position, target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            if d.Magnitude > 6 then moved = true end
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                        startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    return function() return moved end
end

------------------------------------------------------------------
-- SECAO 8: MONTAGEM DA JANELA
------------------------------------------------------------------
ScreenGui = new("ScreenGui", {
    Name = "TecnoHubV1", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
})
do
    local parented = false
    local okH, hui = pcall(function() return gethui and gethui() end)
    if okH and hui then
        parented = pcall(function() ScreenGui.Parent = hui end) and ScreenGui.Parent ~= nil
    end
    if not parented then
        parented = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
            and ScreenGui.Parent ~= nil
    end
    if not parented then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local cam = Workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
local W = math.clamp(math.floor(vp.X * 0.62), 380, 520)
local H = math.clamp(math.floor(vp.Y * 0.78), 220, 300)

local Main = new("Frame", {
    Name = "Main", Size = UDim2.fromOffset(W, H),
    Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
    BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ClipsDescendants = true,
}, ScreenGui)
corner(Main, 10)

local Top = new("Frame", {
    Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Top, BorderSizePixel = 0,
}, Main)
new("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1, Text = HUB_NAME .. " " .. HUB_VERSION .. "  |  Blox Fruits",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Top)

local function topButton(txt, x, color)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(26, 22), Position = UDim2.new(1, x, 0.5, -11),
        BackgroundColor3 = color, Text = txt, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold, TextSize = 13,
    }, Top)
    corner(b, 5)
    return b
end
local MinBtn   = topButton("-", -64, Theme.Off)
local CloseBtn = topButton("X", -34, Color3.fromRGB(200, 70, 70))

local Sidebar = new("ScrollingFrame", {
    Size = UDim2.new(0, 96, 1, -34), Position = UDim2.fromOffset(2, 32),
    BackgroundColor3 = Theme.Side, BorderSizePixel = 0, ScrollBarThickness = 2,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Main)
corner(Sidebar, 8)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, Sidebar)
new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, Sidebar)

local Content = new("Frame", {
    Size = UDim2.new(1, -104, 1, -36), Position = UDim2.fromOffset(100, 34),
    BackgroundTransparency = 1,
}, Main)

makeDraggable(Top, Main)

-- Botao flutuante para abrir/fechar a janela (arrastavel)
local Float = new("TextButton", {
    Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 10, 0.5, -18),
    BackgroundColor3 = Theme.Accent, Text = "T", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 18, ZIndex = 10,
}, ScreenGui)
corner(Float, 18)
local floatMoved = makeDraggable(Float, Float)
Float.Activated:Connect(function()
    if not floatMoved() then Main.Visible = not Main.Visible end
end)
MinBtn.Activated:Connect(function() Main.Visible = false end)

-- Sistema de abas
local Tabs, TabButtons = {}, {}

local function selectTab(name)
    for n, page in pairs(Tabs) do
        page.Visible = (n == name)
        TabButtons[n].BackgroundColor3 = (n == name) and Theme.Accent or Theme.Item
        TabButtons[n].TextColor3 = (n == name) and Color3.new(1, 1, 1) or Theme.Sub
    end
end

local function addTab(name)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Item, Text = name,
        TextColor3 = Theme.Sub, Font = Enum.Font.GothamMedium, TextSize = 11,
        TextWrapped = true, AutoButtonColor = false, LayoutOrder = nextOrder(),
    }, Sidebar)
    corner(btn)
    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, Content)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8),
    }, page)
    btn.Activated:Connect(function() selectTab(name) end)
    Tabs[name], TabButtons[name] = page, btn
    return page
end

------------------------------------------------------------------
-- SECAO 9: ABAS
------------------------------------------------------------------
local DIALOG_MSG = "The Function Doesn't Have. Wait the others versions!"

----- 1. MAIN -----------------------------------------------------
local pMain = addTab("Main")
UI.Section(pMain, "Player")
local InfoLabel = UI.Label(pMain, "Loading...", Theme.Text)
local MainStatus = UI.Label(pMain, "Status: Idle", Theme.Warn)
StatusLabels[#StatusLabels + 1] = MainStatus
UI.Section(pMain, "Quick Controls")
UI.Toggle(pMain, "Anti-AFK", Config.AntiAFK, function(v) Config.AntiAFK = v end)
UI.Button(pMain, "Stop All Farms", stopAllFarms)
UI.Label(pMain, "Only one farm runs at a time. Open the Farm tab to start.")

task.spawn(function()
    while State.Running do
        local ping = "?"
        pcall(function()
            ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) .. " ms"
        end)
        InfoLabel.Text = string.format(
            "Name: %s\nLevel: %s\nBeli: %s\nFragments: %s\nSea: %s\nFPS: %d   Ping: %s",
            LocalPlayer.Name, tostring(getLevel()), tostring(getData("Beli", "?")),
            tostring(getData("Fragments", "?")), Sea and tostring(Sea) or "unknown", fps, ping)
        task.wait(1)
    end
end)

----- 2. SETTINGS -------------------------------------------------
local pSet = addTab("Settings")
UI.Section(pSet, "Combat")
UI.Cycle(pSet, "Weapon", function() return { "Melee", "Sword", "Gun", "Blox Fruit" } end,
    Config.Weapon, function(v) Config.Weapon = v end)
UI.Toggle(pSet, "Auto Equip weapon", Config.AutoEquip, function(v) Config.AutoEquip = v end)
UI.Toggle(pSet, "Auto Haki (Buso)", Config.AutoHaki, function(v) Config.AutoHaki = v end)
UI.Toggle(pSet, "Auto Click (attack)", Config.AutoClick, function(v) Config.AutoClick = v end)
UI.Section(pSet, "Movement")
UI.Stepper(pSet, "Tween speed", 100, 350, 25, Config.TweenSpeed, function(v) Config.TweenSpeed = v end)
UI.Stepper(pSet, "Farm height", 5, 40, 5, Config.Height, function(v) Config.Height = v end)
UI.Section(pSet, "Interface")
UI.Stepper(pSet, "GUI transparency", 0, 0.6, 0.1, 0, function(v) Main.BackgroundTransparency = v end)
UI.Button(pSet, "Destroy Hub", function() if Env.TecnoHubUnload then Env.TecnoHubUnload() end end)
UI.Label(pSet, "Tip: high tween speed may trigger the game's anti-cheat.")

----- 3. FARM -----------------------------------------------------
local pFarm = addTab("Farm")
local FarmStatus = UI.Label(pFarm, "Status: Idle", Theme.Warn)
StatusLabels[#StatusLabels + 1] = FarmStatus
UI.Label(pFarm, "One farm at a time. Turning one on turns the others off.")

local function farmToggle(key, text)
    FarmToggles[key] = UI.Toggle(pFarm, text, false, function(v) setFarm(key, v) end)
end

UI.Section(pFarm, "Level Farm")
farmToggle("Level", "Level Farm (no quest)")
UI.Label(pFarm, "Kills enemies matching your level. Needs enemies loaded near you; if none, flies to the hunting area (Sea 1 data).")

UI.Section(pFarm, "Quest Farm")
farmToggle("Quest", "Quest Farm")
UI.Label(pFarm, "Accepts the quest for your level and kills its mob. Sea 1, levels 1-374 only (see QUEST_DATA).")

UI.Section(pFarm, "Boss Farm")
UI.Cycle(pFarm, "Boss", function() return BossList end, Config.Boss, function(v) Config.Boss = v end)
farmToggle("Boss", "Boss Farm")
UI.Label(pFarm, "Attacks the chosen boss only while it is spawned.")

UI.Section(pFarm, "Mastery Farm")
UI.Cycle(pFarm, "Mastery weapon", function() return { "Melee", "Sword", "Gun" } end,
    Config.MasteryWeapon, function(v) Config.MasteryWeapon = v end)
farmToggle("Mastery", "Mastery Farm")

UI.Section(pFarm, "Fruit Mastery Farm")
for _, k in ipairs(SKILL_KEYS) do
    UI.Toggle(pFarm, "Use skill " .. k, State.Skills[k], function(v) State.Skills[k] = v end)
end
farmToggle("FruitMastery", "Fruit Mastery Farm")
UI.Label(pFarm, "Equips your Blox Fruit and presses the selected keys. Skill aim depends on the game; needs VirtualInputManager.")

UI.Section(pFarm, "Material Farm")
UI.Cycle(pFarm, "Enemy", enemyNames, Config.MaterialMob, function(v) Config.MaterialMob = v end)
farmToggle("Material", "Material Farm")
UI.Label(pFarm, "Tap Enemy to cycle through enemies loaded near you. Drops depend on the game.")

UI.Section(pFarm, "Chest Farm")
farmToggle("Chest", "Chest Farm")
UI.Label(pFarm, "Flies to the nearest chest and collects it.")

UI.Section(pFarm, "Observation Farm [EXPERIMENTAL]")
farmToggle("Observation", "Observation Farm")
UI.Label(pFarm, "Presses E once and stays next to enemies without attacking. Progress is not verified by the script.", Theme.Warn)

UI.Section(pFarm, "Sea Events Farm [EXPERIMENTAL]")
farmToggle("SeaEvents", "Sea Events Farm")
UI.Label(pFarm, "Attacks Sea Beasts / boats if found. Not available in Sea 1. Uses the skills selected above.", Theme.Warn)

----- 4. LOCAL PLAYER ---------------------------------------------
local pLP = addTab("Local Player")
UI.Section(pLP, "Speed and Jump")
UI.Toggle(pLP, "Custom WalkSpeed", false, function(v)
    Config.WalkSpeedOn = v
    if not v then local h = getHum(); if h then h.WalkSpeed = 16 end end
end)
UI.Stepper(pLP, "WalkSpeed", 16, 150, 10, Config.WalkSpeed, function(v) Config.WalkSpeed = v end)
UI.Toggle(pLP, "Custom JumpPower", false, function(v)
    Config.JumpOn = v
    if not v then local h = getHum(); if h then h.JumpPower = 50 end end
end)
UI.Stepper(pLP, "JumpPower", 50, 200, 10, Config.JumpPower, function(v) Config.JumpPower = v end)
UI.Toggle(pLP, "Infinite Jump", false, function(v) Config.InfJump = v end)
UI.Section(pLP, "Other")
UI.Toggle(pLP, "Noclip", false, function(v) Config.Noclip = v end)
UI.Button(pLP, "Reset Character", function()
    local h = getHum()
    if h then h.Health = 0 end
end)
UI.Label(pLP, "The game may reset or flag speed changes. Use moderate values.")

----- 5. STATES AND ESP (nao disponivel) --------------------------
local pEsp = addTab("States And ESP")
UI.Dialog(pEsp, DIALOG_MSG)

----- 6. FRUITS AND RAIDS (nao disponivel) ------------------------
local pFr = addTab("Fruits And Raids")
UI.Dialog(pFr, DIALOG_MSG)

----- 7. SHOP (nao disponivel) ------------------------------------
local pShop = addTab("Shop")
UI.Dialog(pShop, DIALOG_MSG)

----- 8. MISC -----------------------------------------------------
local pMisc = addTab("Misc")
local MiscLabel = UI.Label(pMisc, "Ready.", Theme.Warn)

UI.Section(pMisc, "Server")
UI.Button(pMisc, "Rejoin Server", function()
    MiscLabel.Text = "Rejoining..."
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end)
UI.Button(pMisc, "Server Hop", function()
    MiscLabel.Text = "Searching for a server..."
    task.spawn(function()
        local ok, res = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId
                .. "/servers/Public?sortOrder=Asc&limit=100")
        end)
        if not ok then MiscLabel.Text = "Server Hop failed: executor has no HttpGet." return end
        local okJ, data = pcall(function() return HttpService:JSONDecode(res) end)
        if not okJ or type(data) ~= "table" or not data.data then
            MiscLabel.Text = "Server Hop failed: invalid response."
            return
        end
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                MiscLabel.Text = "Teleporting..."
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) end)
                return
            end
        end
        MiscLabel.Text = "No suitable server found."
    end)
end)
UI.Button(pMisc, "Copy JobId", function()
    if setclipboard then
        setclipboard(game.JobId)
        MiscLabel.Text = "JobId copied."
    else
        MiscLabel.Text = "Executor has no setclipboard."
    end
end)

UI.Section(pMisc, "Graphics")
local origLighting = {}
UI.Toggle(pMisc, "Fullbright", false, function(v)
    if v then
        origLighting = {
            Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
        }
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd = 2, 14, 1e6
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    else
        for k, val in pairs(origLighting) do pcall(function() Lighting[k] = val end) end
    end
end)
UI.Button(pMisc, "FPS Boost (one-time, irreversible)", function()
    MiscLabel.Text = "Applying FPS boost..."
    task.spawn(function()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        Lighting.GlobalShadows = false
        local n = 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                or d:IsA("Fire") or d:IsA("Sparkles") then
                d.Enabled = false
            end
            n = n + 1
            if n % 2000 == 0 then task.wait() end -- nao travar o celular
        end
        MiscLabel.Text = "FPS boost applied (rejoin to undo)."
    end)
end)

----- 9. CREDITO --------------------------------------------------
local pCred = addTab("Credito")
UI.Section(pCred, HUB_NAME .. " " .. HUB_VERSION)
UI.Label(pCred, "Hub para Blox Fruits, feito para o Delta Executor (mobile).", Theme.Text)
UI.Section(pCred, "Creditos")
UI.Label(pCred, "Projeto: Tecno Hub", Theme.Text)
UI.Label(pCred, "Codigo: gerado com auxilio do Claude (Anthropic)", Theme.Text)
UI.Section(pCred, "Aviso")
UI.Label(pCred, "Versao inicial (V1). Algumas abas ainda nao tem funcoes e serao adicionadas em versoes futuras. Dados de quests/bosses podem mudar com atualizacoes do jogo.")
UI.Label(pCred, "Usar scripts no Roblox pode violar os Termos de Uso e causar banimento.", Theme.Warn)

------------------------------------------------------------------
-- SECAO 10: INICIALIZACAO
------------------------------------------------------------------
CloseBtn.Activated:Connect(function()
    if Env.TecnoHubUnload then Env.TecnoHubUnload() end
end)

local function Unload()
    State.Running = false
    State.Farm = nil
    if State.Tween then pcall(function() State.Tween:Cancel() end) end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
    Env.TecnoHubUnload = nil
end
Env.TecnoHubUnload = Unload

selectTab("Main")
