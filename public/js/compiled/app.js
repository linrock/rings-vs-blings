(function() {
  var ARENA_HEIGHT, ARENA_WIDTH, ATTACK_DAMAGE_BLING, ATTACK_DAMAGE_RING, ATTACK_RANGE_BLING, ATTACK_RANGE_RING, ATTACK_RATE_RING, Arena, BERSERK_DURATION, Bling, COLOR_BLING, COLOR_RING, COLOR_RING_BERSERK, CollisionGrid, DirectionIndicator, Entity, Explosion, FPS, FadeAway, GRID_SIZE, HP_BLING, HP_RING, MAX_SPEED_BLING, MAX_SPEED_RING, Projectile, RADIUS, RADIUS_2, Ring, SELECTOR_BORDER, SELECTOR_FILL, Selector, arena, context;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  ARENA_WIDTH = 800;
  ARENA_HEIGHT = 480;
  GRID_SIZE = 20;
  FPS = 40;
  RADIUS = 9;
  RADIUS_2 = RADIUS * RADIUS;
  SELECTOR_FILL = 'rgba(102,255,0,0.1)';
  SELECTOR_BORDER = 'green';
  COLOR_RING = 'darkblue';
  COLOR_RING_BERSERK = 'deepskyblue';
  HP_RING = 45;
  MAX_SPEED_RING = 2.25;
  ATTACK_RATE_RING = ~~(0.8608 * FPS);
  ATTACK_RANGE_RING = 200;
  ATTACK_DAMAGE_RING = 6;
  BERSERK_DURATION = 15 * FPS;
  COLOR_BLING = 'rgb(102,255,0)';
  HP_BLING = 30;
  MAX_SPEED_BLING = 2.9531;
  ATTACK_RANGE_BLING = 40;
  ATTACK_DAMAGE_BLING = 35;
  arena = document.getElementById('arena');
  arena.width = ARENA_WIDTH;
  arena.height = ARENA_HEIGHT;
  context = arena.getContext('2d');
  Entity = (function() {
    function Entity(kwargs) {
      this.radius = RADIUS;
      this.flags = {
        moving: false,
        selected: false,
        finished: false
      };
      this.properties = {
        collides: true,
        selectable: false
      };
      this.max_speed = false;
      this.move_queue = [];
      this.position = (kwargs != null ? kwargs.position : void 0) || false;
      this.target_position = false;
      this.direction = false;
      this.frame_offset = ~~(Math.random() * 100);
    }
    Entity.prototype.draw = function() {
      context.beginPath();
      context.arc(this.position[0], this.position[1], this.radius, 2 * Math.PI, false);
      context.fillStyle = this.color;
      if (this.flags.selected) {
        context.strokeStyle = 'orange';
        context.lineWidth = 3;
        context.stroke();
      }
      return context.fill();
    };
    Entity.prototype.mainLoop = function() {
      if (this.flags.moving || this.move_queue.length > 0) {
        this.calculateNewPosition();
      }
      return this.draw();
    };
    Entity.prototype.calculateNewPosition = function() {
      var direction, m, vector;
      if (this.move_queue.length > 0 && this.flags.moving === false) {
        return this.move(this.move_queue.shift());
      } else {
        vector = [this.target_position[0] - this.position[0], this.target_position[1] - this.position[1]];
        m = Math.sqrt(Math.pow(vector[0], 2) + Math.pow(vector[1], 2));
        vector = [vector[0] * this.max_speed / m, vector[1] * this.max_speed / m];
        direction = [vector[0] > 0, vector[1] > 0];
        if (direction[0] !== this.direction[0] || direction[1] !== this.direction[1]) {
          this.flags.moving = false;
          return this.direction = false;
        } else {
          return this.setPosition([this.position[0] + vector[0], this.position[1] + vector[1]]);
        }
      }
    };
    Entity.prototype.move = function(position, queue) {
      if (queue == null) {
        queue = false;
      }
      if (queue) {
        return this.move_queue.push(this.boundedPosition(position));
      } else {
        this.setTargetPosition(position);
        this.direction = [this.target_position[0] - this.position[0] > 0, this.target_position[1] - this.position[1] > 0];
        return this.flags.moving = true;
      }
    };
    Entity.prototype.boundedPosition = function(position) {
      if (position[0] <= this.radius) {
        position[0] = this.radius + Math.random() * 0.5;
      }
      if (position[0] >= ARENA_WIDTH - this.radius) {
        position[0] = ARENA_WIDTH - this.radius;
      }
      if (position[1] <= this.radius) {
        position[1] = this.radius + Math.random() * 0.5;
      }
      if (position[1] >= ARENA_HEIGHT - this.radius) {
        position[1] = ARENA_HEIGHT - this.radius;
      }
      return position;
    };
    Entity.prototype.setTargetPosition = function(position) {
      return this.target_position = this.boundedPosition(position);
    };
    Entity.prototype.setPosition = function(position) {
      return this.position = this.boundedPosition(position);
    };
    Entity.prototype.destroy = function() {
      return this.flags.finished = true;
    };
    return Entity;
  })();
  Bling = (function() {
    __extends(Bling, Entity);
    function Bling(kwargs) {
      Bling.__super__.constructor.call(this, kwargs);
      this.hp = HP_BLING;
      this.max_speed = MAX_SPEED_BLING;
      this.color = COLOR_BLING;
      this.target = false;
    }
    Bling.prototype.takeDamage = function(hp) {
      this.hp -= hp;
      this.color = 'orange';
      if (this.hp <= 0 && !this.flags.finished) {
        this.destroy();
        return BvR.selectors.kills.innerText = ++BvR.stats.kills;
      }
    };
    Bling.prototype.checkNearbyEnemies = function() {
      var d2, e, i, x, y, _ref, _results;
      _ref = BvR.arena.entities;
      _results = [];
      for (i in _ref) {
        e = _ref[i];
        if (e instanceof Ring && !e.flags.finished) {
          x = e.position[0] - this.position[0];
          y = e.position[1] - this.position[1];
          d2 = Math.pow(x, 2) + Math.pow(y, 2);
          if (d2 < Math.pow(ATTACK_RANGE_BLING / 2, 2)) {
            this.destroy();
            break;
          }
        }
      }
      return _results;
    };
    Bling.prototype.animate = function() {
      if (BvR.frame % 2 === 0) {
        this.color = COLOR_BLING;
      }
      switch ((BvR.frame + this.frame_offset) % 30) {
        case 0:
          return this.radius = RADIUS;
        case 21:
          return this.radius = RADIUS * 1.05;
        case 25:
          return this.radius = RADIUS * 1.1;
        case 29:
          return this.radius = RADIUS * 1.05;
      }
    };
    Bling.prototype.mainLoop = function() {
      Bling.__super__.mainLoop.call(this);
      this.animate();
      this.checkNearbyEnemies();
      if (BvR.frame % 5 === 0) {
        return this.attackNearest();
      }
    };
    Bling.prototype.draw = function() {
      Bling.__super__.draw.call(this);
      context.strokeStyle = 'darkgreen';
      context.lineWidth = 2;
      return context.stroke();
    };
    Bling.prototype.destroy = function() {
      var e;
      e = new Explosion({
        position: this.position,
        radius: ATTACK_RANGE_BLING,
        damage: ATTACK_DAMAGE_BLING
      });
      BvR.arena.addEntity(e);
      return this.flags.finished = true;
    };
    Bling.prototype.attackNearest = function() {
      var candidates, d2, e, i, target, x, y, _ref;
      if (!(this.target_id && BvR.arena.entities[this.target_id])) {
        candidates = [];
        _ref = BvR.arena.entities;
        for (i in _ref) {
          e = _ref[i];
          if (e instanceof Ring) {
            x = e.position[0] - this.position[0];
            y = e.position[1] - this.position[1];
            d2 = Math.pow(x, 2) + Math.pow(y, 2);
            candidates.push([d2, i]);
          }
        }
        if (candidates.length > 0) {
          candidates.sort();
          this.target_id = candidates[0][1];
        }
      }
      if (target = BvR.arena.entities[this.target_id]) {
        return this.move(target.position);
      }
    };
    return Bling;
  })();
  Ring = (function() {
    __extends(Ring, Entity);
    function Ring(kwargs) {
      Ring.__super__.constructor.call(this, kwargs);
      this.hp = HP_RING;
      this.max_speed = MAX_SPEED_RING;
      this.attack_damage = ATTACK_DAMAGE_RING;
      this.color = COLOR_RING;
      this.berserk_start = 0;
      this.flags.berserk = false;
      this.properties.selectable = true;
    }
    Ring.prototype.checkNearbyEnemies = function() {
      var candidates, d2, e, i, p, target, x, y, _ref;
      candidates = [];
      _ref = BvR.arena.entities;
      for (i in _ref) {
        e = _ref[i];
        if (e instanceof Bling) {
          x = e.position[0] - this.position[0];
          y = e.position[1] - this.position[1];
          d2 = Math.pow(x, 2) + Math.pow(y, 2);
          if (d2 < Math.pow(ATTACK_RANGE_RING, 2)) {
            candidates.push([d2, i]);
          }
        }
      }
      if (candidates.length > 0) {
        candidates.sort();
        target = BvR.arena.entities[candidates[0][1]];
        p = new Projectile({
          position: this.position,
          target: target,
          damage: this.attack_damage
        });
        BvR.arena.addEntity(p);
        return this.color = 'yellow';
      }
    };
    Ring.prototype.mainLoop = function() {
      if (BvR.frame % 2 === 0) {
        this.color = COLOR_RING;
      }
      if (this.flags.berserk) {
        if (this.berserk_start + BERSERK_DURATION > BvR.frame) {
          this.max_speed = MAX_SPEED_RING * 1.5;
          this.attack_damage = ATTACK_DAMAGE_RING * 1.5;
          if (BvR.frame % 2 === 0) {
            this.color = COLOR_RING_BERSERK;
          }
        } else {
          this.flags.berserk = false;
          this.max_speed = MAX_SPEED_RING;
          this.attack_damage = ATTACK_DAMAGE_RING;
        }
      }
      Ring.__super__.mainLoop.call(this);
      if (!this.flags.moving && (BvR.frame + this.frame_offset) % ATTACK_RATE_RING === 0) {
        return this.checkNearbyEnemies();
      }
    };
    Ring.prototype.takeDamage = function(hp) {
      if (this.hp -= hp <= 0) {
        return this.destroy();
      }
    };
    Ring.prototype.berserk = function() {
      if (this.hp > 10) {
        console.log('BERSERK');
        this.hp -= 10;
        this.flags.berserk = true;
        return this.berserk_start = BvR.frame;
      }
    };
    Ring.prototype.destroy = function() {
      var f;
      if (!this.flags.finished) {
        f = new FadeAway({
          position: this.position,
          radius: this.radius,
          color_code: [0, 0, 139]
        });
        BvR.arena.addEntity(f);
      }
      return this.flags.finished = true;
    };
    return Ring;
  })();
  FadeAway = (function() {
    function FadeAway(kwargs) {
      this.position = kwargs.position;
      this.radius = kwargs.radius;
      this.color_code = kwargs.color_code;
      this.rate = kwargs.rate || 1 / FPS;
      this.opacity = 1;
      this.setColor(this.color_code);
      this.flags = {
        finished: false
      };
    }
    FadeAway.prototype.draw = function() {
      context.beginPath();
      context.arc(this.position[0], this.position[1], this.radius, 2 * Math.PI, false);
      context.fillStyle = this.color;
      return context.fill();
    };
    FadeAway.prototype.mainLoop = function() {
      this.setColor();
      this.opacity -= this.rate;
      if (this.opacity > 0) {
        return this.draw();
      } else {
        return this.flags.finished = true;
      }
    };
    FadeAway.prototype.setColor = function() {
      return this.color = 'rgba(' + this.color_code[0] + ',' + this.color_code[1] + ',' + this.color_code[2] + ',' + this.opacity + ')';
    };
    return FadeAway;
  })();
  Explosion = (function() {
    function Explosion(kwargs) {
      this.position = kwargs.position;
      this.r_max = kwargs.radius;
      this.r_max_2 = Math.pow(kwargs.radius, 2);
      this.damage = kwargs.damage;
      this.radius = 0;
      this.rate = 240 / FPS;
      this.color = COLOR_BLING;
      this.flags = {
        finished: false
      };
      this.damageNearbyEnemies();
    }
    Explosion.prototype.draw = function() {
      context.beginPath();
      context.arc(this.position[0], this.position[1], this.radius, 2 * Math.PI, false);
      context.fillStyle = this.color;
      return context.fill();
    };
    Explosion.prototype.mainLoop = function() {
      if (this.radius >= this.r_max) {
        this.fadeOut();
        this.rate *= -1;
      }
      this.radius += this.rate;
      if (this.radius > 0) {
        return this.draw();
      } else {
        return this.destroy();
      }
    };
    Explosion.prototype.damageNearbyEnemies = function() {
      var d2, e, i, x, y, _ref, _results;
      _ref = BvR.arena.entities;
      _results = [];
      for (i in _ref) {
        e = _ref[i];
        _results.push(e instanceof Ring ? (x = e.position[0] - this.position[0], y = e.position[1] - this.position[1], d2 = Math.pow(x, 2) + Math.pow(y, 2), d2 <= this.r_max_2 ? e.takeDamage(this.damage) : void 0) : void 0);
      }
      return _results;
    };
    Explosion.prototype.fadeOut = function() {
      var f;
      if (!this.flags.finished) {
        f = new FadeAway({
          position: this.position,
          radius: this.r_max,
          color_code: [102, 255, 0],
          rate: 1.5 / FPS
        });
        return BvR.arena.addEntity(f);
      }
    };
    Explosion.prototype.destroy = function() {
      return this.flags.finished = true;
    };
    return Explosion;
  })();
  Projectile = (function() {
    function Projectile(kwargs) {
      this.position = kwargs.position;
      this.target = kwargs.target;
      this.damage = kwargs.damage;
      this.direction = [this.target.position[0] - this.position[0] > 0, this.target.position[1] - this.position[1] > 0];
      this.max_speed = 20;
      this.rate = 5;
      this.radius = 2;
      this.color = 'black';
      this.flags = {
        finished: false
      };
    }
    Projectile.prototype.draw = function() {
      context.beginPath();
      context.arc(this.position[0], this.position[1], this.radius, 2 * Math.PI, false);
      context.fillStyle = this.color;
      return context.fill();
    };
    Projectile.prototype.mainLoop = function() {
      var direction, m, vector;
      if (!this.flags.finished) {
        this.draw();
        vector = [this.target.position[0] - this.position[0], this.target.position[1] - this.position[1]];
        direction = [vector[0] > 0, vector[1] > 0];
        m = Math.sqrt(Math.pow(vector[0], 2) + Math.pow(vector[1], 2));
        vector = [vector[0] * this.max_speed / m, vector[1] * this.max_speed / m];
        if (direction[0] !== this.direction[0] || direction[1] !== this.direction[1]) {
          this.flags.finished = true;
          return this.target.takeDamage(this.damage);
        } else {
          return this.position = [this.position[0] + vector[0], this.position[1] + vector[1]];
        }
      }
    };
    return Projectile;
  })();
  Arena = (function() {
    function Arena() {
      this.entities = {};
      this.interval = false;
      this.counter = 0;
      this.mainLoop();
    }
    Arena.prototype.mainLoop = function() {
      return this.interval = setInterval(__bind(function() {
        var e, i, _ref, _ref2, _ref3;
        context.clearRect(0, 0, ARENA_WIDTH, ARENA_HEIGHT);
        _ref = this.entities;
        for (i in _ref) {
          e = _ref[i];
          if ((_ref2 = e.flags) != null ? _ref2.finished : void 0) {
            this.deleteEntity(i);
          } else {
            if ((_ref3 = e.properties) != null ? _ref3.collides : void 0) {
              BvR.collisions.updateEntity(i, e.position);
            }
            BvR.collisions.handleCollisions(i);
            e.mainLoop();
          }
        }
        BvR.selector.draw();
        return BvR.frame++;
      }, this), 1000 / FPS);
    };
    Arena.prototype.addEntity = function(e) {
      var _ref;
      this.entities[this.counter] = e;
      if ((_ref = e.properties) != null ? _ref.collides : void 0) {
        BvR.collisions.updateEntity(this.counter, e.position);
      }
      return this.counter++;
    };
    Arena.prototype.deleteEntity = function(id) {
      delete BvR.collisions.id_lookup[id];
      return delete this.entities[id];
    };
    Arena.prototype.spawnEntity = function(count, type) {
      var generatePosition, i, _results;
      if (type == null) {
        type = Bling;
      }
      generatePosition = __bind(function() {
        var e, i, position, x, y, _ref, _ref2;
        if (type === Bling) {
          position = [550 + Math.random() * 200, 230 + Math.random() * 200];
        } else {
          position = [50 + Math.random() * 150, 50 + Math.random() * 150];
        }
        _ref = this.entities;
        for (i in _ref) {
          e = _ref[i];
          if (e instanceof type) {
            _ref2 = e.position, x = _ref2[0], y = _ref2[1];
            if (Math.pow(position[0] - x, 2) + Math.pow(position[1] - y, 2) < RADIUS_2 * 4) {
              return generatePosition();
            }
          }
        }
        return position;
      }, this);
      _results = [];
      for (i = 1; 1 <= count ? i <= count : i >= count; 1 <= count ? i++ : i--) {
        _results.push(this.addEntity(new type({
          position: generatePosition()
        })));
      }
      return _results;
    };
    Arena.prototype.nextWave = function() {
      return BvR.selectors.wave.innerText = ++BvR.stats.wave;
    };
    return Arena;
  })();
  DirectionIndicator = (function() {
    function DirectionIndicator() {
      this.properties = {
        visible: false,
        collides: false,
        selectable: false
      };
      this.begin = false;
      this.end = false;
    }
    DirectionIndicator.prototype.mainLoop = function() {
      return this.draw();
    };
    DirectionIndicator.prototype.draw = function() {
      if (this.begin && this.end) {
        context.moveTo(this.begin);
        context.lineTo(this.end);
        context.strokeStyle = 'green';
        return context.stroke();
      }
    };
    return DirectionIndicator;
  })();
  Selector = (function() {
    function Selector() {
      this.start = false;
      this.end = false;
      this.bindKeys();
    }
    Selector.prototype.bindKeys = function() {
      var getOffsets;
      getOffsets = function(e) {
        var x, y;
        x = e.x - arena.offsetLeft - arena.clientLeft + window.pageXOffset;
        y = e.y - arena.offsetTop - arena.clientTop + window.pageYOffset;
        return [x, y];
      };
      document.onselectstart = function(e) {
        return e.preventDefault();
      };
      document.onmousemove = __bind(function(e) {
        if (this.start) {
          return this.end = getOffsets(e);
        }
      }, this);
      document.onmousedown = __bind(function(e) {
        var entity, i, position, _ref, _results;
        position = getOffsets(e);
        if (e.button === 0) {
          return this.start = position;
        } else if (e.button === 2) {
          _ref = BvR.arena.entities;
          _results = [];
          for (i in _ref) {
            entity = _ref[i];
            _results.push(entity.flags.selected ? e.shiftKey ? entity.move(position, true) : entity.move(position) : void 0);
          }
          return _results;
        }
      }, this);
      document.onmouseup = __bind(function(e) {
        var entity, i, x, y, _ref, _ref2, _ref3, _results;
        if (e.button === 0) {
          this.selectRegion(this.start, this.end);
          _ref = getOffsets(e), x = _ref[0], y = _ref[1];
          _ref2 = BvR.arena.entities;
          _results = [];
          for (i in _ref2) {
            entity = _ref2[i];
            if (((_ref3 = entity.properties) != null ? _ref3.selectable : void 0) && Math.pow(entity.position[0] - x, 2) + Math.pow(entity.position[1] - y, 2) < RADIUS_2) {
              entity.flags.selected = true;
              break;
            }
          }
          return _results;
        }
      }, this);
      document.oncontextmenu = function() {
        return false;
      };
      return document.onkeydown = __bind(function(e) {
        var entity, i, _ref, _results;
        if (e.keyCode === 27) {
          this.deselectAll();
        }
        if (e.keyCode === 84) {
          _ref = BvR.arena.entities;
          _results = [];
          for (i in _ref) {
            entity = _ref[i];
            _results.push(entity instanceof Ring && entity.flags.selected ? entity.berserk() : void 0);
          }
          return _results;
        }
      }, this);
    };
    Selector.prototype.draw = function() {
      if (this.start && this.end) {
        context.fillStyle = SELECTOR_FILL;
        context.fillRect(this.start[0], this.start[1], this.end[0] - this.start[0], this.end[1] - this.start[1]);
        context.beginPath();
        context.strokeStyle = SELECTOR_BORDER;
        context.rect(this.start[0], this.start[1], this.end[0] - this.start[0], this.end[1] - this.start[1]);
        return context.stroke();
      }
    };
    Selector.prototype.mainLoop = function() {
      return this.draw();
    };
    Selector.prototype.deselectAll = function() {
      var e, i, _ref, _ref2, _results;
      _ref = BvR.arena.entities;
      _results = [];
      for (i in _ref) {
        e = _ref[i];
        _results.push(((_ref2 = e.properties) != null ? _ref2.selectable : void 0) ? e.flags.selected = false : void 0);
      }
      return _results;
    };
    Selector.prototype.selectRegion = function(start, end) {
      var e, i, x, xs, y, ys, _ref, _ref2, _ref3;
      xs = start[0] < end[0] ? [start[0], end[0]] : [end[0], start[0]];
      ys = start[1] < end[1] ? [start[1], end[1]] : [end[1], start[1]];
      _ref = BvR.arena.entities;
      for (i in _ref) {
        e = _ref[i];
        if ((_ref2 = e.properties) != null ? _ref2.selectable : void 0) {
          _ref3 = e.position, x = _ref3[0], y = _ref3[1];
          e.flags.selected = (xs[0] < x && x < xs[1]) && (ys[0] < y && y < ys[1]);
        }
      }
      return this.start = this.end = false;
    };
    return Selector;
  })();
  CollisionGrid = (function() {
    function CollisionGrid() {
      this.grid_lookup = {};
      this.id_lookup = {};
      this.initializeLookupTable();
    }
    CollisionGrid.prototype.initializeLookupTable = function() {
      var x, y, _ref, _results;
      _results = [];
      for (x = 0, _ref = ARENA_WIDTH / GRID_SIZE; 0 <= _ref ? x <= _ref : x >= _ref; 0 <= _ref ? x++ : x--) {
        _results.push((function() {
          var _ref2, _results2;
          _results2 = [];
          for (y = 0, _ref2 = ARENA_HEIGHT / GRID_SIZE; 0 <= _ref2 ? y <= _ref2 : y >= _ref2; 0 <= _ref2 ? y++ : y--) {
            _results2.push(this.grid_lookup[[x, y]] = {});
          }
          return _results2;
        }).call(this));
      }
      return _results;
    };
    CollisionGrid.prototype.updateEntity = function(id, position) {
      var junk, x, x0, xy, y, y0, _i, _len, _ref, _results;
      if (!(id && position)) {
        return;
      }
      x = [~~((position[0] - RADIUS) / GRID_SIZE), ~~((position[0] + RADIUS) / GRID_SIZE)];
      if (x[0] === x[1]) {
        x = [x[0]];
      }
      y = [~~((position[1] - RADIUS) / GRID_SIZE), ~~((position[1] + RADIUS) / GRID_SIZE)];
      if (y[0] === y[1]) {
        y = [y[0]];
      }
      _ref = this.id_lookup[id];
      for (xy in _ref) {
        junk = _ref[xy];
        delete this.grid_lookup[xy][id];
      }
      this.id_lookup[id] = {};
      _results = [];
      for (_i = 0, _len = x.length; _i < _len; _i++) {
        x0 = x[_i];
        _results.push((function() {
          var _j, _len2, _results2;
          _results2 = [];
          for (_j = 0, _len2 = y.length; _j < _len2; _j++) {
            y0 = y[_j];
            this.id_lookup[id][[x0, y0]] = true;
            _results2.push(this.grid_lookup[[x0, y0]][id] = true);
          }
          return _results2;
        }).call(this));
      }
      return _results;
    };
    CollisionGrid.prototype.detectCollisions = function(id) {
      var collisions, e, i, junk, p, x, xy, y, _ref, _ref2, _ref3;
      _ref = BvR.arena.entities[id].position, x = _ref[0], y = _ref[1];
      collisions = {};
      _ref2 = this.id_lookup[id];
      for (xy in _ref2) {
        junk = _ref2[xy];
        _ref3 = this.grid_lookup[xy];
        for (i in _ref3) {
          junk = _ref3[i];
          if (i + '' !== id + '') {
            if (e = BvR.arena.entities[i]) {
              p = e.position;
              if (Math.pow(p[0] - x, 2) + Math.pow(p[1] - y, 2) <= 4 * RADIUS_2) {
                collisions[i] = p;
              }
            } else {
              BvR.arena.deleteEntity(i);
            }
          }
        }
      }
      return collisions;
    };
    CollisionGrid.prototype.handleCollisions = function(id) {
      var e0, i, offset, position, _ref, _results;
      e0 = BvR.arena.entities[id];
      _ref = this.detectCollisions(id);
      _results = [];
      for (i in _ref) {
        position = _ref[i];
        offset = [(e0.position[0] - position[0]) * 0.1, (e0.position[1] - position[1]) * 0.1];
        _results.push(e0.setPosition([e0.position[0] + offset[0], e0.position[1] + offset[1]]));
      }
      return _results;
    };
    return CollisionGrid;
  })();
  window.BvR = {
    arena: new Arena(),
    selector: new Selector(),
    collisions: new CollisionGrid(),
    frame: 0,
    stats: {
      kills: 0,
      wave: 0
    },
    selectors: {
      kills: document.getElementById('kills-count'),
      wave: document.getElementById('wave-count')
    }
  };
  BvR.arena.spawnEntity(40, Ring);
  BvR.arena.spawnEntity(30, Bling);
}).call(this);
