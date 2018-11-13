//CONTENTS:
//Robustris
//Robustris block datum
//Arcade game
//CodeBreaker (aka Mastermind)

#define SETUP_BLOCKS_HORIZ 10
#define SETUP_BLOCKS_VERT 12
#define SETUP_BLOCK_COLOR "565D4B"
#define SETUP_PLAYFIELD_COLOR "7A856A"
#define SETUP_ROTATE_DELAY 5

/computer/file/pda_program/robustris
	name = "Robustris"
	size = 6
	setup_use_process = 1
	var/tmp/list/blocks = null
	var/tmp/list/blockmap = null
	var/tmp/playing = 0
	var/tmp/paused = 0
	var/tmp/last_rotation = 0 //Don't bog down everything spinning blocks!!
	var/tmp/highscore = 0

	var/tmp/robustris_block/active_block = null

	init()
		if (!blocks)
			blocks = list()
			clear_blocks()
			playing = -1

		return

	/* new disposing() pattern should handle this. -singh
	Del()
		clear_blocks()
		..()
	*/

	disposing()
		clear_blocks()

		blocks = null
		if (blockmap)
			blockmap.len = 0
			blockmap = null

		..()

	return_text()
		if (..())
			return

		var/dat = return_text_header()

		dat += {"<center><strong>Robustris<br>
		Score:</strong> [highscore]
	<style type="text/css">
	#playfield
	{
		border: 3px solid;
		background-color: #[SETUP_PLAYFIELD_COLOR];
		height: [16*(SETUP_BLOCKS_VERT+1)]px;
		width: [(16*SETUP_BLOCKS_HORIZ)+6]px;
		overflow-x: hidden;
		overflow-y: hidden;
		word-wrap: break-word;
		position: relative;
	}
	.block
	{
		border: 1px solid
		height: 16px;
		width: 16px;
		position: absolute;
		background: #[SETUP_BLOCK_COLOR];
	}
	</style>

	<div id="playfield"><tt>"}
		for (var/robustris_block/B in blocks)
			dat += "<div class='block'style='bottom: [B.gridy*16]px;left: [B.gridx*16]px'><font color=#[SETUP_BLOCK_COLOR]>#</font></div>"

		dat += "</tt></div>"
		if (playing > -1)
			if (paused)
				dat += "<a href='byond://?src=\ref[src];resume=1'>Resume</a></strong> | "
			else
				dat += "<a href='byond://?src=\ref[src];pause=1'>Pause</a></strong>"

		if (playing < 1)
			dat += "<a href='byond://?src=\ref[src];newgame=1'>New Game</a></strong>"

		dat += {"</center>

	<script language="JavaScript">
		function passkey(){
			var evar=window.event;
			var ourKey=evar.keyCode? evar.keyCode : evar.charCode;
			window.location="byond://?src=\ref[src];movedir=" + ourKey;
		}

		document.onkeypress=passkey
	</script>
	"}

		return dat

	process(var/speedup = 1)
		if (..() || playing<1)
			return

		if (!active_block)
			active_block = generate_new_block()
		else
			var/list/superblock = list(active_block) + active_block.related
			var/robustris_block/stop = null
			for (var/robustris_block/B in superblock)
				var/next_y_position = B.gridy-1
				if (next_y_position >= 0)
					stop = blockmap[B.gridy][B.gridx+1]
					if (stop)
						break
				else
					stop = 1
					break

			if (stop)
				var/game_over = 0
				var/list/check_pass = list()
				for (var/robustris_block/B in superblock)
					// drsingh for index out of bounds
					if (blockmap.len < B.gridy + 1)
						continue

					var/list/blockx = blockmap[B.gridy + 1]
					if (blockx.len < B.gridx + 1)
						continue

					blockmap[B.gridy+1][B.gridx+1] = B
					if (B.gridy > SETUP_BLOCKS_VERT)
						game_over = 1

					if (!(B.gridy in check_pass))
						check_pass += B.gridy

				active_block = null
				if (game_over)
					playing = -1
				else
					check_completion(check_pass)
			else
				for (var/robustris_block/B in superblock)
					B.gridy--


			master.updateSelfDialog()
			if (speedup)
				spawn (5) //Ugh the process loop for items is so slow most of the time
					process(0)

		return

	Topic(href, href_list)
		if (..())
			return

		if (href_list["movedir"])
			if (!active_block || !playing)
				return
			var/movedir = href_list["movedir"]
			switch(movedir)
				if ("97") //A
					move_block(active_block, -1)
				if ("100") //D
					move_block(active_block, 1)
				if ("115") //S
					rotate_block(active_block, 1, -1)
				if ("119") //W
					rotate_block(active_block, -1, 1)
			if (ishuman(usr))
				var/mob/living/carbon/human/H = usr
				if (H.sims)
					H.sims.affectMotive("fun", 0.5)

		else if (href_list["newgame"])
			clear_blocks()
			playing = 1
			paused = 0

		else if (href_list["pause"])
			playing = 0
			paused = 1

		else if (href_list["resume"])
			playing = 1
			paused = 0

		master.add_fingerprint(usr)
		master.updateSelfDialog()
		return

	proc
		clear_blocks()
			for (var/robustris_block/B in blocks)
				qdel(B)

			if (isnull(blocks))
				blocks = list()

			blocks.len = 0
			highscore = 0

			//qdel(blockmap)
			blockmap = new /list(SETUP_BLOCKS_VERT + 3, SETUP_BLOCKS_HORIZ)
			return

		generate_new_block()
			var/robustris_block/newblock = new /robustris_block(rand(1,SETUP_BLOCKS_HORIZ-2),SETUP_BLOCKS_VERT)

			var/block_type = pick(1,2,3,4,20;5)
			switch(block_type)
				if (1) //Square block
					newblock.related += new /robustris_block(newblock.gridx,newblock.gridy+1,newblock)
					newblock.related += new /robustris_block(newblock.gridx+1,newblock.gridy+1,newblock)
					newblock.related += new /robustris_block(newblock.gridx+1,newblock.gridy,newblock)
					newblock.cannot_rotate = 1
				if (2) //L block
					newblock.related += new /robustris_block(newblock.gridx + pick(1,-1),newblock.gridy,newblock)
					newblock.related += new /robustris_block(newblock.gridx,newblock.gridy+1,newblock)
					newblock.related += new /robustris_block(newblock.gridx,newblock.gridy+2,newblock)
				if (3) //T block
					newblock.related += new /robustris_block(newblock.gridx+1,newblock.gridy,newblock)
					newblock.related += new /robustris_block(newblock.gridx-1,newblock.gridy,newblock)
					newblock.related += new /robustris_block(newblock.gridx,newblock.gridy+1,newblock)
				if (4) //That stupid Z block
					newblock.related += new /robustris_block(newblock.gridx,newblock.gridy+1,newblock)
					if (prob(50))
						newblock.related += new /robustris_block(newblock.gridx+1,newblock.gridy+1,newblock)
						newblock.related += new /robustris_block(newblock.gridx+1,newblock.gridy+2,newblock)
					else
						newblock.related += new /robustris_block(newblock.gridx-1,newblock.gridy+1,newblock)
						newblock.related += new /robustris_block(newblock.gridx-1,newblock.gridy+2,newblock)
				if (5) //The rare and treasured line block
					for (var/i=1,i<=3,i++)
						newblock.related += new /robustris_block(newblock.gridx,newblock.gridy+i,newblock)

			blocks += list(newblock) + newblock.related

			return newblock

		//Move a block left or right however far.
		move_block(var/robustris_block/theblock, magnitude=0)
			if (!magnitude)
				return TRUE

			var/list/superblock = list(theblock) + theblock.related
			for (var/robustris_block/B in superblock)
				var/new_x_position = B.gridx + magnitude
				if (new_x_position < 0 || new_x_position >= SETUP_BLOCKS_HORIZ)
					return FALSE

				if (B.gridy < 0 || B.gridy >= SETUP_BLOCKS_VERT)
					return FALSE

				var/test = blockmap[B.gridy+1][new_x_position+1]
				if (test)
					return FALSE

			//I guess we CAN move! Time to all move together!
			for (var/robustris_block/B in superblock)
				B.gridx = B.gridx + magnitude

			return TRUE

		rotate_block(var/robustris_block/theblock, x_adjust=1, y_adjust=-1)
			if (!theblock || theblock.cannot_rotate || ( last_rotation && world.time < (last_rotation + SETUP_ROTATE_DELAY) ))
				return FALSE

			last_rotation = world.time
			var/n = 0
			var/list/new_posx = new /list(theblock.related.len)
			var/list/new_posy = new /list(theblock.related.len)

			//Determine and test new block location for collision.
			for (var/robustris_block/B in theblock.related)
				n++
				var/testx = theblock.gridx + (B.rely * x_adjust)
				var/testy = theblock.gridy + (B.relx * y_adjust)
				if (testx < 0 || testx >= SETUP_BLOCKS_HORIZ || testy < 0)
					return FALSE

				if (!isnull(blockmap[testy + 1][testx + 1]))
					return FALSE

				new_posx[n] = testx
				new_posy[n] = testy

			//If everything is OK then go ahead and move them.
			n = 0
			for (var/robustris_block/B in theblock.related)
				n++
				B.gridx = new_posx[n]
				B.relx = B.gridx - theblock.gridx
				B.gridy = new_posy[n]
				B.rely = B.gridy - theblock.gridy

			return TRUE

		check_completion(var/list/rows_to_shift = list())
			for (var/iy in rows_to_shift)
				for (var/ix=1,ix <= SETUP_BLOCKS_HORIZ, ix++)
					var/robustris_block/check = blockmap[iy+1][ix]
					if (isnull(check))
						rows_to_shift -= iy
						break

			if (rows_to_shift.len)
				for (var/n in rows_to_shift)
					blockmap.Cut(n+1,n+2)
				blockmap += new /list(rows_to_shift.len, SETUP_BLOCKS_HORIZ)

				for (var/robustris_block/B in blocks)
					if (B.gridy in rows_to_shift)
						blocks -= B
						qdel(B)
						continue
					else
						var/shift_count = 0
						for (var/n in rows_to_shift)
							if (n < B.gridy)
								shift_count++

						B.gridy -= shift_count

				highscore += (100 * rows_to_shift.len)

			return

/robustris_block
	var/gridx = 0
	var/gridy = 0
	var/list/related = list()
	var/cannot_rotate = 0 //Don't even bother trying!
	var/relx = 0
	var/rely = 0 //Coordinates relative to an origin block.

	New(var/starting_x=0,var/starting_y=0,var/robustris_block/origin)
		..()
		gridx = starting_x
		gridy = starting_y
		if (origin)
			relx = gridx - origin.gridx
			rely = gridy - origin.gridy

		return

/computer/file/pda_program/arcade
	name = "Arcade 250"
	size = 8
	var/enemy_name = "Space Villian"
	var/temp = "Winners Don't Use Spacedrugs" //Temporary message, for attack messages, etc
	var/player_hp = 30 //Player health/attack points
	var/player_mp = 10
	var/enemy_hp = 45 //Enemy health/attack points
	var/enemy_mp = 20
	var/gameover = 0
	var/blocked = 0 //Player cannot attack/heal while set

	New(obj/holding as obj)
		..()

		var/name_part1 = pick("the Automatic ", "Farmer ", "Lord ", "Professor ", "the Evil ", "the Dread King ", "the Space ", "Lord ")
		var/name_part2 = pick("Melonoid", "Murdertron", "Sorcerer", "Ruin", "Jeff", "Ectoplasm", "Crushulon")

		enemy_name = replacetext((name_part1 + name_part2), "the ", "")



	return_text()
		if (..())
			return

		var/dat = return_text_header()

		dat += "<center><h4>[enemy_name]</h4></center>"

		dat += "<br><center><h3>[temp]</h3></center>"
		dat += "<br><center>Health: [player_hp] | Magic: [player_mp] | Enemy Health: [enemy_hp]</center>"

		if (gameover)
			dat += "<center><strong><a href='byond://?src=\ref[src];newgame=1'>New Game</a>"
		else
			dat += "<center><strong><a href='byond://?src=\ref[src];attack=1'>Attack</a> | "
			dat += "<a href='byond://?src=\ref[src];heal=1'>Heal</a> | "
			dat += "<a href='byond://?src=\ref[src];charge=1'>Recharge Power</a>"

		dat += "</strong></center>"

		return dat

	Topic(href, href_list)
		if (..())
			return

		if (!blocked)
			if (href_list["attack"])
				blocked = 1
				var/attackamt = rand(2,6)
				temp = "You attack for [attackamt] damage!"
				master.updateSelfDialog()

				sleep(10)
				enemy_hp -= attackamt
				arcade_action()

			else if (href_list["heal"])
				blocked = 1
				var/pointamt = rand(1,3)
				var/healamt = rand(6,8)
				temp = "You use [pointamt] magic to heal for [healamt] damage!"
				master.updateSelfDialog()

				sleep(10)
				player_mp -= pointamt
				player_hp += healamt
				blocked = 1
				master.updateSelfDialog()
				arcade_action()

			else if (href_list["charge"])
				blocked = 1
				var/chargeamt = rand(4,7)
				temp = "You regain [chargeamt] points"
				player_mp += chargeamt

				master.updateSelfDialog()
				sleep(10)
				arcade_action()

		if (href_list["newgame"]) //Reset everything
			temp = "New Round"
			player_hp = 30
			player_mp = 10
			enemy_hp = 45
			enemy_mp = 20
			gameover = 0

		master.add_fingerprint(usr)
		master.updateSelfDialog()
		return

	proc/arcade_action()
		if ((enemy_mp <= 0) || (enemy_hp <= 0))
			gameover = 1
			temp = "[enemy_name] has fallen! Rejoice!"

		else if ((enemy_mp <= 5) && (prob(70)))
			var/stealamt = rand(2,3)
			temp = "[enemy_name] steals [stealamt] of your power!"
			player_mp -= stealamt
			master.updateSelfDialog()

			if (player_mp <= 0)
				gameover = 1
				sleep(10)
				temp = "You have been drained! GAME OVER"

		else if ((enemy_hp <= 10) && (enemy_mp > 4))
			temp = "[enemy_name] heals for 4 health!"
			enemy_hp += 4
			enemy_mp -= 4

		else
			var/attackamt = rand(3,6)
			temp = "[enemy_name] attacks for [attackamt] damage!"
			player_hp -= attackamt

		if ((player_mp <= 0) || (player_hp <= 0))
			gameover = 1
			temp = "You have been crushed! GAME OVER"

		blocked = 0
		return

/computer/file/pda_program/codebreaker
	name = "CodeBreaker"
	size = 4
	var/solution = ""
	var/code_length = 4
	var/list/code_chars = list("A","B","C","D")
	var/attempts = 10
	var/init_attempts = 0
	var/list/attempt_log = list()
	var/playing = 0
	var/temp = ""
	var/difficulty = "Normal"

	return_text()
		if (..())
			return

		var/dat = return_text_header()

		dat += "<center><h4>CodeBreaker</h4></center>"

		if (playing)
			dat += "<br>[temp]"

			if (playing == -1)
				dat += "<br><strong>The Code was</strong> \"[solution]\""
				dat += "<br><a href='byond://?src=\ref[src];menu=1'>Main Menu</a>"
			else
				dat += "<br><a href='byond://?src=\ref[src];guess=1'>Guess</a>"
				dat += "<br><a href='byond://?src=\ref[src];giveup=1'>Give Up</a>"

			dat += "<br><small>Attempts Remaining: [attempts]"
			for (var/i=0, i < attempt_log.len ,i++)
				dat += "<br>[attempt_log[i+1]]"
			dat += "</small><br>"

		else
			dat += "<br><center><h3><a href='byond://?src=\ref[src];newgame=1'>New Game</a></h3></center>"
			dat += "<br><center><h3><a href='byond://?src=\ref[src];difficulty=1'>Difficulty: [difficulty]</a></h3></center>"

		return dat

	Topic(href, href_list)
		if (..())
			return

		if (href_list["newgame"])
			playing = 1
			solution = ""
			var/length = code_length
			while (length > 0)
				length--
				solution += "[pick(code_chars)]"
			switch(difficulty)
				if ("Easy") attempts = 3
				if ("Normal") attempts = 10
				if ("Hard") attempts = 30
				if ("Ultra-Hard") attempts = 50
			init_attempts = attempts

			var/charstring = ""
			for (var/X in code_chars)
				charstring += "[X] "
			temp = "This game has a [code_length]-character code featuring the characters \"[charstring]\". Good luck."

		else if (href_list["menu"])
			playing = 0
			attempt_log = list()
			temp = ""
			solution = ""

		else if (href_list["giveup"])
			if (alert("Are you sure you want to give up?","CodeBreaker","Yes","No") == "Yes")
				attempts = 0
				playing = -1
				temp = "<strong>YOU LOSE!</strong>"

		else if (href_list["guess"])
			var/attempt = input("Enter your guess.","CodeBreaker") as null|text
			if (!attempt)
				temp = "Illegal move."
				master.updateSelfDialog()
				return
			if (lentext(attempt) != lentext(solution))
				temp = "Illegal move."
				master.updateSelfDialog()
				return
			if (attempt == solution)
				playing = -1
				temp = "<strong>YOU WIN!</strong>"
			else
				if (attempts <= 1)
					playing = -1
					temp = "<strong>YOU LOSE!</strong>"
				else
					attempts--

					var/length = lentext(solution)

					var/list/lockcode_list = list()
					for (var/i=0,i < length,i++)
						//lockcode_list += "[copytext(bp.lockcode,i+1,i+2)]"
						lockcode_list["[copytext(solution,i+1,i+2)]"]++

					var/correct_full = 0
					var/correct_char = 0
					var/current
					var/seek = 0
					for (var/i=0,i < length,i++)
						current = copytext(attempt,i+1,i+2)
						if (current == copytext(solution,i+1,i+2))
							correct_full++
							//correct_char++
							//continue
						seek = lockcode_list.Find(current)
						if (seek)
							correct_char++
							lockcode_list[current]--
							if (lockcode_list[current] <= 0)
								lockcode_list -= current

					attempt_log.Insert(1,"Guess [init_attempts - attempts]: [attempt] ([correct_char]/[correct_full])")
					temp = "Incorrect. [correct_char] correct characters, [correct_full] in correct position."

		else if (href_list["difficulty"])
			switch(difficulty)
				if ("Ultra-Hard")
					set_difficulty("Easy",2,3)
					code_chars = list("A","B")
				if ("Easy")
					set_difficulty("Normal",4,10)
					code_chars = list("A","B","C","D")
				if ("Normal")
					set_difficulty("Hard",5,30)
					code_chars = list("A","B","C","D","E")
				if ("Hard")
					set_difficulty("Ultra-Hard",6,50)
					code_chars = list("A","B","C","D","E","F")

		master.add_fingerprint(usr)
		master.updateSelfDialog()
		return

	proc/set_difficulty(var/diff,var/code_length,var/attempts)
		if (!diff || !code_length || !attempts || !code_chars.len)
			return null
		difficulty = diff
		code_length = code_length
		attempts = attempts

#undef SETUP_BLOCKS_HORIZ
#undef SETUP_BLOCKS_VERT
#undef SETUP_BLOCK_COLOR
#undef SETUP_PLAYFIELD_COLOR
#undef SETUP_ROTATE_DELAY