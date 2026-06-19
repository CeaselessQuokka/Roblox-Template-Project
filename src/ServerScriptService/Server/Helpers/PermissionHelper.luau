--!strict
-- Services --
const ConfigService = game:GetService("ConfigService")

-- Types --
export type UserId = number
export type Permissions = { [UserId]: { [Permission]: boolean? } }

-- Variables --
const USE_CONFIG_SERVICE = true -- When true will query ConfigService for permissions if the user ID is not already cached (subject to CACHE_DURATION and CACHE_JITTER).
const CACHE_DURATION = 60 -- How long (in seconds) permissions should be cached before checking ConfigService again.
const CACHE_JITTER = 30 -- Random amount of seconds to add to the cache duration to help ease thundering herd.

const VALID_PERMISSIONS = {
	Cmdr = true,
}
export type Permission = keyof<typeof(VALID_PERMISSIONS)>

const permissions: Permissions = {}
local cacheResetTimestamp = 0

-- Permissions Helper --
const PermissionHelper = {}

-- Queries ConfigService for on-the-fly permission checking if the player is not already cached.
-- This allows the giving and taking of permissions in real-time without having to update this script and the
-- experience.
function PermissionHelper.HasPermission(playerOrUserId: Player | UserId, permission: Permission): boolean
	const userId = if typeof(playerOrUserId) == "number" then playerOrUserId else playerOrUserId.UserId
	if not USE_CONFIG_SERVICE or os.time() < cacheResetTimestamp then
		return permissions[userId] ~= nil and permissions[userId][permission] == true
	else
		cacheResetTimestamp = os.time() + CACHE_DURATION + Random.new():NextNumber(0, CACHE_JITTER)
		table.clear(permissions)
	end

	-- Loaded permissions are strenuously type checked to minimize runtime errors.
	const experienceConfig = ConfigService:GetConfigAsync()
	const loadedPermissions: Permissions = experienceConfig:GetValue("Permissions")
	if loadedPermissions == nil then
		return false
	elseif typeof(loadedPermissions) ~= "table" then
		warn(
			`[{script.Name}] Invalid Permissions table loaded from ConfigService: "{loadedPermissions}" ({typeof(
				loadedPermissions
			)})`
		)
		return false
	end

	-- Merge loaded permissions with cached permissions.
	for loadedUserId, userPermissions in loadedPermissions do
		-- Ensure user ID is a number.
		const sanitizedUserId = tonumber(loadedUserId)
		if not sanitizedUserId then
			warn(`[{script.Name}] Invalid user ID loaded from ConfigService: "{loadedUserId}" ({typeof(loadedUserId)})`)
			continue
		elseif math.isnan(sanitizedUserId) then
			warn(`[{script.Name}] Invalid user ID loaded from ConfigService: "{loadedUserId}" is NaN.`)
			continue
		end

		-- Ensure the loaded user permissions is a table.
		if typeof(userPermissions) ~= "table" then
			warn(
				`[{script.Name}] Invalid permissions table loaded from ConfigService for user ID "{sanitizedUserId}": "{userPermissions}" ({typeof(
					userPermissions
				)})`
			)
			continue
		end

		-- Ensure each permission is valid.
		for permission, hasPermission in userPermissions do
			if not VALID_PERMISSIONS[permission] then
				warn(
					`[{script.Name}] Invalid permission loaded from ConfigService for user ID "{sanitizedUserId}": "{permission}" is not a recognized permission.`
				)
				userPermissions[permission] = nil
				continue
			end
			if typeof(hasPermission) ~= "boolean" then
				warn(
					`[{script.Name}] Invalid permission value loaded from ConfigService for user ID "{sanitizedUserId}" and permission "{permission}": "{hasPermission}" ({typeof(
						hasPermission
					)})`
				)
				userPermissions[permission] = nil
				continue
			end
		end

		-- Overwrite cached permissions.
		permissions[sanitizedUserId] = userPermissions
	end
	return permissions[userId] ~= nil and permissions[userId][permission] == true
end

return table.freeze(PermissionHelper)
