local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local Library = ReplicatedStorage:WaitForChild("Library")
local Client = Library.Client
local network = ReplicatedStorage.Network
local LocalPlayer = game.Players.LocalPlayer
local localPlayerName = LocalPlayer.Name


local function fullOptimizer()
    -- turn off settings
    -- Delete/Disable scripts
    for _, v in pairs(game:GetService("Players")[localPlayerName].PlayerGui:GetChildren()) do
        v:Destroy()
    end

    local settingsCmds = require(Client.SettingsCmds)

    network["Slider Setting"]:InvokeServer("SFX", 0)
    network["Slider Setting"]:InvokeServer("Music", 0)

    local toggleSettings = {
        "Notifications",
        "ItemNotifications",
        "GlobalHatchMessages",
        "ServerHatchMessages",
        "GlobalNameDisplay",
        "FireworkShow",
        "ShowOtherPets",
        "PetSFX",
        "PetAuras",
        "Vibrations"
    }

    for _, settingNames in pairs(toggleSettings) do
        if settingsCmds.Get(settingNames) == "Off" then
            -- turn off and on for it to work
            network["Toggle Setting"]:InvokeServer(settingNames)
            task.wait(1)
            network["Toggle Setting"]:InvokeServer(settingNames)
        else
            network["Toggle Setting"]:InvokeServer(settingNames)
        end
    end

    for _, v in workspace.MAP:GetChildren() do
        if v.Name ~= "SPAWNS" and v.Name ~= "INTERACT" then
            v:Destroy()
        end
    end

    -- disable annoying xp balls
    Client.XPBallCmds:Destroy()
    network.XPBalls_BulkCreate:Destroy()
    Library.Types.XPBalls:Destroy()


    for i, v in getconnections(game:GetService("Players").LocalPlayer.Idled) do v:Disable() end

    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), game:GetService("Workspace").CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), game:GetService("Workspace").CurrentCamera.CFrame)
    end)
    print("[Anti-AFK Activated!]")


    local function clearTextures(v)
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = "Plastic"
            v.Reflectance = 0
            v.Transparency = 1
        elseif v:IsA("MeshPart") and tostring(v.Parent) == "Orbs" then
            v.Transparency = 1
        elseif (v:IsA("Decal") or v:IsA("Texture")) then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("MeshPart") then
            v.Material = "Plastic"
            v.Reflectance = 0
            v.TextureID = 10385902758728957
            v.Transparency = 1
        elseif v:IsA("SpecialMesh") then
            v.TextureId = 0
        elseif v:IsA("ShirtGraphic") then
            v.Graphic = 1
        elseif (v:IsA("Shirt") or v:IsA("Pants")) then
            v[v.ClassName .. "Template"] = 1
        elseif v.Name == "PetBillboard" then
            v.Enabled = false
        end
    end

    -- for _, v in pairs(game:GetDescendants()) do
    --     clearTextures(v)
    -- end
    
    -- leave Breakables Frontend, Flying Gifts, Hidden Gifts and Relics
    game:GetService("Players")[localPlayerName].PlayerScripts.RbxCharacterSounds:Destroy()
    task.wait(0.5)
    game:GetService("Players")[localPlayerName].PlayerScripts.PlayerModule:Destroy()
    
    for _, v in pairs(game:GetService("Players")[localPlayerName].PlayerScripts:GetChildren()) do  -- avoid Scripts
        if v.Name ~= "Scripts" then
            v:Destroy()
        end
    end
    
    for _, v in pairs(game:GetService("Players")[localPlayerName].PlayerScripts.Scripts:GetChildren()) do
        if v.Name ~= "Game" then
            v:Destroy()
        end
    end

    for _, v in pairs(game:GetService("Players")[localPlayerName].PlayerScripts.Scripts.Game:GetChildren()) do
        if v.Name ~= "Breakables Frontend" and v.Name ~= "Flying Gifts" and v.Name ~= "Hidden Gifts" and v.Name ~= "Relics" and v.Name ~= "Hoverboards" then
            v:Destroy()
        end
    end
    

    -- make player invis
    for _, v in pairs(game.Players:GetChildren()) do
        for _, v2 in pairs(v.Character:GetDescendants()) do
            if v2:IsA("BasePart") or v2:IsA("Decal") then
                v2.Transparency = 1
            end
        end
    end

    -- make pets letter invis
    for _, v in pairs(workspace.__THINGS.Pets:GetDescendants()) do
        if v.Name == "PetBillboard" then
            v.Enabled = false
        end
    end

    for _, v in pairs(workspace.MAP.INTERACT:GetChildren()) do
        if v.Name ~= "Machines" and v.Name ~= "Items" then
            v:Destroy()
        end
    end

    hookfunction(getsenv(LocalPlayer.PlayerScripts.Scripts.Game["Breakables Frontend"]).updateBreakable, function()
        return
    end)

    hookfunction(require(Client.WorldFX).RewardBillboard, function()
        return
    end)

    hookfunction(require(Client.OrbCmds.Orb).RenderParticles, function()
        return
    end)

    hookfunction(require(Client.OrbCmds.Orb).SimulatePhysics, function()
        return
    end)

    hookfunction(require(Client.GUIFX.Confetti).Play, function()
        return
    end)

    for _, v in pairs(ReplicatedStorage.Assets:GetChildren()) do
        if v.Name ~= "Cutscenes" and v.Name ~= "Particles" and v.Name ~= "UI" and v.Name ~= "Models" then
            v:Destroy()
        end    
    end

    local worldFXList = {"Confetti", "RewardImage", "QuestGlow", "Damage", "SpinningChests", "RewardItem", "Sparkles", "AnimatePad", "PlayerTeleport", "AnimateChest", "Poof",
    "SmallPuff", "Flash", "Arrow3D", "ArrowPointer3D", "RainbowGlow"}

    for x, y in pairs(worldFXList) do
        hookfunction(require(Client.WorldFX[y]), function()
            return
        end)
    end

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") or v:IsA("BasePart") then
            v.Transparency = 1
        end
    end


    -- workspace.DescendantAdded:Connect(function(v)
    --     clearTextures(v)
    -- end)


    -- Lower FOV and Set Camera to First-Person
    game.Workspace.CurrentCamera.FieldOfView = 1
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson

    -- Disable Particle Effects
    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") then
            v.Enabled = false
        end
    end

    -- Disable Shadows
    game.Lighting.GlobalShadows = false

    -- Lower Lighting Quality
    game.Lighting.Brightness = 0
    game.Lighting.OutdoorAmbient = Color3.new(0, 0, 0) -- Set to black for minimal lighting
    game.Lighting.TimeOfDay = "14:00:00" -- Keep it in daytime for simpler lighting

    -- Disable Textures
    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v:IsA("Texture") or v:IsA("Decal") then
            v:Destroy() -- or set Texture to nil
        end
    end

    -- Disconnect Unnecessary Events
    local connections = getconnections or get_signal_cons
    for _, connection in pairs(connections(game:GetService("RunService").RenderStepped)) do
        connection:Disable()
    end

    local function setAllLightsToNoLight()
        for _, v in ipairs(game:GetDescendants()) do
            -- Check if the object is a light
            if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                -- Set the light to NoLight by setting its brightness to 0
                v.Brightness = 0
                v.Enabled = false
            end
        end
    end

    setAllLightsToNoLight()
end


fullOptimizer()
