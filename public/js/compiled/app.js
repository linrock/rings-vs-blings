(function() {
  var ARENA_HEIGHT, ARENA_WIDTH, ATTACK_DAMAGE_BLING, ATTACK_DAMAGE_RING, ATTACK_RANGE_BLING, ATTACK_RANGE_RING, ATTACK_RATE_RING, Arena, Bling, COLOR_BLING, COLOR_RING, Entity, Explosion, FPS, HP_BLING, HP_RING, MAX_SPEED_BLING, MAX_SPEED_RING, Projectile, Ring, Selector, arena, b, context, r, _i, _j, _len, _len2, _ref, _ref2;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  ARENA_WIDTH = 640;
  ARENA_HEIGHT = 480;
  FPS = 40;
  COLOR_RING = 'darkblue';
  HP_RING = 45;
  MAX_SPEED_RING = 10;
  ATTACK_RATE_RING = 30;
  ATTACK_RANGE_RING = 800;
  ATTACK_DAMAGE_RING = 10;
  COLOR_BLING = 'lightgreen';
  HP_BLING = 35;
  MAX_SPEED_BLING = 5;
  ATTACK_RANGE_BLING = 20;
  ATTACK_DAMAGE_BLING = 30;
  arena = document.getElementById('arena');
  arena.width = ARENA_WIDTH;
  arena.height = ARENA_HEIGHT;
  context = arena.getContext('2d');
  Entity = (function() {
    function Entity(kwargs) {
      this.radius = 6;
      this.flags = {
        moving: false,
        selected: false,
        finished: false
      };
      this.max_speed = false;
      this.position = (kwargs != null ? kwargs.position : void 0) || false;
      this.target_position = false;
      this.direction = false;
    }
    Entity.prototype.draw = function() {
      if (this.flags.moving) {
        this.calculateNewPosition();
      }
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
      return this.draw();
    };
    Entity.prototype.calculateNewPosition = function() {
      var direction, m, vector;
      vector = [this.target_position[0] - this.position[0], this.target_position[1] - this.position[1]];
      m = Math.sqrt(Math.pow(vector[0], 2) + Math.pow(vector[1], 2));
      vector = [vector[0] * this.max_speed / m, vector[1] * this.max_speed / m];
      direction = [vector[0] > 0, vector[1] > 0];
      if (direction[0] !== this.direction[0] || direction[1] !== this.direction[1]) {
        this.flags.moving = false;
        return this.direction = false;
      } else {
        return this.position = [this.position[0] + vector[0], this.position[1] + vector[1]];
      }
    };
    Entity.prototype.move = function(position) {
      this.target_position = position;
      this.direction = [this.target_position[0] - this.position[0] > 0, this.target_position[1] - this.position[1] > 0];
      return this.flags.moving = true;
    };
    return Entity;
  })();
  Bling = (function() {
    __extends(Bling, Entity);
    function Bling(kwargs) {
      Bling.__super__.constructor.call(this, kwargs);
      this.hp = HP_BLING;
      this.max_speed = MAX_SPEED_BLING;
      this.frame_offset = ~~(Math.random() * 20);
      this.color = COLOR_BLING;
      this.target = false;
    }
    Bling.prototype.takeDamage = function(hp) {
      this.hp -= hp;
      this.color = 'orange';
      if (this.hp <= 0) {
        return this.explode();
      }
    };
    Bling.prototype.checkNearbyEnemies = function() {
      var d2, e, i, x, y, _ref, _results;
      _ref = BvR.arena.entities;
      _results = [];
      for (i in _ref) {
        e = _ref[i];
        if (e instanceof Ring) {
          x = e.position[0] - this.position[0];
          y = e.position[1] - this.position[1];
          d2 = Math.pow(x, 2) + Math.pow(y, 2);
          if (d2 < Math.pow(ATTACK_RANGE_BLING / 2, 2)) {
            this.explode();
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
      if ((BvR.frame + this.frame_offset) % 40 === 3) {
        return this.radius = 6;
      } else if ((BvR.frame + this.frame_offset) % 40 === 37) {
        return this.radius = 6.8;
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
      context.lineWidth = 1;
      return context.stroke();
    };
    Bling.prototype.explode = function() {
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
        candidates.sort();
        this.target_id = candidates[0][1];
      }
      target = BvR.arena.entities[this.target_id];
      if (target) {
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
      this.color = COLOR_RING;
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
          damage: ATTACK_DAMAGE_RING
        });
        BvR.arena.addEntity(p);
        return this.color = 'yellow';
      }
    };
    Ring.prototype.mainLoop = function() {
      Ring.__super__.mainLoop.call(this);
      if (BvR.frame % 2 === 0) {
        this.color = COLOR_RING;
      }
      if (!this.flags.moving && BvR.frame % ATTACK_RATE_RING === 0) {
        return this.checkNearbyEnemies();
      }
    };
    Ring.prototype.takeDamage = function(hp) {
      console.log('Took ' + hp + ' damage');
      this.hp -= hp;
      if (this.hp <= 0) {
        return this.flags.finished = true;
      }
    };
    return Ring;
  })();
  Explosion = (function() {
    function Explosion(kwargs) {
      this.position = kwargs.position;
      this.r_max = kwargs.radius;
      this.r_max_2 = Math.pow(kwargs.radius, 2);
      this.damage = kwargs.damage;
      this.radius = 0;
      this.rate = 120 / FPS;
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
        this.rate *= -1;
      }
      this.radius += this.rate;
      if (this.radius > 0) {
        return this.draw();
      } else {
        return this.flags.finished = true;
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
      this.counter = 0;
      this.redrawLoop();
    }
    Arena.prototype.redrawLoop = function() {
      return this.interval = setInterval(__bind(function() {
        var e, i, _ref, _ref2;
        context.clearRect(0, 0, ARENA_WIDTH, ARENA_HEIGHT);
        BvR.selector.draw();
        _ref = this.entities;
        for (i in _ref) {
          e = _ref[i];
          if ((_ref2 = e.flags) != null ? _ref2.finished : void 0) {
            delete this.entities[i];
          } else {
            e.mainLoop();
          }
        }
        return BvR.frame++;
      }, this), 1000 / FPS);
    };
    Arena.prototype.addEntity = function(e) {
      return this.entities[this.counter++] = e;
    };
    return Arena;
  })();
  Selector = (function() {
    function Selector() {
      this.start = false;
      this.end = false;
      this.bindKeys();
    }
    Selector.prototype.bindKeys = function() {
      document.onmousemove = __bind(function(e) {
        var x, y;
        if (this.start) {
          x = e.x - arena.offsetLeft - arena.clientLeft;
          y = e.y - arena.offsetTop - arena.clientTop;
          return this.end = [x, y];
        }
      }, this);
      document.onmousedown = __bind(function(e) {
        var i, position, x, y, _ref, _results;
        x = e.x - arena.offsetLeft - arena.clientLeft;
        y = e.y - arena.offsetTop - arena.clientTop;
        position = [x, y];
        if (e.button === 2) {
          _ref = BvR.arena.entities;
          _results = [];
          for (i in _ref) {
            e = _ref[i];
            _results.push(e.flags.selected ? (e.move(position), e.flags.selected = false) : void 0);
          }
          return _results;
        } else {
          return this.start = position;
        }
      }, this);
      document.onmouseup = __bind(function(e) {
        return this.selectRegion(this.start, this.end);
      }, this);
      document.oncontextmenu = function() {
        return false;
      };
      return document.onkeydown = __bind(function(e) {
        if (e.keyCode === 27) {
          return this.deselectAll();
        }
      }, this);
    };
    Selector.prototype.draw = function() {
      if (this.start && this.end) {
        context.beginPath();
        context.rect(this.start[0], this.start[1], this.end[0] - this.start[0], this.end[1] - this.start[1]);
        context.strokeStyle = 'black';
        return context.stroke();
      }
    };
    Selector.prototype.mainLoop = function() {
      return this.draw();
    };
    Selector.prototype.deselectAll = function() {
      var e, i, _ref, _results;
      _ref = BvR.arena.entities;
      _results = [];
      for (i in _ref) {
        e = _ref[i];
        _results.push(e instanceof Ring ? e.flags.selected = false : void 0);
      }
      return _results;
    };
    Selector.prototype.selectRegion = function(start, end) {
      var e, i, x, xs, y, ys, _ref, _ref2;
      xs = [Math.min(start[0], end[0]), Math.max(start[0], end[0])];
      ys = [Math.min(start[1], end[1]), Math.max(start[1], end[1])];
      _ref = BvR.arena.entities;
      for (i in _ref) {
        e = _ref[i];
        if (e instanceof Ring) {
          _ref2 = e.position, x = _ref2[0], y = _ref2[1];
          e.flags.selected = (xs[0] < x && x < xs[1]) && (ys[0] < y && y < ys[1]);
        }
      }
      return this.start = this.end = false;
    };
    return Selector;
  })();
  window.BvR = {
    arena: new Arena(),
    selector: new Selector(),
    frame: 0
  };
  _ref = [
    new Ring({
      position: [100, 100]
    }), new Ring({
      position: [120, 100]
    }), new Ring({
      position: [80, 70]
    })
  ];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    r = _ref[_i];
    BvR.arena.addEntity(r);
  }
  _ref2 = [
    new Bling({
      position: [500, 100]
    }), new Bling({
      position: [550, 120]
    }), new Bling({
      position: [500, 80]
    }), new Bling({
      position: [530, 70]
    }), new Bling({
      position: [450, 170]
    }), new Bling({
      position: [480, 200]
    })
  ];
  for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
    b = _ref2[_j];
    BvR.arena.addEntity(b);
  }
}).call(this);
