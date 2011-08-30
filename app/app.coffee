ARENA_WIDTH = 640
ARENA_HEIGHT = 480
FPS = 40

HP_RING = 45
MAX_SPEED_RING = 10
ATTACK_RATE_RING = 30
ATTACK_RANGE_RING = 80
ATTACK_DAMAGE_RING = 6

HP_BLING = 35
MAX_SPEED_BLING = 5
ATTACK_RANGE_BLING = 20
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
    @color = 'lightgreen'
    @target = false
  takeDamage: (hp) ->
    @hp -= hp
    @explode() if @hp <= 0
  checkNearbyEnemies: ->
    for i,e of BvR.arena.entities
      if e instanceof Ring
        x = e.position[0]-@position[0]
        y = e.position[1]-@position[1]
        d = Math.sqrt(Math.pow(x,2)+Math.pow(y,2))
        if d < ATTACK_RANGE_BLING/2
          @explode()
          break
  animate: ->
    if (BvR.frame + @frame_offset) % 40 == 3
      @radius = 6
    else if (BvR.frame + @frame_offset) % 40 == 37
      @radius = 6.8
  mainLoop: ->
    super()
    @animate()
    @checkNearbyEnemies()
    @attackNearest() if BvR.frame % ~~(FPS/3) == 0
  explode: ->
    e = new Explosion
      position: @position
      radius: ATTACK_RANGE_BLING
      damage: ATTACK_DAMAGE_BLING
    BvR.arena.addEntity(e)
    @flags.finished = true
  attackNearest: ->
    unless @target_id and BvR.arena.entities[@target_id]
      for i,e of BvR.arena.entities
        if e instanceof Ring
          @target_id = i
          break
    @move(BvR.arena.entities[@target_id].position)


class Ring extends Entity
  constructor: (kwargs) ->
    super(kwargs)
    @hp = HP_RING
    @max_speed = MAX_SPEED_RING
    @color = 'darkblue'
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
      BvR.arena.entities[candidates[0][1]].takeDamage(ATTACK_DAMAGE_RING)
  mainLoop: ->
    super()
    @checkNearbyEnemies() if not @flags.moving and BvR.frame % ATTACK_RATE_RING == 0
  takeDamage: (hp) ->
    console.log('Took ' + hp + ' damage')
    @hp -= hp
    @flags.finished = true if @hp <= 0


class Explosion
  constructor: (kwargs) ->
    @position = kwargs.position
    @r_max = kwargs.radius
    @r_max_2 = Math.pow(kwargs.radius,2)
    @damage = kwargs.damage
    @radius = 0
    @rate = 120/FPS
    @color = 'lightgreen'
    @flags =
      finished: false
    @damageNearbyEnemies()
  draw: ->
    @rate *= -1 if @radius >= @r_max
    @radius += @rate
    if @radius > 0
      context.beginPath()
      context.arc(@position[0], @position[1], @radius, 2*Math.PI, false)
      context.fillStyle = @color
      context.fill()
    else
      @flags.finished = true
  mainLoop: -> @draw()
  damageNearbyEnemies: ->
    for i,e of BvR.arena.entities
      if e instanceof Ring
        x = e.position[0]-@position[0]
        y = e.position[1]-@position[1]
        d2 = Math.pow(x,2)+Math.pow(y,2)
        if d2 <= @r_max_2
          e.takeDamage(@damage)


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
    xs = [Math.min(start[0],end[0]), Math.max(start[0],end[0])]
    ys = [Math.min(start[1],end[1]), Math.max(start[1],end[1])]
    for i,e of BvR.arena.entities
      if e instanceof Ring
        [x,y] = e.position
        e.flags.selected = xs[0] < x < xs[1] and ys[0] < y < ys[1]
    @start = @end = false


window.BvR =
  arena: new Arena()
  selector: new Selector()
  frame: 0


BvR.arena.addEntity(r) for r in [
  new Ring(position: [100,100]),
  new Ring(position: [120,100])
  new Ring(position: [80,70])
]
BvR.arena.addEntity(b) for b in [
  new Bling(position: [500,100]),
  new Bling(position: [550,120]),
  new Bling(position: [500,80])
  new Bling(position: [530,70])
  new Bling(position: [450,170])
  new Bling(position: [480,200])
]
