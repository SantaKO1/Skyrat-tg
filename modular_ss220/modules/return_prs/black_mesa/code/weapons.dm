/obj/item/crowbar/freeman
	name = "blood soaked crowbar"
	desc = "A heavy handed crowbar, it drips with blood."
	icon = 'modular_ss220/modules/return_prs/black_mesa/icons/misc/freeman.dmi'
	icon_state = "crowbar"
	force = 35
	throwforce = 45
	toolspeed = 0.1
	wound_bonus = 10
	hitsound = 'modular_nova/master_files/sound/weapons/crowbar2.ogg'
	mob_throw_hit_sound = 'modular_nova/master_files/sound/weapons/crowbar2.ogg'
	force_opens = TRUE

/obj/item/crowbar/freeman/ultimate
	name = "\improper Freeman's crowbar"
	desc = "A weapon wielded by an ancient physicist, the blood of hundreds seeps through this rod of iron and malice."
	force = 45

/obj/item/crowbar/freeman/ultimate/Initialize(mapload)
	. = ..()
	add_filter("rad_glow", 2, list("type" = "outline", "color" = "#fbff1479", "size" = 2))

/obj/item/shield/riot/pointman/hecu
	name = "ballistic shield"
	desc = "A shield fit for those that want to sprint headfirst into the unknown! Cumbersome as hell."
	icon_state = "ballistic"
	icon = 'modular_ss220/modules/return_prs/black_mesa/icons/misc/ballistic.dmi'
	worn_icon_state = "ballistic_worn"
	worn_icon = 'modular_ss220/modules/return_prs/black_mesa/icons/misc/ballistic.dmi'
	inhand_icon_state = "ballistic"
	lefthand_file = 'modular_ss220/modules/return_prs/black_mesa/icons/misc/ballistic_l.dmi'
	righthand_file = 'modular_ss220/modules/return_prs/black_mesa/icons/misc/ballistic_r.dmi'
	force = 14
	throwforce = 5
	throw_speed = 1
	throw_range = 1
	block_chance = 45
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	attack_verb_continuous = list("shoves", "bashes")
	attack_verb_simple = list("shove", "bash")
	transparent = TRUE
	max_integrity = 150
	shield_break_leftover = /obj/item/ballistic_broken

/obj/item/ballistic_broken
	name = "broken ballistic shield"
	desc = "An unsalvageable, unrecoverable mess of armor steel and kevlar. Should've maintained it, huh?"
	icon_state = "ballistic_broken"
	icon = 'modular_ss220/modules/return_prs/black_mesa/icons/misc/ballistic.dmi'
	w_class = WEIGHT_CLASS_BULKY
