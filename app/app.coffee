ARENA_WIDTH = 640
ARENA_HEIGHT = 480
FPS = 40

COLOR_RING = 'darkblue'
HP_RING = 45
MAX_SPEED_RING = 4
ATTACK_RATE_RING = 30
ATTACK_RANGE_RING = 300
ATTACK_DAMAGE_RING = 10

COLOR_BLING = 'lightgreen'
HP_BLING = 35
MAX_SPEED_BLING = 4*1.3
ATTACK_RANGE_BLING = 40
ATTACK_DAMAGE_BLING = 30


arena = document.getElementById('arena')
arena.width = ARENA_WIDTH
arena.height = ARENA_HEIGHT
context = arena.getContext('2d')


class Entity
  constructor: (kwargs) ->
    @radius = 6
    @flags =
      moving: false
      selected: false
      finished: false
    @max_speed = false
    @position = kwargs?.position or false
    @target_position = false
    @direction = false
  draw: ->
    @calculateNewPosition() if @flags.moving
    context.beginPath()
    context.arc(@position[0], @position[1], @radius, 2*Math.PI, false)
    context.fillStyle = @color
    if @flags.selected
      context.strokeStyle = 'orange'
      context.lineWidth = 3
      context.stroke()
    context.fill()
  mainLoop: ->
    @draw()
  calculateNewPosition: ->
    vector = [@target_position[0]-@position[0], @target_position[1]-@position[1]]
    m = Math.sqrt(Math.pow(vector[0],2)+Math.pow(vector[1],2))
    vector = [vector[0]*@max_speed/m, vector[1]*@max_speed/m]
    direction = [vector[0] > 0, vector[1] > 0]
    if direction[0] != @direction[0] or direction[1] != @direction[1]
      @flags.moving = false
      @direction = false
    else
      @position = [@position[0]+vector[0], @position[1]+vector[1]]
  move: (position) ->
    @target_position = position
    @direction = [@target_position[0]-@position[0] > 0, @target_position[1]-@position[1] > 0]
    @flags.moving = true


class Bling extends Entity
  constructor: (kwargs) ->
    super(kwargs)
    @hp = HP_BLING
    @max_speed = MAX_SPEED_BLING
    @frame_offset = ~~(Math.random()*20)
    @color = COLOR_BLING
    @target = false
  takeDamage: (hp) ->
    @hp -= hp
    @color = 'orange'
    if @hp <= 0
      @explode()
      BvR.selectors.kills.innerText = ++BvR.scores.kills
  checkNearbyEnemies: ->
    for i,e of BvR.arena.entities
      if e instanceof Ring and not e.flags.finished
        x = e.position[0]-@position[0]
        y = e.position[1]-@position[1]
        d2 = Math.pow(x,2)+Math.pow(y,2)
        if d2 < Math.pow(ATTACK_RANGE_BLING/2,2)
          @explode()
          break
  animate: ->
    @color = COLOR_BLING if BvR.frame % 2 == 0
    switch (BvR.frame + @frame_offset) % 40
      when 3 then @radius = 6
      when 37 then @radius = 6.8
  mainLoop: ->
    super()
    @animate()
    @checkNearbyEnemies()
    @attackNearest() if BvR.frame % 5 == 0
  draw: ->
    super()
    context.strokeStyle = 'darkgreen'
    context.lineWidth = 1
    context.stroke()
  explode: ->
    e = new Explosion
      position: @position
      radius: ATTACK_RANGE_BLING
      damage: ATTACK_DAMAGE_BLING
    BvR.arena.addEntity(e)
    @flags.finished = true
  attackNearest: ->
    unless @target_id and BvR.arena.entities[@target_id]
      candidates = []
      for i,e of BvR.arena.entities
        if e instanceof Ring
          x = e.position[0]-@position[0]
          y = e.position[1]-@position[1]
          d2 = Math.pow(x,2)+Math.pow(y,2)
          candidates.push([d2,i])
      if candidates.length > 0
        candidates.sort()
        @target_id = candidates[0][1]
    target = BvR.arena.entities[@target_id]
    @move(target.position) if target


class Ring extends Entity
  constructor: (kwargs) ->
    super(kwargs)
    @hp = HP_RING
    @max_speed = MAX_SPEED_RING
    @color = COLOR_RING
  checkNearbyEnemies: ->
    candidates = []
    for i,e of BvR.arena.entities
      if e instanceof Bling
        x = e.position[0]-@position[0]
        y = e.position[1]-@position[1]
        d2 = Math.pow(x,2)+Math.pow(y,2)
        if d2 < Math.pow(ATTACK_RANGE_RING,2)
          candidates.push([d2,i])
    if candidates.length > 0
      candidates.sort()
      target = BvR.arena.entities[candidates[0][1]]
      p = new Projectile
        position: @position
        target: target
        damage: ATTACK_DAMAGE_RING
      BvR.arena.addEntity(p)
      @color = 'yellow'
  mainLoop: ->
    super()
    @color = COLOR_RING if BvR.frame % 2 == 0
    @checkNearbyEnemies() if not @flags.moving and BvR.frame % ATTACK_RATE_RING == 0
  takeDamage: (hp) ->
    console.log('A ring took ' + hp + ' damage!')
    @hp -= hp
    @destroy() if @hp <= 0
  destroy: ->
    unless @flags.finished
      f = new FadeAway(position: @position, radius: @radius)
      BvR.arena.addEntity(f)
    @flags.finished = true


class FadeAway
  constructor: (kwargs) ->
    @position = kwargs.position
    @radius = kwargs.radius
    @color = 'rgba(0,0,139,1)'
    @opacity = 1
    @rate = 1/FPS
    @flags =
      finished: false
    console.log('New fadeaway...')
  draw: ->
    context.beginPath()
    context.arc(@position[0], @position[1], @radius, 2*Math.PI, false)
    context.fillStyle = @color
    context.fill()
  mainLoop: ->
    @color = 'rgba(0,0,139,' + @opacity + ')'
    @opacity -= @rate
    if @opacity > 0
      @draw()
    else
      @flags.finished = true


class Explosion
  constructor: (kwargs) ->
    @position = kwargs.position
    @r_max = kwargs.radius
    @r_max_2 = Math.pow(kwargs.radius,2)
    @damage = kwargs.damage
    @radius = 0
    @rate = 240/FPS
    @color = COLOR_BLING
    @flags =
      finished: false
    @damageNearbyEnemies()
  draw: ->
    context.beginPath()
    context.arc(@position[0], @position[1], @radius, 2*Math.PI, false)
    context.fillStyle = @color
    context.fill()
  mainLoop: ->
    @rate *= -1 if @radius >= @r_max
    @radius += @rate
    if @radius > 0
      @draw()
    else
      @flags.finished = true
  damageNearbyEnemies: ->
    for i,e of BvR.arena.entities
      if e instanceof Ring
        x = e.position[0]-@position[0]
        y = e.position[1]-@position[1]
        d2 = Math.pow(x,2)+Math.pow(y,2)
        if d2 <= @r_max_2
          e.takeDamage(@damage)


class Projectile
  constructor: (kwargs) ->
    @position = kwargs.position
    @target = kwargs.target
    @damage = kwargs.damage
    @direction = [@target.position[0]-@position[0] > 0, @target.position[1]-@position[1] > 0]
    @max_speed = 20
    @rate = 5
    @radius = 2
    @color = 'black'
    @flags =
      finished: false
  draw: ->
    context.beginPath()
    context.arc(@position[0], @position[1], @radius, 2*Math.PI, false)
    context.fillStyle = @color
    context.fill()
  mainLoop: ->
    unless @flags.finished
      @draw()
      vector = [@target.position[0]-@position[0], @target.position[1]-@position[1]]
      direction = [vector[0] > 0, vector[1] > 0]
      m = Math.sqrt(Math.pow(vector[0],2)+Math.pow(vector[1],2))
      vector = [vector[0]*@max_speed/m, vector[1]*@max_speed/m]
      if direction[0] != @direction[0] or direction[1] != @direction[1]
        @flags.finished = true
        @target.takeDamage(@damage)
      else
        @position = [@position[0]+vector[0], @position[1]+vector[1]]


class Arena
  constructor: ->
    @entities = {}
    @counter = 0
    @redrawLoop()
  redrawLoop: ->
    @interval = setInterval =>
      context.clearRect(0,0,ARENA_WIDTH,ARENA_HEIGHT)
      BvR.selector.draw()
      for i,e of @entities
        if e.flags?.finished
          delete @entities[i]
        else
          e.mainLoop()
      BvR.frame++
    , 1000/FPS
  addEntity: (e) ->
    @entities[@counter++] = e
  spawnBlings: (count) ->
    for i in [1..count]
      @addEntity(new Bling(position: [400+Math.random()*200, 20+Math.random()*300]))
  spawnRings: (count) ->
    for i in [1..count]
      @addEntity(new Ring(position: [20+Math.random()*50, 20+Math.random()*100]))


class Selector
  constructor: ->
    @start = false
    @end = false
    @bindKeys()
  bindKeys: ->
    document.onmousemove = (e) =>
      if @start
        x = e.x-arena.offsetLeft-arena.clientLeft
        y = e.y-arena.offsetTop-arena.clientTop
        @end = [x,y]
    document.onmousedown = (e) =>
      x = e.x-arena.offsetLeft-arena.clientLeft
      y = e.y-arena.offsetTop-arena.clientTop
      position = [x,y]
      if e.button == 2
        for i,e of BvR.arena.entities
          if e.flags.selected
            e.move(position)
            e.flags.selected = false
      else
        @start = position
    document.onmouseup = (e) =>
      @selectRegion(@start, @end)
    document.oncontextmenu = -> false
    document.onkeydown = (e) =>
      @deselectAll() if e.keyCode == 27
  draw: ->
    if @start and @end
      context.beginPath()
      context.rect(@start[0], @start[1], @end[0]-@start[0], @end[1]-@start[1])
      context.strokeStyle = 'black'
      context.stroke()
  mainLoop: -> @draw()
  deselectAll: ->
    for i,e of BvR.arena.entities
      if e instanceof Ring
        e.flags.selected = false
  selectRegion: (start, end) ->
    xs = if start[0]<end[0] then [start[0],end[0]] else [end[0],start[0]]
    ys = if start[1]<end[1] then [start[1],end[1]] else [end[1],start[1]]
    for i,e of BvR.arena.entities
      if e instanceof Ring
        [x,y] = e.position
        e.flags.selected = xs[0] < x < xs[1] and ys[0] < y < ys[1]
    @start = @end = false


window.BvR =
  arena: new Arena()
  selector: new Selector()
  frame: 0
  scores:
    kills: 0
  selectors:
    kills: document.getElementById('kills-count')


BvR.arena.spawnRings(5)
BvR.arena.spawnBlings(5)
