--!strict
-- Types --
export type Singleton = {
	Enabled: boolean?,

	Initialize: (self: Singleton) -> (),
	Start: (self: Singleton) -> (),
}

-- Functions --
const function HandleError(err: any)
	task.spawn(error, err)
end

const function IsModuleLoadable(module: Instance): boolean
	return module:IsA("ModuleScript") and module:GetAttribute("Enabled") ~= false
end

const function GetModules(root: Instance, deep: boolean?): { ModuleScript }
	const function GetDeep(instance: Instance, modules: { ModuleScript }): { ModuleScript }
		for _, child in instance:GetChildren() do
			if child:IsA("ModuleScript") then
				table.insert(modules, child)
			elseif child:IsA("Folder") then
				GetDeep(child, modules)
			end
		end
		return modules
	end

	if deep then
		return GetDeep(root, {})
	else
		const modules = root:GetChildren() :: { ModuleScript }
		for index = #modules, 1, -1 do
			if not modules[index]:IsA("ModuleScript") then
				table.remove(modules, index)
			end
		end
		return modules
	end
end

-- Loading Helper --
const LoadingHelper = {}

-- Yields until initialization is complete (or errors).
function LoadingHelper.InitializeSingleton(singletonModule: ModuleScript)
	xpcall(function()
		const singleton = (require)(singletonModule) :: Singleton
		if
			typeof(singleton) == "table"
			and typeof(singleton.Initialize) == "function"
			and singleton.Enabled ~= false
		then
			singleton:Initialize()
		end
	end, HandleError)
end

-- Does not yield.
function LoadingHelper.StartSingleton(singletonModule: ModuleScript)
	task.spawn(xpcall, function()
		const singleton = (require)(singletonModule) :: Singleton
		if typeof(singleton) == "table" and typeof(singleton.Start) == "function" and singleton.Enabled ~= false then
			singleton:Start()
		end
	end, HandleError)
end

function LoadingHelper.LoadSingletons(root: Instance, deep: boolean?)
	-- Shuffle singletons to help ensure they are execution order independent.
	const singletonModules = GetModules(root, deep)
	Random.new():Shuffle(singletonModules)

	-- Wait for all singletons to initialize.
	const singletonsLeft: { [ModuleScript]: true? } = {}
	for _, singletonModule in singletonModules do
		singletonsLeft[singletonModule] = true
		task.spawn(function()
			LoadingHelper.InitializeSingleton(singletonModule)
			singletonsLeft[singletonModule] = nil
		end)
	end

	local startTime = os.clock()
	while next(singletonsLeft) do
		if os.clock() - startTime >= 10 then
			const singletonNames: { string } = {}
			for singletonModule in singletonsLeft do
				table.insert(singletonNames, singletonModule.Name)
			end
			warn(
				`[{script.Name}] Initialization of singletons is taking longer than expected. {#singletonNames} remaining singletons: {table.concat(
					singletonNames,
					", "
				)}`
			)
			startTime = os.clock()
		end
		task.wait(0.125)
	end

	-- Start all singletons without yielding.
	for _, singletonModule in singletonModules do
		LoadingHelper.StartSingleton(singletonModule)
	end
end

function LoadingHelper.LoadComponent(component: ModuleScript)
	if IsModuleLoadable(component) then
		xpcall(require, HandleError, component)
	end
end

function LoadingHelper.LoadComponents(root: Instance, deep: boolean?)
	const componentModules = GetModules(root, deep)
	Random.new():Shuffle(componentModules)
	for _, componentModule in componentModules do
		LoadingHelper.LoadComponent(componentModule)
	end
end

return table.freeze(LoadingHelper)
