globals [
  daily-heat-index
  age-groups
  age-group
  age-weights
  count_dead
  count_hospitalized
  count_exhausted
  count_total
  hospital-duration
  total_exhausted
  total_hospitalized
  total_dead
  exhausted-counts   ; for each age group
  hospitalized-counts ; for each age group
]

turtles-own [
  heat-exposed?
  heat-exhausted?
  hospitalized?
  recovered?
  dead?
  age           ; Age of the individual
  rest-days
  rest-needed   ; Whether the individual needs rest to recover from heat exhaustion (true/false)
  hospital-time ; Time spent in the hospital (ticks)
  activity-level  ; Activity level of the individual (0 = low, 1 = moderate, 2 = high)
  comorbidity
]


to setup-environment
  set daily-heat-index 0
  set count_dead 0
  set count_hospitalized 0
  set count_exhausted 0
  set age-groups [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85]
  set age-weights [0.65 0.05 0.1 0.13 0.16 0.2 0.15 0.13 0.28 0.35 0.35 0.28 0.28 0.28 0.3 0.48 0.55 0.7]  ; mortality pattern
  ;set age-weights [0.09 0.1 0.32 0.6 0.50 0.48 0.45 0.38 0.35 0.35 0.32 0.25 0.23 0.22 0.21 0.21 0.21 0.17] ; morbidity pattern
  set exhausted-counts n-values length age-groups [0]
  set hospitalized-counts n-values length age-groups [0]
  set hospital-duration 4
end

to generate-random-boolean
  let random-value random-float 1
  ifelse random-value < 0.5 [
    set comorbidity true
  ] [
    set comorbidity false
  ]
end

to setup
  clear-all
  setup-environment
  create-turtles-for-age-groups
  set count_total count turtles
  ask turtles [
    setxy random-xcor random-ycor
    set shape "person"
    set activity-level 0
    set comorbidity one-of [true false]
    set heat-exposed? false
    set heat-exhausted? false
    set hospitalized? false
    set recovered? false
    set dead? false
   ]
  ask turtles [recolor]
  reset-ticks
end


to go
  if ticks <= 365 [
    update-environment
    update-individuals
    ask turtles [move]
    ask turtles [recolor]

    tick
  ]
  if ticks > 365 [
    print-exhausted-counts
    stop
  ]
  go
end

to create-turtles-for-age-groups
  let num-turtles-per-group 100

  ; Iterate over each age group
  let num-age-groups length age-groups
  let i 0
  while [i < num-age-groups - 1] [
    let lower-bound item i age-groups
    let upper-bound item (i + 1) age-groups

    ; Calculate the number of turtles for the current age group
    let num-turtles num-turtles-per-group

    ; Create turtles for the current age group
    create-turtles num-turtles [
      set age random (upper-bound - lower-bound) + lower-bound
    ]
    set i i + 1
  ]

  ; Handle the last age group (85+)
  let lower-bound item (num-age-groups - 1) age-groups
  let num-turtles num-turtles-per-group
  create-turtles num-turtles [
    let turtle-age lower-bound + random (100 - lower-bound + 1)
    set age turtle-age
  ]
end


to update-environment
  ; Calculate the current month based on ticks
  let current-month floor (ticks / 31)

  ; Calculate the average heat index for the current month
  let average-heat-indexes [28 29 29.5 32 33.5 37 37.2 39.5 35 31 30 29]
  let average-heat-index item current-month average-heat-indexes

  ; Calculate the daily heat index variation around the average heat index of the month
  let heat-index-variation random 4 - 2

  ; Calculate the daily heat index and update
  let current-heat-index average-heat-index + heat-index-variation
  set daily-heat-index current-heat-index
end



to move
  if dead? = false and hospitalized? = false
  [
    right random 150
    left random 150
    fd 1
  ]
end



to update-individuals
  ask turtles [
    calculate-risk
    if daily-heat-index > 27 [
      set heat-exposed? true
      set activity-level random 3 ; Randomize activity level between 0 and 2
      calculate-risk
    ]
    ifelse heat-exposed? [
      ifelse heat-exhausted? [
        set rest-days random-rest-days
        handle-rest-mechanism
      ] [
        ; Handle turtles not yet exhausted
        calculate-risk
      ]
    ] [
      ; Reset rest-days for turtles not exposed to heat
      set heat-exhausted? false
      set rest-days 0
    ]
    if hospitalized? [
      set hospital-time hospital-time + 1
      update-hospitalized-turtle
    ]
  ]
end



to handle-rest-mechanism
  if rest-days = 1 [
    if random-float 100 < 80 [
    set recovered? true
    set heat-exposed? false
    set heat-exhausted? false
    set rest-days 0
    ]
  ]
  if rest-days >= 2 and rest-days <= 3 [
    set heat-exposed? false
    set heat-exhausted? false
    recover-or-hospitalize
  ]
  if rest-days >= 4 [
    ; Death or further hospitalization
    set heat-exposed? false
    set heat-exhausted? false
    recover-or-die
  ]
end

to-report random-rest-days
  let random-value random-float 1
  ifelse random-value < 0.4 [
    ; 60% chance for 1 day of rest
    report 1
  ] [
    ; 40% chance for 2-3 days of rest
    ifelse random-value < 0.9 [
      report random 3 + 2 ; Generates a random number between 2 and 3
    ] [
      ; Remaining 10% chance for 4+ days of rest
      report random 4 + 1 ; Generates a random number 4+
    ]
  ]
end

to recover-or-hospitalize
  let age-index find-age-index age age-groups

  ; Determine if the individual recovers or hospitalize
  ifelse random-float 100 < 2 [
    set recovered? true
    set heat-exposed? false
    set heat-exhausted? false
    set hospitalized? false
    set hospital-time 0
    set count_hospitalized count_hospitalized - 1
  ] [
    ; Hospitalized with 98% probability
    set hospitalized? true
    set heat-exhausted? false
    set hospital-time hospital-time + 1 ; Increment hospital time
    set count_hospitalized count_hospitalized + 1
    if hospitalized? [set total_hospitalized total_hospitalized + 1]
    if hospitalized? [increase-hospitalized-count age-index]
    update-hospitalized-turtle
  ]
end

to update-hospitalized-turtle
  ifelse hospital-time >= hospital-duration [
    set recovered? true
    set count_hospitalized count_hospitalized - 1
  ] [
    ifelse recovered? [
      ; reset hospital-related variables
      set hospitalized? false
      set hospital-time 0
    ] [
      ; Increment hospital time if the turtle hasn't recovered yet
      set hospital-time hospital-time + 1
    ]
  ]
end

to recover-or-die
  ; Determine if the individual recovers from further hospitalization or dies
  ifelse random-float 100 < 92 [
    set recovered? true
    set heat-exposed? false
    set heat-exhausted? false
    ;set recovered? false
    set hospitalized? false
    set hospital-time 0

  ] [
    ; Die with 0.8% probability
    set dead? true
    set heat-exhausted? false
    set hospitalized? false
    set count_dead count_dead + 1
    if dead? [set total_dead total_dead + 1]
  ]
end




to calculate-risk
  let age-index find-age-index age age-groups
  let age-w item age-index age-weights

  let activity 0
  if activity-level = 0 [set activity 0]
  if activity-level = 1 [set activity 1]
  if activity-level = 2 [set activity 2]
  let comorbidity-w 0
  if comorbidity = false [set comorbidity-w 0]
  if comorbidity = true [set comorbidity-w 1]
  let risk-weight 0.1 * age-w + 0.1 * comorbidity-w + 0.05 * activity

  ifelse daily-heat-index >= 33 and daily-heat-index <= 41 [
    set heat-exhausted? random-float 1 < 0.0055 * risk-weight    ; 0.0055
    if heat-exhausted? [set total_exhausted total_exhausted + 1]
    if heat-exhausted? [increase-exhausted-count age-index]
  ][
    ifelse daily-heat-index >= 42 and daily-heat-index <= 51 [
      set heat-exhausted? random-float 1 < 0.08 * risk-weight    ; 0.08
      if heat-exhausted? [set total_exhausted total_exhausted + 1]
      if heat-exhausted? [increase-exhausted-count age-index]
    ][
      if daily-heat-index < 33 [
        set heat-exhausted? random-float 1 < 0.00020 * risk-weight  ; 0.0002
        if heat-exhausted? [set total_exhausted total_exhausted + 1]
        if heat-exhausted? [increase-exhausted-count age-index]
      ]
      if daily-heat-index > 51 [
        set heat-exhausted? random-float 1 < 0.12 * risk-weight
        if heat-exhausted? [set total_exhausted total_exhausted + 1]
        if heat-exhausted? [increase-exhausted-count age-index]
      ]
    ]
  ]
end


to increase-exhausted-count [index]
  let current-count item index exhausted-counts
  let updated-count current-count + 1
  set exhausted-counts replace-item index exhausted-counts updated-count
end

to increase-hospitalized-count [index]
  let current-count item index hospitalized-counts
  let updated-count current-count + 1
  set hospitalized-counts replace-item index hospitalized-counts updated-count
end


to-report find-age-index [turtle-age age-groups1]
  let index 0
  let stop-loop false
  while [index < length age-groups1 - 1 and not stop-loop] [
    ifelse turtle-age >= item index age-groups1 and turtle-age < item (index + 1) age-groups1 [
      set stop-loop true
    ] [
      set index index + 1
    ]
  ]
  if stop-loop = false [
    set index length age-groups1 - 1 ; If the age exceeds the maximum age group, set index to the last index
  ]
  report index
end



to print-exhausted-counts
  let num-age-groups length exhausted-counts
  let index 0
  while [index < num-age-groups] [
    let lower-bound item index age-groups
    let upper-bound item (index) age-groups
    let exhausted-count-item item index exhausted-counts
    let hospitalized-count-item item index hospitalized-counts
    print (word "Age group: " lower-bound "-" upper-bound " Exhausted count: " exhausted-count-item " Hospitalized count: " hospitalized-count-item)

    set index index + 1
  ]
end


to recolor ;; recolors agent
  ifelse heat-exposed? [set color [227 178 93]] [set color blue]
  if heat-exhausted? [set color red]
  if hospitalized? [set color white]
  if recovered? [set color yellow]
  if dead? [set color grey]
end
@#$#@#$#@
GRAPHICS-WINDOW
260
14
626
381
-1
-1
10.85
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
43
80
106
113
NIL
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
129
79
192
112
start
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
75
399
462
579
ED Visits
NIL
NIL
5.0
5.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -2139308 true "" "plot count turtles with [heat-exhausted?]"

PLOT
484
402
822
575
heat-index
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -3844592 true "" "plot daily-heat-index"

MONITOR
35
179
113
224
ED Visits
count turtles with [heat-exhausted? = true]
17
1
11

MONITOR
77
128
162
173
NIL
count turtles
17
1
11

MONITOR
167
324
228
369
dead %
(total_dead / count turtles) * 100
17
1
11

PLOT
643
235
886
385
mortality
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" "plot count turtles with [dead? = true]"

MONITOR
99
324
159
369
hosp %
(total_hospitalized / count turtles) * 100
17
1
11

MONITOR
30
323
91
368
ED V %
(total_exhausted / count turtles) * 100
17
1
11

MONITOR
96
267
159
312
NIL
total_hospitalized
17
1
11

MONITOR
166
269
230
314
NIL
total_dead
17
1
11

MONITOR
30
268
91
313
total_ED
total_exhausted
17
1
11

PLOT
645
74
886
224
hospitalized
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -12345184 true "" "plot count turtles with [hospitalized?]"

MONITOR
122
179
199
224
hospitalized
count turtles with [hospitalized? = true]
17
1
11

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
NetLogo 6.4.0
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
