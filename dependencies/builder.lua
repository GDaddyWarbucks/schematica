local Builder = {}

do
    local round = math.round

    Builder.__index = Builder

    local function Round(Number) 
        if typeof(Number) == "number" then
            return round(Number / 3) * 3
        end
    end

    local Blocks = game.ReplicatedStorage.Blocks
    local Place = game.ReplicatedStorage.Remotes.Functions.CLIENT_BLOCK_PLACE_REQUEST
    local Heartbeat = game.RunService.Heartbeat

    function Builder.new(Data)
        local self = setmetatable({}, Builder)
        self.Data = Data.Blocks
        self.Size = Vector3.new(Data.Size[1], Data.Size[2], Data.Size[3])
        self.Abort = false

        return self
    end

    function Builder:SetupBlock(Model) -- Private
        for i, v in next, Model:GetDescendants() do
            if v:IsA("BasePart") then
                v.CanCollide = false
                if v.Transparency < 1 then
                    v.Transparency = 0.5
                end
            end
        end
    end

    function Builder:Init()
        local Model = Instance.new("Model")

        local Center = Instance.new("Part")
        Center.Position = Vector3.new(0, 0, 0)--Vector3.new(0, - Round(self.Size.Y / 2), 0)
        Center.Size = Vector3.new(3, 3, 3)
        Center.Transparency = 1
        Center.CanCollide = false
        Center.Anchored = true
        Center.Parent = Model
        Center.Name = "[Center]"

        Model.PrimaryPart = Center

        for Block, Array in next, self.Data do
            for i, v in next, Array do
                local Part = Blocks[Block]:Clone()

                if Part:IsA("Model") then
                    Part:SetPrimaryPartCFrame(CFrame.new(unpack(v.C)))
                elseif Part:IsA("BasePart") then
                    Part.CFrame = CFrame.new(unpack(v.C))
                end

                Part.Parent = Model
                self:SetupBlock(Part)
            end
        end

        self.Model = Model
    end

    function Builder:SetCFrame(CF)
        if self.Model then
            self.Model:SetPrimaryPartCFrame(CF)
            self.Model.PrimaryPart.CFrame = CFrame.new(CF.Position.X, CF.Position.Y, CF.Position.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
        end
    end

    function Builder:Render(Appear)
        if self.Model then
            self.Model.Parent = Appear and workspace or game.ReplicatedStorage
        end
    end

    function Builder:IsTaken(Position, Block)
        local Parts = workspace:FindPartsInRegion3(Region3.new(Position, Position), nil, math.huge)
        for i, v in next, Parts do
            if v.Parent and v.Parent.Name == "Blocks" and v.Name == Block then
                return true
            end
        end
        return false
    end

    function Builder:Build(Callback)
        Callback.Start()
        for i, v in next, self.Model:GetChildren() do
            local Part = v:IsA("Model") and v.PrimaryPart or v:IsA("BasePart") and v
            if not self:IsTaken(Part.Position, v.Name) then 
                if self.Abort then
                    self.Abort = false
                    break
                else
                    if v.Name ~= "[Center]" then
                        Callback.Build(Part.CFrame)
                        spawn(function()
                            Place:InvokeServer({
                                blockType = v.Name;
                                cframe = Part.CFrame;
                                player_tracking_category = "join_from_web";
                                upperSlab = false;
                            })
                        end)
                        wait()
                    end
                end
            end
        end
        Callback.End()
    end

    function Builder:Abort()
        self.Abort = true
    end

    function Builder:Destroy()
        self.Model:Destroy()
        self.Model = nil
        self.Abort = true
        
        self = nil
    end
end

return Builder
