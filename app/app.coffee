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
  draw: ->
    @calculateNewPosition() if @flags.moving
    context.beginPath()
    context.arc(@position[0], @position[1], @radius, 2*Math.PI, false)
    context.fillStyle = @color
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
    @redrawLoop()
  redrawLoop: ->
    @interval = setInterval ->
      context.clearRect(0,0,ARENA_WIDTH,ARENA_HEIGHT)
      e.draw() for e in entities
    , 1000/FPS


class Selection
  constructor: ->
    @start = false
    @end = false
    @bindKeys()
  bindKeys: ->
    document.onmousemove = (e) ->
      x = e.x-arena.offsetLeft-arena.clientLeft
      y = e.y-arena.offsetTop-arena.clientTop
      @end = [x,y]
      if @start
        context.fillRect(@start[0], @start[1], @end[0], @end[1])
    document.onmousedown = (e) ->
      console.dir(arena)
      x = e.x-arena.offsetLeft-arena.clientLeft
      y = e.y-arena.offsetTop-arena.clientTop
      @start = [x,y]
    document.onmouseup = (e) ->
      x = e.x-arena.offsetLeft-arena.clientLeft
      y = e.y-arena.offsetTop-arena.clientTop
      @start = false
      # context.fillRect(x, y, 50, 50)


r = new Ring()
r.position = [100,100]
r.move([200,300])
r.draw()

b = new Bling()
b.position = [500,100]
b.draw()

entities = []
entities.push(r)
entities.push(b)


new Arena()
new Selection()
