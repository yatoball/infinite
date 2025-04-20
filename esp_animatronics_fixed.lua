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

-- Configurações
local config = {
    espAtivo = true,
    mostrarDistancia = true,
    tamanhoFonte = 18,
    transparencia = 0,
    borda = true,
    intervaloAtualizacao = 1
}

-- Lista de ESPs ativos
local espsAtivos = {}

-- Criar painel principal
local painel = Instance.new("Frame")
painel.Name = "Painel"
painel.Size = UDim2.new(0, 300, 0, 350)
painel.Position = UDim2.new(0.5, -150, 0.5, -175)
painel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
painel.BorderSizePixel = 0
painel.ZIndex = 100
painel.Active = true
painel.Draggable = true
painel.Parent = screenGui

-- Funções de utilidade
local function addCantos(elemento, raio)
    local cantos = Instance.new("UICorner")
    cantos.CornerRadius = UDim.new(0, raio or 8)
    cantos.Parent = elemento
    return cantos
end

local function addBorda(elemento, cor, espessura)
    local borda = Instance.new("UIStroke")
    borda.Color = cor or Color3.fromRGB(60, 60, 90)
    borda.Thickness = espessura or 1.5
    borda.Parent = elemento
    return borda
end

-- Aplicar estilo ao painel
addCantos(painel)
addBorda(painel, Color3.fromRGB(80, 80, 120), 1.5)

-- Cabeçalho
local cabecalho = Instance.new("Frame")
cabecalho.Size = UDim2.new(1, 0, 0, 40)
cabecalho.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
cabecalho.BorderSizePixel = 0
cabecalho.ZIndex = 101
cabecalho.Parent = painel
addCantos(cabecalho, 8)

-- Desenvolvedor (acima do título)
local textoDesenvolvedor = Instance.new("TextLabel")
textoDesenvolvedor.Size = UDim2.new(1, -50, 0, 16)
textoDesenvolvedor.Position = UDim2.new(0, 12, 0, 5)
textoDesenvolvedor.BackgroundTransparency = 1
textoDesenvolvedor.Font = Enum.Font.Gotham
textoDesenvolvedor.Text = "Desenvolvido por @yato"
textoDesenvolvedor.TextSize = 11
textoDesenvolvedor.TextColor3 = Color3.fromRGB(200, 200, 255)
textoDesenvolvedor.TextXAlignment = Enum.TextXAlignment.Left
textoDesenvolvedor.ZIndex = 102
textoDesenvolvedor.Parent = cabecalho

-- Título
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -50, 0, 20)
titulo.Position = UDim2.new(0, 12, 0, 20)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.GothamBold
titulo.Text = "Animatronic ESP"
titulo.TextSize = 16
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.ZIndex = 102
titulo.Parent = cabecalho

-- Botão de fechar
local botaoFechar = Instance.new("TextButton")
botaoFechar.Size = UDim2.new(0, 26, 0, 26)
botaoFechar.Position = UDim2.new(1, -35, 0.5, -13)
botaoFechar.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
botaoFechar.Text = "×"
botaoFechar.TextSize = 24
botaoFechar.Font = Enum.Font.GothamBold
botaoFechar.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoFechar.ZIndex = 102
botaoFechar.Parent = cabecalho
addCantos(botaoFechar, 8)

botaoFechar.MouseButton1Click:Connect(function()
    painel.Visible = false
end)

-- Conteúdo
local conteudo = Instance.new("Frame")
conteudo.Size = UDim2.new(1, -20, 1, -50)
conteudo.Position = UDim2.new(0, 10, 0, 45)
conteudo.BackgroundTransparency = 1
conteudo.ZIndex = 101
conteudo.Parent = painel

-- Funções para criar elementos
local function criarTitulo(parent, pos, texto)
    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0, 25)
    titulo.Position = pos
    titulo.BackgroundTransparency = 1
    titulo.Font = Enum.Font.GothamBold
    titulo.Text = texto
    titulo.TextSize = 13
    titulo.TextColor3 = Color3.fromRGB(100, 130, 255)
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.ZIndex = 102
    titulo.Parent = parent
    return titulo
end

local function criarSeparador(parent, pos)
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Position = pos
    sep.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    sep.BorderSizePixel = 0
    sep.ZIndex = 102
    sep.Parent = parent
    return sep
end

local function criarToggle(parent, pos, texto, estado, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.Position = pos
    frame.BackgroundTransparency = 1
    frame.ZIndex = 102
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = texto
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 103
    label.Parent = frame
    
    local toggleBack = Instance.new("Frame")
    toggleBack.Size = UDim2.new(0, 44, 0, 22)
    toggleBack.Position = UDim2.new(1, -50, 0.5, -11)
    toggleBack.BackgroundColor3 = estado and Color3.fromRGB(70, 200, 120) or Color3.fromRGB(200, 60, 60)
    toggleBack.ZIndex = 103
    toggleBack.Parent = frame
    addCantos(toggleBack, 11)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = UDim2.new(estado and 1 or 0, estado and -20 or 3, 0.5, -8)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.ZIndex = 104
    toggleCircle.Parent = toggleBack
    addCantos(toggleCircle, 8)
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 105
    button.Parent = frame
    
    local state = estado
    
    button.MouseButton1Click:Connect(function()
        state = not state
        toggleBack.BackgroundColor3 = state and Color3.fromRGB(70, 200, 120) or Color3.fromRGB(200, 60, 60)
        toggleCircle:TweenPosition(
            UDim2.new(state and 1 or 0, state and -20 or 3, 0.5, -8),
            Enum.EasingDirection.InOut,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        callback(state)
    end)
    
    return frame, function() return state end
end

local function criarSlider(parent, pos, texto, min, max, inicial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.Position = pos
    frame.BackgroundTransparency = 1
    frame.ZIndex = 102
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = texto .. ": " .. inicial
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 103
    label.Parent = frame
    
    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, 0, 0, 8)
    sliderBack.Position = UDim2.new(0, 0, 0.7, 0)
    sliderBack.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sliderBack.ZIndex = 103
    sliderBack.Parent = frame
    addCantos(sliderBack, 4)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((inicial - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(90, 130, 250)
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 104
    sliderFill.Parent = sliderBack
    addCantos(sliderFill, 4)
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new((inicial - min) / (max - min), -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.ZIndex = 105
    sliderKnob.Parent = sliderBack
    addCantos(sliderKnob, 8)
    
    local value = inicial
    
    local function updateSlider(newValue)
        value = math.clamp(newValue, min, max)
        if math.floor(value) == value then
            value = math.floor(value)
        else
            value = math.floor(value * 100) / 100
        end
        
        local percent = (value - min) / (max - min)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderKnob.Position = UDim2.new(percent, -8, 0.5, -8)
        label.Text = texto .. ": " .. value
        callback(value)
    end
    
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = game:GetService("UserInputService"):GetMouseLocation().X
            local framePos = sliderBack.AbsolutePosition.X
            local frameSize = sliderBack.AbsoluteSize.X
            local percent = math.clamp((mousePos - framePos) / frameSize, 0, 1)
            updateSlider(min + (max - min) * percent)
            
            local connection
            connection = game:GetService("RunService").RenderStepped:Connect(function()
                local mousePos = game:GetService("UserInputService"):GetMouseLocation().X
                local framePos = sliderBack.AbsolutePosition.X
                local frameSize = sliderBack.AbsoluteSize.X
                local percent = math.clamp((mousePos - framePos) / frameSize, 0, 1)
                updateSlider(min + (max - min) * percent)
            end)
            
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if connection then connection:Disconnect() end
                end
            end)
        end
    end)
    
    return frame, function() return value end
end

-- Adicionar controles à interface
criarTitulo(conteudo, UDim2.new(0, 0, 0, 5), "CONFIGURAÇÕES GERAIS")
criarSeparador(conteudo, UDim2.new(0, 0, 0, 30))

local toggleESP, getESPState = criarToggle(conteudo, UDim2.new(0, 0, 0, 40), "ESP Ativo", config.espAtivo, function(state)
    config.espAtivo = state
    if state then
        atualizarESP()
    else
        removerESP()
    end
end)

local toggleDist, getDistState = criarToggle(conteudo, UDim2.new(0, 0, 0, 80), "Mostrar Distância", config.mostrarDistancia, function(state)
    config.mostrarDistancia = state
    atualizarESP()
end)

local toggleBorda, getBordaState = criarToggle(conteudo, UDim2.new(0, 0, 0, 120), "Borda de Texto", config.borda, function(state)
    config.borda = state
    atualizarESP()
end)

criarTitulo(conteudo, UDim2.new(0, 0, 0, 165), "PERSONALIZAÇÃO")
criarSeparador(conteudo, UDim2.new(0, 0, 0, 190))

local sliderFonte, getFonteSize = criarSlider(conteudo, UDim2.new(0, 0, 0, 200), "Tamanho da Fonte", 10, 30, config.tamanhoFonte, function(val)
    config.tamanhoFonte = val
    atualizarESP()
end)

local sliderTransp, getTransp = criarSlider(conteudo, UDim2.new(0, 0, 0, 250), "Transparência do Texto", 0, 0.9, config.transparencia, function(val)
    config.transparencia = val
    atualizarESP()
end)

criarTitulo(conteudo, UDim2.new(0, 0, 0, 300), "DESEMPENHO")
criarSeparador(conteudo, UDim2.new(0, 0, 0, 325))

local sliderIntervalo = criarSlider(conteudo, UDim2.new(0, 0, 0, 335), "Intervalo (segundos)", 0.1, 2, config.intervaloAtualizacao, function(val)
    config.intervaloAtualizacao = val
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
                gui.Size = UDim2.new(0, 200, 0, config.mostrarDistancia and 70 or 50)
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

-- Tecla para abrir/fechar interface
local function toggleMenu()
    painel.Visible = not painel.Visible
end

-- Registrar tecla F1
local uisConnection
uisConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
        toggleMenu()
    end
end)

-- Loop de atualização otimizado
local lastUpdate = tick()
local updateConnection
spawn(function()
    updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local currentTime = tick()
        if config.espAtivo and (currentTime - lastUpdate) >= config.intervaloAtualizacao then
            atualizarESP()
            lastUpdate = currentTime
        end
    end)
end)

-- Inicializar ESP
atualizarESP()

-- Mostrar mensagem de inicialização
local notif = Instance.new("Frame")
notif.Size = UDim2.new(0, 280, 0, 80)
notif.Position = UDim2.new(0.5, -140, 0, -100)
notif.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
notif.BorderSizePixel = 0
notif.ZIndex = 200
notif.Parent = screenGui
addCantos(notif)
addBorda(notif, Color3.fromRGB(90, 90, 150), 1.5)

local notifText = Instance.new("TextLabel")
notifText.Size = UDim2.new(1, -20, 1, -20)
notifText.Position = UDim2.new(0, 10, 0, 10)
notifText.BackgroundTransparency = 1
notifText.Font = Enum.Font.GothamSemibold
notifText.Text = "ESP ativado com sucesso!\nPressione F1 para abrir o menu."
notifText.TextSize = 14
notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
notifText.ZIndex = 201
notifText.Parent = notif

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

-- Forçar menu visível após 1 segundo 
spawn(function()
    wait(4)
    painel.Visible = true
    print("Menu forçado a abrir!")
end)

-- Criar função global para abrir o menu
getgenv().abrirMenuESP = toggleMenu  -- Pode ser chamado do console

-- Imprimir mensagem de confirmação no console
print("ESP instalado com sucesso! Use F1 ou digite abrirMenuESP() no console para abrir o menu.") 