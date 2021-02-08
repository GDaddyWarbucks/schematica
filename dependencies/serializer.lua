local Serializer = {}

do
    local min = math.min
    local max = math.max
    local round = math.round

    Serializer.__index = Serializer

    local function Round(Number) 
        if typeof(Number) == "number" then
            return round(Number / 3) * 3
        end
    end

    function Serializer.new(Start, End)
        local self = setmetatable({}, Serializer)
        
        self.Start = Start
        self.End = End

        return self
    end

    function Serializer:SetStart(Start)
        self.Start = Start
    end

    function Serializer:SetEnd(End)
        self.End = End
    end

    function Serializer:Format(CF)
        local x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33 = CF:components()
        return CFrame.new(Round(x), Round(y), Round(z), m11, m12, m13, m21, m22, m23, m31, m32, m33)
    end

    function Serializer:Serialize()
        local Start, End = Vector3.new(math.min(self.Start.X, self.End.X), math.min(self.Start.Y, self.End.Y), math.min(self.Start.Z, self.End.Z)), Vector3.new(math.max(self.Start.X, self.End.X), math.max(self.Start.Y, self.End.Y), math.max(self.Start.Z, self.End.Z))
        local Region = Region3.new(Start, End)
        local Output = {}

        local Model = Instance.new("Model")

        for i, v in next, workspace:FindPartsInRegion3(Region, nil, math.huge) do
            if v.Parent.Name == "Blocks" then
                local Clone = v:Clone()
                Clone:ClearAllChildren()
                Clone.Parent = Model
                
                if Output[v.Name] == nil then 
                    Output[v.Name] = {}
                end
            end
        end
        
        local CF, Size = Model:GetBoundingBox()
        local Start, End = CF.Position - Size / 2, CF.Position + Size / 2
        local Center = self:Format(CFrame.new((Start + End) / 2)) - Vector3.new(2, 0, 2)

        for i, v in next, Model:GetChildren() do
            if v:IsA("Model") then
                table.insert(Output[v.Name], {
                    C = {Center:ToObjectSpace(v.PrimaryPart.CFrame):components()};
                })
            elseif v:IsA("BasePart") then
                if v.Name:find("Slab") and v:FindFirstChild("top") then
                    table.insert(Output[v.Name], {
                        C = {Center:ToObjectSpace(v.CFrame):components()};
                        U = true
                    })
                else
                    table.insert(Output[v.Name], {
                        C = {Center:ToObjectSpace(v.CFrame):components()};
                    })
                end
            end
        end

        return {Size = {Size.X, Size.Y, Size.Z}, Blocks = Output}
    end
end

return Serializer
