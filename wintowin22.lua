local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
&nbsp;
&nbsp;

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
&nbsp;
&nbsp;

-- CONFIG --
local AIM_SENSITIVITY = 0.25
local AIM_FOV = 60 -- grados para buscar objetivo cercano al centro
local TRIGGER_ANGLE = 5 -- grados para disparar
local TRIGGER_COOLDOWN = 0.3 -- segundos entre disparos para evitar spam
local WALL_CHECK_IGNORE_LIST = {localPlayer.Character} -- ignorar el propio personaje
&nbsp;
&nbsp;

-- ESTADOS --
local aimbotEnabled = false
local triggerbotEnabled = false
local espEnabled = false
local chamsEnabled = false
local running = true
local lastTriggerTime = 0
&nbsp;
&nbsp;

-- TABLA PARA GUARDAR ESP Y CHAMS QUE CREAMOS
local espBoxes = {}
local chamsHighlights = {}
&nbsp;
&nbsp;

-- FUNCIONES --
&nbsp;
&nbsp;

local function isEnemy(player)
    return player.Team ~= localPlayer.Team
end
&nbsp;
&nbsp;

local function hasLineOfSight(targetHead)
    local origin = camera.CFrame.Position
    local direction = (targetHead.Position - origin).Unit * 500 -- largo suficiente
&nbsp;
&nbsp;

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = WALL_CHECK_IGNORE_LIST
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
&nbsp;
&nbsp;

    local result = Workspace:Raycast(origin, direction, raycastParams)
    if result then
        -- Si el hit no es parte del targetHead o su personaje, bloquea la visión
        return result.Instance:IsDescendantOf(targetHead.Parent)
    else
        return true -- Línea libre
    end
end
&nbsp;
&nbsp;

local function getClosestTarget()
    local closestPlayer = nil
    local shortestAngle = AIM_FOV
&nbsp;
&nbsp;

    local camCFrame = camera.CFrame
    local camLookVector = camCFrame.LookVector
&nbsp;
&nbsp;

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and isEnemy(player) and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local directionToHead = (head.Position - camCFrame.Position).Unit
            local angle = math.deg(math.acos(camLookVector:Dot(directionToHead)))
&nbsp;
&nbsp;

            if angle < shortestAngle and hasLineOfSight(head) then
                shortestAngle = angle
                closestPlayer = player
            end
        end
    end
&nbsp;
&nbsp;

    return closestPlayer, shortestAngle
end
&nbsp;
&nbsp;

local function moveAimTowards(targetPos)
    local camCFrame = camera.CFrame
    local targetDirection = (targetPos - camCFrame.Position).Unit
    local currentLookVector = camCFrame.LookVector
&nbsp;
&nbsp;

    local newLookVector = currentLookVector:Lerp(targetDirection, AIM_SENSITIVITY)
    camera.CFrame = CFrame.new(camCFrame.Position, camCFrame.Position + newLookVector)
end
&nbsp;
&nbsp;

local function fireWeapon()
    local currentTime = tick()
    if currentTime - lastTriggerTime >= TRIGGER_COOLDOWN then
        lastTriggerTime = currentTime
        -- Adaptar a tu sistema real de disparo
        print("Disparando!")
    end
end
&nbsp;
&nbsp;

-- ESP FUNCTIONS --
&nbsp;
&nbsp;

local function createESP(player)
    if espBoxes[player] then
        return -- Ya creado
    end
    if not (player.Character and player.Character:FindFirstChild("Head")) then return end
&nbsp;
&nbsp;

    local head = player.Character.Head
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESPBox"
    box.Size = Vector3.new(2, 2, 1)
    box.Adornee = head
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = Color3.new(1, 0, 0) -- rojo
    box.Transparency = 0.5
    box.Parent = head
&nbsp;
&nbsp;

    espBoxes[player] = box
end
&nbsp;
&nbsp;

local function removeESP(player)
    if espBoxes[player] then
        espBoxes[player]:Destroy()
        espBoxes[player] = nil
    end
end
&nbsp;
&nbsp;

-- CHAMS FUNCTIONS --
&nbsp;
&nbsp;

local function createChams(player)
    if chamsHighlights[player] then
        return
    end
    if not (player.Character and player.Character:FindFirstChild("Head")) then return end
&nbsp;
&nbsp;

    local highlight = Instance.new("Highlight")
    highlight.Name = "ChamHighlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.Adornee = player.Character
    highlight.Parent = localPlayer:WaitForChild("PlayerGui")
&nbsp;
&nbsp;

    chamsHighlights[player] = highlight
end
&nbsp;
&nbsp;

local function removeChams(player)
    if chamsHighlights[player] then
        chamsHighlights[player]:Destroy()
        chamsHighlights[player] = nil
    end
end
&nbsp;
&nbsp;

-- Gestionar cuando un jugador aparezca o muera para crear o limpiar ESP/Chams --
&nbsp;
&nbsp;

local function onCharacterAdded(player, character)
    -- Añadir ignorar del personaje para raycast
    if not table.find(WALL_CHECK_IGNORE_LIST, character) then
        table.insert(WALL_CHECK_IGNORE_LIST, character)
    end
    if espEnabled then createESP(player) end
    if chamsEnabled then createChams(player) end
end
&nbsp;
&nbsp;

local function onCharacterRemoving(player)
    removeESP(player)
    removeChams(player)
    -- Quitar personaje de ignore list
    for i,v in pairs(WALL_CHECK_IGNORE_LIST) do
        if v == player.Character then
            table.remove(WALL_CHECK_IGNORE_LIST, i)
            break
        end
    end
end
&nbsp;
&nbsp;

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
    player.CharacterRemoving:Connect(function()
        onCharacterRemoving(player)
    end)
&nbsp;
&nbsp;

    -- Si ya tiene personaje:
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end
&nbsp;
&nbsp;

local function onPlayerRemoving(player)
    removeESP(player)
    removeChams(player)
end
&nbsp;
&nbsp;

-- Iniciar listeners para jugadores existentes y nuevos --
&nbsp;
&nbsp;

for _, player in pairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        onPlayerAdded(player)
    end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        onPlayerAdded(player)
    end
end)
Players.PlayerRemoving:Connect(function(player)
    onPlayerRemoving(player)
end)
&nbsp;
&nbsp;

-- LOOP --
&nbsp;
&nbsp;

local connection
&nbsp;
&nbsp;

local function startLoop()
    connection = RunService.RenderStepped:Connect(function()
        if not running then
            connection:Disconnect()
            return
        end
&nbsp;
&nbsp;

        if aimbotEnabled or triggerbotEnabled then
            local target, angle = getClosestTarget()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local headPos = target.Character.Head.Position
&nbsp;
&nbsp;

                if aimbotEnabled then
                    moveAimTowards(headPos)
                end
&nbsp;
&nbsp;

                if triggerbotEnabled and angle < TRIGGER_ANGLE then
                    fireWeapon()
                end
            end
        end
&nbsp;
&nbsp;

        -- Mantener ESP y Chams sincronizados con estado toggled
&nbsp;
&nbsp;

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer and isEnemy(player) then
                if espEnabled then
                    createESP(player)
                else
                    removeESP(player)
                end
&nbsp;
&nbsp;

                if chamsEnabled then
                    createChams(player)
                else
                    removeChams(player)
                end
            else
                removeESP(player)
                removeChams(player)
            end
        end
    end)
end
&nbsp;
&nbsp;

startLoop()
&nbsp;
&nbsp;

-- GUI --
&nbsp;
&nbsp;

local PlayerGui = localPlayer:WaitForChild("PlayerGui")
&nbsp;
&nbsp;

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotTriggerbotGUI"
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false
&nbsp;
&nbsp;

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 230)
frame.Position = UDim2.new(0.5, -140, 0.5, -115)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui
&nbsp;
&nbsp;

local dragBar = Instance.new("Frame")
dragBar.Size = UDim2.new(1, 0, 0, 30)
dragBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dragBar.BorderSizePixel = 0
dragBar.Parent = frame
&nbsp;
&nbsp;

local title = Instance.new("TextLabel")
title.Text = "Aimbot & Triggerbot Control"
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = dragBar
&nbsp;
&nbsp;

local closeButton = Instance.new("TextButton")
closeButton.Text = "X"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 20
closeButton.Parent = dragBar
&nbsp;
&nbsp;

local function createToggle(text, positionY)
    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0, 120, 0, 30)
    label.Position = UDim2.new(0, 10, 0, positionY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
&nbsp;
&nbsp;

    local toggle = Instance.new("TextButton")
    toggle.Text = "Off"
    toggle.Size = UDim2.new(0, 50, 0, 30)
    toggle.Position = UDim2.new(0, 180, 0, positionY)
    toggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.SourceSansBold
    toggle.TextSize = 18
    toggle.Parent = frame
&nbsp;
&nbsp;

    return label, toggle
end
&nbsp;
&nbsp;

local aimbotLabel, aimbotToggle = createToggle("Aimbot", 50)
local triggerbotLabel, triggerbotToggle = createToggle("Triggerbot", 100)
local espLabel, espToggle = createToggle("ESP", 150)
local chamsLabel, chamsToggle = createToggle("Chams", 190)
&nbsp;
&nbsp;

aimbotToggle.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotToggle.Text = aimbotEnabled and "On" or "Off"
    aimbotToggle.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
end)
&nbsp;
&nbsp;

triggerbotToggle.MouseButton1Click:Connect(function()
    triggerbotEnabled = not triggerbotEnabled
    triggerbotToggle.Text = triggerbotEnabled and "On" or "Off"
    triggerbotToggle.BackgroundColor3 = triggerbotEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
end)
&nbsp;
&nbsp;

espToggle.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espToggle.Text = espEnabled and "On" or "Off"
    espToggle.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
end)
&nbsp;
&nbsp;

chamsToggle.MouseButton1Click:Connect(function()
    chamsEnabled = not chamsEnabled
    chamsToggle.Text = chamsEnabled and "On" or "Off"
    chamsToggle.BackgroundColor3 = chamsEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
end)
&nbsp;
&nbsp;

-- Drag --
&nbsp;
&nbsp;

local dragging = false
local dragInput, mousePos, framePos
&nbsp;
&nbsp;

local function update(input)
    local delta = input.Position - mousePos
    frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
end
&nbsp;
&nbsp;

dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = frame.Position
&nbsp;
&nbsp;

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
&nbsp;
&nbsp;

dragBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
&nbsp;
&nbsp;

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
&nbsp;
&nbsp;

-- Close GUI and stop script when pressing "X"
&nbsp;
&nbsp;

closeButton.MouseButton1Click:Connect(function()
    running = false
    if connection then connection:Disconnect() end
    screenGui:Destroy()
end)
&nbsp;
&nbsp;

-- Toggle GUI visibility with RightAlt (Alt Gr)
&nbsp;
&nbsp;

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightAlt then
        frame.Visible = not frame.Visible
    end
end)
&nbsp;
&nbsp;

-- Initialization --
&nbsp;
&nbsp;

aimbotToggle.Text = "Off"
aimbotToggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
triggerbotToggle.Text = "Off"
triggerbotToggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
espToggle.Text = "Off"
espToggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
chamsToggle.Text = "Off"
chamsToggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
frame.Visible = true
&nbsp;
&nbsp;
