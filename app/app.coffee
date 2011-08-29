ARENA_WIDTH = 640
ARENA_HEIGHT = 480
FPS = 40

MAX_SPEED_RING = 10
MAX_SPEED_BLING = 100

ATTACK_RANGE_RING = 80
ATTACK_RANGE_BLING = 20

ATTACK_DAMAGE_RING = 6
ATTACK_DAMAGE_BLING = 30


arena = document.getElementById('arena')
arena.width = ARENA_WIDTH
arena.height = ARENA_HEIGHT
context = arena.getContext('2d')


class Entity
  constructor: ->
    @radius = 6
    @flags =
      moving: false
      selected: false
      finished: false
    @max_speed = false
    @position = false
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
  constructor: ->
    super()
    @hp = 40
    @max_speed = MAX_SPEED_BLING
    @frame_offset = ~~(Math.random()*20)
    @color = 'lightgreen'
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
  draw: ->
    super()
    @animate()
    @checkNearbyEnemies()
  explode: ->
    e = new Explosion
      position: @position
      radius: ATTACK_RANGE_BLING
      damage: ATTACK_DAMAGE_BLING
    BvR.arena.addEntity(e)
    @flags.finished = true


class Ring extends Entity
  constructor: ->
    super()
    @hp = 45
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
  draw: ->
    super()
    @checkNearbyEnemies() unless @flags.moving
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
          e.draw()
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


r0 = new Ring()
r0.position = [100,100]
r0.draw()
BvR.arena.addEntity(r0)

r1 = new Ring()
r1.position = [120,100]
r1.draw()
BvR.arena.addEntity(r1)


b0 = new Bling()
b0.position = [500,100]
b0.draw()
BvR.arena.addEntity(b0)

b1 = new Bling()
b1.position = [550,120]
b1.draw()
BvR.arena.addEntity(b1)

b2 = new Bling()
b2.position = [500,80]
b2.draw()
BvR.arena.addEntity(b2)

