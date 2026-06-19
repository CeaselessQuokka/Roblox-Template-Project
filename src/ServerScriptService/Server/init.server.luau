--!strict
-- Services --
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

-- Imports --
const Cmdr: any = require(ReplicatedStorage.Packages.Cmdr)

const LoadingHelper = require(ReplicatedStorage.Shared.Helpers.LoadingHelper)
const PermissionHelper = require(script.Helpers.PermissionHelper)

-- Initialize Server --
-- Load services and components.
LoadingHelper.LoadSingletons(script.Services, true)
LoadingHelper.LoadComponents(script.Components, true)
LoadingHelper.LoadComponents(ReplicatedStorage.Shared.Components, true)

-- Initialize Cmdr.
Cmdr:RegisterDefaultCommands()
Cmdr:RegisterCommandsIn(script.Cmdr.Commands)
Cmdr:RegisterTypesIn(script.Cmdr.Types)
Cmdr.Registry:RegisterHook("BeforeRun", function(context): string?
	const isAuthorized = RunService:IsStudio() or PermissionHelper.HasPermission(context.Executor, "Cmdr")
	return if not isAuthorized then "You do not have permission to run this command." else nil
end)
