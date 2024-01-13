-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
	local mem_shift = mdword(0x21C0794)
	-- Static Pokemon data is inconsistent between locations & resets,
    -- so find the current offset using a relative value	
	local foe_offset = mdword(mem_shift + 0x217A8)
	
	pointers = {
		party_count = mem_shift + 0xB0,
		party_data  = mem_shift + 0xB4,

		foe_count 	= foe_offset - 0x2D5C,
		current_foe = foe_offset - 0x2D58,
		
		map_header	= mem_shift + 0x1294,
		trainer_x 	= mem_shift + 0x129A,
		trainer_z 	= mem_shift + 0x129E,
		trainer_y 	= mem_shift + 0x12A2,
		facing		= mem_shift + 0x238A4,
		
		battle_state_value = mem_shift + 0x44878, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
		battle_indicator   = 0x021D18F2 -- static
	}
	
	-- TODO replace the methods that depend on these pointers
	pointers.in_starter_battle = mbyte(pointers.battle_indicator)
	pointers.current_pokemon   = mem_shift + 0x475B8        -- 0A is POkemon menu 0E is animation
	pointers.foe_in_battle	   = pointers.current_pokemon + 0xC0
	pointers.foe_status		   = pointers.foe_in_battle + 0x6C
	pointers.current_hp		   = mword(pointers.current_pokemon + 0x4C)
	pointers.level			   = mbyte(pointers.current_pokemon + 0x34)
	pointers.foe_current_hp	   = mword(pointers.foe_in_battle + 0x4C)
	pointers.foe_PID		   = mdword(pointers.foe_in_battle + 0x68)
	pointers.foe_TID		   = mword(pointers.foe_in_battle + 0x74)
	pointers.foe_SID		   = mword(pointers.foe_in_battle + 0x75)
	pointers.saveFlag		   = mbyte(mem_shift + 0x2832A)
	pointers.fishOn			   = mbyte(0x021CF636)
end

function mode_starters(starter) --starters for platinum
    console.log("Waiting to reach overworld...")
    wait_frames(200)

    while mbyte(pointers.battle_indicator) == 0x1D do
        local rand1 = math.random(3, 60)
        console.log(rand1)
        press_button("A")
        wait_frames(rand1)
    end

    while mbyte(pointers.battle_indicator) ~= 0xFF do
        local rand2 = math.random(3, 60)
        wait_frames(rand2)
        press_button("A")
        wait_frames(rand2)
    end
    --we can save right in front of the bag in platinum so all we have to do is open and select are starter

    -- Open briefcase and skip through dialogue until starter select
    console.log("Skipping dialogue to briefcase")
    local selected_starter = mdword(0x2101DEC) + 0x203E8 -- 0: Turtwig, 1: Chimchar, 2: Piplup
    local starters_ready = selected_starter + 0x84       -- 0 before hand appears, A94D afterwards

    while not (mdword(starters_ready) > 0) do
        press_button("B")
        wait_frames(2)
    end

    -- Need to wait for hand to be visible to find offset
    console.log("Selecting starter...")

    -- Highlight and select target
    while mdword(selected_starter) < starter do
        press_sequence("Right", 10)
    end

    while #party == 0 do
        press_sequence("A", 6)
    end

    console.log("Waiting to see starter...")
    if config.hax then
        mon = party[1]
        local was_target = pokemon.log(mon)
        if was_target then
            pause_bot("Starter meets target specs!")
        else
            press_button("Power")
        end
    else
        while pointers.in_starter_battle ~= 0x41 do
            skip_dialogue()
        end
        while pointers.in_starter_battle == 0x41 and pointers.battle_state_value == 0 do
            press_sequence("B", 5)
        end
        wait_frames(50)
        mon = party[1]
        local was_target = pokemon.log(mon)
        if was_target then
            pause_bot("Starter meets target specs!")
        else
            console.log("Starter was not a target, resetting...")
            selected_starter = 0
            starters_ready = 0
            press_button("Power")
        end
    end
end
