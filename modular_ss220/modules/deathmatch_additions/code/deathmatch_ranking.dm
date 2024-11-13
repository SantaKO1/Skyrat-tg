#define DEATHMATCH_JSON_PATH "data/deathmatch_ratings.json"
#define DEATHMATCH_BACKUP_PATH "data/deathmatch_ratings.json.backup"

GLOBAL_LIST_EMPTY(deathmatch_ratings)

/datum/deathmatch_ranking
	/// Player's ckey
	var/ckey
	/// Current ELO rating
	var/rating = 1200
	/// Total matches played
	var/matches_played = 0
	/// Total kills
	var/kills = 0
	/// Total deaths
	var/deaths = 0
	/// Highest rating achieved
	var/highest_rating = 1200
	/// Longest kill streak
	var/best_streak = 0
	/// Current kill streak
	var/current_streak = 0
	/// Last time rating was updated
	var/last_update = 0

SUBSYSTEM_DEF(deathmatch)
	name = "Deathmatch"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_PERSISTENCE

	/// Whether deathmatch mode is enabled
	var/enabled = FALSE
	/// Minimum rating possible
	var/min_rating = 100
	/// Maximum rating possible
	var/max_rating = 3000
	/// Base K-factor for ELO calculations
	var/base_k_factor = 32
	/// Whether ratings need saving
	var/needs_save = FALSE

/datum/controller/subsystem/deathmatch/Initialize()
	. = ..()
	enabled = TRUE
	load_ratings()

/datum/controller/subsystem/deathmatch/proc/load_ratings()
	if(fexists(DEATHMATCH_JSON_PATH))
		var/json_data = file2text(DEATHMATCH_JSON_PATH)
		if(!json_data)
			log_game("Failed to load deathmatch ratings - empty JSON file")
			return

		try
			var/list/loaded_data = json_decode(json_data)
			for(var/ckey in loaded_data)
				var/list/player_data = loaded_data[ckey]
				var/datum/deathmatch_ranking/R = new
				R.ckey = ckey
				R.rating = player_data["rating"]
				R.matches_played = player_data["matches_played"]
				R.kills = player_data["kills"]
				R.deaths = player_data["deaths"]
				R.highest_rating = player_data["highest_rating"]
				R.best_streak = player_data["best_streak"]
				R.current_streak = 0 // Reset streak on load
				R.last_update = player_data["last_update"]
				GLOB.deathmatch_ratings[ckey] = R

		catch(var/exception/e)
			log_game("Failed to load deathmatch ratings: [e]")

	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery({"
			CREATE TABLE IF NOT EXISTS [format_table_name("deathmatch_ratings")] (
				ckey VARCHAR(32) NOT NULL PRIMARY KEY,
				rating INT NOT NULL,
				matches_played INT NOT NULL,
				kills INT NOT NULL,
				deaths INT NOT NULL,
				highest_rating INT NOT NULL,
				best_streak INT NOT NULL,
				last_update INT NOT NULL
			) DEFAULT CHARSET=utf8mb4
		"})
		query.Execute()
		qdel(query)

/datum/controller/subsystem/deathmatch/proc/save_ratings()
	var/list/save_data = list()
	for(var/ckey in GLOB.deathmatch_ratings)
		var/datum/deathmatch_ranking/R = GLOB.deathmatch_ratings[ckey]
		save_data[ckey] = list(
			"rating" = R.rating,
			"matches_played" = R.matches_played,
			"kills" = R.kills,
			"deaths" = R.deaths,
			"highest_rating" = R.highest_rating,
			"best_streak" = R.best_streak,
			"last_update" = R.last_update
		)

	// Backup old file
	if(fexists(DEATHMATCH_JSON_PATH))
		fcopy(DEATHMATCH_JSON_PATH, DEATHMATCH_BACKUP_PATH)

	// Write new data
	fdel(DEATHMATCH_JSON_PATH)
	WRITE_FILE(DEATHMATCH_JSON_PATH, json_encode(save_data))

	if(SSdbcore.Connect())
		for(var/ckey in GLOB.deathmatch_ratings)
			var/datum/deathmatch_ranking/R = GLOB.deathmatch_ratings[ckey]
			var/datum/db_query/query = SSdbcore.NewQuery(
				"INSERT INTO [format_table_name("deathmatch_ratings")] \
				(ckey, rating, matches_played, kills, deaths, highest_rating, best_streak, last_update) \
				VALUES (:ckey, :rating, :matches, :kills, :deaths, :highest, :streak, :update) \
				ON DUPLICATE KEY UPDATE \
				rating = :rating, matches_played = :matches, kills = :kills, \
				deaths = :deaths, highest_rating = :highest, best_streak = :streak, \
				last_update = :update",
				list(
					"ckey" = ckey,
					"rating" = R.rating,
					"matches" = R.matches_played,
					"kills" = R.kills,
					"deaths" = R.deaths,
					"highest" = R.highest_rating,
					"streak" = R.best_streak,
					"update" = R.last_update
				)
			)
			query.Execute()
			qdel(query)

	needs_save = FALSE

/datum/controller/subsystem/deathmatch/proc/update_player_stats(mob/killer, mob/victim, is_kill = TRUE)
	if(!enabled || !killer?.ckey || !victim?.ckey)
		return

	var/datum/deathmatch_ranking/killer_rating = get_or_create_rating(killer.ckey)
	var/datum/deathmatch_ranking/victim_rating = get_or_create_rating(victim.ckey)

	if(is_kill)
		// Update kill counts
		killer_rating.kills++
		victim_rating.deaths++

		// Update streaks
		killer_rating.current_streak++
		victim_rating.current_streak = 0
		killer_rating.best_streak = max(killer_rating.current_streak, killer_rating.best_streak)

		// Calculate ELO changes
		var/k_factor = base_k_factor
		if(killer_rating.matches_played < 30)
			k_factor *= 2

		var/expected_score = 1 / (1 + (10 ** ((victim_rating.rating - killer_rating.rating) / 400)))
		var/rating_change = round(k_factor * (1 - expected_score))

		// Apply rating changes
		killer_rating.rating = clamp(killer_rating.rating + rating_change, min_rating, max_rating)
		victim_rating.rating = clamp(victim_rating.rating - rating_change, min_rating, max_rating)

		// Update highest ratings
		killer_rating.highest_rating = max(killer_rating.rating, killer_rating.highest_rating)
		victim_rating.highest_rating = max(victim_rating.rating, victim_rating.highest_rating)

	killer_rating.last_update = world.time
	victim_rating.last_update = world.time
	needs_save = TRUE

/datum/controller/subsystem/deathmatch/proc/get_or_create_rating(ckey)
	if(!ckey)
		return

	if(!GLOB.deathmatch_ratings[ckey])
		var/datum/deathmatch_ranking/R = new
		R.ckey = ckey
		GLOB.deathmatch_ratings[ckey] = R
		needs_save = TRUE

	return GLOB.deathmatch_ratings[ckey]

/datum/controller/subsystem/deathmatch/proc/update_match_stats(list/players)
	for(var/ckey in players)
		var/datum/deathmatch_ranking/R = get_or_create_rating(ckey)
		if(R)
			R.matches_played++
			R.current_streak = 0
			R.last_update = world.time
			needs_save = TRUE

/datum/controller/subsystem/deathmatch/proc/update_rating(mob/killer, mob/victim)
	update_player_stats(killer, victim, TRUE)

/datum/controller/subsystem/deathmatch/proc/update_kill_stats(mob/killer, mob/victim)
	update_player_stats(killer, victim, TRUE)

/datum/controller/subsystem/deathmatch/proc/get_player_ranking_data(ckey)
	var/datum/deathmatch_ranking/R = get_or_create_rating(ckey)
	if(!R)
		return null

	return list(
		"current" = R.rating,
		"highest" = R.highest_rating,
		"kills" = R.kills,
		"deaths" = R.deaths,
		"matches" = R.matches_played,
		"streak" = R.current_streak,
		"best_streak" = R.best_streak
	)

#undef DEATHMATCH_JSON_PATH
#undef DEATHMATCH_BACKUP_PATH
