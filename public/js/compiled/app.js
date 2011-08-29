(function() {
  var ARENA_HEIGHT, ARENA_WIDTH, ATTACK_DAMAGE_BLING, ATTACK_DAMAGE_RING, ATTACK_RANGE_BLING, ATTACK_RANGE_RING, Arena, Bling, Entity, Explosion, FPS, MAX_SPEED_BLING, MAX_SPEED_RING, Ring, Selector, arena, b0, b1, b2, context, r0, r1;
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
  MAX_SPEED_RING = 10;
  MAX_SPEED_BLING = 100;
  ATTACK_RANGE_RING = 80;
  ATTACK_RANGE_BLING = 20;
  ATTACK_DAMAGE_RING = 6;
  ATTACK_DAMAGE_BLING = 30;
  arena = document.getElementById('arena');
  arena.width = ARENA_WIDTH;
  arena.height = ARENA_HEIGHT;
  context = arena.getContext('2d');
  Entity = (function() {
    function Entity() {
      this.radius = 6;
      this.flags = {
        moving: false,
        selected: false,
        finished: false
      };
      this.max_speed = false;
      this.position = false;
      this.target_position = false;
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
    Entity.prototype.calculateNewPosition = function() {
      var m, s, vector;
      vector = [this.target_position[0] - this.position[0], this.target_position[1] - this.position[1]];
      m = Math.sqrt(Math.pow(vector[0], 2) + Math.pow(vector[1], 2));
      vector = [vector[0] * this.max_speed / m, vector[1] * this.max_speed / m];
      this.position = [this.position[0] + vector[0], this.position[1] + vector[1]];
      s = [vector[0] > 0, vector[1] > 0];
      if (s[0] * (this.position[0] - this.target_position[0]) > 0 && s[1] * (this.position[1] - this.target_position[1]) > 0) {
        this.position = this.target_position;
        return this.flags.moving = false;
      }
    };
    Entity.prototype.move = function(position) {
      this.target_position = position;
      return this.flags.moving = true;
    };
    return Entity;
  })();
  Bling = (function() {
    __extends(Bling, Entity);
    function Bling() {
      Bling.__super__.constructor.call(this);
      this.hp = 40;
      this.max_speed = MAX_SPEED_BLING;
      this.color = 'lightgreen';
    }
    Bling.prototype.takeDamage = function(hp) {
      this.hp -= hp;
      if (this.hp <= 0) {
        return this.explode();
      }
    };
    Bling.prototype.checkNearbyEnemies = function() {
      var d, e, i, x, y, _ref, _results;
      _ref = BvR.arena.entities;
      _results = [];
      for (i in _ref) {
        e = _ref[i];
        _results.push(e instanceof Ring ? (x = e.position[0] - this.position[0], y = e.position[1] - this.position[1], d = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2)), d < ATTACK_RANGE_BLING ? (this.explode(), e.takeDamage(ATTACK_DAMAGE_BLING)) : void 0) : void 0);
      }
      return _results;
    };
    Bling.prototype.draw = function() {
      Bling.__super__.draw.call(this);
      return this.checkNearbyEnemies();
    };
    Bling.prototype.explode = function() {
      var e;
      e = new Explosion({
        position: this.position
      });
      BvR.arena.addEntity(e);
      return this.flags.finished = true;
    };
    return Bling;
  })();
  Ring = (function() {
    __extends(Ring, Entity);
    function Ring() {
      Ring.__super__.constructor.call(this);
      this.hp = 45;
      this.max_speed = MAX_SPEED_RING;
      this.color = 'darkblue';
    }
    Ring.prototype.checkNearbyEnemies = function() {
      var candidates, d, e, i, x, y, _ref;
      candidates = [];
      _ref = BvR.arena.entities;
      for (i in _ref) {
        e = _ref[i];
        if (e instanceof Bling) {
          x = e.position[0] - this.position[0];
          y = e.position[1] - this.position[1];
          d = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2));
          if (d < ATTACK_RANGE_RING) {
            candidates.push([d, i]);
          }
        }
      }
      if (candidates.length > 0) {
        candidates.sort();
        return BvR.arena.entities[candidates[0][1]].takeDamage(ATTACK_DAMAGE_RING);
      }
    };
    Ring.prototype.draw = function() {
      Ring.__super__.draw.call(this);
      if (!this.flags.moving) {
        return this.checkNearbyEnemies();
      }
    };
    Ring.prototype.takeDamage = function(hp) {
      this.hp -= hp;
      if (this.hp <= 0) {
        return this.flags.finished = true;
      }
    };
    return Ring;
  })();
  Explosion = (function() {
    function Explosion(args) {
      this.position = args.position;
      this.max_radius = 20;
      this.radius = 0;
      this.rate = 120 / FPS;
      this.color = 'lightgreen';
      this.flags = {
        finished: false
      };
    }
    Explosion.prototype.draw = function() {
      if (this.radius >= this.max_radius) {
        this.rate *= -1;
      }
      this.radius += this.rate;
      if (this.radius > 0) {
        context.beginPath();
        context.arc(this.position[0], this.position[1], this.radius, 2 * Math.PI, false);
        context.fillStyle = this.color;
        return context.fill();
      } else {
        return this.flags.finished = true;
      }
    };
    return Explosion;
  })();
  Arena = (function() {
    function Arena() {
      this.entities = {};
      this.counter = 0;
      this.redrawLoop();
    }
    Arena.prototype.redrawLoop = function() {
      return this.interval = setInterval(__bind(function() {
        var e, i, _ref, _ref2, _results;
        context.clearRect(0, 0, ARENA_WIDTH, ARENA_HEIGHT);
        BvR.selector.draw();
        _ref = this.entities;
        _results = [];
        for (i in _ref) {
          e = _ref[i];
          _results.push(((_ref2 = e.flags) != null ? _ref2.finished : void 0) ? delete this.entities[i] : e.draw());
        }
        return _results;
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
      return document.oncontextmenu = function() {
        return false;
      };
    };
    Selector.prototype.draw = function() {
      if (this.start && this.end) {
        context.beginPath();
        context.rect(this.start[0], this.start[1], this.end[0] - this.start[0], this.end[1] - this.start[1]);
        context.strokeStyle = 'black';
        return context.stroke();
      }
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
    selector: new Selector()
  };
  r0 = new Ring();
  r0.position = [100, 100];
  r0.draw();
  BvR.arena.addEntity(r0);
  r1 = new Ring();
  r1.position = [120, 100];
  r1.draw();
  BvR.arena.addEntity(r1);
  b0 = new Bling();
  b0.position = [500, 100];
  b0.draw();
  BvR.arena.addEntity(b0);
  b1 = new Bling();
  b1.position = [550, 120];
  b1.draw();
  BvR.arena.addEntity(b1);
  b2 = new Bling();
  b2.position = [500, 80];
  b2.draw();
  BvR.arena.addEntity(b2);
}).call(this);
