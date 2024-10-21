local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local Root = ReplicatedStorage["__DIRECTORY"].Upgrades.Root
local Library = ReplicatedStorage:WaitForChild("Library")
local Client = Library.Client
local network = ReplicatedStorage.Network
local LocalPlayer = game.Players.LocalPlayer
local usedInstantLuckPotion3Amount = 0
local hugeFound = false

local save = require(Client.Save)
local upgradeCmds = require(Client.UpgradeCmds)
local fruitCmds = require(Client.FruitCmds)

local orb = require(Client.OrbCmds.Orb)
local inventory = save.Get().Inventory
local maxFruitQueue = fruitCmds.ComputeFruitQueueLimit()

local localPlayerName = LocalPlayer.Name
local upgradeFruitTimeStart = tick()
local upgradeFruitDelay = 60

-- discord
local doNotResend = {}
local httpService = game:GetService("HttpService")
local botProfilePic = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeohpvtXa0yu6PeaFaw9-Pd6ryrJl3sdzlDg&s"
local cacheFileName = "sentContentCache.json"
local sentContentCache = isfile(cacheFileName) and httpService:JSONDecode(readfile(cacheFileName)) or {}

-- gui display
local bestDifficulty = 0
local bestDifficultyDisplay


orb.DefaultPickupDistance = 0  -- slowly comes to player, disable
orb.CollectDistance = 400  -- insane instant magnet
orb.BillboardDistance = 0  -- disables gui showing collected coins
orb.SoundDistance = 0
orb.CombineDelay = 0
orb.CombineDistance = 400


while not upgradeCmds.IsUnlocked(require(Root)) do
    task.wait(1)
    network["Eggs_Roll"]:InvokeServer()
    task.wait(1)
    network["Tutorial_ClickedUpgrades"]:FireServer()
    task.wait(1)
    network["Upgrades_Purchase"]:InvokeServer("Root")
end


local function len(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end


local function findRelics()
    for i=1, 50 do
        if not save.Get()["Relics"][tostring(i)] then
            require(Client.Network).Invoke("Relic_Found", i)
            task.wait()
            print(i)
        end
    end
    if len(save.Get()["Relics"]) < 39 then
        network["Travel to Trading Plaza"]:InvokeServer()
    end
end


local moreRelics = require(Root["Faster Egg Open"]["Faster Egg Open 2"]["Instant Egg Open"]["Golden Dice"]["Small Coin Piles"]["Large Coin Piles"]["More Breakables"]["Even More Breakables"].Relics["More Relics"])
if upgradeCmds.IsUnlocked(moreRelics) then
    findRelics()
    task.wait(3)
end
if workspace:FindFirstChild("TRADING") then
    while true do
        network["Travel to Main World"]:InvokeServer()
        task.wait(5)
    end
end

pcall(function()
    game:GetService("CoreGui"):ClearAllChildren()
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/whatsbasement/rb-opt/refs/heads/main/pet%20go%20opti.lua"))()
print("[Optimize Done!]")

workspace.OUTER:Destroy()
game:GetService("Lighting"):ClearAllChildren()
workspace[localPlayerName].HumanoidRootPart.Anchored = true

local platform = Instance.new("Part")
platform.Parent = workspace
platform.Anchored = true
platform.CFrame = workspace.MAP.SPAWNS.Spawn.CFrame + Vector3.new(0, -5.5, 0)
platform.Size = Vector3.new(500, 1, 500)
-- platform.Transparency = 1
workspace[localPlayerName].HumanoidRootPart.Anchored = false


require(Client.PlayerPet).CalculateSpeedMultiplier = function(...)
    return 500
end

require(Client.FriendCmds).HasOnlineFriends = function(...)
    return true
end

require(Client.FriendCmds).GetEffectiveFriendsOnline = function(...)
    return 110
end


pcall(function()
    game:GetService("CoreGui"):ClearAllChildren()
end)


local function findChest()
    for _, v in workspace["__THINGS"].Breakables:GetChildren() do
        if v:FindFirstChild("Top") then
            return tonumber(v.Name)
        end
    end
end


local function findNormal()
    local normal = {}
    for _, v in workspace["__THINGS"].Breakables:GetChildren() do
        if v:FindFirstChild("1") or v:FindFirstChild("2") or v:FindFirstChild("3") then
            table.insert(normal, tonumber(v.Name))
        end
    end
    return normal
end


local function findFruitCrate()
    for _, v in workspace["__THINGS"].Breakables:GetChildren() do
        if v:FindFirstChild("Apple") or v:FindFirstChild("Banana") or v:FindFirstChild("Pineapple") then
            return tonumber(v.Name)
        end
    end
end


local function petTargetChestAndBreakables()
    local chestNum = findChest()
    local fruitCrateNum
    local normalNum  -- table

    if not chestNum then
        fruitCrateNum = findFruitCrate()
    end
    if not chestNum or not fruitCrateNum then
        normal = findNormal()
    end
    
    local normalIndex = 0
    local args = {
        [1] = {}
    }
    for petId, _ in pairs(require(Client.PlayerPet).GetAll()) do
        normalIndex = normalIndex + 1
        if chestNum then 
            args[1][petId] = chestNum
        elseif fruitCrateNum then
            args[1][petId] = fruitCrateNum
        else
            pcall(function()
                args[1][petId] = normal[normalIndex]
            end)
        end
    end

    network["Breakables_JoinPetBulk"]:FireServer(unpack(args))
end


local function tapChestAndBreakables()
    local target = findChest()

    if not target then  -- target is assigned to chest first, if failed, assign fruit crate
        target = findFruitCrate()
    end
    if not target then  -- if fruit crate failed, then assign normal breakable
        for _, v in workspace["__THINGS"].Breakables:GetChildren() do
            if v:FindFirstChild("1") or v:FindFirstChild("2") or v:FindFirstChild("3") then
                target = tonumber(v.Name)
                break
            end
        end
    end

    for _, v in workspace["__THINGS"].Breakables:GetChildren() do
        if v:FindFirstChild("base") then
            target = tonumber(v.Name)
            break
        end
    end

    network["Breakables_PlayerDealDamage"]:FireServer(target)
end


local function traverseModules(module)
    for _, child in ipairs(module:GetChildren()) do
        if upgradeCmds.IsUnlocked(child.Name) then
            traverseModules(child)
        elseif upgradeCmds.CanAfford(child.Name) then
            -- if child.Name ~= "Trading Booths" and child.Name ~= "More Pet Details" and child.Name ~= "Hoverboard" and child.Name ~= "Faster Pets" then
            upgradeCmds.Unlock(child.Name)
            print("Bought affordable upgrade: " .. child.Name)
            -- end
        end
    end
end


local function checkAndConsumeFruits()
    for fruitId, tbl in pairs(inventory.Fruit) do
        if not tbl.sh and fruitCmds.GetActiveFruits()[tbl.id] ~= nil then
            local fruitConsumedAmount = #fruitCmds.GetActiveFruits()[tbl.id]["Normal"] 
            if (fruitConsumedAmount < maxFruitQueue) and (tbl._am ~= nil) then
                if tbl._am < fruitCmds.GetMaxConsume(fruitId) then
                    fruitCmds.Consume(fruitId, tonumber(tbl._am))
                    task.wait(0.5)
                else
                    fruitCmds.Consume(fruitId, maxFruitQueue - fruitConsumedAmount)
                    task.wait(0.5)
                end
            end
        else
            fruitCmds.Consume(fruitId)
            task.wait(0.5)
        end
    end
end


local function collectHiddenGift()
    for _, v in workspace["__THINGS"].HiddenGifts:GetChildren() do
        for _, v2 in v:GetChildren() do
            task.wait(0.5)
            workspace[localPlayerName].HumanoidRootPart.CFrame = v2.CFrame + Vector3.new(10, 0, 0)

            local character = game.Players.LocalPlayer.Character

            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                local targetPosition = v2.Position

                humanoid:MoveTo(targetPosition)
                task.wait(1)
            end
        end
    end
end


local function teleportToFlyingGift()
    for _, v in pairs(game:GetService("Workspace")["__THINGS"].FlyingGifts:GetChildren()) do
        for _, v2 in pairs(v:GetChildren()) do
            if v2.Name == "String" then
                game:GetService("Workspace")[localPlayerName].HumanoidRootPart.CFrame = v2.CFrame
                task.wait(1)
            end
        end
    end
end


local function teleportToDig()
    for _, v in workspace["__THINGS"].Digging:GetChildren() do
        task.wait(2)
        workspace[localPlayerName].HumanoidRootPart.CFrame = v.CFrame
    end
end


local function teleportToMachine(machineName)    
    -- print("Teleporting To", machineName)
    workspace[localPlayerName].HumanoidRootPart.CFrame = workspace.MAP.INTERACT.Machines[machineName].PadGlow.CFrame + Vector3.new(-20, -10, 0)
    task.wait(1)
end


local function consumeBestPotion()
    local potionNames = {"Faster Rolls Potion", "Breakables Potion", "Lucky Potion", "Items Potion", "Coins Potion"}
    
    for _, potionName in pairs(potionNames) do
        local highestPotionTier = 0
        local highestPotionTierId
        for potionId, tbl in pairs(require(game:GetService("ReplicatedStorage").Library.Client.Save).Get().Inventory.Consumable) do
            if potionName == tbl.id and tbl.tn > highestPotionTier then
                highestPotionTier = tbl.tn
                highestPotionTierId = potionId
            end
        end

        local potionDir = game:GetService("ReplicatedStorage")["__DIRECTORY"].Effects.Timed["Effect | " .. potionName]
        local bestConsumedPotionTier = require(game:GetService("ReplicatedStorage").Library.Client.EffectCmds).GetBest(require(potionDir))
        
        if bestConsumedPotionTier < highestPotionTier then
            print("Consumed " .. potionName .. " Tier " .. highestPotionTier)
            pcall(function() network["Consumables_Consume"]:InvokeServer(highestPotionTierId, 1) end)
            task.wait(1)
        end
    end
end



local function consumeInstantLuck3Combo(instantLuck3PotionId)
    local potionNames = {"Golden Dice Potion", "Blazing Dice Potion", "The Cocktail"}
    local potionsFound = {
        ["Golden Dice Potion"] = nil,
        ["Blazing Dice Potion"] = nil,
        ["The Cocktail"] = nil
    }

    -- Check for golden/blazing dice potion
    for _, potionName in pairs(potionNames) do
        for potionId, tbl in pairs(require(game:GetService("ReplicatedStorage").Library.Client.Save).Get().Inventory.Consumable) do
            if potionName == tbl.id then
                potionsFound[tbl.id] = potionId
            end
        end
    end

    -- if found both golden/blazing potion
    if potionsFound["Golden Dice Potion"] ~= nil and potionsFound["Blazing Dice Potion"] ~= nil then
        -- check if cocktail already used
        local cocktailDir = game:GetService("ReplicatedStorage")["__DIRECTORY"].Effects.Timed["Effect | The Cocktail"]
        if require(game:GetService("ReplicatedStorage").Library.Client.EffectCmds).GetBest(require(cocktailDir)) == 0 then
            if potionsFound["The Cocktail"] then
                pcall(function() network["Consumables_Consume"]:InvokeServer(potionsFound["The Cocktail"], 1) end)  -- consume cocktail 
                task.wait(1)
            else
                print("No cocktail found")
                return
            end
        end

        print(potionsFound["Golden Dice Potion"])
        pcall(function() network["Consumables_Consume"]:InvokeServer(potionsFound["Golden Dice Potion"], 1) end)  -- consume golden 
        task.wait(1)
        pcall(function() network["Consumables_Consume"]:InvokeServer(potionsFound["Blazing Dice Potion"], 1) end)  -- consume blazing
        task.wait(1)
        pcall(function() network["Consumables_Consume"]:InvokeServer(potionsFound["The Cocktail"], 1) end)  -- consume blazing
        task.wait(1)
        pcall(function() network["Consumables_Consume"]:InvokeServer(instantLuck3PotionId, 1) end)
        task.wait(1)
    end
end


local function smartPotionUpgrade()
    for itemId, tbl in pairs(save.Get().Inventory.Consumable) do
        task.wait()
        if tbl.id == "Lucky Potion" then
            if tbl.tn == 1 and tbl._am ~= nil and tbl._am >= 3 then
                -- print("Crafted Lucky Tier 2")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 1, math.floor(tbl._am / 3))
                task.wait(0.5)
    
            elseif tbl.tn == 2 and tbl._am ~= nil and tbl._am >= 4 then
                -- print("Crafted Lucky Tier 3")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 2, math.floor(tbl._am / 4))
                task.wait(0.5)
    
            elseif tbl.tn == 3 and tbl._am ~= nil and tbl._am >= 5 then
                local stopCraftingTier4Lucky
                local lucky4Amount = 0
                -- if more than 150 lucky 4, stop crafting
                -- else craft more lucky 4's until 150
                for _, tbl2 in pairs(save.Get().Inventory.Consumable) do
                    if tbl2.id == "Lucky Potion" and tbl2.tn == 4 and tbl2._am ~= nil then
                        if tbl2._am >= 150 then
                            stopCraftingTier4Lucky = true
                            -- print("stop crafting tier 4 lucky")
                            break
                        else
                            lucky4Amount = tbl2._am
                        end
                    end
                end

                if not stopCraftingTier4Lucky then
                    local amountToCraft
                    if math.floor(tbl._am / 5) >= (150 - lucky4Amount) then
                        -- craft straight to 150
                        amountToCraft = (150 - lucky4Amount)
                    else
                        -- craft however available
                        amountToCraft = math.floor(tbl._am / 5)
                    end
                    -- print("Crafted Lucky Tier 4")
                    network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 3, amountToCraft)
                    task.wait(0.5)
                end
    
            elseif tbl.tn == 4 and tbl._am ~= nil and tbl._am >= 5 then
                local stopCraftingTier5Lucky
                local lucky5Amount = 0
                for _, tbl2 in pairs(save.Get().Inventory.Consumable) do
                    if tbl2.id == "Lucky Potion" and tbl2.tn == 5 and tbl2._am ~= nil then
                        if tbl2._am >= 50 then
                            stopCraftingTier5Lucky = true
                            -- print("stop crafting tier 5 lucky")
                            break
                        else
                            lucky5Amount = tbl2._am
                        end
                    end
                end
                if not stopCraftingTier5Lucky then
                    local amountToCraft
                    if math.floor(tbl._am / 5) >= (50 - lucky5Amount) then
                        amountToCraft = (50 - lucky5Amount)
                    else 
                        amountToCraft = math.floor(tbl._am / 5)
                    end

                    for _, tbl2 in pairs(save.Get().Inventory.Fruit) do
                        if tbl2.id == "Orange" and not tbl2.sh and tbl2._am ~= nil and tbl2._am >= 12 then  -- check non shiny fruit
                            -- print("Crafted Lucky Tier 5")
                            if math.floor(tbl2._am / 12) < amountToCraft then amountToCraft = math.floor(tbl2._am / 12) end
                            network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 4, amountToCraft)
                            task.wait(0.5)
                            break
                        end
                    end
                end

            elseif tbl.tn == 5 and tbl._am ~= nil and tbl._am >= 5 then
                local stopCraftingTier6Lucky
                local lucky6Amount = 0
                for _, tbl2 in pairs(save.Get().Inventory.Consumable) do
                    if tbl2.id == "Lucky Potion" and tbl2.tn == 6 and tbl2._am ~= nil then
                        if tbl2._am >= 25 then  -- 25 is to craft 1x tier 7 lucky pot
                            stopCraftingTier6Lucky = true
                            -- print("stop crafting tier 6 lucky")
                            break
                        else
                            lucky6Amount = tbl2._am
                        end
                    end
                end
                if not stopCraftingTier6Lucky then
                    local amountToCraft
                    if math.floor(tbl._am / 5) >= (25 - lucky6Amount) then
                        amountToCraft = (25 - lucky6Amount)
                    else 
                        amountToCraft = math.floor(tbl._am / 5)
                    end

                    for _, tbl2 in pairs(save.Get().Inventory.Fruit) do
                        if tbl2.id == "Orange" and not tbl2.sh and tbl2._am ~= nil and tbl2._am >= 30 then  -- check non shiny fruit
                            -- print("Crafted Lucky Tier 6")
                            if math.floor(tbl2._am / 30) < amountToCraft then amountToCraft = math.floor(tbl2._am / 30) end
                            network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 5, amountToCraft)
                            task.wait(0.5)
                            break
                        end
                    end
                end

            elseif tbl.tn == 6 and tbl._am ~= nil and tbl._am >= 5 then
                local stopCraftingTier7Lucky
                local lucky7Amount = 0
                for _, tbl2 in pairs(save.Get().Inventory.Consumable) do
                    -- if best potion exists, stop crafting (only need 1)
                    if tbl2.id == "Lucky Potion" and tbl2.tn == 7 then  -- only for last/best potion
                        stopCraftingTier7Lucky = true
                        -- print("stop crafting tier 7 lucky")
                        break
                    end
                end
                if not stopCraftingTier7Lucky then
                    for _, tbl2 in pairs(save.Get().Inventory.Fruit) do
                        -- if enough orange and tier 6, craft 1 tier best potion
                        if tbl2.id == "Orange" and tbl2.sh and tbl2._am ~= nil and tbl2._am >= 5 then  -- checks for shiny orange
                            -- print("Crafted Lucky Tier 7")
                            network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 6, 1)
                            task.wait(0.5)
                            break
                        end
                    end
                end
            end
        end
    
    
        if tbl.id == "Coins Potion" then
            if tbl.tn == 1 and tbl._am ~= nil and tbl._am >= 3 then
                -- print("Crafted Coins Potion 2")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 7, math.floor(tbl._am / 3))
                task.wait(0.5)
    
            elseif tbl.tn == 2 and tbl._am ~= nil and tbl._am >= 4 then
                -- print("Crafted Coins Potion 3")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 8, math.floor(tbl._am / 4))
                task.wait(0.5)
    
            elseif tbl.tn == 3 and tbl._am ~= nil and tbl._am >= 5 then
                -- print("Crafted Coins Potion 4")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 9, math.floor(tbl._am / 5))
                task.wait(0.5)
    
            elseif tbl.tn == 4 and tbl._am ~= nil and tbl._am >= 5 then
                local amountToCraft = math.floor(tbl._am / 5)
                for _, tbl2 in pairs(save.Get().Inventory.Fruit) do
                    if tbl2.id == "Banana" and not tbl2.sh and tbl2._am ~= nil and tbl2._am >= 12 then
                        -- print("Crafted Coins Potion 5")
                        if math.floor(tbl2._am / 12) < amountToCraft then amountToCraft = math.floor(tbl2._am / 12) end
                        network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 10, amountToCraft)
                        task.wait(0.5)
                    end
                end
            
            elseif tbl.tn == 5 and tbl._am ~= nil and tbl._am >= 5 then
                local amountToCraft = math.floor(tbl._am / 5)
                for _, tbl2 in pairs(save.Get().Inventory.Fruit) do
                    if tbl2.id == "Banana" and not tbl2.sh and tbl2._am ~= nil and tbl2._am >= 30 then
                        -- print("Crafted Coins Potion 6")
                        if math.floor(tbl2._am / 30) < amountToCraft then amountToCraft = math.floor(tbl2._am / 30) end
                        network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 11, amountToCraft)
                        task.wait(0.5)
                    end
                end

            elseif tbl.tn == 6 and tbl._am ~= nil and tbl._am >= 5 then
                local amountToCraft = math.floor(tbl._am / 5)
                for _, tbl2 in pairs(save.Get().Inventory.Fruit) do
                    if tbl2.id == "Banana" and tbl2.sh and tbl2._am ~= nil and tbl2._am >= 5 then
                        -- print("Crafted Coins Potion 7")
                        if math.floor(tbl2._am / 5) < amountToCraft then amountToCraft = math.floor(tbl2._am / 5) end
                        network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 12, amountToCraft)
                        task.wait(0.5)
                    end
                end
            end
        end
    
    
        if tbl.id == "Breakables Potion" then
            if tbl.tn == 1 and tbl._am ~= nil and tbl._am >= 3 then
                -- print("Crafted Breakables Potion 2")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 14, math.floor(tbl._am / 3))
                task.wait(0.5)
            
            elseif tbl.tn == 2 and tbl._am ~= nil and tbl._am >= 5 then
                -- print("Crafted Breakables Potion 3")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 15, math.floor(tbl._am / 5))
                task.wait(0.5)
            end
        end


        if tbl.id == "Faster Rolls Potion" then
            if tbl.tn == 1 and tbl._am ~= nil and tbl._am >= 5 then
                local amountToCraft = math.floor(tbl._am / 5)
                for _, tbl2 in pairs(save.Get().Inventory.Fruit) do
                    if tbl2.id == "Watermelon" and not tbl2.sh and tbl2._am ~= nil and tbl2._am >= 30 then
                        -- print("Crafted Faster Rolls Potion 2")
                        if math.floor(tbl2._am / 30) < amountToCraft then amountToCraft = math.floor(tbl2._am / 30) end
                        network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 17, amountToCraft)
                        task.wait(0.5)
                        break
                    end
                end
            end
        end
    
    
        if tbl.id == "Items Potion" then
            if tbl.tn == 1 and tbl._am ~= nil and tbl._am >= 3 then
                -- print("Crafted Items Potion 2")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 19, math.floor(tbl._am / 3))
                task.wait(0.5)
    
            elseif tbl.tn == 2 and tbl._am ~= nil and tbl._am >= 4 then
                -- print("Crafted Items Potion 3")
                network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 20, math.floor(tbl._am / 4))
                task.wait(0.5)

            elseif tbl.tn == 3 and tbl._am ~= nil and tbl._am >= 5 then
                local amountToCraft = math.floor(tbl._am / 5)
                for _, tbl2 in pairs(save.Get().Inventory.Fruit) do
                    if tbl2.id == "Pineapple" and not tbl2.sh and tbl2._am ~= nil and tbl2._am >= 20 then
                        -- print("Crafted Items Potion 4")
                        if math.floor(tbl2._am / 20) < amountToCraft then amountToCraft = math.floor(tbl2._am / 20) end
                        network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 21, amountToCraft)
                        task.wait(0.5)
                        break
                    end
                end
            end
        end
    end
end


-- Get potion and fruit amounts from the player's inventory
local function getInventoryAmounts()
    local amounts = {
        instantLuck2Amount = 0,
        instantLuck1Amount = 0,
        rainbowDiceAmount = 0,
        goldenDiceAmount = 0,
        lucky5Amount = 0,
        lucky4Amount = 0,
        lucky3Amount = 0,
        rainbowFruitAmount = 0,
        orangeAmount = 0,
    }

    -- Get potions amount
    for itemId, tbl in pairs(save.Get().Inventory.Consumable) do
        if tbl.id == "Instant Luck Potion" and tbl.tn == 2 and tbl._am ~= nil then
            amounts.instantLuck2Amount = tbl._am
        elseif tbl.id == "Instant Luck Potion" and tbl.tn == 1 and tbl._am ~= nil then
            amounts.instantLuck1Amount = tbl._am
        elseif tbl.id == "Rainbow Dice Potion" and tbl._am ~= nil then
            amounts.rainbowDiceAmount = tbl._am
        elseif tbl.id == "Golden Dice Potion" and tbl._am ~= nil then
            amounts.goldenDiceAmount = tbl._am
        elseif tbl.id == "Lucky Potion" and tbl.tn == 5 and tbl._am ~= nil then
            amounts.lucky5Amount = tbl._am
        elseif tbl.id == "Lucky Potion" and tbl.tn == 4 and tbl._am ~= nil then
            amounts.lucky4Amount = tbl._am
        elseif tbl.id == "Lucky Potion" and tbl.tn == 3 and tbl._am ~= nil then
            amounts.lucky3Amount = tbl._am
        end
    end

    -- Get orange and rainbow fruit amount
    for itemId, tbl in pairs(save.Get().Inventory.Fruit) do
        if tbl.id == "Orange" and tbl._am ~= nil then
            amounts.orangeAmount = tbl._am
        elseif tbl.id == "Rainbow" and tbl._am ~= nil then
            amounts.rainbowFruitAmount = tbl._am
        end
    end

    return amounts
end

-- Function to craft potions using server invokes
local function craft(potion)
    local amounts = getInventoryAmounts()

    if potion == "instantLuck3" then
        if amounts.instantLuck2Amount >= 3 and amounts.rainbowDiceAmount >= 2 then
            amounts.instantLuck2Amount = amounts.instantLuck2Amount - 3
            amounts.rainbowDiceAmount = amounts.rainbowDiceAmount - 2
            print('making')
            network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 30, 1)
            task.wait(0.5)
            print("Crafted: Instant Luck 3")
        else
            while amounts.instantLuck2Amount < 3 or amounts.rainbowDiceAmount < 2 do
                task.wait() -- Default wait before trying again
                amounts = getInventoryAmounts()  -- Re-check inventory
                if amounts.instantLuck2Amount < 3 then
                    craft("instantLuck2")
                end
                if amounts.rainbowDiceAmount < 2 then
                    craft("rainbowDice")
                end
            end
            amounts.instantLuck2Amount = amounts.instantLuck2Amount - 3
            amounts.rainbowDiceAmount = amounts.rainbowDiceAmount - 2
            network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 30, 1)
            task.wait(0.5)
            print("Crafted: Instant Luck 3")
        end
    elseif potion == "instantLuck2" then
        if amounts.instantLuck1Amount < 3 then
            error("Not enough Instant Luck 1 potions to craft Instant Luck 2, quitting process.")
        else
            while amounts.rainbowDiceAmount < 2 do
                task.wait() -- Default wait before trying again
                amounts = getInventoryAmounts()  -- Re-check inventory
                if amounts.rainbowDiceAmount < 2 then
                    craft("rainbowDice")
                end
            end
            amounts.instantLuck1Amount = amounts.instantLuck1Amount - 3
            amounts.rainbowDiceAmount = amounts.rainbowDiceAmount - 2
            network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 29, 1)
            task.wait(0.5)
            print("Crafted: Instant Luck 2")
        end
    elseif potion == "rainbowDice" then
        if amounts.lucky4Amount >= 2 and amounts.rainbowFruitAmount >= 4 then
            amounts.lucky4Amount = amounts.lucky4Amount - 2
            amounts.rainbowFruitAmount = amounts.rainbowFruitAmount - 4
            network["CraftingMachine_Craft"]:InvokeServer("PotionCraftingMachine", 26, 1)
            task.wait(0.5)
            print("Crafted: Rainbow Dice")
        else
            error("Not enough materials to craft Rainbow Dice, quitting process.")
        end
    end
end


local function upgradeFruits()
    teleportToMachine("UpgradeFruitsMachine")
    local rainbowFruitAmount
    for _, tbl in pairs(save.Get().Inventory.Fruit) do
        if not tbl.sh and tbl.id == "Rainbow" then
            rainbowFruitAmount = tbl._am
            break
        end
    end
    
    for fruitId, tbl in pairs(save.Get().Inventory.Fruit) do
        -- make up to 2000 rainbow fruits
        if tbl._am ~= nil and tbl._am >= 425 and rainbowFruitAmount < 2000 then  -- keep 400, use 25 to make rainbow fruit
            local amountToCraft = (2000 - rainbowFruitAmount) * 25
            if amountToCraft > (tbl._am - 400) then
                amountToCraft = tbl._am - 400
            end
            local args = {
                [1] = {
                    [fruitId] = amountToCraft
                },
                [2] = false
            }
            rainbowFruitAmount = rainbowFruitAmount + (amountToCraft / 25)
            network["UpgradeFruitsMachine_Activate"]:InvokeServer(unpack(args))
            task.wait(2)
        end
    end
    
    -- REMEMBER TO ADD, ONLY MAKE SHINY FRUIT IF UNLOCK 18 SHINY
    local shinyFruitsAmount = {}
    for _, tbl in pairs(save.Get().Inventory.Fruit) do
        if tbl.sh then
            shinyFruitsAmount[tbl.id] = tbl._am or 0
        end
    end
    
    for fruitId, tbl in pairs(save.Get().Inventory.Fruit) do
        -- make up to 100 shiny fruits
        for fruitName, fruitAmount in pairs(shinyFruitsAmount) do
            if fruitName == tbl.id and not tbl.sh and tbl._am ~= nil and tbl._am >= 450 and fruitAmount < 50 then  -- keep 432 cuz 450-18
                local amountToCraft = (50 - fruitAmount) * 18
                if amountToCraft > (tbl._am - 400) then
                    amountToCraft = tbl._am - 400
                end
                local args = {
                    [1] = {
                        [fruitId] = amountToCraft
                    },
                    [2] = true
                }
                network["UpgradeFruitsMachine_Activate"]:InvokeServer(unpack(args))
                task.wait(2)
            end
        end
    end    
end


local function saveCache() writefile(cacheFileName, httpService:JSONEncode(sentContentCache)) end
local function isContentSent(content) return table.find(sentContentCache, content) end

local function sendWebhook(content)
    if isContentSent(content) then return end
    table.insert(sentContentCache, content)
    if #sentContentCache > 10 then table.remove(sentContentCache, 1) end
    saveCache()

    local messageContent = {
        ["content"] = "<@" .. getgenv().petsGoConfig.DISCORD_ID .. ">\n```" .. content .. "\nAccount Name: " .. localPlayerName .. "```",
        ["username"] = "What's Bot",
        ["avatar_url"] = botProfilePic
    }
    
    local jsonData = httpService:JSONEncode(messageContent)
    local requestFunction = syn and syn.request or request or http_request or http and http.request
    if requestFunction then
        pcall(function()
            requestFunction({
                Url = getgenv().petsGoConfig.WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = jsonData
            })
        end)
    end
end


local function mailPet()
    for petId, tbl in require(game:GetService("ReplicatedStorage").Library.Client.Save).Get().Inventory.Pet do
        local petDifficulty = require(game.ReplicatedStorage.Library.Directory.Pets)[tbl.id].difficulty
        if petDifficulty >= getgenv().petsGoConfig.MAIL_PET_ODDS then
            -- unlock pet before sending
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Locking_SetLocked"):InvokeServer(petId, false)
            task.wait(2)
            local args = {
                [1] = getgenv().petsGoConfig.USERNAME_TO_MAIL,
                [2] = tbl.id .. " for you",
                [3] = "Pet",
                [4] = petId,
                [5] = 1
            }
            
            print("Sent " .. tbl.id)
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Mailbox: Send"):InvokeServer(unpack(args))
            task.wait(5)
            break
        end
    end
end


-- buy advanced merchant potions
require(Client.Network).Fired("Merchant_Updated"):Connect(function(...)
    local args = {...}
    local indexTokenAmount = 0

    for itemId, tbl in pairs(save.Get().Inventory.Misc) do
        if tbl.id == "Index Token" and tbl._am ~= nil then
            indexTokenAmount = tbl._am
        end
    end    

    print("Offers for AdvancedIndexMerchant:")
    for offerIndex, offer in pairs(args[1]["AdvancedIndexMerchant"].Offers) do
        local itemId = offer.ItemData.data.id
        local tier = offer.ItemData.data.tn
        local stock = offer.Stock
        local priceId = offer.PriceData.data.id
        local cost = offer.PriceData.data._am

        if itemId == "The Cocktail" or itemId == "Instant Luck Potion" or itemId == "Rainbow Dice Potion" then
            if indexTokenAmount >= (cost * stock) then
                for i=1, stock do
                    network["Merchant_RequestPurchase"]:InvokeServer("AdvancedIndexMerchant", tonumber(offerIndex))
                    task.wait(1)
                    print("Bought:", itemId .. ", Item Number:", offerIndex)
                end
            else
                -- check if always not enough index or too much index tokens. then adjust script
                print("Can't Afford Index Item")
            end
        end
        
        -- pcall(print, string.format("Offer %d: Item: %s, Tier: %d, Stock: %d, Price ID: %s, Cost: %s", offerIndex, itemId, tier, stock, priceId, cost))
    end
end)


local breakables = require(Root["Faster Egg Open"]["Faster Egg Open 2"]["Instant Egg Open"]["Golden Dice"]["Small Coin Piles"])
task.spawn(function()
    while true do
        task.wait()
        pcall(petTargetChestAndBreakables)
        pcall(tapChestAndBreakables)

        local rainbowCountdown = save.Get().DiceCombos["Rainbow"]
        if rainbowCountdown ~= 79 then
            network.Eggs_Roll:InvokeServer()
            
        elseif rainbowCountdown == 79 then
            print("Rainbow READY")
            task.wait(1)
            local instantLuck3PotionFound
            for itemId, tbl in pairs(save.Get().Inventory.Consumable) do
                if tbl.id == "Instant Luck Potion" and tbl.tn == 3 then
                    instantLuck3PotionFound = true
                    pcall(consumeBestPotion)  -- use every best potion before luck 3
                    consumeInstantLuck3Combo(itemId)
                    network.Eggs_Roll:InvokeServer()
                    break
                end
            end
            if not instantLuck3PotionFound then  -- this is required due to it being stuck at rainbowCountdown
                print("No Instant Luck 3 Potions Detected")
                for itemId, tbl in pairs(save.Get().Inventory.Consumable) do
                    if tbl.id == "Golden Dice Potion" then
                        print("consumed golden dice potion")
                        pcall(function() network["Consumables_Consume"]:InvokeServer(itemId, 1) end)
                        task.wait(1)
                        break
                    end
                end
                network.Eggs_Roll:InvokeServer()
            end
        end
    end
end)


local advancedIndexShop = require(Root["Faster Egg Open"]["Faster Egg Open 2"].Inventory.Trading["Pet Index"]["Index Shop"]["Advanced Index Shop"])
local coinPresents = require(Root["Faster Egg Open"]["Faster Egg Open 2"]["Instant Egg Open"]["Golden Dice"]["Small Coin Piles"]["Large Coin Piles"]["Coin Crates"]["Coin Presents"])
local petDigCoins = require(Root["Faster Egg Open"]["Faster Egg Open 2"]["Instant Egg Open"]["Auto Roll"].Luckier["Even Luckier"]["Egg 2"]["Egg 3"]["Pet Dig Coins"])
local potionVending = require(Root["Faster Egg Open"]["Faster Egg Open 2"].Inventory.Fruit["Lucky Potion"]["Potion Vending"])
local potionWizard = require(Root["Faster Egg Open"]["Faster Egg Open 2"].Inventory.Fruit["Lucky Potion"]["Lucky Potion Tier 2"]["Potion Crafting"]["Crafting More Potion Recipes"]["Potion Wizard"])
local fruitMachine = require(Root["Faster Egg Open"]["Faster Egg Open 2"].Inventory.Fruit["More Fruit"]["Finding Fruit"]["Rainbow Fruit"]["Fruit Machine"])
local merchantUpgrade = require(Root["Faster Egg Open"]["Faster Egg Open 2"].Inventory.Fruit["Lucky Potion"]["Coins Potion"]["Coins Potion Tier 2"]["Coins Potion Tier 3"].Merchant)
local fruitBoost = require(Root["Faster Egg Open"]["Faster Egg Open 2"].Inventory.Fruit)
local potionsUpgrade = require(Root["Faster Egg Open"]["Faster Egg Open 2"].Inventory.Fruit["Lucky Potion"])

local mailPetDelayStart = tick()
local mailPetDelay = 60

local antiAfkDelayStart = tick()
local antiAfkDelay = 60
local webhookSendDelayStart = tick()
local webhookSendDelay = 60
game:GetService'StarterGui':SetCore("DevConsoleVisible", true)

-- collect forever pack free
network["ForeverPacks: Claim Free"]:InvokeServer("Default")
-- background stuff
task.spawn(function()
    while true do
        task.wait()
        traverseModules(Root)
        
        pcall(checkAndConsumeFruits)

        pcall(consumeBestPotion)
        
        if (tick() - antiAfkDelayStart) >= antiAfkDelay then
            network["Idle Tracking: Stop Timer"]:FireServer()
            antiAfkDelayStart = tick()
        end

        
        if (tick() - webhookSendDelayStart) >= webhookSendDelay then
            for petId, tbl in save.Get().Inventory.Pet do
                local sentBefore = false
                for _, petName in pairs(doNotResend) do
                    if tbl.id == petName then
                        sentBefore = true
                        break
                    end
                end
                
                if not sentBefore then
                    local petDifficulty = require(Library.Directory.Pets)[tbl.id].difficulty
                    if petDifficulty >= getgenv().petsGoConfig.WEBHOOK_ODDS then
                        if petDifficulty >= 1000000000 then
                            hugeFound = true
                        end
                        table.insert(doNotResend, tbl.id)
                        local quantity = tbl._am or 1
                        sendWebhook("Pet Found: " .. tbl.id .. "\nQuantity: " .. quantity)
                    end
                end
            end
            webhookSendDelayStart = tick()
        end

        if getgenv().petsGoConfig.MAIL_PET and (tick() - mailPetDelayStart) >= mailPetDelay then
            mailPet()
            mailPetDelayStart = tick()
        end

        if require(ReplicatedStorage.Library.Client.LoginStreakCmds).CanClaim() then
            network["Login Streaks: Bonus Roll Request"]:InvokeServer()
        end

        if require(ReplicatedStorage.Library.Client.BonusRollCmds).HasAvailable() then
            network["Bonus Rolls: Claim"]:InvokeServer()
            task.wait(1)
        end

        if require(Client.HoverboardCmds).IsEquipped() then
            print("wtf")
            game.ReplicatedStorage.Network.Hoverboard_RequestUnequip:FireServer()
        end

        pcall(collectHiddenGift)

        pcall(teleportToFlyingGift)

        pcall(teleportToDig)

        if upgradeCmds.IsUnlocked(potionVending) and save.Get()["VendingStocks"].PotionVendingMachine > 0 then
            teleportToMachine("PotionVendingMachine")
            for i=1, save.Get()["VendingStocks"].PotionVendingMachine do
                network["VendingMachines_Purchase"]:InvokeServer("PotionVendingMachine")
                task.wait(0.5)
            end
        end

        if upgradeCmds.IsUnlocked(fruitMachine) and (tick() - upgradeFruitTimeStart) >= upgradeFruitDelay then
            upgradeFruitTimeStart = tick()
            pcall(upgradeFruits)
        end

        if upgradeCmds.IsUnlocked(merchantUpgrade) then
            if len(save.Get().CustomMerchantPurchases.StandardMerchant.Purchased) < 6 then
                teleportToMachine("StandardMerchant")
                for i=1, 6 do
                    for _=1, 5 do
                        network["CustomMerchants_Purchase"]:InvokeServer("StandardMerchant", i)
                        task.wait(0.5)
                    end
                end
            end
        end

        if upgradeCmds.IsUnlocked(potionWizard) then
            local potionCraftingMagnitude = (workspace[localPlayerName].HumanoidRootPart.Position - workspace.MAP.INTERACT.Machines.PotionCraftingMachine.PadGlow.Position).Magnitude
            if potionCraftingMagnitude > 30 then
                task.wait(1)
                teleportToMachine("PotionCraftingMachine")
            end
            pcall(craft, "instantLuck3")
            pcall(smartPotionUpgrade)
        end
    end
end)


-- ===============================================  GUI  ===============================================
local function activateGui()
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.IgnoreGuiInset = true -- Allows GUI to cover the screen

    -- Create a black Frame to cover the whole screen
    local overlayFrame = Instance.new("Frame", gui)
    overlayFrame.Size = UDim2.new(1, 0, 1, 0) -- Full width and height
    overlayFrame.Position = UDim2.new(0, 0, 0, 0) -- Top left corner
    overlayFrame.BackgroundColor3 = Color3.new(0, 0, 0) -- Black background

    -- Create a TextLabel for the toggle message
    local toggleLabel = Instance.new("TextLabel", overlayFrame)
    toggleLabel.Size = UDim2.new(0, 300, 0, 30) -- Width: 300px, Height: 30px
    toggleLabel.Position = UDim2.new(0.5, -150, 0, 10) -- Centered horizontally, positioned at the top
    toggleLabel.Text = 'Press "O" to toggle overlay'
    toggleLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    toggleLabel.BackgroundTransparency = 1 -- Make label background transparent
    toggleLabel.TextScaled = true
    toggleLabel.TextSize = 14 -- Set a smaller text size for one line

    -- Create a TextLabel for the player's username
    local usernameLabel = Instance.new("TextLabel", overlayFrame)
    usernameLabel.Size = UDim2.new(0, 600, 0, 70) -- Width: 600px, Height: 70px
    usernameLabel.Position = UDim2.new(0.5, -300, 0.5, -155) -- Positioned above BEST PET
    usernameLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    usernameLabel.BackgroundTransparency = 1 -- Make label background transparent
    usernameLabel.TextScaled = true
    usernameLabel.TextSize = 36 -- Set a larger text size

    -- Create a TextLabel for the best difficulty message
    local bestPetLabel = Instance.new("TextLabel", overlayFrame)
    bestPetLabel.Size = UDim2.new(0, 600, 0, 70) -- Width: 600px, Height: 70px
    bestPetLabel.Position = UDim2.new(0.5, -300, 0.5, -85) -- Adjusted to align properly
    bestPetLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    bestPetLabel.BackgroundTransparency = 1 -- Make label background transparent
    bestPetLabel.TextScaled = true
    bestPetLabel.TextSize = 36 -- Set a larger text size

    -- Create a TextLabel for Current Rolls
    local currentRollsLabel = Instance.new("TextLabel", overlayFrame)
    currentRollsLabel.Size = UDim2.new(0, 600, 0, 70) -- Width: 600px, Height: 70px
    currentRollsLabel.Position = UDim2.new(0.5, -300, 0.5, -15) -- Positioned below BEST PET
    currentRollsLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    currentRollsLabel.BackgroundTransparency = 1 -- Make label background transparent
    currentRollsLabel.TextScaled = true
    currentRollsLabel.TextSize = 36 -- Same text size as BEST PET

    -- Create a TextLabel for Total Rolls
    local totalRollsLabel = Instance.new("TextLabel", overlayFrame)
    totalRollsLabel.Size = UDim2.new(0, 600, 0, 70) -- Width: 600px, Height: 70px
    totalRollsLabel.Position = UDim2.new(0.5, -300, 0.5, 55) -- Positioned below Current Rolls
    totalRollsLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    totalRollsLabel.BackgroundTransparency = 1 -- Make label background transparent
    totalRollsLabel.TextScaled = true
    totalRollsLabel.TextSize = 36 -- Same text size as BEST PET

    -- Create a TextLabel for Current Inventory
    local inventoryLabel = Instance.new("TextLabel", overlayFrame)
    inventoryLabel.Size = UDim2.new(0, 600, 0, 70) -- Width: 600px, Height: 70px
    inventoryLabel.Position = UDim2.new(0.5, -300, 0.5, 125) -- Positioned below Total Rolls
    inventoryLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    inventoryLabel.BackgroundTransparency = 1 -- Make label background transparent
    inventoryLabel.TextScaled = true
    inventoryLabel.TextSize = 36 -- Same text size as BEST PET

    -- Create a TextLabel for Instant 3 potion usage
    local instantLuckLabel = Instance.new("TextLabel", overlayFrame)
    instantLuckLabel.Size = UDim2.new(0, 600, 0, 70) -- Width: 600px, Height: 70px
    instantLuckLabel.Position = UDim2.new(0.5, -300, 0.5, 195) -- Positioned below Current Inventory
    instantLuckLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
    instantLuckLabel.BackgroundTransparency = 1 -- Make label background transparent
    instantLuckLabel.TextScaled = true
    instantLuckLabel.TextSize = 36 -- Same text size as other labels

    local RunService = game:GetService("RunService")

    -- Set initial state to visible
    local overlayVisible = true

    -- Function to toggle 3D rendering
    local function toggleRendering(state)
        pcall(function()
            RunService:Set3dRenderingEnabled(state)
        end)
    end

    -- Set initial rendering state
    toggleRendering(false) -- Set 3D rendering to false when GUI is activated

    -- Function to toggle overlay visibility
    local function toggleOverlay()
        overlayVisible = not overlayVisible -- Toggle visibility
        gui.Enabled = overlayVisible -- Show or hide the overlay
        
        -- Toggle 3D rendering based on overlay visibility
        if overlayVisible then
            toggleRendering(false) -- Set 3D rendering to false when overlay is active
        else
            toggleRendering(true) -- Set 3D rendering to true when overlay is inactive
        end
    end

    -- Detect key press for "O"
    local userInputService = game:GetService("UserInputService")
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.O and not gameProcessed then
            toggleOverlay()
        end
    end)

    -- Variables for best difficulty
    local bestDifficulty = 0
    local bestDifficultyDisplay = ""

    local startTotalRolls = save.Get().TotalRolls
    local startInventoryNotifications = save.Get().InventoryNotifications

    -- Function to get the best difficulty pet and update the display
    local function getBestDifficultyPet()
        -- Get best pet to display in GUI
        for petId, tbl in require(Client.PlayerPet).GetAll() do
            local petDifficulty = require(Library.Directory.Pets)[tbl.item._data.id].difficulty
            if petDifficulty > bestDifficulty then
                bestDifficulty = petDifficulty

                if petDifficulty >= 1000000 then
                    bestDifficultyDisplay = "BEST PET: " .. math.floor(petDifficulty / 1000000) .. "M" 
                elseif petDifficulty >= 100000 then
                    bestDifficultyDisplay = "BEST PET: " .. math.floor(petDifficulty / 100000) .. "K" 
                else
                    bestDifficultyDisplay = "BEST PET: " .. petDifficulty
                end
            end
        end

        -- Update the GUI label
        bestPetLabel.Text = bestDifficultyDisplay
    end

    -- Update the GUI periodically
    while true do
        local currentTotalRolls = save.Get().TotalRolls
        local currentRolls = currentTotalRolls - startTotalRolls
        local currentInventoryNotification = save.Get().InventoryNotifications - startInventoryNotifications

        -- Check if a huge pet is found
        if hugeFound then
            overlayFrame.BackgroundColor3 = Color3.new(0, 1, 0) -- Change to green if huge pet is found
        end

        -- Updating the Username label
        usernameLabel.Text = "Username: " .. localPlayerName

        currentRollsLabel.Text = "Current Rolls: (+" .. currentRolls .. ")"
        totalRollsLabel.Text = "Total Rolls: " .. currentTotalRolls
        inventoryLabel.Text = "Current Inventory: (+" .. currentInventoryNotification .. ")"

        -- Adding the Instant Luck Potion 3 amount
        instantLuckLabel.Text = "Instant 3: " .. usedInstantLuckPotion3Amount

        getBestDifficultyPet()
        wait(1) -- Update every second (you can adjust the wait time)
    end
end

activateGui()

-- ===============================================  GUI  ===============================================


