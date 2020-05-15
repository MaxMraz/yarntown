soulslike_enemies.md

To use this enemy framework, create enemies like so:

```
local enemy = ...

local souls_enemy = require"enemies/lib/souls_enemy"

function enemy:on_created()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  souls_enemy:create(enemy, {
  	--set life, damage, particular noises, etc
  	initial_movement_type = enemy:get_property("initial_movement_type") or "random",
  	life = 220,
  	melee_range = 48,
  })
end

function enemy:choose_attack()
	--we'll go over this later
end
```

When this enemy is created, the souls_enemy script will initialize all the enemy's behavior, such as triggering aggression when it sees the player, approaching then attacking, taking damage, etc. There are a number of properties you can set for any enemy breed, listed here with their defaults.
```lua
local properties = {
	life = 150,
	damage = 20,
	pushed_back_when_hurt = false,
	push_hero_on_sword = false,
	hurts_to_touch = false, --sets enemy:can_attack()
	enemy_hurt_sound = "enemy_hurt",
	initial_movement_type = "stopped", --other options are "random" or "path" (path is still TODO)
	agro_cone_size = "medium", --enemy's vision area sprite. Corresponds to enemies/tools/agro_cone_ .. agro_cone_size
	speed = 50,
	attack_range = 40, --enemy will get this close to hero before attacking. If the enemy has ranged attacks available to it, this may be quite far.
	deagro_threshold = 250, --distance at which enemy will stop chasing hero
}

Multiple attacks:
Each enemy is required to have its own `enemy:choose_attack()` function. This allows multiple enemies to use the same attacks, but each under different circumstances, or even to create its own cooldown time for a certain attack. Here's an example function:

```lua
function enemy:choose_attack()
	local hero = enemy:get_map():get_hero()
	if enemy:get_distance(hero) > 40 then
		local attack = require("enemies/lib/attacks/melee_attack")
		attack:melee_attack(enemy, DAMAGE+10, "enemies/weapons/axe_slam")
	elseif enemy:get_distance(hero) <= 40 then
		local attack = require("enemies/lib/attacks/melee_attack")
		attack:set_wind_up_time(400)
		enemy.recovery_time = 1000
		attack:melee_attack(enemy, DAMAGE, "enemies/weapons/axe_swipe")
	else
		enemy:choose_next_state("attack")
	end

end
```

This example uses distance to the hero to decide which attack to use. An enemy with ranged attacks would almost certainly first check distance first, but perhaps use a random number to decide on attacks when close to the player.

This example also sets

In the case that no condition is true, this enemy calls `enemy:choose_next_state()`. This is part of the framework that advances enemy states, and takes the current state as an argument to decide which state to advance with next. States in this case are simply functions.



There are a couple resources required for these enemies to function. Then specific attacks may all require their own resources.

Required Resources:
Sprites:
- `enemies/tools/agro_cone_medium`: This is a sprite that represents the enemy's vision. Allows to create as many sizes and patterns as necessary, prefixed with "agro_cone_" .. size

Enemy sprite animations:
- "walking" (looping)
- "stopped" (looping)
-- Then these next two are specific to attacks. Your own attacks can use whatever animations you want.
- "wind_up" (looping) --this is the default anticipation pose before attacking.
- "melee_attack" (nonlooping) --this is the default attack animation



Creating attacks:

Attacks are highly modular, each attack being its own script. As each enemy is responsible for calling its own attacks, their requirements, idiosyncracies and methods of being called can vary.

The only requirement is that each attack call `enemy:choose_next_state("attack")` when it is finished. This will move the enemy into its "recovery" state, where it stands still for a length of time equal to the current value of `enemy.recovery_time`. I would recommend setting `enemy.recovery` time in the enemy's choose_attack() method, rather than hard coding it into an attack. This will allow one enemy to use that attack multiple times quickly, while another may leave itself open for attack after using the same attack.

