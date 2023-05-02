local UI = {}

local function create(class:string,parent:Instance,properties:{})
	local inst = Instance.new(class)
	if properties then
		for _,v in pairs(properties) do
			if _ == "Parent" or _ == "ClassName" then continue end
			inst[_]=v
		end
	else
		return warn("There's no properties!")
	end
	inst.Parent = parent
	return inst
end

local function check(inst:Instance,properties:{})
	if properties then
		if inst then
			for _,v in pairs(properties) do
				if inst[_] ~= v then
					if _ == "CFrame" then
						local pos = v.Position
						local ori = v.LookVector
						if (inst[_].Position - pos).Magnitude >= 0.05 then
							return false
						elseif (inst[_].LookVector - ori).Magnitude >= 0.05 then
							return false
						end
						continue
					elseif _ == "Orientation" then
						if (inst[_] - v).Magnitude >= 0.05 then
							return false
						end
					elseif _ == "Position" then
						if (inst[_] - v).Magnitude >= 0.05 then
							return false
						end
					else
						print(_)
						return false
					end
				end
			end
			return true
		else
			return false
		end
	end
	return warn("No properties has been given!")
end

local function fetchProperties(classToCollect :string)
	local HttpService = game:GetService("HttpService")
	local myProps :{string} = {}
	local apiDumpClasses = HttpService:JSONDecode(HttpService:GetAsync("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json")).Classes
	local found = false

	repeat found = false
		for _, class in pairs(apiDumpClasses) do
			if class.Name ~= classToCollect then continue end
			for _, member in pairs(class.Members) do
				if member.MemberType == "Property" then
					table.insert(myProps,member.Name)
				end
			end
			classToCollect = class.Superclass
			found = true
		end
		assert(found,"Class not found: "..classToCollect)
	until classToCollect == "<<<ROOT>>>"

	return myProps
end

function UI:Create(s:{})
	return create(s.ClassName,s.Parent,s)
end

function UI:Check(s:Instance,properties:{})
	return check(s,properties)
end

function UI:SetProps(s:Instance,properties:{})
	if properties then
		for _,v in pairs(properties) do
			if _ == "Parent" or _ == "ClassName" then continue end
			s[_]=v
		end

		if properties["Parent"] then
			s["Parent"] = properties["Parent"]
		end
	else
		return warn("There's no properties!")
	end
end

function UI:Serialize(p:Instance,properties,bl)
	local s do
		local blacklist = {"Origin","ExtentsSize","ExtentsCFrame","className","ResizeIncrement","SpecificGravity","ResizeableFaces","ReceiveAge","Pivot Offset","SourceAssetId","RobloxLocked","DataCost","Mass","AssemblyLinearVelocity","AssemblyAngularVelocity","AssemblyCenterOfMass","AssemblyMass","AssemblyRootPart","CenterOfMass","CurrentPhysicalProperties"}
		if bl then
			for _,v in pairs(bl) do
				table.insert(blacklist,v)
			end
		end
		s={}
		do
			local t = {}
			local ep = properties or fetchProperties(p.ClassName)

			for i,v in pairs(blacklist) do
				if table.find(ep,v,1) then
					local b = table.find(ep,v,1)
					table.remove(ep,b)
				end
			end

			for i,v in pairs(ep) do
				t[v]=p[v]
			end

			s[p.Name]=t
		end
	end
	return s
end

function UI:SetRefit(p:Instance,properties,bl,call)
	local s = UI:Serialize(p,properties,bl)[p.Name]

	local func do
		if not call then
			func = function()
				if not UI:Check(p,s) then
					if p and p.Parent == s.Parent then
						UI:SetProps(p,s)
					else
						p = UI:Create(s)
					end
				else
					for _,v in pairs(p:GetChildren()) do
						v:Destroy()
					end
				end
			end
		else
			func = call
		end
	end

	return game:GetService"RunService".PreSimulation:Connect(function() task.defer(func) end),s
end

return UI