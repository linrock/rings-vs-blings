ARENA_WIDTH = 960
ARENA_HEIGHT = 600
GRID_SIZE = 20

FPS = 60
RADIUS = 9
RADIUS_2 = RADIUS*RADIUS

SELECTOR_FILL = 'rgba(102,255,0,0.1)'
SELECTOR_BORDER = 'green'

MOVE_NORMAL = 0
MOVE_ATTACK = 1

RING_SPAWN_CENTER = [200,200]
BLING_SPAWN_CENTER = [700,500]

COLOR_RING = 'rgb(50,100,255)'
COLOR_RING_BERSERK = 'rgb(30,180,255)'
HP_RING = 45
MAX_SPEED_RING = 2.25*40/FPS
ATTACK_RATE_RING = ~~(0.8608*FPS)
ATTACK_RANGE_RING = 160
ATTACK_DAMAGE_RING = 6
BERSERK_DURATION = 15*FPS

COLOR_BLING = 'rgb(102,255,0)'
HP_BLING = 30
MAX_SPEED_BLING = 2.9531*40/FPS # 2.5
ATTACK_RANGE_BLING = 160/3
ATTACK_DAMAGE_BLING = 35


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
    @properties =
      collides: true
      selectable: false
    @max_speed = false
    @move_queue = []
    @position = kwargs?.position or false
    @target_position = false
    @direction = false
    @frame_offset = ~~(Math.random()*100)
  draw: ->
    context.beginPath()
    context.arc(@position[0], @position[1], @radius, 2*Math.PI, false)
    context.fillStyle = @color
    if @flags.selected
      context.strokeStyle = 'lightgreen'
      context.lineWidth = 3
      context.stroke()
    context.fill()
  mainLoop: ->
    @calculateNewPosition() if @flags.moving or @move_queue.length > 0
    @draw()
  calculateNewPosition: ->
    if @move_queue.length > 0 and @flags.moving == false
      @move(@move_queue.shift())
    else
      vector = [@target_position[0]-@position[0], @target_position[1]-@position[1]]
      m = Math.sqrt(Math.pow(vector[0],2)+Math.pow(vector[1],2))
      vector = [vector[0]*@max_speed/m, vector[1]*@max_speed/m]
      direction = [vector[0] > 0, vector[1] > 0]
      if direction[0] != @direction[0] or direction[1] != @direction[1]
        @flags.moving = false
        @direction = false
      else
        @setPosition([@position[0]+vector[0], @position[1]+vector[1]])
  move: (position, queue = false) ->
    if queue
      @move_queue.push(@boundedPosition(position))
    else
      @setTargetPosition(position)
      @direction = [@target_position[0]-@position[0] > 0, @target_position[1]-@position[1] > 0]
      @flags.moving = true
  boundedPosition: (position) ->
    position[0] = @radius+Math.random()*0.5 if position[0] <= @radius
    position[0] = ARENA_WIDTH-@radius if position[0] >= ARENA_WIDTH-@radius
    position[1] = @radius+Math.random()*0.5 if position[1] <= @radius
    position[1] = ARENA_HEIGHT-@radius if position[1] >= ARENA_HEIGHT-@radius
    position
  setTargetPosition: (position) ->
    @target_position = @boundedPosition(position)
  setPosition: (position) ->
    @position = @boundedPosition(position)
  destroy: ->
    @flags.finished = true


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
      @destroy()
      BvR.selectors.kills.innerText = ++BvR.stats.kills
  checkNearbyEnemies: ->
    for i,e of BvR.arena.entities
      if e instanceof Ring and not e.flags.finished
        x = e.position[0]-@position[0]
        y = e.position[1]-@position[1]
        d2 = Math.pow(x,2)+Math.pow(y,2)
        if d2 < Math.pow(ATTACK_RANGE_BLING/2,2)
          @destroy()
          break
  animate: ->
    @color = COLOR_BLING if BvR.frame % 2 == 0
    switch (BvR.frame + @frame_offset) % 30
      when 0 then @radius = RADIUS
      when 21 then @radius = RADIUS*1.08
      when 25 then @radius = RADIUS*1.15
      when 29 then @radius = RADIUS*1.08
  mainLoop: ->
    super()
    @animate()
    @checkNearbyEnemies()
    @attackNearest() if BvR.frame % 5 == 0
  draw: ->
    super()
    context.strokeStyle = 'darkgreen'
    context.lineWidth = 2
    context.stroke()
  destroy: ->
    e = new Explosion
      position: @position
      radius: ATTACK_RANGE_BLING
      damage: ATTACK_DAMAGE_BLING
    BvR.arena.addEntity(e)
    @flags.finished = true
  attackNearest: ->
    candidates = []
    for i,e of BvR.arena.entities
      if e instanceof Ring
        [x,y] = [e.position[0]-@position[0], e.position[1]-@position[1]]
        d2 = Math.pow(x,2)+Math.pow(y,2)
        candidates.push([d2,i])
    if candidates.length > 0
      closest = candidates.sort()[0]
      if target = BvR.arena.entities[@target_id]
        [x,y] = target.position
        d2 = Math.pow(x,2)+Math.pow(y,2)
        if closest[0] < 0.1*d2
          @target_id = closest[1]
      else
        @target_id = closest[1]
      target = BvR.arena.entities[@target_id]
      @move(target.position)



class Ring extends Entity
  constructor: (kwargs) ->
    super(kwargs)
    @hp = HP_RING
    @max_speed = MAX_SPEED_RING
    @attack_damage = ATTACK_DAMAGE_RING
    @color = COLOR_RING
    @berserk_start = 0
    @last_attack_at = 0
    @flags.berserk = false
    @properties.selectable = true
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
        damage: @attack_damage
      BvR.arena.addEntity(p)
      @last_attack_at = BvR.frame
      @color = 'yellow'
  draw: ->
    super()
    context.strokeStyle = '#2f2f2f'
    context.lineWidth = 1
    context.stroke()
  mainLoop: ->
    if @flags.berserk
      if @berserk_start + BERSERK_DURATION > BvR.frame
        @max_speed = MAX_SPEED_RING*1.5
        @attack_damage = ATTACK_DAMAGE_RING*1.5
        @color = COLOR_RING_BERSERK if BvR.frame % 5 == 0
      else
        @flags.berserk = false
        @max_speed = MAX_SPEED_RING
        @attack_damage = ATTACK_DAMAGE_RING
    else
      @color = COLOR_RING if BvR.frame % 5 == 0
    super()
    if not @flags.moving and BvR.frame > (ATTACK_RATE_RING+@last_attack_at)
      @checkNearbyEnemies()
  takeDamage: (hp) ->
    @hp -= hp
    @destroy() if @hp <= 0
  berserk: ->
    if @hp > 10
      @hp -= 10
      @flags.berserk = true
      @berserk_start = BvR.frame
  destroy: ->
    unless @flags.finished
      f = new FadeAway
        position: @position,
        radius: @radius,
        color_code: [50,100,255]
      BvR.arena.addEntity(f)
    @flags.finished = true


class FadeAway
  constructor: (kwargs) ->
    @position = kwargs.position
    @radius = kwargs.radius
    @color_code = kwargs.color_code
    @rate = kwargs.rate or 1/FPS
    @opacity = 1
    @setColor(@color_code)
    @flags =
      finished: false
  draw: ->
    context.beginPath()
    context.arc(@position[0], @position[1], @radius, 2*Math.PI, false)
    context.fillStyle = @color
    context.fill()
  mainLoop: ->
    @setColor()
    @opacity -= @rate
    if @opacity > 0
      @draw()
    else
      @flags.finished = true
  setColor: ->
    @color = 'rgba('+@color_code[0]+','+@color_code[1]+','+@color_code[2]+','+@opacity+')'


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
    if @radius >= @r_max
      @fadeOut()
      @rate *= -1
    @radius += @rate
    if @radius > 0
      @draw()
    else
      @destroy()
  damageNearbyEnemies: ->
    for i,e of BvR.arena.entities
      if e instanceof Ring
        x = e.position[0]-@position[0]
        y = e.position[1]-@position[1]
        d2 = Math.pow(x,2)+Math.pow(y,2)
        if d2 <= @r_max_2
          e.takeDamage(@damage)
  fadeOut: ->
    unless @flags.finished
      f = new FadeAway
        position: @position
        radius: @r_max
        color_code: [102,255,0]
        rate: 1.5/FPS
      BvR.arena.addEntity(f)
  destroy: ->
    @flags.finished = true


class Projectile
  constructor: (kwargs) ->
    @position = kwargs.position
    @target = kwargs.target
    @damage = kwargs.damage
    @color = kwargs.color || 'rgba(255,255,0,0.8)'
    @direction = [@target.position[0]-@position[0] > 0, @target.position[1]-@position[1] > 0]
    @max_speed = 25
    @rate = 5
    @radius = 2
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
    @interval = false
    @counter = 0
    @mainLoop()
  mainLoop: ->
    @interval = setInterval =>
      context.clearRect(0,0,ARENA_WIDTH,ARENA_HEIGHT)
      for i,e of @entities
        if e.flags?.finished
          @deleteEntity(i)
        else
          BvR.collisions.updateEntity(i, e.position) if e.properties?.collides
          BvR.collisions.handleCollisions(i)
          e.mainLoop()
      BvR.selector.draw()
      BvR.frame++
    , 1000/FPS
  addEntity: (e) ->
    @entities[@counter] = e
    BvR.collisions.updateEntity(@counter, e.position) if e.properties?.collides
    @counter++
  deleteEntity: (id) ->
    delete BvR.collisions.id_lookup[id]
    delete @entities[id]
  spawnEntity: (count, type = Bling) ->
    checkPositionAvailable = (position) =>
      for i,e of @entities
        if e instanceof type
          [x,y] = e.position
          return true if Math.pow(position[0]-x,2)+Math.pow(position[1]-y,2) < RADIUS_2*4
      true
    if type == Ring
      center = RING_SPAWN_CENTER
    else
      center = BLING_SPAWN_CENTER
    positions = [center]
    for i in [1..count]
      angle = Math.random()*2*Math.PI
      m = (RADIUS+1)
      v = [m*Math.cos(angle), m*Math.sin(angle)]
      position = positions[positions.length-1]
      new_position = [position[0]+v[0],position[1]+v[1]]
      until checkPositionAvailable(new_position)
        new_position = [position[0]+v[0],position[1]+v[1]]
      positions.push(new_position)
      @addEntity(new type(position: new_position))
  nextWave: ->
    BvR.selectors.wave.innerText = ++BvR.stats.wave


class DirectionIndicator
  constructor: ->
    @properties =
      visible: false
      collides: false
      selectable: false
    @begin = false
    @end = false
  mainLoop: -> @draw()
  draw: ->
    if @begin and @end
      context.moveTo(@begin)
      context.lineTo(@end)
      context.strokeStyle = 'green'
      context.stroke()


class MoveIndicator
  constructor: (kwargs) ->
    @type = kwargs.type || MOVE_NORMAL
    @position = kwargs.position
    @flags =
      finished: false
  mainLoop: -> @draw()
  draw: ->
    unless @flags.finished
      f = new FadeAway
        position: @position,
        radius: 5,
        rate: 1/FPS
        color_code: [50,205,50]
      BvR.arena.addEntity(f)
    @flags.finished = true


class Selector
  constructor: ->
    @start = false
    @end = false
    @bindKeys()
  bindKeys: ->
    getOffsets = (e) ->
      x = e.x-arena.offsetParent.offsetLeft+arena.clientLeft+window.pageXOffset
      y = e.y-arena.offsetTop-arena.clientTop+window.pageYOffset
      [x,y]
    document.onselectstart = (e) ->
      e.preventDefault()
    document.onmousemove = (e) =>
      @end = getOffsets(e) if @start
    document.onmousedown = (e) =>
      position = getOffsets(e)
      switch e.button
        when 0
          @start = position
        when 2
          for i,entity of BvR.arena.entities
            if entity.flags.selected
              if e.shiftKey
                entity.move(position, true)
              else
                entity.move(position)
              m = new MoveIndicator(position: position)
              BvR.arena.addEntity(m)
    document.onmouseup = (e) =>
      if e.button == 0
        @selectRegion(@start, @end)
        [x,y] = getOffsets(e)
        for i,entity of BvR.arena.entities
          if entity.properties?.selectable and Math.pow(entity.position[0]-x,2)+Math.pow(entity.position[1]-y,2) < RADIUS_2
            entity.flags.selected = true
            break
    document.oncontextmenu = -> false
    document.onkeydown = (e) =>
      switch e.keyCode
        when 27 # esc
          @deselectAll()
        when 72 # h
          for i,entity of BvR.arena.entities
            if entity.flags.selected
              entity.flags.moving = false
        when 84 # t
          for i,entity of BvR.arena.entities
            if entity instanceof Ring and entity.flags.selected
              entity.berserk()
  draw: ->
    if @start and @end
      context.fillStyle = SELECTOR_FILL
      context.fillRect(@start[0], @start[1], @end[0]-@start[0], @end[1]-@start[1])
      context.strokeStyle = SELECTOR_BORDER
      context.lineWidth = 3
      context.rect(@start[0], @start[1], @end[0]-@start[0], @end[1]-@start[1])
      context.stroke()
  mainLoop: -> @draw()
  deselectAll: ->
    for i,e of BvR.arena.entities
      if e.properties?.selectable
        e.flags.selected = false
  selectRegion: (start, end) ->
    xs = if start[0]<end[0] then [start[0],end[0]] else [end[0],start[0]]
    ys = if start[1]<end[1] then [start[1],end[1]] else [end[1],start[1]]
    for i,e of BvR.arena.entities
      if e.properties?.selectable
        [x,y] = e.position
        e.flags.selected = xs[0] < x < xs[1] and ys[0] < y < ys[1]
    @start = @end = false


class CollisionGrid
  constructor: ->
    @grid_lookup = {}
    @id_lookup = {}
    @initializeLookupTable()
  initializeLookupTable: ->
    for x in [0..ARENA_WIDTH/GRID_SIZE]
      for y in [0..ARENA_HEIGHT/GRID_SIZE]
        @grid_lookup[[x,y]] = {}
  updateEntity: (id, position) ->
    return unless id and position
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
    [x,y] = BvR.arena.entities[id].position
    collisions = {}
    for xy,junk of @id_lookup[id]
      for i,junk of @grid_lookup[xy]
        if i+'' != id+''
          if e = BvR.arena.entities[i]
            p = e.position
            if Math.pow(p[0]-x,2)+Math.pow(p[1]-y,2) <= 4*RADIUS_2
              collisions[i] = p
          else
            BvR.arena.deleteEntity(i)
    collisions
  handleCollisions: (id) ->
    e0 = BvR.arena.entities[id]
    for i,position of @detectCollisions(id)
      offset = [(e0.position[0]-position[0])*0.1, (e0.position[1]-position[1])*0.1]
      e0.setPosition([e0.position[0]+offset[0], e0.position[1]+offset[1]])



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


BvR.arena.spawnEntity(60, Ring)
BvR.arena.spawnEntity(45, Bling)
