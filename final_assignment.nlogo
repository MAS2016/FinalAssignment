; --- Global variables ---
; The following global variables exist, all of which are defined in the interface:
;   1) initial_bees           : the intitial number of bees
;   2) scout_worker_ratio     : the desired ratio between scout-bees and worker-bees
;   3) number_of_food_sources : the number of food sources in the environment (fixed)
;   4) nectar_refill_rate     : the speed at which nectar of food sources refills
;   5) bee_capacity           : the total number of bees that a hive can hold
;   6) energy_loss_rate       : the speed at which bees lose energy (kan evt. ook lokaal)
;   7) carrying_capacity      : the maximum amount of food a worker bee can carry
;   8) gain_from_food         : amount of energy that bees gain from eating 1 food
;   9) color-list             : global list of colors to indicate food source quality (max_food_value)

globals
  [color-list]

; --- Agents ---
; The following types of agents exist:
;   1) Scout-bees
;   2) Worker-bees
;   3) Queen-bees
;   4) Sites (possible hive locations)
;   5) Hives
;   6) Sensors (sensors that allow an agent to observe the environment)
;   (optional: enemy)
breed [scouts scout]
breed [workers worker]
breed [queens queen]
breed [hives hive]
breed [sensors sensor]

; --- Local variables ---
; The following local variables exist:
; FOR BEES:
;   1) beliefs                : the agent's current belief base
;   2) desires                : the agent's current desire
;   3) intentions             : the agent's current intention
;   4) carrying               : the amount of food a worker bee is carrying
;   5) age                    : the current age of a bee
;   6) max_age                : maximum age of a bee (i.e. at which it dies) (normal distribution)
;   7) energy                 : the current amount of energy that a bee has
;   8) max_energy             : maximum energy of a bee (normal distribution)
;   9) outgoing_messages      : the current outgoing message (coming from a scout or queen)
;  10) incoming_messages      : the current incoming message

; FOR FOOD SOURCE (patches):
;  11) food_value             : the amount of food that is stored in a source
;  12) max_food_value         : maximum amount of food that can be stored in a source (i.e. its quality)

; FOR HIVES:
;  13) total_food_in_hive     : the current amount of food that a hive holds
;  14) total_bees_in_hive     : the current amount of bees that a hive holds

; ###################
; #   SCOUT AGENT   #
; ###################

scouts-own [
  beliefs
  desire
  intention
  age
  max_age
  energy
  max_energy
  incoming_messages
  outgoing_messages
  my_home
]

; ###################
; #   WORKER AGENT  #
; ###################

workers-own [
  beliefs
  desire
  intention
  age
  max_age
  energy
  max_energy
  incoming_messages
  carrying
  my_home
]

; ###################
; #    QUEEN AGENT  #
; ###################

queens-own [
  beliefs
  desire
  intention
  age
  max_age
  energy
  max_energy
  incoming_messages
  outgoing_messages
  my_home
]

; ###################
; #    HIVE AGENT   #
; ###################

hives-own[total_food_in_hive total_bees_in_hive]

patches-own [food_value max_food_value]
;--------------------------------------------------------------------------------------------------

; --- Setup ---
to setup
  clear-all
  reset-ticks
  setup-food-sources   ; determine food locations with quality
  setup-hive           ; create a hive at a random location
  setup-queen
  setup-workers
  setup-scouts
;  setup-agents         ; create scouts, workers, and a queen

end

; --- Setup food-sources ---
to setup-food-sources
  ask patches [set pcolor white]
    ask n-of number_of_food_sources patches [  ; ask random patches to become food
      set max_food_value random-normal 30 20   ; set max food value according to a normal distribution
      set-color                                ; set color according to max food value
      set food_value max_food_value            ; set initial food value to maximum
      set-color                                ; set color according to food value
      set plabel food_value
      set plabel-color white
    ]
end

to set-color
  set color-list [129 129 128.5 128 127.5 127 126.5 126 125 124 123 122]
  ifelse max_food_value < 10 [set pcolor item 0 color-list][
  ifelse max_food_value < 15 [set pcolor item 1 color-list][
  ifelse max_food_value < 20 [set pcolor item 2 color-list][
  ifelse max_food_value < 25 [set pcolor item 3 color-list][
  ifelse max_food_value < 30 [set pcolor item 4 color-list][
  ifelse max_food_value < 35 [set pcolor item 5 color-list][
  ifelse max_food_value < 40 [set pcolor item 6 color-list][
  ifelse max_food_value < 45 [set pcolor item 7 color-list][
  ifelse max_food_value < 50 [set pcolor item 8 color-list][
  ifelse max_food_value < 55 [set pcolor item 9 color-list][
  ifelse max_food_value < 60 [set pcolor item 10 color-list][
  if max_food_value >= 60 [set pcolor item 11 color-list]
  ]]]]]]]]]]]
end


; --- Setup hive ---
to setup-hive
    create-hives 1 [
      setxy (random max-pxcor) (random min-pycor)
      set shape "hive"
      set color yellow
      set size 3
      set total_food_in_hive 0
      set label total_food_in_hive set label-color red
      set total_bees_in_hive initial_bees
    ]
end


; --- Setup agents ---
to setup-agents
  ; create QUEEN bee on location of hive
  setup-queen
  ; create swarm of WORKERS and SCOUTS (dependent on initial_bees & ratio) on location of hive
  setup-workers
  setup-scouts
  ; set current age & max_age
  ; set current energy & max_energy
  ; bees have global energy_loss_rate & carrying_capacity
end

to setup-queen
  create-queens 1 [
    move-to [patch-here] of hive 0
    set shape "bee 2"
    set size 2
    set color red
    set my_home [patch-here] of hive 0
    set beliefs []
    set incoming_messages []
    set outgoing_messages []
    set age 0
    set max_age random-normal 50 10
    set energy 100
    set max_energy random-normal 70 30
  ]
end

to setup-workers
  create-workers round (initial_bees / (scout_worker_ratio + 1)) [
    move-to [patch-here] of hive 0
    fd random-float 4
    set shape "bee"
    set color black
    set my_home [patch-here] of hive 0
    set beliefs []
    set incoming_messages []
    set age 0
    set max_age random-normal 50 10
    set energy 100
    set max_energy random-normal 70 30
  ]
end


to setup-scouts
  create-scouts round (scout_worker_ratio * (initial_bees / (scout_worker_ratio + 1))) [
    move-to [patch-here] of hive 0
    fd random-float 4
    set shape "bee"
    set size 1.5
    set color red
    set my_home [patch-here] of hive 0
    set beliefs []
    set incoming_messages []
    set outgoing_messages []
    set age 0
    set max_age random-normal 50 10
    set energy 100
    set max_energy random-normal 70 30
  ]
end


;-------------------------------------------------------------------------------------------------

to go
  ask scouts [move-around]
  ask workers [move-around]
  ask queens [move-around]
  tick
end

; --- Main processing cycle ---
;to go
;  update-desires
;  update-beliefs
;  update-intentions
;  execute-actions
;  send-messages
;  increase-age
;  tick
;end

; --- Update desires ---

to update-desires
  ; every agent: survive (of we laten deze geheel weg en nemen alleen specifieke mee)

  ; WORKERS:
  ;     'collect food'                     : forever
  ask workers
    [set desire "collect food"]

  ; SCOUTS:
  ;     'find food & optimal hive location': forever
  ask scouts
    [set desire "find food & optimal hive location"]

  ; QUEEN(S):
  ;     'manage colony'                    : else
  ask queens
    [set desire "manage colony"]

end

; --- Update beliefs ---
to update-beliefs
; to reduce computational load, beliefs about location of own hive, current amount of food carrying, energy level, age, and number of bees in hive are not explicitely implemented as beliefs

  ; WORKERS:
  ;     location of own hive (my_home)
  ;     probable location of 1 food source : based on received message from scout (incoming_messages)
  ;     location of new site to migrate to : based on received message from queen (delete if at this location)
  ;     current amount of food carrying
  ;     current energy level
  ;
  ;     if food source reaches 0 and worker notices, worker deletes food source from belief base

  ask workers
    [set beliefs incoming_messages]  ; belief about location of food, received from scout


  ; SCOUTS:
  ;     location of own hive
  ;     locations of new food source       : based on observation via its sensors (evt. niet altijd de juiste)
  ;     locations of known food sources
  ;     location and quality of new site   : based on observation and reasoning
  ;     location of new site to migrate to : based on received message from queen
  ;     current energy level

  ask scouts []
    ;[update-food-sources]

  ; QUEEN(S):
  ;     number of workers
  ;     number of scouts
  ;     amount of food in hive
  ;     hive threshold
  ;     location and quality of new sites  : based on received messages from scouts
  ;     current energy level

  ask queens[
    let blf_workers (count workers)
  ]

end

; --- Update intentions ---
; SHOULD BE DEPENDENT UPON BELIEFS & DESIRES
; 'Observe' should be split into 2 intentions: 'walk around' and 'look around'

to update-intentions
  ; WORKERS:
  ;     wait for message  : if no belief about food location
  ;     fly to location   : if there is a belief about food location and it believes energy is sufficient
  ;     move around       : als locatie die scout doorgaf niet goed is, dan zelf food vinden
  ;     look around
  ;     collect food      : if current location = food location in belief & food_value > 0 & carrying < carrying_capacity
  ;     fly to hive       : if it carries food
  ;     drop food in hive : if it believes it carries food and is in hive
  ;     eat               : if belief energy level is below max_energy and bee is at own hive
  ;     migrate           : if received message from queen

  ; SCOUTS:
  ;     move around       : if no beliefs about food or location of new site -> observe (walk & look around)
  ;     look around
  ;     fly to hive       : if it believes there is food or a good new site
  ;     tell worker about location of food : if it believes there is food somewhere and it is at the hive
  ;     tell queen about location & quality of new site : if it has belief about new site and is at hive
  ;     migrate           : if received message from queen

  ; QUEEN(S):
  ;     produce new worker-bee : if belief number of scouts & workers is above scout_worker_ratio
  ;     produce new scout-bee  : if belief number of scouts & workers is below scout_worker_ratio
  ;     produce new queen      : if belief number scouts + workers in hive >= hive_threshold and has belief about new site
  ;                            : the new queen's belief about own hive = location of new site
  ;     tell others to migrate
  ;     migrate to new site    : if belief own hive != current location
  ;     create new hive        : if current location = belief location of new (optimal) site

  end
; --- Execute actions ---
; ACTIONS SHOULD IMMEDIATELY FOLLOW AN INTENTION
; opnieuw is het denk ik goed om 1 actie per tick te laten uitvoeren
; onderstaande is te lezen als: intentie --> bijbehorende acties

to execute-actions
  execute-scout-actions
  execute-worker-actions
  execute-queen-actions
end

; ######################
; #  GENERAL METHODS   #
; ######################
; these include:
; 1) migrate
; 2) eat
; 3) use energy


; 1) migrate
to migrate
;  set target to newest message from queen
end

; 2) eat
; increase own energy by 1
; decrease food in hive
to eat
  set energy energy + gain_from_food
  ask my_home[
    set total_food_in_hive total_food_in_hive - 1
  ]
end

; 3) use energy
to use-energy
  set energy energy - energy_loss_rate
end

; ######################
; #    SCOUT METHODS   #
; ######################

  ; SCOUTS:
  ;     move-around          --> move in random direction
  ;     look around          --> check sensors for food
  ;     fly to hive          --> move straight to own hive
  ;     tell worker about location of food --> send-messages (to workers)
  ;     tell queen about location & quality of new site --> send-messages (to queen)
  ;     migrate              --> move straight to new site location and set own hive to this location
  ;     eat                  --> energy + 1 & total_food_in_hive - 1

to execute-scout-actions
  ask scouts [
    ifelse intention = "move around" [move-around][
    ifelse intention = "look around" [look-around][
    ifelse intention = "fly to hive" [fly-to-hive][
    ifelse intention = "tell worker about location of food" [tell-worker][
    ifelse intention = "tell queen about location and quality of new site" [tell-queen][
    ifelse intention = "migrate" [migrate][
    if intention = "eat"[eat]
    ]]]]]]

  ]
end

to move-around
  rt (random 60 - random 60) fd random-float .1
end

to look-around
  ; spawn sensors in radius
  ; let sensors check
  ; let sensors die
end

to fly-to-hive

end

to calculate-quality
; If on a new patch, the quality of this patch is assessed.
; This is done by checking the list of known patches with food.
; Determine the 'total gain' - i.e. for a given radius the sum of: (total food in patch) / (carrying capacity - energy cost to reach food)
; energy cost to reach food = (distance to patch) * 2 (to and from) * energy_loss_rate
; if (other) hive in radius, set quality to 0
; save the quality of the site
end

to tell-worker
end

to tell-queen
end

; ######################
; #   WORKER METHODS   #
; ######################

  ; WORKERS:
  ;     wait for message  : if no belief about food location
  ;     fly to location   : if there is a belief about food location and it believes energy is sufficient
  ;     move around       : als locatie die scout doorgaf niet goed is, dan zelf food vinden
  ;     look around
  ;     collect food      : if current location = food location in belief & food_value > 0 & carrying < carrying_capacity
  ;     fly to hive       : if it carries food
  ;     drop food in hive : if it believes it carries food and is in hive
  ;     eat               : if belief energy level is below max_energy and bee is at own hive
  ;     migrate           : if received message from queen

to execute-worker-actions
  ifelse intention = "wait for message" [wait-for-message][
  ifelse intention = "collect food" [collect-food][
  ifelse intention = "drop food in hive" [drop-food-in-hive][
  ifelse intention = "" [][
  ifelse intention = "" [][
  ]]]]]
end

to move
  set heading first beliefs
  forward 1
end

to wait-for-message
  ;fly around in a circle
end

to collect-food
  set carrying carrying + 1
  ask patch-here [
    set plabel plabel - 1
  ]
end

; Add the food cargo to the total food in the hive and update carrying accordingly
to drop-food-in-hive
  let cargo carrying
  ask my_home[
    set total_food_in_hive total_food_in_hive + cargo
  ]
  set carrying 0
end

; ######################
; #    QUEEN METHODS   #
; ######################

  ; QUEEN(S):
  ;     produce new worker-bee --> hatch 1 worker with characteristics (age, energy, own hive, etc.) at location
  ;     produce new scout-bee  --> hatch 1 scout with characteristics at location
  ;     produce new queen      --> hatch 1 queen with characteristics
  ;     tell others to migrate --> send-messages (to some workers and scouts) - THIS SHOULD BE DONE BY THE NEW QUEEN
  ;     migrate to new site    --> move straight to new site location and set own hive to this location
  ;     create new hive        --> create hive at own hive location and set total food & bees in this hive
  ;     eat                    --> energy + 1 & total_food_in_hive - 1

to execute-queen-actions
  ifelse intention = "produce new worker bee"[produce-new-worker-bee][
  ifelse intention = "produce new scout bee"[produce-new-scout-bee][
  ifelse intention = "produce new queen"[produce-new-queen][
  ifelse intention = "tell others to migrate"[][
  ifelse intention = "migrate to new site"[migrate][
  ifelse intention = "create new hive"[create-new-hive][
  ]]]]]]
end

to produce-new-worker-bee
  let parent_home my_home
  hatch-workers 1 [
    set my_home parent_home
    set age 0

    ; Values below are arbitrarily chosen for now
    set max_age random 100
    set energy 100
    set max_energy 100
  ]
end

to produce-new-scout-bee
  let parent_home my_home
  hatch-scouts 1 [
    set my_home parent_home
    set age 0

    ; Values below are arbitrarily chosen for now
    set max_age random 100
    set energy 100
    set max_energy 100
  ]
end

to produce-new-queen
  let parent_home my_home
  ;let child_home first sent_messages[0] ; ervan uitgaande dat een message bestaat uit een patch en afzender
  hatch-queens 1 [
    set age 0

    ; Values below are arbitrarily chosen for now
    set max_age random 100
    set energy 100
    set max_energy 100

    ; convert number of workers and scout homes with parent home to child home
    ; do that somewhere here
  ]
end

to create-new-hive

end

; --- Send messages ---
;to send messages
  ; scout -> worker          : set outgoing_messages to location of food and set incoming messages of SOME worker bees to this location.
  ; scout -> queen           : set outgoing_messages to location & quality of new site and set incoming_messages of queen to this.
  ; queen -> workers & scouts: set outgoing_messages to location of new site and set incoming_messages of SOME bees to this location.
;end

; Scout message to worker
; patch
; message to percentage of workers in hive
; ask (n-of (scout_message_effectiveness * number of workers in hive)  workers)

; Scout message to queen
; if quality of patch reaches threshold, scout communicates:
; patch and quality

; Queen message to workers & scouts
; new hive location
; if new hive location --> migrate (queen message effectiveness)

; --- Send messages ---
;to send-messages
;  ; Here should put the code related to sending messages to other agents.
;  ; Note that this could be seen as a special case of executing actions, but for conceptual clarity it has been put in a separate method.
;  ask vacuums [
;    if not empty? outgoing_messages
;    [
;      ; check welke ontvanger bericht moet krijgen
;      ; stuur naar specifieke ontvanger
;      foreach outgoing_messages [
;        let msg ?
;        if not member? msg sent_messages[
;          set sent_messages lput msg sent_messages
;          let col [color] of self
;          ask vacuums with [color = item 1 msg]
;          [ ;message color
;            let in_msg list (item 0 msg) (col)
;            set incoming_messages lput in_msg incoming_messages
;          ]
;          set outgoing_messages remove-item 0 outgoing_messages
;        ]
;      ]
;     ]
;    ]
;end
@#$#@#$#@
GRAPHICS-WINDOW
248
12
973
582
32
24
11.0
1
10
1
1
1
0
0
0
1
-32
32
-24
24
1
1
1
ticks
120.0

SLIDER
6
58
211
91
number_of_food_sources
number_of_food_sources
1
100
17
1
1
NIL
HORIZONTAL

BUTTON
8
406
75
439
SETUP
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
76
406
139
439
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
204
179
237
gain_from_food
gain_from_food
0
10
10
1
1
NIL
HORIZONTAL

SLIDER
6
124
179
157
scout_worker_ratio
scout_worker_ratio
0.05
2
0.05
0.05
1
NIL
HORIZONTAL

SLIDER
6
171
178
204
carrying_capacity
carrying_capacity
0
20
5
1
1
NIL
HORIZONTAL

SLIDER
6
91
178
124
nectar_refill_rate
nectar_refill_rate
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
7
237
179
270
energy_loss_rate
energy_loss_rate
0
100
50
1
1
NIL
HORIZONTAL

PLOT
9
454
209
604
Number of bees
Ticks
Number
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Queens" 1.0 0 -2674135 true "" "plot count queens"
"Workers" 1.0 0 -1184463 true "" "plot count workers"
"Scouts" 1.0 0 -7500403 true "" "plot count scouts"

SLIDER
7
11
179
44
initial_bees
initial_bees
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
8
279
244
312
scout_message_effectiveness
scout_message_effectiveness
0
1
0.75
0.05
1
NIL
HORIZONTAL

SLIDER
7
314
247
347
queen_message_effectiveness
queen_message_effectiveness
0
1
0.75
0.05
1
NIL
HORIZONTAL

SLIDER
8
361
180
394
scout_radius
scout_radius
0
5
2
0.5
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

hive
false
0
Circle -7500403 true true 118 203 94
Rectangle -6459832 true false 120 0 180 105
Circle -7500403 true true 65 171 108
Circle -7500403 true true 116 132 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
