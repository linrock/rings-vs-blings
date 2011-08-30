ARENA_WIDTH = 640
ARENA_HEIGHT = 480
GRID_SIZE = 20

FPS = 40
RADIUS = 8
RADIUS_2 = RADIUS*RADIUS

COLOR_RING = 'darkblue'
HP_RING = 45
MAX_SPEED_RING = 2.25
ATTACK_RATE_RING = ~~(0.8608*40)
ATTACK_RANGE_RING = 200
ATTACK_DAMAGE_RING = 6

COLOR_BLING = 'lightgreen'
HP_BLING = 35
MAX_SPEED_BLING = 2.9531 # 2.5
ATTACK_RANGE_BLING = 40
ATTACK_DAMAGE_BLING = 30


arena = document.getElementById('arena')
arena.width = ARENA_WIDTH
arena.height = ARENA_HEIGHT
context = arena.getContext('2d')


class Entity
  constructor: (kwargs) ->
    @radius = RADIUS
    @flags =
      moving: false
      selected: false
      finished: false
    @max_speed = false
    @position = kwargs?.position or false
    @target_position = false
    @direction = false
    @frame_offset = ~~(Math.random()*100)
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
    @color = COLOR_BLING
    @target = false
  takeDamage: (hp) ->
    @hp -= hp
    @color = 'orange'
    if @hp <= 0 and not @flags.finished
      @explode()
      BvR.selectors.kills.innerText = ++BvR.stats.kills
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
      when 3 then @radius = RADIUS
      when 37 then @radius = RADIUS+1
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
    @checkNearbyEnemies() if not @flags.moving and (BvR.frame+@frame_offset) % ATTACK_RATE_RING == 0
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
    @mainLoop()
  mainLoop: ->
    @interval = setInterval =>
      context.clearRect(0,0,ARENA_WIDTH,ARENA_HEIGHT)
      BvR.selector.draw()
      for i,e of @entities
        if e.flags?.finished
          delete BvR.collisions.id_lookup[i]
          delete @entities[i]
        else
          BvR.collisions.updateEntity(i, e.position) if e.flags?.moving?
          BvR.collisions.handleCollisions(i)
          e.mainLoop()
      BvR.frame++
    , 1000/FPS
  addEntity: (e) ->
    @entities[@counter] = e
    BvR.collisions.updateEntity(@counter, e.position)
    @counter++
  spawnEntity: (count, type = Bling) ->
    generatePosition = =>
      if type == Bling
        position = [300+Math.random()*300, 150+Math.random()*300]
      else
        position = [20+Math.random()*150, 20+Math.random()*150]
      for i,e of @entities
        if e instanceof type
          [x,y] = e.position
          if Math.pow(position[0]-x,2)+Math.pow(position[1]-y,2) < RADIUS_2*4
            return generatePosition()
      position
    for i in [1..count]
      @addEntity(new type(position: generatePosition()))
  nextWave: ->
    BvR.selectors.wave.innerText = ++BvR.stats.wave


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
      if e.button == 0
        @start = position
      else if e.button == 2
        for i,e of BvR.arena.entities
          if e.flags.selected
            e.move(position)
    document.onmouseup = (e) =>
      if e.button == 0
        @selectRegion(@start, @end)
        x = e.x-arena.offsetLeft-arena.clientLeft
        y = e.y-arena.offsetTop-arena.clientTop
        for i,e of BvR.arena.entities
          if e instanceof Ring and Math.pow(e.position[0]-x,2) + Math.pow(e.position[1]-y,2) < RADIUS_2
            e.flags.selected = true
            break
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


class CollisionGrid
  constructor: ->
    @grid_lookup = {}
    @id_lookup = {}
    @initializeLookupTable()
  initializeLookupTable: ->
    for x in [0..ARENA_WIDTH/GRID_SIZE-2]
      for y in [0..ARENA_HEIGHT/GRID_SIZE-2]
        @grid_lookup[[x,y]] = {}
  updateEntity: (id, position) ->
    x = [~~((position[0]-RADIUS)/GRID_SIZE), ~~((position[0]+RADIUS)/GRID_SIZE)]
    x = [x[0]] if x[0] == x[1]
    y = [~~((position[1]-RADIUS)/GRID_SIZE), ~~((position[1]+RADIUS)/GRID_SIZE)]
    y = [y[0]] if y[0] == y[1]
    for xy,junk of @id_lookup[id]
      delete @grid_lookup[xy][id]
    @id_lookup[id] = {}
    for x0 in x
      for y0 in y
        @id_lookup[id][[x0,y0]] = true
        @grid_lookup[[x0,y0]][id] = true
  detectCollisions: (id) ->
    position = BvR.arena.entities[id].position
    collisions = {}
    for xy,junk of @id_lookup[id]
      for i,junk of @grid_lookup[xy]
        if id+'' != i+''
          break unless e = BvR.arena.entities[i]
          p = e.position
          if Math.pow(p[0]-position[0],2)+Math.pow(p[1]-position[1],2) < 4*RADIUS_2
            collisions[i] = p
    collisions
  handleCollisions: (id) ->
    e = BvR.arena.entities[id]
    for i,position of @detectCollisions(id)
      [x,y] = position
      e.position = [e.position[0]+(e.position[0]-x)*0.05, e.position[1]+(e.position[1]-y)*0.05]


window.BvR =
  arena: new Arena()
  selector: new Selector()
  collisions: new CollisionGrid()
  frame: 0
  stats:
    kills: 0
    wave: 0
  selectors:
    kills: document.getElementById('kills-count')
    wave: document.getElementById('wave-count')


BvR.arena.spawnEntity(30, Ring)
BvR.arena.spawnEntity(30, Bling)
