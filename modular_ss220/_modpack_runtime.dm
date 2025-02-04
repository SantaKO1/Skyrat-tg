/**
 * Toggles a modpacks enabled state and handles dependencies
 *
 * params:
 * * modpack_id - string ID of modpack to modify
 * * enable - boolean TRUE to enable, FALSE to disable
 */
/datum/controller/subsystem/modpacks/proc/set_modpack_enabled(modpack_id, enable)
	var/datum/modpack/package = loaded_modpacks_assoc[modpack_id]
	if(!package || package.enabled == enable)
		return FALSE

	if(enable)
		for(var/dependency_id in package.mod_depends)
			var/datum/modpack/dep = loaded_modpacks_assoc[dependency_id]
			if(!dep?.enabled)
				return FALSE

	package.enabled = enable
	if(enable)
		package.on_enable()
	else
		package.on_disable()
		var/list/to_process = package.dependents.Copy()
		while(length(to_process))
			var/datum/modpack/current = to_process[1]
			to_process.Cut(1, 2)
			if(current.enabled)
				current.enabled = FALSE
				current.on_disable()
				to_process += current.dependents

	return TRUE

/datum/modpack/proc/on_enable()
	SHOULD_CALL_PARENT(TRUE)

/datum/modpack/proc/on_disable()
	SHOULD_CALL_PARENT(TRUE)
