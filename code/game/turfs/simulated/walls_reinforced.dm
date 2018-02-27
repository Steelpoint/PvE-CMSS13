/turf/simulated/wall/r_wall
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to seperate rooms."
	icon_state = "r_wall"
	opacity = 1
	density = 1

	damage_cap = 3000
	max_temperature = 6000

	walltype = "rwall"

/turf/simulated/wall/r_wall/attack_hand(mob/user as mob)
	if (HULK in user.mutations)
		if (prob(10) || rotting)
			usr << text("\blue You smash through the wall.")
			usr.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))
			dismantle_wall(1)
			return
		else
			usr << text("\blue You punch the wall.")
			return

	if(rotting)
		user << "\blue This wall feels rather unstable."
		return

	add_fingerprint(user)

/turf/simulated/wall/r_wall/attackby(obj/item/W as obj, mob/user as mob)

	if (!(istype(user, /mob/living/carbon/human) || ticker) && ticker.mode.name != "monkey")
		user << "<span class='warning'>You don't have the dexterity to do this!</span>"
		return

	//get the user's location
	if( !istype(user.loc, /turf) )	return	//can't do this stuff whilst inside objects and such

	if(rotting)
		if(W.heat_source >= 3000)
			if(istype(W, /obj/item/tool/weldingtool))
				var/obj/item/tool/weldingtool/WT = W
				WT.remove_fuel(0,user)
			user << "<span class='notice'>You burn away the fungi with \the [W].</span>"
			playsound(src, 'sound/items/Welder.ogg', 25, 1)
			for(var/obj/effect/E in src) if(E.name == "Wallrot")
				cdel(E)
			rotting = 0
			return
		else if(!is_sharp(W) && W.force >= 10 || W.force >= 20)
			user << "<span class='notice'>\The [src] crumbles away under the force of your [W.name].</span>"
			src.dismantle_wall()
			return

	//THERMITE related stuff. Calls src.thermitemelt() which handles melting simulated walls and the relevant effects
	if(thermite)
		if(W.heat_source >= 1000)
			if(hull)
				user << "<span class='warning'>[src] is much too tough for you to do anything to it with [W]</span>."
			else
				if(istype(W, /obj/item/tool/weldingtool))
					var/obj/item/tool/weldingtool/WT = W
					WT.remove_fuel(0,user)
				thermitemelt(user)
			return

	if(damage && istype(W, /obj/item/tool/weldingtool))
		var/obj/item/tool/weldingtool/WT = W
		if(WT.remove_fuel(0,user))
			user << "<span class='notice'>You start repairing the damage to [src].</span>"
			playsound(src, 'sound/items/Welder.ogg', 25, 1)
			if(do_after(user, max(5, damage / 5, TRUE, 5, BUSY_ICON_CLOCK)) && WT && WT.isOn())
				user << "<span class='notice'>You finish repairing the damage to [src].</span>"
				take_damage(-damage)
			return
		else
			user << "<span class='warning'>You need more welding fuel to complete this task.</span>"
			return

	var/turf/T = user.loc	//get user's location for delay checks

	//DECONSTRUCTION
	switch(d_state)
		if(0)
			if (istype(W, /obj/item/tool/wirecutters))
				playsound(src, 'sound/items/Wirecutter.ogg', 25, 1)
				src.d_state = 1
				src.icon_state = "r_wall-1"
				new /obj/item/stack/rods( src )
				user << "<span class='notice'>You cut the outer grille.</span>"
				return

		if(1)
			if (istype(W, /obj/item/tool/screwdriver))
				user << "<span class='notice'>You begin removing the support lines.</span>"
				playsound(src, 'sound/items/Screwdriver.ogg', 25, 1)

				sleep(40)
				if( !istype(src, /turf/simulated/wall/r_wall) || !user || !W || !T )	return

				if( d_state == 1 && user.loc == T && user.get_active_hand() == W )
					src.d_state = 2
					src.icon_state = "r_wall-2"
					user << "<span class='notice'>You remove the support lines.</span>"
				return

			//REPAIRING (replacing the outer grille for cosmetic damage)
			else if( istype(W, /obj/item/stack/rods) )
				var/obj/item/stack/O = W
				src.d_state = 0
				src.icon_state = "r_wall"
				relativewall_neighbours()	//call smoothwall stuff
				user << "<span class='notice'>You replace the outer grille.</span>"
				if (O.amount > 1)
					O.amount--
				else
					cdel(O)
				return

		if(2)
			if( istype(W, /obj/item/tool/weldingtool) )
				var/obj/item/tool/weldingtool/WT = W
				if( WT.remove_fuel(0,user) )

					user << "<span class='notice'>You begin slicing through the metal cover.</span>"
					playsound(src, 'sound/items/Welder.ogg', 25, 1)

					sleep(60)
					if( !istype(src, /turf/simulated/wall/r_wall) || !user || !WT || !WT.isOn() || !T )	return

					if( d_state == 2 && user.loc == T && user.get_active_hand() == WT )
						src.d_state = 3
						src.icon_state = "r_wall-3"
						user << "<span class='notice'>You press firmly on the cover, dislodging it.</span>"
				else
					user << "<span class='notice'>You need more welding fuel to complete this task.</span>"
				return

			if( istype(W, /obj/item/tool/pickaxe/plasmacutter) )

				user << "<span class='notice'>You begin slicing through the metal cover.</span>"
				playsound(src, 'sound/items/Welder.ogg', 25, 1)

				sleep(40)
				if( !istype(src, /turf/simulated/wall/r_wall) || !user || !W || !T )	return

				if( d_state == 2 && user.loc == T && user.get_active_hand() == W )
					src.d_state = 3
					src.icon_state = "r_wall-3"
					user << "<span class='notice'>You press firmly on the cover, dislodging it.</span>"
				return

		if(3)
			if (istype(W, /obj/item/tool/crowbar))

				user << "<span class='notice'>You struggle to pry off the cover.</span>"
				playsound(src, 'sound/items/Crowbar.ogg', 25, 1)

				sleep(100)
				if( !istype(src, /turf/simulated/wall/r_wall) || !user || !W || !T )	return

				if( d_state == 3 && user.loc == T && user.get_active_hand() == W )
					src.d_state = 4
					src.icon_state = "r_wall-4"
					user << "<span class='notice'>You pry off the cover.</span>"
				return

		if(4)
			if (istype(W, /obj/item/tool/wrench))

				user << "<span class='notice'>You start loosening the anchoring bolts which secure the support rods to their frame.</span>"
				playsound(src, 'sound/items/Ratchet.ogg', 25, 1)

				sleep(40)
				if( !istype(src, /turf/simulated/wall/r_wall) || !user || !W || !T )	return

				if( d_state == 4 && user.loc == T && user.get_active_hand() == W )
					src.d_state = 5
					src.icon_state = "r_wall-5"
					user << "<span class='notice'>You remove the bolts anchoring the support rods.</span>"
				return

		if(5)
			if( istype(W, /obj/item/tool/weldingtool) )
				var/obj/item/tool/weldingtool/WT = W
				if( WT.remove_fuel(0,user) )

					user << "<span class='notice'>You begin slicing through the support rods.</span>"
					playsound(src, 'sound/items/Welder.ogg', 25, 1)

					sleep(100)
					if( !istype(src, /turf/simulated/wall/r_wall) || !user || !WT || !WT.isOn() || !T )	return

					if( d_state == 5 && user.loc == T && user.get_active_hand() == WT )
						src.d_state = 6
						src.icon_state = "r_wall-6"
						new /obj/item/stack/rods( src )
						user << "<span class='notice'>The support rods drop out as you cut them loose from the frame.</span>"
				else
					user << "<span class='notice'>You need more welding fuel to complete this task.</span>"
				return

			if( istype(W, /obj/item/tool/pickaxe/plasmacutter) )

				user << "<span class='notice'>You begin slicing through the support rods.</span>"
				playsound(src, 'sound/items/Welder.ogg', 25, 1)

				sleep(70)
				if( !istype(src, /turf/simulated/wall/r_wall) || !user || !W || !T )	return

				if( d_state == 5 && user.loc == T && user.get_active_hand() == W )
					src.d_state = 6
					src.icon_state = "r_wall-6"
					new /obj/item/stack/rods( src )
					user << "<span class='notice'>The support rods drop out as you cut them loose from the frame.</span>"
				return

		if(6)
			if( istype(W, /obj/item/tool/crowbar) )

				user << "<span class='notice'>You struggle to pry off the outer sheath.</span>"
				playsound(src, 'sound/items/Crowbar.ogg', 25, 1)

				sleep(100)
				if( !istype(src, /turf/simulated/wall/r_wall) || !user || !W || !T )	return

				if( user.loc == T && user.get_active_hand() == W )
					user << "<span class='notice'>You pry off the outer sheath.</span>"
					dismantle_wall()
				return

//vv OK, we weren't performing a valid deconstruction step or igniting thermite,let's check the other possibilities vv

	//DRILLING
	if (istype(W, /obj/item/tool/pickaxe/diamonddrill))

		user << "<span class='notice'>You begin to drill though the wall.</span>"

		sleep(200)
		if( !istype(src, /turf/simulated/wall/r_wall) || !user || !W || !T )	return

		if( user.loc == T && user.get_active_hand() == W )
			user << "<span class='notice'>Your drill tears though the last of the reinforced plating.</span>"
			dismantle_wall()

	//REPAIRING
	else if( istype(W, /obj/item/stack/sheet/metal) && d_state )
		var/obj/item/stack/sheet/metal/MS = W

		user << "<span class='notice'>You begin patching-up the wall with \a [MS].</span>"

		sleep( max(20*d_state,100) )	//time taken to repair is proportional to the damage! (max 10 seconds)
		if( !istype(src, /turf/simulated/wall/r_wall) || !user || !MS || !T )	return

		if( user.loc == T && user.get_active_hand() == MS && d_state )
			src.d_state = 0
			src.icon_state = "r_wall"
			relativewall_neighbours()	//call smoothwall stuff
			user << "<span class='notice'>You repair the last of the damage.</span>"
			if (MS.amount > 1)
				MS.amount--
			else
				cdel(MS)

	//APC
	else if( istype(W,/obj/item/frame/apc) )
		var/obj/item/frame/apc/AH = W
		AH.try_build(src)

	else if( istype(W,/obj/item/frame/air_alarm) )
		var/obj/item/frame/air_alarm/AH = W
		AH.try_build(src)

	else if(istype(W,/obj/item/frame/fire_alarm))
		var/obj/item/frame/fire_alarm/AH = W
		AH.try_build(src)
		return

	else if(istype(W,/obj/item/frame/light_fixture))
		var/obj/item/frame/light_fixture/AH = W
		AH.try_build(src)
		return

	else if(istype(W,/obj/item/frame/light_fixture/small))
		var/obj/item/frame/light_fixture/small/AH = W
		AH.try_build(src)
		return

	//Poster stuff
	else if(istype(W,/obj/item/contraband/poster))
		place_poster(W,user)
		return

	return



/turf/simulated/wall/r_wall/can_be_dissolved()
	if(hull)
		return 0
	else
		return 2


//Just different looking wall
/turf/simulated/wall/r_wall/research
	icon_state = "research"
	walltype = "research"

/turf/simulated/wall/r_wall/dense
	icon_state = "iron0"
	walltype = "iron"

/turf/simulated/wall/r_wall/unmeltable
	name = "heavy reinforced wall"
	desc = "A huge chunk of ultra-reinforced metal used to seperate rooms. Looks virtually indestructible."
	icon_state = "r_wall"
	walltype = "rwall"
	hull = 1

	ex_act(severity) //Should make it indestructable
		return

	fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
		return

	attackby() //This should fix everything else. No cables, etc
		return
