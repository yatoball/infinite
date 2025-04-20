-- ESP para Animatrônicos em Forgotten Memories (Versão Simplificada)
-- Criar funções principais no ambiente padrão para evitar problemas de escopo
local ESP = {}
ESP.Enabled = true
ESP.Objects = {}

-- Obter serviços
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

-- Configurações
local settings = {
    TextSize = 18,
    TextColor = Color3.fromRGB(255, 255, 255),
    BoxColor = Color3.fromRGB(255, 0, 0),
    BoxThickness = 1,
    MaxDistance = 10000
}

-- Criar objetos de interface
local function createESPText()
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESPGui"
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.ClipsDescendants = false
    
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = settings.TextSize
    textLabel.TextColor3 = settings.TextColor
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Parent = billboardGui
    
    return billboardGui, textLabel
end

-- Função para criar ESP para um objeto
function ESP:Add(object, displayName)
    if self.Objects[object] then
        return
    end
    
    -- Criar interface para o ESP
    local espGui, espText = createESPText()
    
    -- Adicionar à tabela de objetos
    self.Objects[object] = {
        Object = object,
        DisplayName = displayName or object.Name,
        ESP = espGui,
        Text = espText
    }
    
    -- Adicionar ao contêiner de GUI do jogador
    if not localPlayer.PlayerGui:FindFirstChild("ESPContainer") then
        local container = Instance.new("ScreenGui")
        container.Name = "ESPContainer"
        container.ResetOnSpawn = false
        container.Parent = localPlayer.PlayerGui
    end
    
    espGui.Parent = localPlayer.PlayerGui.ESPContainer
    return self.Objects[object]
end

-- Função para remover ESP de um objeto
function ESP:Remove(object)
    if self.Objects[object] then
        self.Objects[object].ESP:Destroy()
        self.Objects[object] = nil
    end
end

-- Função para limpar todos os ESPs
function ESP:RemoveAll()
    for object, data in pairs(self.Objects) do
        data.ESP:Destroy()
    end
    self.Objects = {}
end

-- Criar interface de controle
local function createControlGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESPControls"
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    frame.Parent = screenGui
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 18
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = "ESP Animatrônicos: ATIVADO"
    toggleButton.Parent = frame
    
    toggleButton.MouseButton1Click:Connect(function()
        ESP.Enabled = not ESP.Enabled
        toggleButton.Text = "ESP Animatrônicos: " .. (ESP.Enabled and "ATIVADO" or "DESATIVADO")
    end)
    
    screenGui.Parent = localPlayer.PlayerGui
    return screenGui
end

-- Função principal de atualização
local function onRenderStep()
    if not ESP.Enabled then
        for _, espData in pairs(ESP.Objects) do
            espData.ESP.Enabled = false
        end
        return
    end
    
    -- Verificar objetos existentes
    for object, espData in pairs(ESP.Objects) do
        if object and object.Parent and object:FindFirstChild("PrimaryPart") then
            local primaryPart = object.PrimaryPart
            
            -- Obter posição do objeto
            local objectPosition = primaryPart.Position
            local onScreen = true  -- Assumir que está na tela
            
            -- Calcular distância
            local distance = (objectPosition - localPlayer.Character.HumanoidRootPart.Position).Magnitude
            
            -- Atualizar ESP
            espData.ESP.Adornee = primaryPart
            espData.ESP.Enabled = distance <= settings.MaxDistance
            
            -- Atualizar texto
            espData.Text.Text = string.format("%s\nDistância: %d studs\nPos: %.1f, %.1f, %.1f", 
                espData.DisplayName,
                math.floor(distance),
                objectPosition.X,
                objectPosition.Y,
                objectPosition.Z
            )
            
            -- Definir cor baseada no nome
            if espData.DisplayName:find("Freddy") then
                espData.Text.TextColor3 = Color3.fromRGB(139, 69, 19)
            elseif espData.DisplayName:find("Bonnie") then
                espData.Text.TextColor3 = Color3.fromRGB(75, 0, 130)
            else
                espData.Text.TextColor3 = settings.TextColor
            end
        else
            -- Remover ESP se o objeto não existe mais
            ESP:Remove(object)
        end
    end
    
    -- Buscar novos animatrônicos
    for _, folder in pairs({workspace:FindFirstChild("Animatronics"), workspace:FindFirstChild("AnimatronicSpawnRoots")}) do
        if folder then
            for _, object in pairs(folder:GetChildren()) do
                if (object.Name == "Freddy" or object.Name == "Bonnie") and 
                   object:IsA("Model") and 
                   object:FindFirstChild("PrimaryPart") then
                    -- Adicionar à lista se não existir ainda
                    if not ESP.Objects[object] then
                        ESP:Add(object, object.Name .. " [" .. folder.Name .. "]")
                    end
                end
            end
        end
    end
end

-- Iniciar o ESP
local controlGui = createControlGUI()
local espContainer = Instance.new("ScreenGui")
espContainer.Name = "ESPContainer"
espContainer.ResetOnSpawn = false
espContainer.Parent = localPlayer.PlayerGui

-- Conectar ao RenderStep
RunService:BindToRenderStep("AnimatronicESP", Enum.RenderPriority.Camera.Value + 1, onRenderStep)

-- Função de limpeza quando o script é parado
local function cleanUp()
    RunService:UnbindFromRenderStep("AnimatronicESP")
    ESP:RemoveAll()
    if controlGui then controlGui:Destroy() end
    if espContainer then espContainer:Destroy() end
end

-- Limpar quando o personagem é removido
localPlayer.CharacterRemoving:Connect(cleanUp)

-- Começar a buscar animatrônicos imediatamente
onRenderStep()

-- Limpar ESPs anteriores
for _, v in pairs(workspace:GetDescendants()) do
    if v.Name == "ESP_Marker" then
        v:Destroy()
    end
end

-- Limpar efeitos anteriores
for _, v in pairs(workspace:GetDescendants()) do
    if v.Name == "ESP_Glow" or v.Name == "ESP_Light" or v.Name == "ESP_Label" then
        v:Destroy()
    end
end

-- Restaurar materiais originais
for _, modelo in pairs(workspace:GetDescendants()) do
    if modelo:IsA("Model") and modelo:FindFirstChild("Humanoid") then
        for _, parte in pairs(modelo:GetDescendants()) do
            if parte:IsA("BasePart") then
                local originalMaterial = parte:FindFirstChild("OriginalMaterial")
                local originalColor = parte:FindFirstChild("OriginalColor")
                
                if originalMaterial and originalColor then
                    parte.Material = Enum.Material[originalMaterial.Value]
                    parte.Color = originalColor.Value
                    
                    originalMaterial:Destroy()
                    originalColor:Destroy()
                end
                
                if parte:FindFirstChild("ESP_Light") then
                    parte:FindFirstChild("ESP_Light"):Destroy()
                end
            end
        end
    end
end

-- Cores para os animatrônicos
local cores = {
    Freddy = Color3.fromRGB(139, 69, 19),
    Bonnie = Color3.fromRGB(75, 0, 130),
    Chica = Color3.fromRGB(255, 255, 0),
    Foxy = Color3.fromRGB(255, 0, 0)
}

-- Função para adicionar apenas nomes 3D
local function adicionarNomes3D(modelo)
    -- Já tem o nome?
    if modelo:FindFirstChild("ESP_Label") then
        return
    end
    
    -- Determinar cor com base no nome
    local cor = cores[modelo.Name] or Color3.new(1, 1, 1)
    
    -- Encontrar parte principal para anexar o rótulo
    local partePrincipal = modelo:FindFirstChild("HumanoidRootPart") or 
                           modelo:FindFirstChild("Head") or 
                           modelo:FindFirstChild("Torso") or 
                           modelo:FindFirstChild("UpperTorso") or 
                           modelo.PrimaryPart or 
                           modelo:FindFirstChildWhichIsA("BasePart")
    
    if not partePrincipal then return end
    
    -- Criar BillboardGui grande e destacado
    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP_Label"
    gui.AlwaysOnTop = true
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.LightInfluence = 0 -- Não afetado pela iluminação
    gui.MaxDistance = 500 -- Visível de muito longe
    gui.Adornee = partePrincipal
    gui.Parent = modelo
    
    -- Texto principal com nome
    local texto = Instance.new("TextLabel")
    texto.BackgroundTransparency = 1
    texto.Size = UDim2.new(1, 0, 1, 0)
    texto.Font = Enum.Font.GothamBold
    texto.TextSize = 24
    texto.Text = modelo.Name
    texto.TextColor3 = cor
    texto.TextStrokeTransparency = 0
    texto.TextStrokeColor3 = Color3.new(0, 0, 0)
    texto.Parent = gui
    
    -- Adicionar indicador de distância (opcional)
    local distancia = Instance.new("TextLabel")
    distancia.Name = "Distancia"
    distancia.BackgroundTransparency = 1
    distancia.Size = UDim2.new(1, 0, 0, 0.4)
    distancia.Position = UDim2.new(0, 0, 1, 0)
    distancia.Font = Enum.Font.Gotham
    distancia.TextSize = 16
    distancia.TextColor3 = cor
    distancia.TextStrokeTransparency = 0
    distancia.TextStrokeColor3 = Color3.new(0, 0, 0)
    distancia.Parent = gui
    
    -- Atualizar distância
    local player = game:GetService("Players").LocalPlayer
    spawn(function()
        while gui and gui.Parent and player and player.Character do
            if not player.Character:FindFirstChild("HumanoidRootPart") then
                wait(0.5)
                continue
            end
            
            local playerPos = player.Character.HumanoidRootPart.Position
            local distValue = (partePrincipal.Position - playerPos).Magnitude
            distancia.Text = math.floor(distValue + 0.5) .. " m"
            
            wait(0.2)
        end
    end)
    
    print("Nome 3D adicionado: " .. modelo.Name)
end

-- Função para buscar animatrônicos
local function buscarAnimatronicos()
    local count = 0
    
    -- Função auxiliar
    local function verificarModelo(modelo)
        if modelo:IsA("Model") and modelo:FindFirstChild("Humanoid") then
            -- Verificar se é animatrônico pelo nome
            if cores[modelo.Name] or 
               modelo.Name:find("Freddy") or 
               modelo.Name:find("Bonnie") or 
               modelo.Name:find("Chica") or 
               modelo.Name:find("Foxy") then
                
                adicionarNomes3D(modelo)
                count = count + 1
            end
        end
    end
    
    -- Verificar todos os modelos no workspace
    for _, v in pairs(workspace:GetDescendants()) do
        pcall(verificarModelo, v)
    end
    
    return count
end

-- Adicionar interface de controle
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_Controle"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 50)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.6
frame.BorderSizePixel = 0
frame.Parent = screenGui

local buttonESP = Instance.new("TextButton")
buttonESP.Size = UDim2.new(0, 140, 0, 30)
buttonESP.Position = UDim2.new(0.5, -70, 0.5, -15)
buttonESP.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
buttonESP.Text = "ESP NOMES: ON"
buttonESP.TextColor3 = Color3.new(0, 1, 0)
buttonESP.Font = Enum.Font.GothamBold
buttonESP.TextSize = 14
buttonESP.Parent = frame

-- Controle de toggle para ESP
local espAtivo = true
buttonESP.MouseButton1Click:Connect(function()
    espAtivo = not espAtivo
    
    if espAtivo then
        buttonESP.Text = "ESP NOMES: ON"
        buttonESP.TextColor3 = Color3.new(0, 1, 0)
        buscarAnimatronicos()
    else
        buttonESP.Text = "ESP NOMES: OFF"
        buttonESP.TextColor3 = Color3.new(1, 0, 0)
        
        -- Remover todos os rótulos
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "ESP_Label" then
                v:Destroy()
            end
        end
    end
end)

-- Executar o sistema
local encontrados = buscarAnimatronicos()
print("ESP de Nomes ativado! Encontrados " .. encontrados .. " animatrônicos.")

-- Loop para manter atualizado
spawn(function()
    while wait(1) do
        if espAtivo then
            buscarAnimatronicos()
        end
    end
end)

-- Versão ultra-simples apenas com nomes
for _, v in pairs(workspace:GetDescendants()) do
    if v.Name == "ESP_Nome" then v:Destroy() end
end

local function adicionarNomes()
    for _, modelo in pairs(workspace:GetDescendants()) do
        if modelo:IsA("Model") and modelo:FindFirstChild("Humanoid") then
            -- Determinar se é um animatrônico e qual cor usar
            local cor
            if modelo.Name == "Freddy" or modelo.Name:find("Freddy") then
                cor = Color3.fromRGB(139, 69, 19)
            elseif modelo.Name == "Bonnie" or modelo.Name:find("Bonnie") then
                cor = Color3.fromRGB(75, 0, 130)
            elseif modelo.Name == "Chica" or modelo.Name:find("Chica") then
                cor = Color3.fromRGB(255, 255, 0)
            elseif modelo.Name == "Foxy" or modelo.Name:find("Foxy") then
                cor = Color3.fromRGB(255, 0, 0)
            else
                continue
            end
            
            -- Adicionar BillboardGui
            if not modelo:FindFirstChild("ESP_Nome") then
                local parte = modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Head") or modelo:FindFirstChildWhichIsA("BasePart")
                if parte then
                    local gui = Instance.new("BillboardGui")
                    gui.Name = "ESP_Nome"
                    gui.Size = UDim2.new(0, 200, 0, 50)
                    gui.StudsOffset = Vector3.new(0, 3, 0)
                    gui.AlwaysOnTop = true
                    gui.LightInfluence = 0
                    gui.Adornee = parte
                    gui.Parent = modelo
                    
                    local texto = Instance.new("TextLabel")
                    texto.Size = UDim2.new(1, 0, 1, 0)
                    texto.BackgroundTransparency = 1
                    texto.Text = modelo.Name
                    texto.Font = Enum.Font.GothamBold
                    texto.TextSize = 24
                    texto.TextColor3 = cor
                    texto.TextStrokeTransparency = 0
                    texto.Parent = gui
                end
            end
        end
    end
end

adicionarNomes()
spawn(function() while wait(2) do adicionarNomes() end end)

-- Limpar interfaces e ESPs existentes
for _, gui in pairs(game:GetService("Players").LocalPlayer:GetChildren()) do
    if gui.Name == "ESP_ImGui" or gui.Name == "ESP_Control" then
        gui:Destroy()
    end
end

for _, gui in pairs(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
    if gui.Name == "ESP_ImGui" or gui.Name == "ESP_Control" then
        gui:Destroy()
    end
end

for _, v in pairs(workspace:GetDescendants()) do
    if v.Name == "ESP_Nome" or v.Name == "ESP_Label" or v.Name == "ESP_Marker" or v.Name == "ESP_Glow" then
        v:Destroy()
    end
end

-- Limpar TODAS as interfaces existentes (incluindo as do canto da tela)
for _, player in pairs(game:GetService("Players"):GetPlayers()) do
    for _, gui in pairs(player:GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name == "ESP_ImGui" or gui.Name:find("ESP")) then
            gui:Destroy()
        end
    end
    
    for _, gui in pairs(player.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name == "ESP_ImGui" or gui.Name:find("ESP")) then
            gui:Destroy()
        end
    end
end

-- Limpar todos os ESPs nos modelos
for _, v in pairs(workspace:GetDescendants()) do
    if v.Name:find("ESP") then
        v:Destroy()
    end
end

-- Criar interface principal com alta prioridade de visualização
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_ImGui_Core"
screenGui.DisplayOrder = 9999
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = game:GetService("CoreGui")

-- Cores para os animatrônicos
local cores = {
    Freddy = Color3.fromRGB(139, 69, 19),
    Bonnie = Color3.fromRGB(75, 0, 130),
    Chica = Color3.fromRGB(255, 255, 0),
    Foxy = Color3.fromRGB(255, 0, 0)
}

-- Configurações do ESP
local config = {
    espAtivo = true,
    mostrarDistancia = true,
    tamanhoFonte = 18,
    transparencia = 0,
    borda = true
}

-- Rastreamento de ESPs ativos
local espsAtivos = {}

-- Criar painel principal
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 320, 0, 350)  -- Reduzindo altura para remover área de botões
mainPanel.Position = UDim2.new(0.5, -160, 0.5, -175)
mainPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainPanel.BorderSizePixel = 0
mainPanel.Active = true
mainPanel.Draggable = true
mainPanel.ZIndex = 9999
mainPanel.Parent = screenGui
mainPanel.Visible = false  -- Inicia invisível para animação

-- Funções de utilidade UI
local function addCorner(element, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = element
    return corner
end

local function addStroke(element, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(60, 60, 70)
    stroke.Thickness = thickness or 1
    stroke.Parent = element
    return stroke
end

local function addGradient(element, colorTop, colorBottom)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorTop or Color3.fromRGB(35, 35, 45)),
        ColorSequenceKeypoint.new(1, colorBottom or Color3.fromRGB(25, 25, 35))
    })
    gradient.Rotation = 90
    gradient.Parent = element
    return gradient
end

-- Aplicar estilo ao painel
addCorner(mainPanel)
addStroke(mainPanel, Color3.fromRGB(80, 80, 120), 1.5)
addGradient(mainPanel)

-- Adicionar cabeçalho
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
header.BorderSizePixel = 0
header.ZIndex = 10000
header.Parent = mainPanel

-- Estilizar cabeçalho
local headerCorner = addCorner(header)
headerCorner.CornerRadius = UDim.new(0, 8)
addGradient(header, Color3.fromRGB(50, 50, 80), Color3.fromRGB(40, 40, 60))

-- Adicionar ícone animado
local iconFrame = Instance.new("Frame")
iconFrame.Size = UDim2.new(0, 30, 0, 30)
iconFrame.Position = UDim2.new(0, 7, 0.5, -15)
iconFrame.BackgroundTransparency = 1
iconFrame.ZIndex = 10001
iconFrame.Parent = header

local iconImage = Instance.new("ImageLabel")
iconImage.Size = UDim2.new(1, 0, 1, 0)
iconImage.BackgroundTransparency = 1
iconImage.Image = "rbxassetid://7733658504"  -- Ícone de fantasma/personagem
iconImage.ImageColor3 = Color3.fromRGB(180, 180, 255)
iconImage.ZIndex = 10002
iconImage.Parent = iconFrame

-- Animação de rotação do ícone
spawn(function()
    while wait(0.05) do
        iconImage.Rotation = (iconImage.Rotation + 1) % 360
    end
end)

-- Container para os textos de título
local titleContainer = Instance.new("Frame")
titleContainer.Size = UDim2.new(1, -90, 1, 0)
titleContainer.Position = UDim2.new(0, 45, 0, 0)
titleContainer.BackgroundTransparency = 1
titleContainer.ZIndex = 10001
titleContainer.Parent = header

-- Texto de desenvolvedor (acima do título principal)
local devText = Instance.new("TextLabel")
devText.Size = UDim2.new(1, 0, 0, 15)
devText.Position = UDim2.new(0, 0, 0, 0)
devText.BackgroundTransparency = 1
devText.Font = Enum.Font.Gotham
devText.Text = "Desenvolvido por @yato"
devText.TextSize = 11
devText.TextColor3 = Color3.fromRGB(200, 200, 255)
devText.TextXAlignment = Enum.TextXAlignment.Left
devText.ZIndex = 10001
devText.Parent = titleContainer

-- Efeito de brilho no texto do desenvolvedor
local devTextStroke = Instance.new("UIStroke")
devTextStroke.Color = Color3.fromRGB(100, 100, 255)
devTextStroke.Thickness = 0.5
devTextStroke.Transparency = 0.8
devTextStroke.Parent = devText

-- Título principal com efeito de brilho
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 20)
titleLabel.Position = UDim2.new(0, 0, 0, 15)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Animatronic ESP"
titleLabel.TextSize = 18
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 10001
titleLabel.Parent = titleContainer

-- Efeito de brilho no texto do título
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(100, 100, 255)
titleStroke.Thickness = 1
titleStroke.Transparency = 0.7
titleStroke.Parent = titleLabel

-- Animação do texto do desenvolvedor (pulsação suave)
spawn(function()
    while wait(0.05) do
        for i = 0, 1, 0.02 do
            if devText.Parent then
                devText.TextColor3 = Color3.fromRGB(
                    200 + (55 * math.sin(i * math.pi)), 
                    200 + (55 * math.sin(i * math.pi)), 
                    255
                )
            else
                break
            end
            wait(0.05)
        end
    end
end)

-- Botão de fechar com animação
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 26, 0, 26)
closeButton.Position = UDim2.new(1, -33, 0.5, -13)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
closeButton.Text = "×"
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.ZIndex = 10001
closeButton.Parent = header
addCorner(closeButton, 6)

closeButton.MouseEnter:Connect(function()
    closeButton:TweenSize(
        UDim2.new(0, 28, 0, 28),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.2,
        true
    )
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
end)

closeButton.MouseLeave:Connect(function()
    closeButton:TweenSize(
        UDim2.new(0, 26, 0, 26),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.2,
        true
    )
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
end)

closeButton.MouseButton1Click:Connect(function()
    -- Animação de fechamento
    mainPanel:TweenSize(
        UDim2.new(0, 320, 0, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true,
        function()
            mainPanel.Visible = false
            mainPanel.Size = UDim2.new(0, 320, 0, 350)
        end
    )
end)

-- Conteúdo principal
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -20, 1, -50)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundTransparency = 1
content.ZIndex = 10000
content.Parent = mainPanel

-- Função para criar um toggle com animação
local function createToggle(parent, position, text, initialState, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.ZIndex = 10000
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 10001
    label.Parent = frame
    
    -- Efeito de brilho no hover
    local hoverEffect = Instance.new("Frame")
    hoverEffect.Size = UDim2.new(1, 0, 1, 0)
    hoverEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hoverEffect.BackgroundTransparency = 0.95
    hoverEffect.Visible = false
    hoverEffect.ZIndex = 10000
    hoverEffect.Parent = frame
    addCorner(hoverEffect, 4)
    
    local toggleBack = Instance.new("Frame")
    toggleBack.Size = UDim2.new(0, 44, 0, 22)
    toggleBack.Position = UDim2.new(1, -50, 0.5, -11)
    toggleBack.BackgroundColor3 = initialState and Color3.fromRGB(70, 200, 120) or Color3.fromRGB(200, 60, 60)
    toggleBack.ZIndex = 10001
    toggleBack.Parent = frame
    addCorner(toggleBack, 11)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = UDim2.new(initialState and 1 or 0, initialState and -20 or 3, 0.5, -8)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.ZIndex = 10002
    toggleCircle.Parent = toggleBack
    addCorner(toggleCircle, 8)
    
    local glowEffect = Instance.new("ImageLabel")
    glowEffect.BackgroundTransparency = 1
    glowEffect.Image = "rbxassetid://5028857084"
    glowEffect.ImageTransparency = 0.6
    glowEffect.ImageColor3 = initialState and Color3.fromRGB(70, 255, 120) or Color3.fromRGB(255, 60, 60)
    glowEffect.Size = UDim2.new(1.5, 0, 1.5, 0)
    glowEffect.Position = UDim2.new(-0.25, 0, -0.25, 0)
    glowEffect.ScaleType = Enum.ScaleType.Slice
    glowEffect.SliceCenter = Rect.new(24, 24, 24, 24)
    glowEffect.ZIndex = 10000
    glowEffect.Parent = toggleCircle
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 10002
    button.Parent = frame
    
    local state = initialState
    
    button.MouseEnter:Connect(function()
        hoverEffect.Visible = true
    end)
    
    button.MouseLeave:Connect(function()
        hoverEffect.Visible = false
    end)
    
    button.MouseButton1Click:Connect(function()
        state = not state
        
        -- Animação para mudar a cor do fundo
        local colorInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local colorProperties = {
            BackgroundColor3 = state and Color3.fromRGB(70, 200, 120) or Color3.fromRGB(200, 60, 60)
        }
        local colorTween = game:GetService("TweenService"):Create(toggleBack, colorInfo, colorProperties)
        colorTween:Play()
        
        -- Animação para o círculo
        toggleCircle:TweenPosition(
            UDim2.new(state and 1 or 0, state and -20 or 3, 0.5, -8),
            Enum.EasingDirection.InOut,
            Enum.EasingStyle.Back,
            0.3,
            true
        )
        
        -- Animação para o brilho
        local glowInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local glowProperties = {
            ImageColor3 = state and Color3.fromRGB(70, 255, 120) or Color3.fromRGB(255, 60, 60)
        }
        local glowTween = game:GetService("TweenService"):Create(glowEffect, glowInfo, glowProperties)
        glowTween:Play()
        
        callback(state)
    end)
    
    return frame, function() return state end
end

-- Função para criar um slider com animação
local function createSlider(parent, position, text, min, max, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.ZIndex = 10000
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text .. ": " .. initial
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 10001
    label.Parent = frame
    
    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, 0, 0, 8)
    sliderBack.Position = UDim2.new(0, 0, 0.7, 0)
    sliderBack.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sliderBack.ZIndex = 10001
    sliderBack.Parent = frame
    addCorner(sliderBack, 4)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((initial - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(90, 130, 250)
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 10002
    sliderFill.Parent = sliderBack
    addCorner(sliderFill, 4)
    
    -- Adicionar brilho ao slider
    local sliderGlow = Instance.new("ImageLabel")
    sliderGlow.BackgroundTransparency = 1
    sliderGlow.Image = "rbxassetid://5028857084"
    sliderGlow.ImageTransparency = 0.7
    sliderGlow.ImageColor3 = Color3.fromRGB(120, 160, 255)
    sliderGlow.ScaleType = Enum.ScaleType.Slice
    sliderGlow.SliceCenter = Rect.new(24, 24, 24, 24)
    sliderGlow.Size = UDim2.new(1, 6, 1, 6)
    sliderGlow.Position = UDim2.new(0, -3, 0, -3)
    sliderGlow.ZIndex = 10001
    sliderGlow.Parent = sliderFill
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new((initial - min) / (max - min), -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.ZIndex = 10003
    sliderKnob.Parent = sliderBack
    addCorner(sliderKnob, 8)
    addStroke(sliderKnob, Color3.fromRGB(90, 130, 250), 1)
    
    -- Adicionar brilho ao knob
    local knobGlow = Instance.new("ImageLabel")
    knobGlow.BackgroundTransparency = 1
    knobGlow.Image = "rbxassetid://5028857084"
    knobGlow.ImageTransparency = 0.5
    knobGlow.ImageColor3 = Color3.fromRGB(120, 160, 255)
    knobGlow.ScaleType = Enum.ScaleType.Slice
    knobGlow.SliceCenter = Rect.new(24, 24, 24, 24)
    knobGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
    knobGlow.Position = UDim2.new(-0.25, 0, -0.25, 0)
    knobGlow.ZIndex = 10002
    knobGlow.Parent = sliderKnob
    
    local value = initial
    
    local function updateSlider(newValue, withAnimation)
        value = math.clamp(newValue, min, max)
        if math.floor(value) == value then
            value = math.floor(value)
        else
            value = math.floor(value * 100) / 100
        end
        
        local percent = (value - min) / (max - min)
        
        if withAnimation then
            -- Animar o preenchimento
            game:GetService("TweenService"):Create(
                sliderFill, 
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(percent, 0, 1, 0)}
            ):Play()
            
            -- Animar o botão
            game:GetService("TweenService"):Create(
                sliderKnob, 
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(percent, -8, 0.5, -8)}
            ):Play()
        else
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            sliderKnob.Position = UDim2.new(percent, -8, 0.5, -8)
        end
        
        label.Text = text .. ": " .. value
        callback(value)
    end
    
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = game:GetService("UserInputService"):GetMouseLocation().X
            local framePos = sliderBack.AbsolutePosition.X
            local frameSize = sliderBack.AbsoluteSize.X
            local percent = math.clamp((mousePos - framePos) / frameSize, 0, 1)
            updateSlider(min + (max - min) * percent, true)
            
            -- Efeito de aumentar o knob quando clicado
            sliderKnob:TweenSize(
                UDim2.new(0, 20, 0, 20),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true
            )
            
            local connection
            connection = game:GetService("RunService").RenderStepped:Connect(function()
                local mousePos = game:GetService("UserInputService"):GetMouseLocation().X
                local framePos = sliderBack.AbsolutePosition.X
                local frameSize = sliderBack.AbsoluteSize.X
                local percent = math.clamp((mousePos - framePos) / frameSize, 0, 1)
                updateSlider(min + (max - min) * percent, false)
            end)
            
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if connection then connection:Disconnect() end
                    
                    -- Restaurar tamanho do knob
                    sliderKnob:TweenSize(
                        UDim2.new(0, 16, 0, 16),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quad,
                        0.1,
                        true
                    )
                end
            end)
        end
    end)
    
    return frame, function() return value end
end

-- Função para criar separador
local function createSeparator(parent, position)
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Position = position
    sep.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    sep.BorderSizePixel = 0
    sep.ZIndex = 10000
    sep.Parent = parent
    
    -- Gradient para o separador
    local sepGradient = Instance.new("UIGradient")
    sepGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.8)
    })
    sepGradient.Parent = sep
    
    -- Animação do gradiente
    spawn(function()
        while sep.Parent do
            for i = 0, 1, 0.01 do
                sepGradient.Offset = Vector2.new(i, 0)
                wait(0.02)
            end
        end
    end)
    
    return sep
end

-- Função para criar título de seção com animação
local function createSectionTitle(parent, position, text)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = position
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = text
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(160, 160, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 10001
    title.Parent = parent
    
    -- Adicionar efeito de texto
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(120, 120, 255)
    titleStroke.Thickness = 1
    titleStroke.Transparency = 0.7
    titleStroke.Parent = title
    
    -- Animação de cores no texto
    spawn(function()
        local hue = 0.6  -- Começa com azul
        while title.Parent do
            -- Alternar entre azul e roxo suavemente
            hue = 0.6 + math.sin(tick() * 0.5) * 0.1
            title.TextColor3 = Color3.fromHSV(hue, 0.7, 1)
            titleStroke.Color = Color3.fromHSV(hue, 0.7, 0.7)
            wait(0.05)
        end
    end)
    
    return title
end

-- Adicionar controles à interface
createSectionTitle(content, UDim2.new(0, 0, 0, 5), "CONFIGURAÇÕES GERAIS")
createSeparator(content, UDim2.new(0, 0, 0, 30))

local toggleESP, getESPState = createToggle(content, UDim2.new(0, 0, 0, 40), "ESP Ativo", config.espAtivo, function(state)
    config.espAtivo = state
    if state then
        atualizarESP()
    else
        removerESP()
    end
end)

local toggleDist, getDistState = createToggle(content, UDim2.new(0, 0, 0, 80), "Mostrar Distância", config.mostrarDistancia, function(state)
    config.mostrarDistancia = state
    atualizarESP()
end)

local toggleBorda, getBordaState = createToggle(content, UDim2.new(0, 0, 0, 120), "Borda de Texto", config.borda, function(state)
    config.borda = state
    atualizarESP()
end)

createSectionTitle(content, UDim2.new(0, 0, 0, 165), "PERSONALIZAÇÃO")
createSeparator(content, UDim2.new(0, 0, 0, 190))

local sliderFonte, getFonteSize = createSlider(content, UDim2.new(0, 0, 0, 200), "Tamanho da Fonte", 10, 30, config.tamanhoFonte, function(val)
    config.tamanhoFonte = val
    atualizarESP()
end)

local sliderTransp, getTransp = createSlider(content, UDim2.new(0, 0, 0, 250), "Transparência do Texto", 0, 0.9, config.transparencia, function(val)
    config.transparencia = val
    atualizarESP()
end)

-- Função para remover ESP
function removerESP()
    for _, esp in pairs(espsAtivos) do
        if esp and esp.Parent then
            esp:Destroy()
        end
    end
    
    espsAtivos = {}
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:find("ESP") then
            v:Destroy()
        end
    end
end

-- Função para atualizar ESP
function atualizarESP()
    if not config.espAtivo then
        removerESP()
        return
    end
    
    -- Limpar ESP existente
    removerESP()
    
    -- Procurar animatrônicos
    for _, modelo in pairs(workspace:GetDescendants()) do
        if modelo:IsA("Model") and modelo:FindFirstChild("Humanoid") then
            -- Verificar se é um animatrônico pelo nome
            local cor
            if modelo.Name == "Freddy" or modelo.Name:find("Freddy") then
                cor = cores.Freddy
            elseif modelo.Name == "Bonnie" or modelo.Name:find("Bonnie") then
                cor = cores.Bonnie
            elseif modelo.Name == "Chica" or modelo.Name:find("Chica") then
                cor = cores.Chica
            elseif modelo.Name == "Foxy" or modelo.Name:find("Foxy") then
                cor = cores.Foxy
            else
                continue
            end
            
            -- Encontrar parte principal
            local parte = modelo:FindFirstChild("HumanoidRootPart") or 
                          modelo:FindFirstChild("Head") or 
                          modelo:FindFirstChildWhichIsA("BasePart")
            
            if parte then
                -- Criar BillboardGui
                local gui = Instance.new("BillboardGui")
                gui.Name = "ESP_Nome"
                gui.Size = UDim2.new(0, 200, 0, 50)
                gui.StudsOffset = Vector3.new(0, 3, 0)
                gui.AlwaysOnTop = true
                gui.LightInfluence = 0
                gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                gui.Adornee = parte
                gui.Parent = modelo
                
                -- Adicionar à lista de ESPs ativos
                table.insert(espsAtivos, gui)
                
                -- Texto principal
                local texto = Instance.new("TextLabel")
                texto.Size = UDim2.new(1, 0, 0, 30)
                texto.Position = UDim2.new(0, 0, 0, 0)
                texto.BackgroundTransparency = 1
                texto.Text = modelo.Name
                texto.Font = Enum.Font.GothamBold
                texto.TextSize = config.tamanhoFonte
                texto.TextColor3 = cor
                texto.TextTransparency = config.transparencia
                texto.TextStrokeTransparency = config.borda and 0 or 1
                texto.TextStrokeColor3 = Color3.new(0, 0, 0)
                texto.Parent = gui
                
                -- Mostrar distância se ativado
                if config.mostrarDistancia then
                    local distancia = Instance.new("TextLabel")
                    distancia.Name = "Distancia"
                    distancia.Size = UDim2.new(1, 0, 0, 20)
                    distancia.Position = UDim2.new(0, 0, 0, 30)
                    distancia.BackgroundTransparency = 1
                    distancia.Font = Enum.Font.Gotham
                    distancia.TextSize = config.tamanhoFonte - 4
                    distancia.TextColor3 = cor
                    distancia.TextTransparency = config.transparencia
                    distancia.TextStrokeTransparency = config.borda and 0 or 1
                    distancia.TextStrokeColor3 = Color3.new(0, 0, 0)
                    distancia.Parent = gui
                    
                    -- Atualizar distância
                    spawn(function()
                        local player = game:GetService("Players").LocalPlayer
                        while gui and gui.Parent and distancia and distancia.Parent do
                            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                local playerPos = player.Character.HumanoidRootPart.Position
                                local distValue = (parte.Position - playerPos).Magnitude
                                distancia.Text = math.floor(distValue + 0.5) .. " m"
                            end
                            wait(0.2)
                        end
                    end)
                end
            end
        end
    end
end

-- Tecla para abrir/fechar interface (F1)
local uisConnection
uisConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F1 then
        mainPanel.Visible = not mainPanel.Visible
    end
end)

-- Loop de atualização
local updateConnection
spawn(function()
    updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if config.espAtivo and not mainPanel.Visible then
            atualizarESP()
            wait(1)  -- Limitar atualização para economizar recursos
        end
    end)
end)

-- Iniciar o sistema
atualizarESP()

-- Mostrar notificação inicial
local notif = Instance.new("Frame")
notif.Size = UDim2.new(0, 280, 0, 80)
notif.Position = UDim2.new(0.5, -140, 0, -100)
notif.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
notif.BorderSizePixel = 0
notif.ZIndex = 10000
notif.Parent = screenGui

addCorner(notif)
addStroke(notif, Color3.fromRGB(90, 90, 150), 1.5)
addGradient(notif, Color3.fromRGB(40, 40, 70), Color3.fromRGB(30, 30, 50))

local notifText = Instance.new("TextLabel")
notifText.Size = UDim2.new(1, -20, 1, -20)
notifText.Position = UDim2.new(0, 10, 0, 10)
notifText.BackgroundTransparency = 1
notifText.Font = Enum.Font.GothamSemibold
notifText.Text = "Animatronic ESP ativado!\nPressione F1 para configurações."
notifText.TextSize = 14
notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
notifText.ZIndex = 10001
notifText.Parent = notif

-- Animação de entrada e saída
notif:TweenPosition(
    UDim2.new(0.5, -140, 0, 20),
    Enum.EasingDirection.Out,
    Enum.EasingStyle.Back,
    0.8,
    true
)

wait(3)

notif:TweenPosition(
    UDim2.new(0.5, -140, 0, -100),
    Enum.EasingDirection.In,
    Enum.EasingStyle.Quint,
    0.5,
    true,
    function()
        notif:Destroy()
    end
)

print("ESP de Animatrônicos ativado! Pressione F1 para abrir o menu.") 