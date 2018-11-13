/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-=-+CARDS+-=-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */

/* ----- TO DO -----
 - throwing a hand/stack/deck scatters the cards
 - throwing a card has a chance of being a good throw and doing a little damage
 - cheaty stuff
 - uno?
 - add cards to hats (fedoras?) (lol)
   ----------------- */

/playing_card
	var/card_name = "playing card"
	var/card_desc = "A card, for playing some kinda game with."
	var/card_face = "blank"
	var/card_back = "suit"
	var/card_foil = 0
	var/card_data = null
	var/card_reversible = 0 // can the card be drawn reversed? ie for tarot
	var/card_reversed = 0 // IS it reversed?
	var/card_tappable = 1 // tap 2 islands for mana
	var/card_tapped = 0 // summon Fog Bank, laugh
	var/card_spooky = 0

	New(cardname, carddesc, cardback, cardface, cardfoil, carddata, cardreversible, cardreversed, cardtappable, cardtapped, cardspooky)
		if (cardname) card_name = cardname
		if (carddesc) card_desc = carddesc
		if (cardback) card_back = cardback
		if (cardface) card_face = cardface
		if (cardfoil) card_foil = cardfoil
		if (carddata) card_data = carddata
		if (cardreversible) card_reversible = cardreversible
		if (cardreversed) card_reversed = cardreversed
		if (cardtappable) card_tappable = cardtappable
		if (cardtapped) card_tapped = cardtapped
		if (cardspooky) card_spooky = cardspooky

	proc/examine_data()
		return card_data

/obj/item/playing_cards
	name = "deck of cards"
	desc = "Some cards, all in a neat stack, for playing some kinda game with."
	icon = 'icons/obj/playing_card.dmi'
	icon_state = "deck-suit"
	w_class = 1.0
	force = 0
	throwforce = 0
	burn_point = 220
	burn_output = 500
	burn_possible = 1
	health = 10
	var/list/cards = list()
	var/face_up = 0
	var/card_name = "blank card"
	var/card_desc = "A playing card."
	var/card_face = "blank"
	var/card_back = "suit"
	var/card_foil = 0
	var/card_data = null
	var/last_shown_off = null
	var/spooky = 0
	var/card_reversible = 0 // can it be drawn reversed?
	var/card_reversed = 0 // IS it reversed?
	var/card_tappable = 1 // tap dat shit
	var/card_tapped = 0

	New()
		..()
		pixel_x = rand(-12, 12)
		pixel_y = rand(-12, 12)

	proc/update_cards()
		if (!cards.len)
			qdel(src)
			return

		overlays = null
		switch (cards.len)
			if (-INFINITY to 0)
				qdel(src)
				return
			if (1)
				for (var/playing_card/Card in cards)
					card_name = Card.card_name
					card_desc = Card.card_desc
					card_face = Card.card_face
					card_back = Card.card_back
					card_foil = Card.card_foil
					card_data = Card.examine_data()
					card_reversible = Card.card_reversible
					card_reversed = Card.card_reversed
					spooky = Card.card_spooky
				if (face_up)
					if (card_reversible && card_reversed)
						name = "reversed [card_name]"
						dir = NORTH
					else if (card_tappable && card_tapped)
						name = "tapped [card_name]"
						if (card_tapped == EAST)
							dir = EAST
						else if (card_tapped == WEST)
							dir = WEST
						else
							dir = pick(EAST, WEST)
							card_tapped = dir
					else
						name = card_name
						dir = SOUTH
					desc = "[card_desc] It's \an [name]."
					icon_state = "card-[card_face]"
					if (card_foil)
						overlays += "card-foil"
				else
					desc = card_desc
					icon_state = "back-[card_back]"
					if (card_tappable && card_tapped)
						name = "tapped playing card"
						if (card_tapped == EAST)
							dir = EAST
						else if (card_tapped == WEST)
							dir = WEST
						else
							dir = pick(EAST, WEST)
							card_tapped = dir
					else
						name = "playing card"
						dir = SOUTH
			if (2 to 4)
				name = "hand of cards"
				desc = "Some cards, for playing some kinda game with."
				icon_state = "hand-[card_back][cards.len]"
				if (face_up)
					face_up = 0
			if (5 to 10)
				name = "hand of cards"
				desc = "Some cards, for playing some kinda game with."
				icon_state = "hand-[card_back]5"
				if (face_up)
					face_up = 0
			if (11 to 19)
				name = "stack of cards"
				desc = "Some cards, all in a neat stack, for playing some kinda game with."
				icon_state = "stack-[card_back]"
				if (face_up)
					face_up = 0
			if (20 to INFINITY)
				name = "deck of cards"
				desc = "Some cards, all in a neat stack, for playing some kinda game with."
				icon_state = "deck-[card_back]"
				if (face_up)
					face_up = 0

	proc/draw_card(var/obj/item/playing_cards/CardStack, var/atom/target as turf|obj|mob, var/draw_face_up = 0, var/playing_card/Card)
		if (!cards.len)
			qdel(src)
			return null

		if (!CardStack || !istype(CardStack, /obj/item/playing_cards))
			CardStack = new /obj/item/playing_cards(loc)
			CardStack.face_up = draw_face_up
			if (target)
				if (ismob(target))
					target:put_in_hand_or_drop(CardStack)
				else
					CardStack.set_loc(target.loc)
		if (!Card || !istype(Card, /playing_card))
			Card = cards[1]
		CardStack.cards += Card
		cards -= Card
		CardStack.update_cards()
		update_cards()
		return CardStack

	proc/add_cards(var/obj/item/playing_cards/CardStack)
		if (!CardStack)
			return
		if (!CardStack.cards.len)
			qdel(CardStack)
			return

		for (var/playing_card/Card in CardStack.cards)
			Card = CardStack.cards[1]
			cards += Card
			CardStack.cards -= Card
			CardStack.update_cards()
			update_cards()

	get_desc(dist)
		update_cards()
		if (dist <= 0 && cards.len == 1 && !face_up)
			. += "It's \an [card_name]."
		if (cards.len == 1 && face_up)
			var/playing_card/Card = cards[1]
			. += Card.examine_data()
		if (dist <= 0 && cards.len >= 2 && cards.len <= 10)
			var/seen_hand = ""
			for (var/playing_card/Card in cards)
				seen_hand += "\an [Card.card_name], "
			var/final_seen_hand = copytext(seen_hand, 1, -2)
			. += "It has [src.cards.len] cards: [final_seen_hand]."
		if (dist <= 0 && cards.len >= 11)
			. += "There's [src.cards.len] cards in the [src.cards.len <= 19 ? "stack" : "deck"]."

	MouseDrop(var/atom/target as obj|mob)
		if (!cards.len)
			qdel(src)
			return
		if (!target)
			return
		if (usr.stat == 2 && !spooky)
			boutput(usr, "<span style=\"color:red\">Ghosts dealing cards? That's too spooky!</span>")
			return
		if (get_dist(usr, src) > 1)
			boutput(usr, "<span style=\"color:red\">You're too far from [src] to draw a card!</span>")
			return
		if (get_dist(usr, target) > 1)
			if (istype(target, /obj/screen/hud))
				var/obj/screen/hud/hud = target
				if (istype(hud.master, /hud/human))
					var/hud/human/h_hud = hud.master // all this just to see if you're trying to deal to someone's hand, ffs
					if (h_hud.master && h_hud.master == usr) // or their face, I guess.  it'll apply to any attempts to deal to your hud
						target = usr
					else
						boutput(usr, "<span style=\"color:red\">You're too far away from [target] to deal a card!</span>")
						return
				else
					boutput(usr, "<span style=\"color:red\">You're too far away from [target] to deal a card!</span>")
					return
			else
				boutput(usr, "<span style=\"color:red\">You're too far away from [target] to deal a card!</span>")
				return

		var/deal_face_up = 0
		var/playing_card/Card = cards[1]
		if (usr.a_intent != INTENT_HELP)
			deal_face_up = 1
		if (usr.a_intent == INTENT_GRAB && cards.len > 1)
			usr.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> looks through [src].</span>",\
			"<span style=\"color:blue\">You look through [src].</span>")
			deal_face_up = 0
			var/list/availableCards = list()
			for (var/playing_card/listCard in cards)
				availableCards += "[listCard.card_name]"
			boutput(usr, "<span style=\"color:blue\">What card would you like to deal from [src]?</span>")
			var/chosenCard = input("Select a card to deal.", "Choose Card") as null|anything in availableCards
			if (!chosenCard)
				return
			for (var/playing_card/findCard in cards)
				if (findCard.card_name == chosenCard)
					Card = findCard
					break

		var/stupid_var = "[deal_face_up ? "\an [Card.card_name]" : "[src]"]"
		var/other_stupid_var = "[deal_face_up ? " \an [Card.card_name]." : "a card"]"

		if (cards.len == 1)
			if (target == src && card_tappable)
				if (card_tapped)
					usr.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> untaps [src].</span>",\
					"<span style=\"color:blue\">You untap [src].</span>")
					card_tapped = null
					update_cards()
				else
					usr.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> taps [src].</span>",\
					"<span style=\"color:blue\">You tap [src].</span>")
					card_tapped = pick(EAST, WEST)
					update_cards()
			else if (ismob(target))
				usr.tri_message("<span style=\"color:blue\"><strong>[usr]</strong> takes [stupid_var][usr == target ? "." : " and deals it to [target]."]</span>",\
				usr, "<span style=\"color:blue\">You take [stupid_var][usr == target ? "." : " and deal it to [target]."]</span>", \
				target, "<span style=\"color:blue\">[target == usr ? "You take" : "<strong>[usr]</strong> takes"] [stupid_var][target == usr ? "." : " and deals it to you."]</span>")
				draw_card(null, target, deal_face_up, Card)
			else if (istype(target, /obj/table))
				usr.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> takes [stupid_var] and places it on [target].</span>",\
				"<span style=\"color:blue\">You take [stupid_var] and place it on [target].</span>")
				draw_card(null, target, deal_face_up, Card)
			else if (istype(target, /obj/item/playing_cards))
				usr.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> takes [stupid_var] and adds it to [target].</span>",\
				"<span style=\"color:blue\">You take [stupid_var] and add it to [target].</span>")
				draw_card(target, null, deal_face_up, Card)
			else
				boutput(usr, "<span style=\"color:red\">What exactly are you trying to accomplish by giving [target] a card? [target] can't use it!</span>")
				return

		else
			if (ismob(target))
				usr.tri_message("<span style=\"color:blue\"><strong>[usr]</strong> draws [other_stupid_var] from [src][usr == target ? "." : " and deals it to [target]."]</span>",\
				usr, "<span style=\"color:blue\">You draw [other_stupid_var] from [src][usr == target ? "." : " and deal it to [target]."]</span>", \
				target, "<span style=\"color:blue\">[target == usr ? "You draw" : "<strong>[usr]</strong> draws"] a card from [src][target == usr ? "." : " and deals it to you."]</span>")
				draw_card(null, target, deal_face_up, Card)
			else if (istype(target, /obj/table))
				usr.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> draws [other_stupid_var] from [src] and places it on [target].</span>",\
				"<span style=\"color:blue\">You draw [other_stupid_var] from [src] and place it on [target].[other_stupid_var]</span>")
				draw_card(null, target, deal_face_up, Card)
			else if (istype(target, /obj/item/playing_cards))
				usr.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> draws [other_stupid_var] from [src] and adds it to [target].</span>",\
				"<span style=\"color:blue\">You draw [other_stupid_var] from [src] and add it to [target].</span>")
				draw_card(target, null, deal_face_up, Card)
			else
				boutput(usr, "<span style=\"color:red\">What exactly are you trying to accomplish by dealing [target] a card? [target] can't use it!</span>")
				return

	attack_hand(mob/user as mob)
		if (get_dist(user, src) <= 0 && cards.len)
			if (user.l_hand == src || user.r_hand == src)
				var/draw_face_up = 0
				if (user.a_intent != INTENT_HELP)
					draw_face_up = 1
				if (user.a_intent == INTENT_GRAB && cards.len > 1)
					user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> looks through [src].</span>",\
					"<span style=\"color:blue\">You look through [src].</span>")
					var/list/availableCards = list()
					for (var/playing_card/Card in cards)
						availableCards += "[Card.card_name]"
					boutput(user, "<span style=\"color:blue\">What card would you like to draw from [src]?</span>")
					var/chosenCard = input("Select a card to draw.", "Choose Card") as null|anything in availableCards
					if (!chosenCard)
						return
					var/playing_card/cardToGive
					for (var/playing_card/Card in cards) // this is so shitty and janky but idgaf right now -barf-
						if (Card.card_name == chosenCard)
							cardToGive = Card
							break
					if (!cardToGive)
						return
					user.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> draws a card from [src].</span>",\
					"<span style=\"color:blue\">You draw \an [chosenCard] from [src].</span>")
					draw_card(null, user, draw_face_up, cardToGive)
				else
					var/playing_card/Card = cards[1]
					user.visible_message("<span style=\"color:blue\"><strong>[usr]</strong> draws [draw_face_up ? "\an [Card.card_name]" : "a card"] from [src].</span>",\
					"<span style=\"color:blue\">You draw [draw_face_up ? "\an [Card.card_name]" : "a card"] from [src].</span>")
					draw_card(null, user, draw_face_up)
			else return ..(user)
		else return ..(user)

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/playing_cards))
			var/obj/item/playing_cards/C = W
			add_cards(C)
			user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> adds [C] to the bottom of [src].</span>",\
			"<span style=\"color:blue\">You add [C] to the bottom of [src].</span>")
		else return ..()

	attack_self(mob/user as mob)
		if (!cards.len)
			qdel(src)
			return
		if ((last_shown_off + 10) > world.time)
			return
		switch (cards.len)
			if (1)
				face_up = !(face_up)
				update_cards()
				user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> flips the card [face_up ? "face up. It's \an [name]." : "face down."]</span>",\
				"<span style=\"color:blue\">You flip the card [face_up ? "face up. It's \an [name]." : "face down."]</span>")
				last_shown_off = world.time
			if (2 to 10)
				var/shown_hand = ""
				for (var/playing_card/Card in cards)
					shown_hand += "\an [Card.card_name], "
				var/final_shown_hand = copytext(shown_hand, 1, -2)
				user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> shows their hand: [final_shown_hand].</span>",\
				"<span style=\"color:blue\">You show your hand: [final_shown_hand].</span>")
				last_shown_off = world.time
			if (11 to INFINITY)
				cards = shuffle(cards)
				for (var/playing_card/Card in cards)
					if (Card.card_reversible)
						Card.card_reversed = rand(0, 1)
				user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> shuffles [src].</span>",\
				"<span style=\"color:blue\">You shuffle [src].</span>")
				last_shown_off = world.time

/obj/item/playing_cards/suit
	desc = "Some playing cards, all in a neat stack. Each belongs to one of four suits and has a number. Collect all 52!"
	icon_state = "deck-suit"
	card_back = "suit"
	var/list/card_suits = list("hearts", "diamonds", "clubs", "spades")
	var/list/card_numbers = list("ace", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "jack", "queen", "king")

	New()
		..()
		var/playing_card/Card
		for (var/suit in card_suits)
			for (var/num in card_numbers)
				Card = new()
				Card.card_name = "[num] of [suit]"
				Card.card_desc = "A classic playing card."
				Card.card_back = "suit"
				if (suit == "hearts" || suit == "diamonds")
					if (num == "jack" || num == "queen" || num == "king")
						Card.card_face = "R-face"
					else
						Card.card_face = "R-[num]"
				else
					if (num == "jack" || num == "queen" || num == "king")
						Card.card_face = "B-face"
					else
						Card.card_face = "B-[num]"
				cards += Card
		update_cards()

/obj/item/playing_cards/tarot
	desc = "Some tarot cards, all in a neat stack. What will the cards tell you?"
	icon_state = "deck-tarot"
	card_back = "tarot"
	var/list/card_major_arcana = list("The Fool", "The Magician", "The High Priestess", "The Empress", "The Emperor", "The Hierophant",\
	"The Lovers", "The Chariot", "Justice", "The Hermit", "Wheel of Fortune", "Strength", "The Hanged Man", "Death", "Temperance",\
	"The Devil", "The Tower", "The Star", "The Moon", "The Sun", "Judgement", "The World")
	var/list/card_minor_arcana_suits = list("wands", "coins", "cups", "swords")
	var/list/card_minor_arcana_numbers = list("ace", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "page", "knight", "queen", "king")

	New()
		..()
		var/playing_card/Card
		for (var/major in card_major_arcana)
			Card = new()
			Card.card_name = "[major]"
			Card.card_desc = "A tarot card."
			Card.card_back = "tarot"
			Card.card_face = "tarot[rand(1, 10)]"
			Card.card_reversible = 1
			if (spooky) Card.card_spooky = 1
			cards += Card

		for (var/minor in card_minor_arcana_suits)
			for (var/num in card_minor_arcana_numbers)
				Card = new()
				Card.card_name = "[num] of [minor]"
				Card.card_desc = "A tarot card."
				Card.card_back = "tarot"
				Card.card_reversible = 1
				if (spooky) Card.card_spooky = 1
				if (minor == "cups" || minor == "coins")
					if (num == "page" || num == "knight" || num == "queen" || num == "king")
						Card.card_face = "R-face"
					else
						Card.card_face = "R-[num]"
				else
					if (num == "page" || num == "knight" || num == "queen" || num == "king")
						Card.card_face = "B-face"
					else
						Card.card_face = "B-[num]"
				cards += Card

/obj/item/playing_cards/tarot/spooky
	spooky = 1

// Traitor Trading Triumvirate?

/obj/item/playing_cards/trading
	name = "\improper Spacemen the Grifening deck"
	desc = "Some trading cards, all in a neat stack. Buy a booster brick today!"
	icon_state = "deck-trade"
	card_back = "trade"
	var/cards_to_generate = 40
	var/list/card_human = list()
	var/list/card_cyborg = list()
	var/list/card_ai = list()
	var/list/card_type_mob = list()
	var/list/card_type_friend = list()
	var/list/card_type_effect = list()
	var/list/card_type_area = list()
	/*var/list/card_nonhuman = list("Changeling", "Wraith")
	var/list/card_antag = list("Traitor", "Nuclear Operative", "Vampire", "Wizard", "Spy", "Revolutionary")
	var/list/card_friend = list("Hooty McJudgementowl", "Heisenbee", "THE OVERBEE", "Dr. Acula", "Jones", "boogiebot",	"George", "automaton",\
	"Murray", "Marty", "Remy", "Mr. Muggles", "Mrs. Muggles", "Mr. Rathen", "????", "Klaus", "Ol' Harner", "Officer Beepsky", "Tanhony",\
	"Krimpus", "Albert", "fat and sassy space bee", "Bombini")
	var/list/card_weapon = list("cyalume saber", "Russian revolver", "emergency toolbox", "mechanical toolbox", "electrical toolbox", "artistic toolbox",\
	"His Grace", "wrestling belt", "sleepy pen", "energy gun", "riot shotgun", "welding tool", "staple gun", "scalpel", "circular saw", "wrench",\
	"red chainsaw", "chainsaw", "stun baton", "phaser gun", "mini rad-poison-crossbow", "suppressed .22 pistol", "fire extinguisher", "crowbar",\
	"laser gun", "screwdriver", "riot launcher", "grenade", "rolling pin", "beaker full of hellchems", "canister bomb", "tank transfer valve bomb",\
	"broken bottle", "glass shard", "metal rods", "axe", "butcher's knife")
	var/list/card_armor = list("bio suit", "bio hood", "armored bio suit", "paramedic suit", "armored paramedic suit", "firesuit", "gas mask",\
	"emergency gas mask", "hard hat", "emergency suit", "emergency hood", "space suit", "labcoat", "armor vest", "Head of Security's beret",\
	"Head of Security's hat", "captain's armor", "captain's hat", "captain's space suit", "red space suit", "helmet", "bomb disposal suit",\
	"sunglasses", "prescription glasses", "ProDoc Healthgoggles", "Spectroscopic Scanner Goggles", "Optical Meson Scanner", "Optical Thermal Scanner",\
	"latex gloves", "insulated gloves", "bedsheet", "bedsheet cape")*/

	booster
		name = "\improper Spacemen the Grifening booster pack"
		desc = "10 trading cards, in a neat little pack. Collect them all today!"
		icon_state = "pack-trade"
		cards_to_generate = 10

	New()
		..()
		generate_lists() // generate lists to make cards out of
		for (var/i=0, i < cards_to_generate, i++) // try to make cards
			switch(rand(1,10))
				if (1 to 4)
					generate_mob_card()
				if (5 to 7)
					generate_effect_card()
				if (8 to 9)
					generate_friend_card()
				if (10)
					generate_area_card()
		update_cards() // update the appearance of the deck

	proc/generate_lists()
		card_human = list()
		card_cyborg = list()
		card_ai = list()
		for (var/mob/living/carbon/human/H in mobs)
			if (ismonkey(H))
				continue
			if (iswizard(H))
				continue
			if (isnukeop(H))
				continue
			card_human += H
		for (var/mob/living/silicon/robot/R in mobs)
			card_cyborg += R
		for (var/mob/living/silicon/ai/A in mobs)
			card_ai += A
		card_type_mob = subtypesof(/playing_card/griffening/creature/mob)
		card_type_friend = subtypesof(/playing_card/griffening/creature/friend)
		card_type_effect = subtypesof(/playing_card/griffening/effect)
		card_type_area = subtypesof(/playing_card/griffening/area)

	proc/generate_mob_card()
		if (!card_human.len || !card_ai.len || !card_cyborg.len)
			generate_lists()
			if (!card_human.len)
				return FALSE

		var/card_type = null
		if (prob(20))
			card_type = /playing_card/griffening/creature/mob/assistant
		else
			card_type = pick(card_type_mob)
			card_type_mob -= card_type

		var/playing_card/griffening/creature/mob/Card = new card_type()
		Card.card_back = "trade"
		if (prob(10))
			Card.card_foil = 1
		if (istype(Card, /playing_card/griffening/creature/mob/ai))
			Card.card_face = "trade-ai[rand(1, 2)]"
			var/mob/living/silicon/ai/A
			if (card_ai.len)
				A = pick(card_ai)
			var/ai_name
			if (!A)
				ai_name = pick("SHODAN", "GLADOS", "HAL-9000")
			else
				card_ai -= A
				ai_name = A.name
			Card.card_name = "[Card.card_foil ? "foil " : null]AI [ai_name]"
		else if (istype(Card, /playing_card/griffening/creature/mob/cyborg))
			Card.card_face = "trade-borg[rand(1,2)]"
			var/mob/living/silicon/robot/A
			if (card_cyborg.len)
				A = pick(card_cyborg)
			var/robot_name
			if (!A)
				robot_name = "Cyborg [pick("Alpha", "Beta", "Gamma", "Delta", "Xi", "Pi", "Theta")]-[rand(10,99)]"
			else
				card_cyborg -= A
				robot_name = A.name
			if (copytext(robot_name, 1, 8) == "Cyborg ")
				robot_name = copytext(robot_name, 8)
			Card.card_name = "[Card.card_foil ? "foil " : null]Cyborg [robot_name]"
		else
			Card.card_face = "trade-person[rand(1, 10)]"
			var/mob/living/carbon/human/A
			if (card_human.len)
				A = pick(card_human)
			var/human_name
			if (!A)
				human_name = "[pick("Pubbie", "Robust", "Shitty", "Father", "Mother", "Handsome")] [pick("Joe", "Jack", "Bill", "Robert", "Luis", "Damian", "Mike", "Jason", "Jane", "Janet", "Oprah", "Angelina", "Megan", "Jennifer", "Anna")]"
			else
				card_human -= A
				human_name = A.name
			Card.card_name = "[Card.card_foil ? "foil " : null][Card.card_name] [human_name]"

		if (Card.randomized_stats)
			// TODO: This will be unbalanced.
			Card.LVL = rand(0, 10)
			Card.ATK = rand(0, 10) * Card.LVL
			Card.DEF = rand(0, 10) * Card.LVL

		cards += Card

		// I'm temporarily disabling a lot of this until I get everything set up. - Marq
		/*

		var/playing_card/griffening/mob/Card = new()
		Card.card_desc = "A trading card."
		Card.card_back = "trade"
		Card.card_face = "trade-person[rand(1, 10)]"
		var/LVL = rand(0, 10)
		var/ATK = rand(0, 10) * max(LVL, 1) // if the level's 0 we want the stats to not all be 0
		var/DEF = rand(0, 10) * max(LVL, 1)
		Card.LVL = LVL
		Card.ATK = ATK
		Card.DEF = DEF
		Card.attributes = ATTRIBUTE_DEFAULT
		Card.card_data += "ATK [ATK] | DEF [DEF]"
		if (prob(10))
			Card.card_foil = 1

		var/mob/living/carbon/human/H = pick(card_human)

		var/job_name
		var/is_human = 1

		if (prob(5))
			var/nonhuman_chance = 100 * (card_nonhuman.len / (card_nonhuman.len + card_antag.len))
			if (prob(nonhuman_chance))
				job_name = pick(card_nonhuman)
				is_human = 0
			else
				job_name = pick(card_antag)
		else
			var/job/J
			if (prob(10))
				J = pick(job_controls.special_jobs)
			else
				J = pick(job_controls.staple_jobs)
			job_name = J.name

		if (is_human)
			Card.template = generate_human_image(H)
		else
			Card.template = generate_special_mob_image(H, job_name)
			Card.human = 0

		Card.card_name = "[Card.card_foil ? "foil " : ""]LVL [LVL] [job_name] [H.real_name]"

		cards += Card
		card_human -= H*/
		return TRUE

	proc/generate_human_image(var/mob/living/carbon/human/H)
		// Human images are obnoxious.
		var/image/ret = image('icons/mob/human.dmi', "blank", MOB_LIMB_LAYER)
		var/image/human_image = H.human_image
		var/skin_tone = H.bioHolder.mobAppearance.s_tone
		human_image.color = rgb(skin_tone + 220, skin_tone + 220, skin_tone + 220)
		var/gender_t = H.gender == FEMALE ? "f" : "m"
		human_image.icon_state = "chest_[gender_t]"
		ret.overlays += human_image
		human_image.icon_state = "groin_[gender_t]"
		ret.overlays += human_image
		human_image.icon_state = "head"
		ret.overlays += human_image
		human_image.icon_state = "l_arm"
		ret.overlays += human_image
		human_image.icon_state = "r_arm"
		ret.overlays += human_image
		human_image.icon_state = "l_leg"
		ret.overlays += human_image
		human_image.icon_state = "r_leg"
		ret.overlays += human_image
		human_image.icon_state = "hand_right"
		ret.overlays += human_image
		human_image.icon_state = "hand_left"
		ret.overlays += human_image
		human_image.icon_state = "foot_left"
		ret.overlays += human_image
		human_image.icon_state = "foot_right"
		ret.overlays += human_image
		var/image/he_image = image('icons/mob/human_hair.dmi', layer = MOB_FACE_LAYER)
		var/image/bd_image = image('icons/mob/human_hair.dmi', layer = MOB_FACE_LAYER)
		he_image.icon_state = "eyes"
		he_image.color = H.bioHolder.mobAppearance.e_color
		ret.overlays += he_image
		he_image.layer = MOB_HAIR_LAYER2
		he_image.icon_state = "[H.cust_one_state]"
		he_image.color = H.bioHolder.mobAppearance.customization_first_color
		ret.overlays += he_image
		bd_image.icon_state = "[H.cust_two_state]"
		bd_image.color = H.bioHolder.mobAppearance.customization_second_color
		ret.overlays += bd_image
		bd_image.layer = MOB_HAIR_LAYER2
		bd_image.icon_state = "[H.cust_three_state]"
		bd_image.color = H.bioHolder.mobAppearance.customization_third_color
		ret.overlays += bd_image
		return ret

	proc/generate_special_mob_image(var/mob/living/carbon/human/H, var/job_name)
		switch (job_name)
			if ("Wraith")
				return image('icons/mob/mob.dmi', "wraith")
			if ("Changeling")
				return generate_human_image(H)

	/*proc/generate_cyborg_card()
		if (!card_cyborg.len)
			return FALSE

		var/playing_card/griffening/mob/Card = new()
		Card.card_desc = "A trading card."
		Card.card_back = "trade"
		Card.card_face = "trade-borg[rand(1, 2)]"
		var/LVL = rand(0, 10)
		var/ATK = rand(0, 10) * max(LVL, 1)
		var/DEF = rand(0, 10) * max(LVL, 1)
		Card.card_data += "ATK [ATK] | DEF [DEF]"
		if (prob(10))
			Card.card_foil = 1

		var/mob/living/silicon/robot/R = pick(card_cyborg)
		if (prob(5))
			Card.card_name = "[Card.card_foil ? "foil " : ""]LVL [LVL] Emagged Cyborg [R.name]"
		else
			Card.card_name = "[Card.card_foil ? "foil " : ""]LVL [LVL] Cyborg [R.name]"

		cards += Card
		card_cyborg -= R
		return TRUE

	proc/generate_ai_card()
		if (!card_ai.len)
			return FALSE

		var/playing_card/Card = new()
		Card.card_desc = "A trading card."
		Card.card_back = "trade"
		Card.card_face = "trade-ai[rand(1, 2)]"
		var/LVL = rand(0, 10)
		var/ATK = rand(0, 10) * max(LVL, 1)
		var/DEF = rand(0, 10) * max(LVL, 1)
		Card.card_data += "ATK [ATK] | DEF [DEF]"
		if (prob(10))
			Card.card_foil = 1

		var/mob/living/silicon/ai/A = pick(card_ai)
		if (prob(5))
			Card.card_name = "[Card.card_foil ? "foil " : ""]LVL [LVL] Subverted AI [A.name]"
		else
			Card.card_name = "[Card.card_foil ? "foil " : ""]LVL [LVL] AI [A.name]"

		cards += Card
		card_ai -= A
		return TRUE*/

	proc/generate_friend_card()
		if (!card_type_friend.len)
			return FALSE

		var/card_type = pick(card_type_friend)
		var/playing_card/griffening/creature/friend/Card = new card_type()
		Card.card_back = "trade"
		Card.card_face = "trade-general[rand(1, 8)]"
		Card.LVL = rand(0, 10)
		Card.ATK = rand(0, 10) * max(Card.LVL, 1)
		Card.DEF = rand(0, 10) * max(Card.LVL, 1)
		if (prob(10))
			Card.card_foil = 1

		Card.card_name = "[Card.card_foil ? "foil " : ""][Card.card_name]"

		cards += Card
		card_type_friend -= card_type
		return TRUE

	proc/generate_area_card()
		if (!card_type_area.len)
			return FALSE

		var/card_type = pick(card_type_area)
		var/playing_card/griffening/area/Card = new card_type()
		Card.card_back = "trade"
		Card.card_face = "trade-general[rand(1, 8)]"
		if (prob(10))
			Card.card_foil = 1

		Card.card_name = "[Card.card_foil ? "foil " : ""][Card.card_name]"

		cards += Card
		return TRUE

	proc/generate_effect_card()
		if (!card_type_effect.len)
			return FALSE

		var/card_type = pick(card_type_effect)
		var/playing_card/griffening/effect/Card = new card_type()
		Card.card_back = "trade"
		Card.card_face = "trade-general[rand(1, 8)]"
		if (prob(10))
			Card.card_foil = 1

		Card.card_name = "[Card.card_foil ? "foil " : ""][Card.card_name]"

		cards += Card
		return TRUE

/obj/item/card_box
	name = "deck box"
	desc = "A little cardboard box for keeping card decks in. Woah! We're truly in the future with technology like this."
	icon = 'icons/obj/playing_card.dmi'
	icon_state = "box"
	force = 1
	throwforce = 1
	w_class = 2
	var/obj/item/playing_cards/Cards
	var/open = 0
	var/icon_closed = "box"
	var/icon_open = "box-open"
	var/icon_empty = "box-empty"
	var/reusable = 1

	suit
		name = "box of playing cards"
		desc = "A little cardboard box with a standard 52-card deck in it."
		icon_state = "box-suit"
		icon_closed = "box-suit"
		icon_open = "box-suit-open"
		icon_empty = "box-suit-empty"

		New()
			..()
			Cards = new /obj/item/playing_cards/suit(src)

	tarot
		name = "box of tarot cards"
		desc = "A little cardboard box with a 78-card tarot deck in it."
		icon_state = "box-tarot"
		icon_closed = "box-tarot"
		icon_open = "box-tarot-open"
		icon_empty = "box-tarot-empty"

		New()
			..()
			Cards = new /obj/item/playing_cards/tarot(src)

	trading
		name = "\improper Spacemen the Grifening deck box"
		desc = "A little cardboard box with an StG deck in it! Wow!"
		icon_state = "box-trade"
		icon_closed = "box-trade"
		icon_open = "box-trade-open"
		icon_empty = "box-trade-empty"

		New()
			..()
			Cards = new /obj/item/playing_cards/trading(src)

	booster
		name = "\improper Spacemen the Grifening booster pack"
		desc = "A little pack that has more cards to perfect your StG decks with!"
		icon_state = "pack-trade"
		icon_closed = "pack-trade"
		icon_open = "pack-trade-open"
		icon_empty = "pack-trade-empty"
		reusable = 0
		New()
			..()
			Cards = new /obj/item/playing_cards/trading/booster(src)

	attack_self(mob/user as mob)
		if (reusable)
			open = !open
		else if (!open)
			open = 1
		else
			boutput(user, "<span style=\"color:red\">[src] is already open!</span>")
		update_icon()
		return

	attackby(obj/item/W as obj, mob/living/user as mob)
		if (reusable)
			if (istype(W, /obj/item/playing_cards))
				var/obj/item/playing_cards/C = W
				if (!open)
					boutput(user, "<span style=\"color:red\">[src] isn't open, you goof!</span>")
					return

				if (Cards)
					if (Cards.cards.len + C.cards.len > 60)
						boutput(user, "<span style=\"color:red\">You try your best to stuff more cards into [src], but there's just not enough room!</span>")
						return
					else
						boutput(user, "<span style=\"color:blue\">You add [C] to the cards in [src].</span>")
						Cards.add_cards(C)
						return

				if (C.cards.len > 60)
					boutput(user, "<span style=\"color:red\">You try your best to stuff the cards into [src], but there's just not enough room for all of them!</span>")
					return

				user.u_equip(W)
				W.layer = initial(W.layer)
				Cards = W
				W.set_loc(src)
				update_icon()
				boutput(user, "You stuff [W] into [src].")
		else
			return ..()

	attack_hand(mob/user as mob)
		if (loc == user && Cards && open)
			user.put_in_hand_or_drop(Cards)
			boutput(user, "You take [Cards] out of [src].")
			Cards = null
			add_fingerprint(user)
			update_icon()
			return
		return ..()

	proc/update_icon()
		if (open && !Cards)
			icon_state = icon_empty
		else if (open && Cards)
			icon_state = icon_open
		else
			icon_state = icon_closed

/obj/item/paper/card_manual
	name = "paper - 'Playing Card Tips & Tricks'"
	info = {"<ul>
	<li>Click on a card in-hand to flip it over.</li>
	<li>Click on a hand in-hand to show it.</li>
	<li>Click on a deck in-hand to shuffle the cards.</li>
	<li>Click-drag a card, hand or deck onto yourself or someone else to deal a card.</li>
	<li>Click-drag a card, hand or deck onto another set of cards to combine them.</li>
	<li>To draw or deal a card face-up, use any intent other than help.</li>
	<li>To draw or deal a specific card, use grab intent.</li>
	<li>To tap or untap a card, click-drag the card onto itself.</li>
	</ul>"}
