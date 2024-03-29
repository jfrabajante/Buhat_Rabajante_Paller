globals [ grass max-cleanfood max-infectedfood  max-zooplankton infected-population a k initial-number-cleanfood initial-number-infectedfood N infx infy trex trey reap treat]  ; keep track of how much grass there is
; Foods and fishes are both breeds of turtle.
breed [ zooplankton a-zooplankton ]  ; infectedfood is its own plural, so we use "a-cleanfood" as the singular.
breed [ cleanfood a-cleanfood ]  ; cleanfood is its own plural, so we use "a-cleanfood" as the singular.
breed [ infectedfood a-infectedfood ]  ; infectedfood is its own plural, so we use "a-cleanfood" as the singular.
breed [ fishes fish ]
turtles-own [ parasites ]       ; the fishes can gain parasites
patches-own [ countdown ]

to setup
  clear-all
  set max-zooplankton 100000
  set max-cleanfood 100000
  set max-infectedfood 100000
  ifelse add-infectionarea? [
  set infected-population (initial-fish-population / initial-number-zooplankton) ;as fish population increases, infection increases
  set a infected-population ;% of population infected by parasites
  set N initial-fish-population
  set initial-number-cleanfood initial-number-zooplankton * (1 - a)
    set initial-number-infectedfood initial-number-zooplankton * a]
  [set initial-number-cleanfood initial-number-zooplankton]
  set infx infection-area-size;pxcor <
  set infy infection-area-size;pycor >
  set trex treatment-area-size;pxcor >
  set trey treatment-area-size;pycor >
  set reap 0
  set treat 0
  ;
  ifelse add-treatment? [
  ask patches
  [ ifelse pxcor > treatment-area-size and pycor > treatment-area-size  ;with treatment
    [set pcolor white]
    [set pcolor blue] ]
  ]
  [ask patches [ set pcolor blue ] ]  ;no treatment
  set-default-shape cleanfood "leaf"
  create-cleanfood initial-number-cleanfood  ; create the clean food, then initialize their variables
  [
    set color green
    set size 1.5  ; easier to see
    set label-color blue - 2
    set parasites 0
    ;move-to one-of patches with [pxcor < 0 and pycor > 0] ;spatial position of clean
    setxy random-xcor random-ycor ;temporal
  ]

  set-default-shape infectedfood "leaf"
  create-infectedfood initial-number-infectedfood  ; create the initial food, then initialize their variables
  [
    set color red
    set size 1.5  ; easier to see
    set label-color blue - 2
    set parasites 0
    if add-infectionarea? [ move-to one-of patches with [pxcor < -1 * infx and pycor > infy] ];spatial position of infected
    ;move-to one-of patches with [(pxcor > 30 and pycor > 30) or (pxcor < -30 and pycor < -30)]
   ;setxy random-xcor random-ycor ;temporal
  ]

  set-default-shape fishes "fish"
  create-fishes initial-fish-population  ; create the fishes, then initialize their variables
  [
    set color yellow
    set size 2  ; easier to see
    set parasites 0 ;+ (parasite-load-in-zooplankton)
    setxy random-xcor random-ycor
  ]
  reset-ticks
end

to go
  if not any? infectedfood [ stop ]
  if ( count cleanfood + count infectedfood ) > 100000 [ stop ] ;world filled with grass
    if ( count fishes ) > 500000 [ stop ] ;world filled with fish
;  if not any? fishes and count cleanfood > max-sheep [ user-message "The sheep have inherited the earth" stop ]

  ask cleanfood [
    reproduce-cleanfood
    ;death
  ]

  ask infectedfood [
        reproduce-infectedfood
    ;death
  ]

  ask fishes [
    move
    bounce
    set parasites parasites - 0
    catch-cleanfood
    catch-infectedfood
    treatment
    death
    reproduce-fishes

  ]
  tick
  display-labels
end

to move  ; turtle procedure
  rt random 50
  lt random 50
  fd 1
end

to bounce  ;for turtles to not stay on the edge
      if (pxcor = min-pxcor or pycor = min-pycor or pxcor = max-pxcor or pycor = max-pycor)
  [  set heading (heading + 180) mod 360]
end

to reproduce-cleanfood  ; clean food procedure
  if random-float 100 < zooplankton-reproduction-rate [  ; throw "dice" to see if you will reproduce
;    set parasites (parasites / 2)                ; divide parasites between parent and offspring
    hatch 1 [ setxy random-xcor random-ycor ] ; hatch an offspring and place it anywhere
 ;   hatch 1 [ rt random-float 360 fd 1 ]   ; hatch an offspring and move it forward 1 step
  ]
end

to reproduce-infectedfood  ; infected food procedure
  if add-infectionarea? [
  if random-float 100 < zooplankton-reproduction-rate [  ; throw "dice" to see if you will reproduce
   ; set parasites (parasites / 2)             ; divide parasites between parent and offspring
    hatch 1 [ setxy random-xcor random-ycor ] ; hatch an offspring and place it anywhere
   ;hatch 1 [move-to one-of patches with [pxcor < -1 * infx and pycor > infy]] ;hatch an offspring and place it in infection area
     ; hatch 1 [move-to one-of patches with [(pxcor > 30 and pycor > 30) or (pxcor < -30 and pycor < -30)]];clutering
   ; hatch 1 [ rt random-float 360 fd 1 ]   ; hatch an offspring and move it forward 1 step
  ]
  ]
end

to reproduce-fishes  ; fish procedure
  if random-float 100 < fish-reproduction-rate [  ; throw "dice" to see if you will reproduce
    set parasites (parasites / 2)               ; divide parasites between parent and offspring
    hatch 1 [ setxy random-xcor random-ycor] ; hatch an offspring and place it anywhere

    ;hatch 1 [ rt random-float 360 fd 1 ]  ; hatch an offspring and move it forward 1 step
  ]
end

to catch-cleanfood  ; fish procedure
  let prey one-of cleanfood-here                ; grab a random food
  if prey != nobody                             ; did we get one?  if so,
    [ ask prey [ die ]                          ; kill it
     ; if parasites > 0 [
    ;    set parasites parasites - 1 ]          ; remove parasites from eating ;treament
  ]
end

to catch-infectedfood  ; fish procedure
  let prey one-of infectedfood-here                    ; grab a random food
  if prey != nobody                             ; did we get one?  if so,
    [ ask prey [ die ]                          ; kill it
  set parasites parasites + random-poisson parasite-load-in-zooplankton ] ; random poisson gain of parasites from eating
; set parasites parasites + parasite-load-in-zooplankton ] ; get parasites from eating
end

to treatment
if add-treatment? [
  if xcor > trex and ycor > trey [
        if parasites > 0 [
        set treat treat + 1 ]     ;counts no. of parasites treated
        if parasites > 0 [
        set parasites parasites - 1 ] ; treats parasites

  ] ; treatment zone
  ]
 ;      if parasites > 0 [
 ;       set parasites parasites - 1 ] ; treatment all
end

to death  ; turtle procedure
  ; when parasites reaches above 10, die

  if parasites > fatal-parasite-load [ set reap reap + 1 ]
    if parasites > fatal-parasite-load [ die ]

end

to display-labels
  ask turtles [ set label "" ]
  if show-parasites? [
    ask fishes [ set label round parasites ]
   ; if grass? [ ask sheep [ set label round parasites ] ]
  ]
end



; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
357
10
849
503
-1
-1
4.8
1
14
1
1
1
0
0
0
1
-50
50
-50
50
1
1
1
ticks
30.0

SLIDER
179
95
352
128
initial-fish-population
initial-fish-population
50
550
150.0
100
1
NIL
HORIZONTAL

SLIDER
1
131
175
164
parasite-load-in-zooplankton
parasite-load-in-zooplankton
2
10
4.0
2
1
NIL
HORIZONTAL

SLIDER
177
166
351
199
fish-reproduction-rate
fish-reproduction-rate
0.0
1.5
0.25
.25
1
%
HORIZONTAL

BUTTON
8
28
77
61
setup
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
90
28
157
61
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
13
75
153
94
Zooplankton settings
11
0.0
0

TEXTBOX
187
74
300
92
Fish settings
11
0.0
0

SWITCH
167
28
313
61
show-parasites?
show-parasites?
0
1
-1000

PLOT
4
214
351
495
Frequency of Parasite Load in Fish Host
No of Parasites
Fishes
0.0
80.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [parasites] of fishes"

MONITOR
966
199
1026
244
Infected
count infectedfood
17
1
11

MONITOR
910
199
967
244
Clean
count cleanfood
17
1
11

MONITOR
856
199
909
244
Fishes
count fishes
17
1
11

SLIDER
2
165
175
198
zooplankton-reproduction-rate
zooplankton-reproduction-rate
0
3
0.0
.5
1
%
HORIZONTAL

SLIDER
178
131
350
164
fatal-parasite-load
fatal-parasite-load
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
2
95
174
128
initial-number-zooplankton
initial-number-zooplankton
550
5550
3550.0
1000
1
NIL
HORIZONTAL

MONITOR
856
294
1027
339
% infected-population
a
4
1
11

MONITOR
853
408
1023
453
Variance
variance [parasites] of fishes
5
1
11

TEXTBOX
1180
401
1330
419
NIL
11
0.0
1

MONITOR
854
357
1024
402
Mean 
mean [parasites] of fishes
5
1
11

MONITOR
853
457
1022
502
Measure of Aggregation (k)
( ( mean [parasites] of fishes ^ 2 ) - ( ( variance [parasites] of fishes ) / N ) ) / ( ( variance [parasites] of fishes ) - ( mean [parasites] of fishes ) )
5
1
11

TEXTBOX
858
182
1008
200
Monitors
11
0.0
1

TEXTBOX
859
341
1042
369
========Output========
11
0.0
1

SLIDER
855
148
1026
181
infection-area-size
infection-area-size
-50
40
0.0
10
1
NIL
HORIZONTAL

SLIDER
852
60
1025
93
treatment-area-size
treatment-area-size
-50
40
20.0
10
1
NIL
HORIZONTAL

MONITOR
856
247
936
292
Dead Fishes
reap
17
1
11

MONITOR
935
247
1027
292
Treated Parasites
treat
17
1
11

SWITCH
852
27
1025
60
add-treatment?
add-treatment?
0
1
-1000

SWITCH
854
115
1026
148
add-infectionarea?
add-infectionarea?
0
1
-1000

TEXTBOX
853
10
1003
28
Treatment Area settings
11
0.0
1

TEXTBOX
855
97
1005
115
Infection Area settings
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model explores the stability of predator-prey ecosystems. Such a system is called unstable if it tends to result in extinction for one or more species involved.  In contrast, a system is stable if it tends to maintain itself over time, despite fluctuations in population sizes.

## HOW IT WORKS

There are two main variations to this model.

In the first variation, wolves and sheep wander randomly around the landscape, while the wolves look for sheep to prey on. Each step costs the wolves energy, and they must eat sheep in order to replenish their energy - when they run out of energy they die. To allow the population to continue, each wolf or sheep has a fixed probability of reproducing at each time step. This variation produces interesting population dynamics, but is ultimately unstable.

The second variation includes grass (green) in addition to wolves and sheep. The behavior of the wolves is identical to the first variation, however this time the sheep must eat grass in order to maintain their energy - when they run out of energy they die. Once grass is eaten it will only regrow after a fixed amount of time. This variation is more complex than the first, but it is generally stable.

The construction of this model is described in two papers by Wilensky & Reisman referenced below.

## HOW TO USE IT

1. Set the GRASS? switch to TRUE to include grass in the model, or to FALSE to only include wolves (red) and sheep (white).
2. Adjust the slider parameters (see below), or use the default settings.
3. Press the SETUP button.
4. Press the GO button to begin the simulation.
5. Look at the monitors to see the current population sizes
6. Look at the POPULATIONS plot to watch the populations fluctuate over time

Parameters:
INITIAL-NUMBER-SHEEP: The initial size of sheep population
INITIAL-NUMBER-WOLVES: The initial size of wolf population
SHEEP-GAIN-FROM-FOOD: The amount of energy sheep get for every grass patch eaten
WOLF-GAIN-FROM-FOOD: The amount of energy wolves get for every sheep eaten
SHEEP-REPRODUCE: The probability of a sheep reproducing at each time step
WOLF-REPRODUCE: The probability of a wolf reproducing at each time step
GRASS?: Whether or not to include grass in the model
GRASS-REGROWTH-TIME: How long it takes for grass to regrow once it is eaten
SHOW-ENERGY?: Whether or not to show the energy of each animal as a number

Notes:
- one unit of energy is deducted for every step a wolf takes
- when grass is included, one unit of energy is deducted for every step a sheep takes

## THINGS TO NOTICE

When grass is not included, watch as the sheep and wolf populations fluctuate. Notice that increases and decreases in the sizes of each population are related. In what way are they related? What eventually happens?

Once grass is added, notice the green line added to the population plot representing fluctuations in the amount of grass. How do the sizes of the three populations appear to relate now? What is the explanation for this?

Why do you suppose that some variations of the model might be stable while others are not?

## THINGS TO TRY

Try adjusting the parameters under various settings. How sensitive is the stability of the model to the particular parameters?

Can you find any parameters that generate a stable ecosystem that includes only wolves and sheep?

Try setting GRASS? to TRUE, but setting INITIAL-NUMBER-WOLVES to 0. This gives a stable ecosystem with only sheep and grass. Why might this be stable while the variation with only sheep and wolves is not?

Notice that under stable settings, the populations tend to fluctuate at a predictable pace. Can you find any parameters that will speed this up or slow it down?

Try changing the reproduction rules -- for example, what would happen if reproduction depended on energy rather than being determined by a fixed probability?

## EXTENDING THE MODEL

There are a number ways to alter the model so that it will be stable with only wolves and sheep (no grass). Some will require new elements to be coded in or existing behaviors to be changed. Can you develop such a version?

Can you modify the model so the sheep will flock?

Can you modify the model so that wolf actively chase sheep?

## NETLOGO FEATURES

Note the use of breeds to model two different kinds of "turtles": wolves and sheep. Note the use of patches to model grass.

Note use of the ONE-OF agentset reporter to select a random sheep to be eaten by a wolf.

## RELATED MODELS

Look at Rabbits Grass Weeds for another model of interacting populations with different rules.

## CREDITS AND REFERENCES

Wilensky, U. & Reisman, K. (1999). Connected Science: Learning Biology through Constructing and Testing Computational Theories -- an Embodied Modeling Approach. International Journal of Complex Systems, M. 234, pp. 1 - 12. (This model is a slightly extended version of the model described in the paper.)

Wilensky, U. & Reisman, K. (2006). Thinking like a Wolf, a Sheep or a Firefly: Learning Biology through Constructing and Testing Computational Theories -- an Embodied Modeling Approach. Cognition & Instruction, 24(2), pp. 171-209. http://ccl.northwestern.edu/papers/wolfsheep.pdf

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Wolf Sheep Predation model.  http://ccl.northwestern.edu/netlogo/models/WolfSheepPredation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2000.

<!-- 1997 2000 -->
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
NetLogo 6.0.4
@#$#@#$#@
set grass? true
setup
repeat 75 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Aggregation Experiment Trial" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean [parasites] of fishes</metric>
    <enumeratedValueSet variable="parasite-load-in-zooplankton">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zooplankton-reproduction-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatal-parasite-load">
      <value value="80"/>
    </enumeratedValueSet>
    <steppedValueSet variable="initial-number-zooplankton" first="550" step="1000" last="5550"/>
    <enumeratedValueSet variable="fish-reproduction-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="initial-fish-population" first="50" step="100" last="550"/>
    <enumeratedValueSet variable="show-parasites?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean [parasites] of fishes</metric>
    <metric>variance [parasites] of fishes</metric>
    <metric>( ( mean [parasites] of fishes ^ 2 ) - ( ( variance [parasites] of fishes ) / N ) ) / ( ( variance [parasites] of fishes ) - ( mean [parasites] of fishes ) )</metric>
    <metric>a</metric>
    <enumeratedValueSet variable="zooplankton-reproduction-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="parasite-load-in-zooplankton">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatal-parasite-load">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-zooplankton">
      <value value="550"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-reproduction-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-fish-population">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-parasites?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Aggregation Experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>( ( mean [parasites] of fishes ^ 2 ) - ( ( variance [parasites] of fishes ) / N ) ) / ( ( variance [parasites] of fishes ) - ( mean [parasites] of fishes ) )</metric>
    <steppedValueSet variable="initial-number-zooplankton" first="550" step="1000" last="5550"/>
    <steppedValueSet variable="initial-fish-population" first="50" step="100" last="550"/>
    <steppedValueSet variable="zooplankton-reproduction-rate" first="0" step="0.5" last="3"/>
    <steppedValueSet variable="fish-reproduction-rate" first="0" step="0.25" last="1.5"/>
    <steppedValueSet variable="parasite-load-in-zooplankton" first="2" step="2" last="10"/>
    <enumeratedValueSet variable="fatal-parasite-load">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-parasites?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Aggregation Experiment spatial 1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>( ( mean [parasites] of fishes ^ 2 ) - ( ( variance [parasites] of fishes ) / N ) ) / ( ( variance [parasites] of fishes ) - ( mean [parasites] of fishes ) )</metric>
    <enumeratedValueSet variable="initial-number-zooplankton">
      <value value="550"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-fish-population">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="zooplankton-reproduction-rate" first="0" step="0.5" last="3"/>
    <steppedValueSet variable="fish-reproduction-rate" first="0" step="0.25" last="1.5"/>
    <steppedValueSet variable="parasite-load-in-zooplankton" first="2" step="2" last="10"/>
    <enumeratedValueSet variable="fatal-parasite-load">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-parasites?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Aggregation Experiment complete spatial" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>( ( mean [parasites] of fishes ^ 2 ) - ( ( variance [parasites] of fishes ) / N ) ) / ( ( variance [parasites] of fishes ) - ( mean [parasites] of fishes ) )</metric>
    <steppedValueSet variable="initial-number-zooplankton" first="550" step="1000" last="5550"/>
    <steppedValueSet variable="initial-fish-population" first="50" step="100" last="550"/>
    <steppedValueSet variable="zooplankton-reproduction-rate" first="0" step="0.5" last="3"/>
    <steppedValueSet variable="fish-reproduction-rate" first="0" step="0.25" last="1.5"/>
    <steppedValueSet variable="parasite-load-in-zooplankton" first="2" step="2" last="10"/>
    <steppedValueSet variable="infcor" first="0" step="10" last="40"/>
    <steppedValueSet variable="trecor" first="0" step="10" last="40"/>
    <enumeratedValueSet variable="fatal-parasite-load">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-parasites?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Aggregation Experiment spatial fixed popu" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>( ( mean [parasites] of fishes ^ 2 ) - ( ( variance [parasites] of fishes ) / N ) ) / ( ( variance [parasites] of fishes ) - ( mean [parasites] of fishes ) )</metric>
    <enumeratedValueSet variable="initial-number-zooplankton">
      <value value="550"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-fish-population">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="zooplankton-reproduction-rate" first="0" step="0.5" last="3"/>
    <steppedValueSet variable="fish-reproduction-rate" first="0" step="0.25" last="1.5"/>
    <steppedValueSet variable="parasite-load-in-zooplankton" first="2" step="2" last="10"/>
    <steppedValueSet variable="infcor" first="0" step="10" last="40"/>
    <steppedValueSet variable="trecor" first="0" step="10" last="40"/>
    <enumeratedValueSet variable="fatal-parasite-load">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-parasites?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Aggregation Experiment spatial fixed popu treatment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>( ( mean [parasites] of fishes ^ 2 ) - ( ( variance [parasites] of fishes ) / N ) ) / ( ( variance [parasites] of fishes ) - ( mean [parasites] of fishes ) )</metric>
    <enumeratedValueSet variable="initial-number-zooplankton">
      <value value="550"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-fish-population">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="zooplankton-reproduction-rate" first="0" step="0.5" last="3"/>
    <steppedValueSet variable="fish-reproduction-rate" first="0" step="0.25" last="1.5"/>
    <steppedValueSet variable="parasite-load-in-zooplankton" first="2" step="2" last="10"/>
    <steppedValueSet variable="trecor" first="0" step="10" last="40"/>
    <enumeratedValueSet variable="infcor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatal-parasite-load">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-parasites?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="clustering" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="parasite-load-in-zooplankton">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zooplankton-reproduction-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-infectionarea?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection-area-size">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatal-parasite-load">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-zooplankton">
      <value value="5550"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fish-reproduction-rate">
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
      <value value="1.25"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-treatment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-fish-population">
      <value value="550"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-parasites?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="treatment-area-size">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
