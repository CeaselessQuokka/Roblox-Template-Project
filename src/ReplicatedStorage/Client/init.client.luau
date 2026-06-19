--!strict
-- Services --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Imports --
const LoadingHelper = require(ReplicatedStorage.Shared.Helpers.LoadingHelper)

-- Initialize Client --
-- Load controllers and components.
LoadingHelper.LoadSingletons(script.Controllers, true)
LoadingHelper.LoadComponents(script.Components, true)
LoadingHelper.LoadComponents(ReplicatedStorage.Shared.Components, true)

-- Initialize Cmdr.
const Cmdr = (require)(ReplicatedStorage:WaitForChild("CmdrClient"))
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
