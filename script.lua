-- // ServerScriptDownloader
-- // by croak14_ and inferiousmalder

local freemodels = {}
for _, v in pairs(game:GetDescendants()) do
    local b = gethiddenproperty(v, "SourceAssetId")
    if b ~= -1 then
        freemodels[#freemodels + 1] = b
    end
end
print("models to take care of: " .. #freemodels)

local function try(func, waittime, retries)
    retries = (retries or 0) + 1
    if retries == 6 then return {} end
    local succ, attempt = pcall(func)
    if not succ then
        task.wait(waittime or 2)
        return try(func, waittime, retries)
    end
    return attempt or {}
end

local placeFolder = "serverscripts/"
local folderName = placeFolder .. tostring(game.PlaceId)
if not isfolder(placeFolder) then makefolder(placeFolder) end
if not isfolder(folderName) then makefolder(folderName) end

local function getdescendants(model)
    if typeof(model) == "Instance" then return model:GetDescendants() end
    if type(model) ~= "table" then return nil end
    local result = {}
    for _, inst in pairs(model) do
        if typeof(inst) == "Instance" then
            result[#result + 1] = inst
            for _, desc in pairs(inst:GetDescendants()) do
                result[#result + 1] = desc
            end
        end
    end
    return result
end

local didmodel = {}
local counter = 0

for i, v in pairs(freemodels) do
    local vs = tostring(v)
    if tonumber(v) > 100 and not didmodel[vs] then
        didmodel[vs] = true
        task.spawn(function()
            local model = try(function() return game.InsertService:LoadLocalAsset("rbxassetid://" .. vs) end, 0.01)
            if model and (typeof(model) == "Instance" or type(model) == "table") then
                local descendants = getdescendants(model)
                if descendants then
                    local toprint = {}
                    for _, sc in pairs(descendants) do
                        if sc:IsA("Script") or sc:IsA("ModuleScript") then
                            counter += 1
                            toprint[#toprint + 1] = '~' .. sc.Name .. '~'
                            local name = folderName .. "/" .. sc.Name:gsub("/", ""):gsub("%z", ""):gsub("%p", "")
                            if isfile(name .. ".lua") then name ..= tostring(counter) end
                            writefile(name .. ".lua",  `-- Saved with croak14_'s and inferiousmalder's ServerScriptDownloader\n-- Parent: {sc.Parent.Name}\n-- AssetId: {tostring(vs)}\n\n\n`..sc.Source)
                        elseif sc:IsA("NumberPose") and sc.Value > 1000000 then
                            local fold = folderName.."/".."NumberPoses"
                            if not isfolder(fold) then makefolder(fold) end
                            writefile(fold.."/"..sc.Name:gsub("/", "")..".txt", "Value: "..tostring(sc.Value))
                        end
                    end
                    if #toprint > 0 then
                        print("SERVERSCRIPTS: " .. table.concat(toprint, " "))
                    end
                end
            end
        end)
        task.wait(0.25)
    end
end

local hadposes = isfolder(folderName.."/NumberPoses") and true or false
local posestext = if hadposes then " and "..tostring(#listfiles(folderName.."/NumberPoses")).." poses" else ""
print(`Finished processing all {#freemodels} models`..posestext)
