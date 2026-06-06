--!strict
-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Imports --
local Cmdr: any = require(ReplicatedStorage.Packages.Cmdr)

local LoadingHelper = require(ReplicatedStorage.Shared.Helpers.LoadingHelper)
local PermissionHelper = require(script.Helpers.PermissionHelper)

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
	local isAuthorized = RunService:IsStudio() or PermissionHelper.HasPermission(context.Executor, "Cmdr")
	return if not isAuthorized then "You do not have permission to run this command." else nil
end)
