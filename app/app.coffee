ARENA_WIDTH = 640
ARENA_HEIGHT = 480
FPS = 40

MAX_SPEED_RING = 10
MAX_SPEED_BLING = 100


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
    @position = [@position[0]+vector[0], @position[1]+vector[1]]
    s = [vector[0] > 0, vector[1] > 0]
    if s[0]*(@position[0]-@target_position[0]) > 0 and s[1]*(@position[1]-@target_position[1]) > 0
      @position = @target_position
      @flags.moving = false
  move: (position) ->
    @target_position = position
    @flags.moving = true


class Bling extends Entity
  constructor: ->
    super()
    @hp = 40
    @max_speed = MAX_SPEED_BLING
    @color = 'lightgreen'


class Ring extends Entity
  constructor: ->
    super()
    @hp = 45
    @max_speed = MAX_SPEED_RING
    @color = 'darkblue'


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
          delete(e)
        else
          e.draw()
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
      x = e.x-arena.offsetLeft-arena.clientLeft
      y = e.y-arena.offsetTop-arena.clientTop
      @end = [x,y]
    document.onmousedown = (e) =>
      x = e.x-arena.offsetLeft-arena.clientLeft
      y = e.y-arena.offsetTop-arena.clientTop
      @start = [x,y]
    document.onmouseup = (e) =>
      x = e.x-arena.offsetLeft-arena.clientLeft
      y = e.y-arena.offsetTop-arena.clientTop
      @selectRegion(@start, @end)
      @start = false
  draw: ->
    if @start
      context.beginPath()
      context.rect(@start[0], @start[1], @end[0]-@start[0], @end[1]-@start[1])
      context.strokeStyle = 'black'
      context.stroke()
  selectRegion: (start, end) ->
    xs = [start[0], end[0]].sort()
    ys = [start[1], end[1]].sort()
    for i,e of BvR.arena.entities
      [x,y] = e.position
      e.flags.selected = x > xs[0] and x < xs[1] and y > ys[0] and y < ys[1]


r = new Ring()
r.position = [100,100]
r.move([200,300])
r.draw()

b = new Bling()
b.position = [500,100]
b.draw()


BvR =
  arena: new Arena()
  selector: new Selector()

BvR.arena.addEntity(r)
BvR.arena.addEntity(b)
