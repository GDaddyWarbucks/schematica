local Printer = {}

do
    Printer.__index = Printer

    setmetatable(Printer, {
        __tostring = function()
            return "Printer"
        end
    })

    local Place = game.ReplicatedStorage.Remotes.Functions.CLIENT_BLOCK_PLACE_REQUEST
    local Hit = game.ReplicatedStorage.Remotes.Functions.CLIENT_BLOCK_HIT_REQUEST

    local Heartbeat = game:GetService("RunService").Heartbeat

    function Printer.new(Start, End, Block)
        local self = setmetatable({}, Printer)

        self.Start = Start
        self.End = End
        self.Block = Block
        self.Abort = false

        return self
    end

    function Printer:SetStart(Start)
        self.Start = Start
    end

    function Printer:SetEnd(End)
        self.End = End
    end

    function Printer:SetBlock(Block)
        self.Block = Block
    end

    function Printer:IsTaken(Position) -- Private
        local Parts = workspace:FindPartsInRegion3(Region3.new(Position, Position), nil, math.huge)
        for i, v in next, Parts do
            if v.Parent and v.Parent.Name == "Blocks" then
                return true
            end
        end
        return false
    end

    function Printer:Build(Callback)
        Callback.Start()
        local Start, End = Vector3.new(math.min(self.Start.X, self.End.X), math.min(self.Start.Y, self.End.Y), math.min(self.Start.Z, self.End.Z)), Vector3.new(math.max(self.Start.X, self.End.X), math.max(self.Start.Y, self.End.Y), math.max(self.Start.Z, self.End.Z))
        for X = Start.X, End.X, 3 do
            if self.Abort then self.Abort = false break end

            for Y = Start.Y, End.Y, 3 do
                if self.Abort then self.Abort = false break end

                for Z = Start.Z, End.Z, 3 do
                    if self.Abort then self.Abort = false break end

                    local Position = Vector3.new(X, Y, Z)
                    Callback.Build(Position)

                    if not self:IsTaken(Position) then
                        spawn(function()
                            Place:InvokeServer({
                                blockType = self.Block;
                                cframe = CFrame.new(Position);
                                player_tracking_category = "join_from_web";
                                upperSlab = false;
                            })
                        end)
                        Heartbeat:wait()
                    end
                end
            end
        end

        Callback.End()
    end

    function Printer:Reverse(Callback)
        Callback.Start()
        local Start, End = Vector3.new(math.min(self.Start.X, self.End.X), math.min(self.Start.Y, self.End.Y), math.min(self.Start.Z, self.End.Z)), Vector3.new(math.max(self.Start.X, self.End.X), math.max(self.Start.Y, self.End.Y), math.max(self.Start.Z, self.End.Z))
        local Region = Region3.new(Start, End)

        local UnbreakableGrassPosition = Vector3.new(6, -6, -141)
        for i, v in next, workspace:FindPartsInRegion3(Region, nil, math.huge) do
            if self.Abort then 
                self.Abort = false 
                Callback.End()
                break 
            end

            if v.Name ~= "bedrock" and (not v:FindFirstChild("portal-to-spawn")) and v.Parent and v.Parent.Name == "Blocks" then
                if v.Parent.Parent.Root.CFrame:PointToObjectSpace(v.Position) ~= UnbreakableGrassPosition then
                    local time = os.time()
                    repeat
                        if v ~= nil and v:IsDescendantOf(workspace) then
                            Callback.Build(v.Position)
                            Hit:InvokeServer({
                                player_tracking_category = "join_from_web";
                                part = v;
                                block = v;
                                norm = v.Position;
                                pos = Vector3.new(-1, 0, 0)
                            })
                        end
                        wait()
                    until v == nil or (not v:IsDescendantOf(workspace)) or os.time() - time > 15 or self.Abort == true
                end
            end
        end

        Callback.End()
    end
end

return Printer
