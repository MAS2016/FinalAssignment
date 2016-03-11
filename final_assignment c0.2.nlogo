; --- Global variables ---
; The following global variables exist:
;   1) initial_bees           : the intitial number of bees
;   2) scout_worker_ratio     : the desired ratio between scout-bees and worker-bees
;   3) number_of_food_sources : the number of food sources in the environment (fixed)
;   4) nectar_refill_rate     : the speed at which nectar of food sources refills
;   5) bee_capacity           : the total number of bees that a hive can hold
;   6) energy_loss_rate       : the speed at which bees lose energy (kan evt. ook lokaal)
;   7) carrying_capacity      : the maximum amount of food a worker bee can carry

globals
  [initial_bees
   scout_worker_ratio
   number_of_food_sources
   nectar_refill_rate
   bee_capacity
   energy_loss_rate          ; how much energy the bee loses per tick
   gain_from_food            ; how much energy the bee gains from eating 1 food
   carrying_capacity         ; how much food the bee can carry
   color-list                ; colors for food sources, which keeps consistency among the hive colors, plot pens colors, and committed bees' colors
   quality-list              ; quality of food sources
   ]


; --- Agents ---
; The following types of agents exist:
;   1) Scout-bees
;   2) Worker-bees
;   3) Queen-bees
;   4) Sites (possible hive locations)
;   5) Hives
;   6) Sensors (sensors that allow an agent to observe the environment)
;   (optional: enemy)
breed [scouts scout]        ;I suggest we only use Bee in stead of Worker and Scout. Bee is always worker but can become (initial) scout
breed [workers worker]      ;Tjeerd en ik denken dat het ook correct is om het zo op te delen, aangezien het een best duidelijk afgebakende 'rol' is. Het bereiken van een specifieke agenset zonder 'ifs' erin is ook een voordeel. De paar methods die overeenkomen nemen we dan voor lief.
breed [queens queen]
breed [sites site]
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

; FOR FOOD SOURCE:
;  11) food_value             : the amount of food that is stored in a source

; FOR HIVES:
;  12) total_food_in_hive     : the current amount of food that a hive holds
;  13) total_bees_in_hive     : the current amount of bees that a hive holds

; ###################
; #   SCOUT AGENT   #
; ###################
;scouts-own [beliefs desires intentions age max_age energy max_energy incoming_messages outgoing_messages]

scouts-own [
  desire                    ; survive (if eating is necessary),
  age                       ; the bee's current age
  max_age                   ; the maximum age a bee will reach
  energy                    ; how much energy the bee has. Each tick, it will burn energy
  max_energy                ; how much energy a bee can have
  incoming_messages         ; the bee's incoming messages
  outgoing_messages         ; the bee's outgoing messages
  sent_messages             ; the bee's sent messages
  my_home                   ; a bee's original position or hive
  belief_sites              ; Lists of patches suitable for a new hive, with this bee's belief about quality
  belief_food               ; List of food patches with a quality


  intention                 ; comparable to "next-task" in BeeSmart: watch-dance, pipe, discover, revisit, go-home, inspect-food-source, dance, take-off, collect-food

  belief-initial-scout?     ; true if bee beliefs to be an initial scout who explores unknown food sources
  belief-no-discovery?      ; true if it is an initial scout and fails to discover any food source on its initial exploration
  belief-on-site?           ; true if it's inspecting a food source
  belief-piping?            ; a bee starts to "pipe" when the decision of the best hive is made. true if a bee observes more bees on a certain hive site than the quorum or when it observes other bees piping

; dance related variables
  belief-circle-switch       ; when making a waggle dance, a bee alternates left and right to make the figure "8". circle-switch alternates between 1 and -1 to tell a bee which direction to turn.
]

; ###################
; #   WORKER AGENT  #
; ###################

workers-own [beliefs desires intentions age max_age energy max_energy incoming_messages carrying]

; ###################
; #    QUEEN AGENT  #
; ###################

queens-own [beliefs desires intentions age max_age energy max_energy incoming_messages outgoing_messages]

; ###################
; #    HIVE AGENT   #
; ###################

hives-own[total_food_in_hive total_bees_in_hive]




;--------------------------------------------------------------------------------------------------

; --- Setup ---
to setup
  clear-all
  setup-food-sources   ; determine food locations with quality
  reset-ticks
  setup-bees           ; create scouts, workers, and a queen
  setup-hives
;  setup-ticks
end


; --- Setup patches ---
;to setup-patches
  ; create a number of food sources on a random location
  ; set food value of each source & its nectar_refill_rate (can be done with 'plabel')
  ; create one hive on a random location, with a bee_capacity
;end


to setup-food-sources
  set color-list [97.9 94.5 57.5 63.8 17.6 14.9 27.5 25.1 117.9 114.4] ; food sources have different colors for clarity
  set quality-list [100 75 50 1 54 48 40 32 24 16]                     ; food sources have different quality = food value
  ask n-of num-food-sources patches with [distancexy 0 0 > 16 and abs pxcor < (max-pxcor - 2) and abs pycor < (max-pycor - 2)][ ;randomly placing food sources around the center in the view with a minimum distance of 16 from the center
    sprout-sites 1 [set shape "flower" set size 2 set color gray set discovered? false] ; initial food source has not yet been discovered (gray)
  ]
  let i 0   ;assign quality and plot pens to each hive
  repeat count sites [
    ask site i [set quality item i quality-list set label quality]
;    set-current-plot "on-site"
;    create-temporary-plot-pen word "site" i
;    set-plot-pen-color item i color-list
;    set-current-plot "committed"
;    create-temporary-plot-pen word "target" i
;    set-plot-pen-color item i color-list
    set i i + 1
  ]
end

; herschrijven om aparte scouts en workers te hebben
to setup-bees
  create-scouts 100 [
    fd random-float 4                  ;let bees spread out from the center
    set my-home patch-here
    set shape "bee"
    set color gray
    set desire "survive"
    set belief-initial-scout? false
    set target nobody
    set belief-circle-switch 1
    set belief-no-discovery? false
    set belief-on-site? false
    set belief-piping? false
    set intention "watch-dance"           ;
;    set task-string "watching-dance"
    ]
  ask n-of (initial-percentage) scouts[set belief-initial-scout? true set bee-timer random 100] ; assigning some of the scouts to be initial scouts. bee-timer here determines how long they will wait before starting initial exploration
end

to setup-hives

end


; --- Setup agents ---
to setup-agents
  ; create QUEEN bee on location of hive
  ; create swarm of WORKERS and SCOUTS (dependent on initial_bees & ratio) on location of hive
  ; set current age & max_age
  ; set current energy & max_energy
  ; bees have global energy_loss_rate & carrying_capacity
end

; --- Setup ticks ---
to setup-ticks
  reset-ticks
end

;-------------------------------------------------------------------------------------------------

; --- Main processing cycle ---
;to go
;  update-desires
;  update-beliefs
;  update-intentions
;  execute-actions
;  send-messages
;  tick
;end

; --- Update desires ---

;to update-desires
  ; every agent: survive (of we laten deze geheel weg en nemen alleen specifieke mee)

  ; WORKERS:
  ;     'collect food'                     : forever

  ; SCOUTS:
  ;     'find food & optimal hive location': forever

  ; QUEEN(S):
  ;     'migrate'                          : if it beliefs hive is full
  ;     'manage hive'                      : else


; --- Update beliefs ---
  ; WORKERS:
  ;     location of own hive
  ;     probable location of 1 food source : based on received message from scout (incoming_messages)
  ;                                        : realistisch zou zijn om niet altijd de precieze locatie te geven
  ;                                          maar soms eentje 'in de buurt'. De worker vliegt daar dan heen en
  ;                                          en moet zelf de precieze locatie vinden (bv. 2 patches verderop).
  ;                                          Als we dit niet doen, heeft worker eigenlijk geen sensors nodig.
  ;     location of new site to migrate to : based on received message from queen
  ;     current amount of food carrying
  ;     current energy level

  ; SCOUTS:
  ;     location of own hive
  ;     locations of new food source       : based on observation via its sensors (evt. niet altijd de juiste)
  ;     locations of known food sources
  ;     location and quality of new site   : based on observation and reasoning
  ;     location of new site to migrate to : based on received message from queen
  ;     current energy level


  ; QUEEN(S):
  ;     number of workers
  ;     number of scouts
  ;     amount of food in hive
  ;     hive threshold
  ;     location and quality of new sites  : based on received messages from scouts
  ;     current energy level


; --- Update intentions ---
; SHOULD BE DEPENDENT UPON BELIEFS & DESIRES
; 'Observe' should be split into 2 intentions: 'walk around' and 'look around'

  ; WORKERS:
  ;     wait for message  : if no belief about food location
  ;     fly to location   : if there is a belief about food location and it believes energy is sufficient
  ;     walk around       : als locatie die scout doorgaf niet goed is, dan zelf food vinden
  ;     look around
  ;     collect food      : if current location = food location in belief & food_value > 0 & carrying < carrying_capacity
  ;     drop food in hive : if it believes it carries food
  ;     eat               : if belief energy level is below max_energy and bee is at own hive
  ;     migrate           : if received message from queen

  ; SCOUTS:
  ;     walk around       : if no beliefs about food or location of new site -> observe (walk & look around)
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
; 1) move
; 2) migrate
; 3) eat
; 4) use energy

; 1) move
to move
  forward 1
end

; 2) migrate
to migrate
;  set target to newest message from queen
end

; 3) eat
; increase own energy by 1
; decrease food in hive
to eat
  set energy energy + gain_from_food
  ask my_home[
    set total_food_in_hive total_food_in_hive - 1
  ]
end

; 4) use energy
to use-energy
  set energy energy - energy_loss_rate
end

; ######################
; #    SCOUT METHODS   #
; ######################

  ; SCOUTS:
  ;     move                 --> move in random direction
  ;     look around          --> check sensors for food
  ;     fly to hive          --> move straight to own hive
  ;     tell worker about location of food --> send-messages (to workers)
  ;     tell queen about location & quality of new site --> send-messages (to queen)
  ;     migrate              --> move straight to new site location and set own hive to this location
  ;     eat                  --> energy + 1 & total_food_in_hive - 1

to execute-scout-actions
  ask scouts [
    ifelse intention == "move" [move][
    ifelse intention == "look around" [look-around][
    ifelse intention == "fly to hive" [fly-to-hive][
    ifelse intention == "tell worker about location of food" [tell-worker][
    ifelse intention == "tell queen about location and quality of new site" [tell-queen][
    ifelse intention == "migrate" [migrate][
    if intention == "eat"[eat]
    ]]]]]]

  ]
end

to calculate-quality
; If on a new patch, the quality of this patch is assessed.
; This is done by checking the list of known patches with food.
; Determine the 'total gain' - i.e. the sum of: (total food in patch) / (carrying capacity - energy cost to reach food)
; energy cost to reach food = (distance to patch) * 2 (to and from) * energy_loss_rate
; save the quality of the site
end

; ######################
; #   WORKER METHODS   #
; ######################

  ; WORKERS (always desires to collect food):
  ;     wait for message     --> swarm around at own hive
  ;     fly to location      --> move to potential food location (look around not yet necessary)
  ;     walk around          --> when location does not appear to have food, then walk & look around
  ;     look around          --> check sensors
  ;     collect food         --> carrying + 1 & food_value of food at location - 1
  ;     drop food in hive    --> carrying = 0 & total_food_in_hive += carrying
  ;     eat                  --> energy + 1 & total_food_in_hive - 1
  ;     migrate              --> move straight to new site location and set own hive to this location

; ######################
; #    QUEEN METHODS   #
; ######################

  ; QUEEN(S):
  ;     produce new worker-bee --> hatch 1 worker with characteristics (age, energy, own hive, etc.) at location
  ;     produce new scout-bee  --> hatch 1 scout with characteristics at location
  ;     produce new queen      --> hatch 1 queen with characteristics
  ;     tell others to migrate --> send-messages (to some workers and scouts)
  ;     migrate to new site    --> move straight to new site location and set own hive to this location
  ;     create new hive        --> create hive at own hive location and set total food & bees in this hive
  ;     eat                    --> energy + 1 & total_food_in_hive - 1


; --- Send messages ---
;to send messages
  ; scout -> worker          : set outgoing_messages to location of food and set incoming messages of SOME worker bees to this location.
  ; scout -> queen           : set outgoing_messages to location & quality of new site and set incoming_messages of queen to this.
  ; queen -> workers & scouts: set outgoing_messages to location of new site and set incoming_messages of SOME bees to this location.
;end
@#$#@#$#@
GRAPHICS-WINDOW
193
10
918
580
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
0
0
1
ticks
120.0

SLIDER
9
11
181
44
num-food-sources
num-food-sources
1
10
7
1
1
NIL
HORIZONTAL

BUTTON
44
202
111
235
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
46
248
109
281
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
9
49
181
82
initial-percentage
initial-percentage
5
25
13
1
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

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

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
