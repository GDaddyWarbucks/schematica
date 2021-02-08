local baseUrl = "https://raw.githubusercontent.com/Jxl-v/schematica/main/"
local function require_module(module) return loadstring(game:HttpGet(string.format("%sdependencies/%s", baseUrl, module)))() end

local Http = game.HttpService
local env = Http:JSONDecode(game:HttpGet(baseUrl .. "env.json"))

--//Getting the modules
local Player = game.Players.LocalPlayer

local Serializer = require_module("serializer.lua")
local Builder = require_module("builder.lua")
local Printer = require_module("printer.lua")
local Library = require_module("venyx.lua")

if game.CoreGui:FindFirstChild("Schematica") then
    game.CoreGui.Schematica:Destroy()
end

if not isfolder("builds") then makefolder("builds") end

local request = syn.request or request or http_request 

local Schematica = Library.new("Schematica")
local Mouse = Player:GetMouse()

do
    local Build = Schematica:addPage("Build")
    local round = math.round

    local V = {}

    V.Connections = {}

    V.ChangingPosition = false;
    V.BuildId = '0';
    V.ShowPreview = true;
    V.Build = nil

    V.Indicator = Instance.new("Part")
    V.Indicator.Size = Vector3.new(3.1, 3.1, 3.1)
    V.Indicator.Transparency = 0.5
    V.Indicator.Anchored = true
    V.Indicator.CanCollide = false
    V.Indicator.BrickColor = BrickColor.new("Bright green")
    V.Indicator.TopSurface = Enum.SurfaceType.Smooth
    V.Indicator.Parent = workspace

    local Handles = Instance.new("Handles")
    Handles.Style = Enum.HandlesStyle.Movement
    Handles.Adornee = V.Indicator
    Handles.Parent = game.CoreGui
    Handles.Visible = false

    V.DragCF = 0

    V.Connections.HandleDown = Handles.MouseButton1Down:Connect(function()
        V.DragCF = Handles.Adornee.CFrame
    end)

    V.Connections.HandleDrag = Handles.MouseDrag:Connect(function(Face, Distance)
        if V.Indicator.Parent.ClassName == "Model" then
            V.Indicator.Parent:SetPrimaryPartCFrame(V.DragCF + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3))
        else
            V.Indicator.CFrame = V.DragCF + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3)
        end
    end)
    --//UI

    V.SelectSection = Build:addSection("Selecting Build")
    V.BuildIdBox = V.SelectSection:addTextbox("Build ID", "0", function(buildId)
        V.BuildId = buildId
    end)

    V.Download = V.SelectSection:addButton("Download / Load", function()
        V.SelectSection:updateButton(V.Download, "Please wait ...")

        if isfile("builds/" .. V.BuildId .. ".s") then
            if V.Build then 
                V.Build.Model.PrimaryPart.Parent = workspace
                V.Build:Destroy()
            end
            local Data = Http:JSONDecode(readfile("builds/" .. V.BuildId .. ".s"))
            V.Build = Builder.new(Data)
            V.SelectSection:updateButton(V.Download, "File loaded!")
        else
            local Response = Http:JSONDecode(game:HttpGet(env.get .. V.BuildId))
            if Response.success == true then
                if V.Build then 
                    V.Build.Model.PrimaryPart.Parent = workspace
                    V.Build:Destroy()
                end
                writefile("builds/" .. V.BuildId .. ".s", game.HttpService:JSONEncode(Response.data))
                V.SelectSection:updateButton(V.Download, "Downloaded!")
            else
                if Response.status == 404 then
                    V.SelectSection:updateButton(V.Download, "Not found")
                elseif Response.status == 400 then
                    V.SelectSection:updateButton(V.Download, "Error")
                end
            end
        end
        wait(1)
        V.SelectSection:updateButton(V.Download, "Download")
    end)

    V.PositionSettings = Build:addSection("Position Settings")

    V.ChangePositionToggle = V.PositionSettings:addToggle("Change Position", false, function(willChange)
        V.ChangingPosition = willChange
    end)

    V.Connections.OnClick = Mouse.Button1Down:Connect(function()
        if Mouse.Target then
            if V.ChangingPosition then
                if Mouse.Target.Parent.Name == "Blocks" or Mouse.Target.Parent.Parent.Name == "Blocks" then
                    local Part = Mouse.Target.Parent.Name == "Blocks" and Mouse.Target or Mouse.Target.Parent.Parent.Name == "Blocks" and Mouse.Target.Parent
                    Handles.Visible = V.ShowPreview
                    if V.Indicator.Parent and V.Indicator.Parent.ClassName == "Model" then
                        V.Indicator.Parent:SetPrimaryPartCFrame(CFrame.new(Part.Position))
                    else
                        V.Indicator.CFrame = CFrame.new(Part.Position)
                    end
                end
            end
        end
    end)

    print("click connection loaded")

    V.LoadPreview = V.PositionSettings:addButton("Load Preview", function()
        if V.Indicator and V.Build then
            V.ChangingPosition = false
            V.PositionSettings:updateToggle(V.ChangePositionToggle, "Change Position", false)
            V.Build:Init()
            V.Build:Render(V.ShowPreview)

            local Box = V.Build.Model:GetBoundingBox()
            V.Build:SetCFrame(V.Indicator.CFrame)    
            
            V.Indicator.Parent = V.Build.Model
            V.Build.Model.PrimaryPart = V.Indicator
        end
    end)

    print("load preview button loaded")
    local Rad90 = math.rad(90)

    V.Rotate = Build:addSection("Rotation")
    V.XRotate = V.Rotate:addButton("Rotate on X", function()
        if V.Build then
            V.Build:SetCFrame(V.Indicator.CFrame * CFrame.Angles(Rad90, 0, 0))
        end
    end)

    V.YRotate = V.Rotate:addButton("Rotate on Y", function()
        if V.Build then
            V.Build:SetCFrame(V.Indicator.CFrame * CFrame.Angles(0, Rad90, 0))
        end
    end)

    V.ZRotate = V.Rotate:addButton("Rotate on Z", function()
        if V.Build then
            V.Build:SetCFrame(V.Indicator.CFrame * CFrame.Angles(0, 0, Rad90))
        end
    end)

    V.BuildSection = Build:addSection("Build")
    V.BuildSection:addToggle("Show Build", true, function(willShow)
        V.ShowPreview = willShow
        V.Indicator.Transparency = willShow and 0.5 or 1
        Handles.Parent = willShow and game.CoreGui or game.ReplicatedStorage
        
        if V.Build then
            if V.Build.Model then
                V.Build:Render(V.ShowPreview)
            else
                Schematica:Notify("Error", "Model doesn't exist")
            end
        end
    end)

    V.BuildSection:addButton("Start Building", function()
        if V.Build then
            local OriginalPosition = Player.Character.HumanoidRootPart.CFrame
            V.Build:Build({
                Start = function()
                    Velocity = Instance.new("BodyVelocity", Player.Character.HumanoidRootPart)
                    Velocity.Velocity = Vector3.new(0, 0, 0)
                end;
                Build = function(CF)
                    Player.Character.HumanoidRootPart.CFrame = CF + Vector3.new(10, 10, 10)
                end;
                End = function()
                    Velocity:Destroy()
                    Player.Character.HumanoidRootPart.CFrame = OriginalPosition
                end;
            })
        end
    end)

    print("start build button loaded")

    V.BuildSection:addButton("Abort", function()
        if V.Build then
            V.Build.Abort = true
        end
    end)
end

do
    local Http = game.HttpService
    local round = math.round
    local Save = Schematica:addPage("Save Builds")

    local V = {}
    V.Connections = {}
    V.ChangeStart = false
    V.ChangeEnd = false
    V.ShowOutline = true
    
    V.Points = Save:addSection("Set Points")

    V.Point1 = V.Points:addToggle("Change Start Point", false, function(willChange)
        V.ChangeStart = willChange
        if willChange then
            V.Points:updateToggle(V.Point2, "Change End Point", false)
            V.ChangeEnd = false
        end
    end)

    V.Point2 = V.Points:addToggle("Change End Point", false, function(willChange)
        V.ChangeEnd = willChange
        if willChange then
            V.Points:updateToggle(V.Point1, "Change Start Point", false)
            V.ChangeStart = false
        end
    end)

    V.Model = Instance.new("Model")

    local SelectionBox = Instance.new("SelectionBox")
    SelectionBox.Adornee = V.Model
    SelectionBox.SurfaceColor3 = Color3.new(1, 0, 0)
    SelectionBox.Color3 = Color3.new(1, 1, 1)
    SelectionBox.Parent = V.Model
    SelectionBox.LineThickness = 0.1
    SelectionBox.SurfaceTransparency = 0.8
    SelectionBox.Visible = false

    V.IndicatorStart = Instance.new("Part")
    V.IndicatorStart.Size = Vector3.new(3.1, 3.1, 3.1)
    V.IndicatorStart.Transparency = 1
    V.IndicatorStart.Anchored = true
    V.IndicatorStart.CanCollide = false
    V.IndicatorStart.BrickColor = BrickColor.new("Really red")
    V.IndicatorStart.Material = "Plastic"
    V.IndicatorStart.TopSurface = Enum.SurfaceType.Smooth
    V.IndicatorStart.Parent = V.Model

    V.IndicatorEnd = Instance.new("Part")
    V.IndicatorEnd.Size = Vector3.new(3.1, 3.1, 3.1)
    V.IndicatorEnd.Transparency = 1
    V.IndicatorEnd.Anchored = true
    V.IndicatorEnd.CanCollide = false
    V.IndicatorEnd.BrickColor = BrickColor.new("Really blue")
    V.IndicatorEnd.Material = "Plastic"
    V.IndicatorEnd.TopSurface = Enum.SurfaceType.Smooth
    V.IndicatorEnd.Parent = V.Model

    local StartHandles = Instance.new("Handles")

    StartHandles.Style = Enum.HandlesStyle.Movement
    StartHandles.Adornee = V.IndicatorStart
    StartHandles.Visible = false
    StartHandles.Parent = game.CoreGui

    local EndHandles = Instance.new("Handles")

    EndHandles.Style = Enum.HandlesStyle.Movement
    EndHandles.Adornee = V.IndicatorEnd
    EndHandles.Visible = false
    EndHandles.Parent = game.CoreGui

    local CF1
    local CF2

    V.Connections.StartHandleDown = StartHandles.MouseButton1Down:connect(function()
        CF1 = StartHandles.Adornee.CFrame
    end)

    V.Connections.StartHandleDrag = StartHandles.MouseDrag:Connect(function(Face, Distance)
        StartHandles.Adornee.CFrame = CF1 + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3)
    end)

    V.Connections.EndHandleDown = EndHandles.MouseButton1Down:connect(function()
        CF2 = EndHandles.Adornee.CFrame
    end)

    V.Connections.EndHandleDrag = EndHandles.MouseDrag:Connect(function(Face, Distance)
        EndHandles.Adornee.CFrame = CF2 + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3)
    end)

    V.Model.Parent = workspace

    V.Connections.Click = Mouse.Button1Down:Connect(function()
        if Mouse.Target then
            if V.ChangeStart or V.ChangeEnd then
                local ToChange = V.ChangeStart and "Start" or "End"
                if Mouse.Target.Parent.Name == "Blocks" or Mouse.Target.Parent.Parent.Name == "Blocks" then
                    local Part = Mouse.Target.Parent.Name == "Blocks" and Mouse.Target or Mouse.Target.Parent.Parent.Name == "Blocks" and Mouse.Target.Parent
                    V[ToChange] = Part.Position

                    if ToChange == "Start" then
                        StartHandles.Visible =  V.ShowOutline
                        V.IndicatorStart.Transparency = V.ShowOutline and 0.5 or 1
                    elseif ToChange == "End" then
                        EndHandles.Visible =  V.ShowOutline
                        V.IndicatorEnd.Transparency = V.ShowOutline and 0.5 or 1
                    end

                    if V.Start and V.End then
                        SelectionBox.Visible =  V.ShowOutline
                        if ToChange == "Start" then
                            V.IndicatorStart.Position = Part.Position
                        elseif ToChange == "End" then
                            V.IndicatorEnd.Position = Part.Position
                        end
                    else
                        V.IndicatorStart.Position = Part.Position
                        V.IndicatorEnd.Position = Part.Position
                    end
                end
            end
        end
    end)

    V.Final = Save:addSection("Save")
    V.Final:addToggle("Show Outline", true, function(willShow)
        V.ShowOutline = willShow
        V.IndicatorStart.Transparency = willShow and 0.5 or 1
        V.IndicatorEnd.Transparency = willShow and 0.5 or 1
        StartHandles.Visible = willShow
        EndHandles.Visible = willShow
        SelectionBox.Visible = willShow
    end)

    V.Final:addButton("Save Area", function()
        local Serialize = Serializer.new(V.IndicatorStart.Position, V.IndicatorEnd.Position)
        local Data = Serialize:Serialize()

        local Response = request({
            Url = env.post;
            Body = game.HttpService:JSONEncode(Data);
            Headers = {
                ["Content-Type"] = "application/json"
            };
            Method = "POST"
        })

        local JSONResponse = Http:JSONDecode(Response.Body)
        if JSONResponse.status == "success" then
            setclipboard(JSONResponse.output)
            writefile("builds/" .. JSONResponse.output .. ".s", game.HttpService:JSONEncode(Data))
            Schematica:Notify("Build Uploaded", "Copied to clipboard")
        else
            Schematica:Notify("Error", JSONResponse.status)
        end
    end)
end

do
    local Print = Schematica:addPage("Printer")

    local round = math.round
    
    local V = {}
    V.Connections = {}
    V.ChangeStart = false
    V.ChangeEnd = false
    V.ShowOutline = true

    V.SetPoints = Print:addSection("Set Points")
    V.ChangeStartToggle = V.SetPoints:addToggle("Change Start Point", false, function(willChange)
        V.ChangeStart = willChange
        if willChange then
            V.ChangeEnd = false
            V.SetPoints:updateToggle(V.ChangeEndToggle, "Change End Point", false)
        end
    end)

    V.ChangeEndToggle = V.SetPoints:addToggle("Change End Point", false, function(willChange)
        V.ChangeEnd = willChange
        if willChange then
            V.ChangeStart = false
            V.SetPoints:updateToggle(V.ChangeStartToggle, "Change Start Point", false)
        end
    end)

    V.Model = Instance.new("Model")

    local SelectionBox = Instance.new("SelectionBox")
    SelectionBox.Adornee = V.Model
    SelectionBox.SurfaceColor3 = Color3.new(0, 1, 0)
    SelectionBox.Color3 = Color3.new(1, 1, 1)
    SelectionBox.Parent = V.Model
    SelectionBox.LineThickness = 0.1
    SelectionBox.SurfaceTransparency = 0.8
    SelectionBox.Visible = false

    V.IndicatorStart = Instance.new("Part")
    V.IndicatorStart.Size = Vector3.new(3.1, 3.1, 3.1)
    V.IndicatorStart.Transparency = 1
    V.IndicatorStart.Anchored = true
    V.IndicatorStart.CanCollide = false
    V.IndicatorStart.BrickColor = BrickColor.new("Really red")
    V.IndicatorStart.Material = "Plastic"
    V.IndicatorStart.TopSurface = Enum.SurfaceType.Smooth
    V.IndicatorStart.Parent = V.Model

    V.IndicatorEnd = Instance.new("Part")
    V.IndicatorEnd.Size = Vector3.new(3.1, 3.1, 3.1)
    V.IndicatorEnd.Transparency = 1
    V.IndicatorEnd.Anchored = true
    V.IndicatorEnd.CanCollide = false
    V.IndicatorEnd.BrickColor = BrickColor.new("Really blue")
    V.IndicatorEnd.Material = "Plastic"
    V.IndicatorEnd.TopSurface = Enum.SurfaceType.Smooth
    V.IndicatorEnd.Parent = V.Model

    local StartHandles = Instance.new("Handles")

    StartHandles.Style = Enum.HandlesStyle.Movement
    StartHandles.Adornee = V.IndicatorStart
    StartHandles.Visible = false
    StartHandles.Parent = game.CoreGui

    local EndHandles = Instance.new("Handles")

    EndHandles.Style = Enum.HandlesStyle.Movement
    EndHandles.Adornee = V.IndicatorEnd
    EndHandles.Visible = false
    EndHandles.Parent = game.CoreGui

    V.DragCF1 = 0
    V.DragCF2 = 0

    V.Connections.StartHandleDown = StartHandles.MouseButton1Down:Connect(function()
        V.DragCF1 = StartHandles.Adornee.CFrame
    end)

    V.Connections.StartHandleDrag = StartHandles.MouseDrag:Connect(function(Face, Distance)
        StartHandles.Adornee.CFrame = V.DragCF1 + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3)
    end)

    V.Connections.EndHandleDown = EndHandles.MouseButton1Down:connect(function()
        V.DragCF2 = EndHandles.Adornee.CFrame
    end)

    V.Connections.EndHandleDrag = EndHandles.MouseDrag:Connect(function(Face, Distance)
        EndHandles.Adornee.CFrame = V.DragCF2 + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3)
    end)

    V.Model.Parent = workspace

    V.Connections.Click = Mouse.Button1Down:Connect(function()
        if Mouse.Target then
            if V.ChangeStart or V.ChangeEnd then
                local ToChange = V.ChangeStart and "Start" or "End"
                if Mouse.Target.Parent.Name == "Blocks" or Mouse.Target.Parent.Parent.Name == "Blocks" then
                    local Part = Mouse.Target.Parent.Name == "Blocks" and Mouse.Target or Mouse.Target.Parent.Parent.Name == "Blocks" and Mouse.Target.Parent
                    V[ToChange] = Part.Position

                    if ToChange == "Start" then
                        StartHandles.Visible =  V.ShowOutline
                        V.IndicatorStart.Transparency = V.ShowOutline and 0.5 or 1
                    elseif ToChange == "End" then
                        EndHandles.Visible =  V.ShowOutline
                        V.IndicatorEnd.Transparency = V.ShowOutline and 0.5 or 1
                    end

                    if V.Start and V.End then
                        SelectionBox.Visible =  V.ShowOutline
                        if ToChange == "Start" then
                            V.IndicatorStart.Position = Part.Position
                        elseif ToChange == "End" then
                            V.IndicatorEnd.Position = Part.Position
                        end
                    else
                        V.IndicatorStart.Position = Part.Position
                        V.IndicatorEnd.Position = Part.Position
                    end
                end
            end
        end
    end)

    V.Final = Print:addSection("Build")
    V.Final:addToggle("Show Outline", true, function(willShow)
        V.ShowOutline = willShow
        V.IndicatorStart.Transparency = willShow and 0.5 or 1
        V.IndicatorEnd.Transparency = willShow and 0.5 or 1

        if V.Start then
            StartHandles.Visible = willShow
        end

        if V.End then
            EndHandles.Visible = willShow
        end

        SelectionBox.Visible = willShow
    end)

    V.Final:addButton("Print Area", function()
        if Player.Character:FindFirstChildOfClass("Tool") then
            local OriginalPosition = Player.Character.HumanoidRootPart.CFrame

            V.Printing = Printer.new(V.IndicatorStart.Position, V.IndicatorEnd.Position)

            local BlockType = Player.Character:FindFirstChildOfClass("Tool").Name:gsub("Seeds", "")
            V.Printing:SetBlock(BlockType)
            V.Printing:Build({
                Start = function()
                    Velocity = Instance.new("BodyVelocity", Player.Character.HumanoidRootPart)
                    Velocity.Velocity = Vector3.new(0, 0, 0)
                end;
                Build = function(Pos)
                    Player.Character.HumanoidRootPart.CFrame = CFrame.new(Pos + Vector3.new(10, 10, 10))
                end;
                End = function()
                    Velocity:Destroy()
                    Player.Character.HumanoidRootPart.CFrame = OriginalPosition
                end;
            })
        else
            Schematica:Notify("Error", "Please hold a block")
        end
    end)

    V.Final:addButton("Destroy Area", function()
        local OriginalPosition = Player.Character.HumanoidRootPart.CFrame
        V.Printing = Printer.new(V.IndicatorStart.Position, V.IndicatorEnd.Position)
        V.Printing:Reverse({
            Start = function()
                Velocity = Instance.new("BodyVelocity", Player.Character.HumanoidRootPart)
                Velocity.Velocity = Vector3.new(0, 0, 0)
            end;
            Build = function(Pos)
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(Pos + Vector3.new(5, 5, 5))
            end;
            End = function()
                Velocity:Destroy()
                Player.Character.HumanoidRootPart.CFrame = OriginalPosition
            end;
        })
    end)

    V.Final:addButton("Abort", function()
        V.Printing.Abort = true
    end)
end

do
    local function closestIsland() local L_6_ = workspace:WaitForChild("Islands"):GetChildren() local L_7_ = Player.Character.HumanoidRootPart.Position for L_8_forvar0 = 1, #L_6_ do local L_9_ = L_6_[L_8_forvar0] if L_9_:FindFirstChild("Root") and math.abs(L_9_.PrimaryPart.Position.X - L_7_.X) <= 1000 and math.abs(L_9_.PrimaryPart.Position.Z - L_7_.Z) <= 1000 then return L_9_ end end return workspace.Islands:FindFirstChild(tostring(Player.UserId).."-island") end

    local Http = game.HttpService
    local Other = Schematica:addPage("Other")
    local ConvertOldSection = Other:addSection("Convert Old Build")

    local V = {}
    ConvertOldSection:addTextbox("File", "", function(File)
        V.File = File
    end)

    local function strArray(a)
        local b = {}

        for i, v in next, a do
            b[i] = tonumber(v)
        end

        return b
    end

    Other:addSection("Save Closest Island"):addButton("Save", function()
        local Closest = closestIsland()
        if Closest then
            local Center, Size = Closest:GetBoundingBox()

            local Serialize = Serializer.new(Center.Position - Size / 2, Center.Position + Size / 2)
            local Data = Serialize:Serialize()

            local Response = request({
                Url = env.post;
                Body = game.HttpService:JSONEncode(Data);
                Headers = {
                    ["Content-Type"] = "application/json"
                };
                Method = "POST"
            })

            local JSONResponse = Http:JSONDecode(Response.Body)
            if JSONResponse.status == "success" then
                setclipboard(JSONResponse.output)
                writefile("builds/" .. JSONResponse.output .. ".s", game.HttpService:JSONEncode(Data))
                Schematica:Notify("Build Uploaded", "Copied to clipboard")
            else
                Schematica:Notify("Error", JSONResponse.status)
            end
        end
    end)
    ConvertOldSection:addButton("Convert", function()
        if isfile("builds/" .. V.File) then
            local Data = Http:JSONDecode(readfile("builds/" .. V.File))
            local Output = {}
            Output.Blocks = {}

            local LowX, LowY, LowZ = 0, 0, 0
            local HighX, HighY, HighZ = 0, 0, 0

            for Block, Array in next, Data do
                Output.Blocks[Block] = {}
                for i, v in next, Array do
                    local Split = strArray(v:split(","))

                    if Split[1] < LowX then
                        LowX = Split[1]
                    elseif Split[1] > HighX then
                        HighX = Split[1]
                    end

                    if Split[2] < LowY then
                        LowY = Split[2]
                    elseif Split[2] > HighY then
                        HighY = Split[2]
                    end

                    if Split[3] < LowZ then
                        LowZ = Split[3]
                    elseif Split[3] > HighZ then
                        HighZ = Split[3]
                    end

                    table.insert(Output.Blocks[Block], {
                        C = strArray(Split)
                    })
                end
            end

            Output.Size = {HighX - LowX, HighY - LowY, HighZ - LowZ}

            local FileName = V.File .. "-converted-" .. tostring(os.time()) .. ".txt"
            writefile(string.format("builds/%s", FileName), Http:JSONEncode(Output))

            Schematica:Notify("Converted!", "Saved file as " .. FileName)
        end
    end)

    local UploadFile = Other:addSection("Upload File")
    UploadFile:addTextbox("File", "", function(File)
        V.ToUpload = File
    end)

    UploadFile:addButton("Upload", function()
        if isfile("builds/" .. V.ToUpload) then
            local Response = request({
                Url = env.post;
                Body = readfile("builds/" .. V.ToUpload);
                Headers = {
                    ["Content-Type"] = "application/json"
                };
                Method = "POST"
            })

            local JSONResponse = Http:JSONDecode(Response.Body)
            if JSONResponse.status == "success" then
                setclipboard(JSONResponse.output)
                writefile("builds/" .. JSONResponse.output, game.HttpService:JSONEncode(Data))
                Schematica:Notify("Build Uploaded", "Copied to clipboard")
            else
                Schematica:Notify("Error", JSONResponse.status)
            end
        end
    end)
end

Schematica:setParent()
