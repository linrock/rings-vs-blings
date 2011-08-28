(function() {
  var ARENA_HEIGHT, ARENA_WIDTH, Arena, Bling, BvR, Entity, FPS, MAX_SPEED_BLING, MAX_SPEED_RING, Ring, Selector, arena, b, context, r;
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
    return Ring;
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
          _results.push(((_ref2 = e.flags) != null ? _ref2.finished : void 0) ? delete e : e.draw());
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
        x = e.x - arena.offsetLeft - arena.clientLeft;
        y = e.y - arena.offsetTop - arena.clientTop;
        return this.end = [x, y];
      }, this);
      document.onmousedown = __bind(function(e) {
        var x, y;
        x = e.x - arena.offsetLeft - arena.clientLeft;
        y = e.y - arena.offsetTop - arena.clientTop;
        return this.start = [x, y];
      }, this);
      return document.onmouseup = __bind(function(e) {
        var x, y;
        x = e.x - arena.offsetLeft - arena.clientLeft;
        y = e.y - arena.offsetTop - arena.clientTop;
        this.selectRegion(this.start, this.end);
        return this.start = false;
      }, this);
    };
    Selector.prototype.draw = function() {
      if (this.start) {
        context.beginPath();
        context.rect(this.start[0], this.start[1], this.end[0] - this.start[0], this.end[1] - this.start[1]);
        context.strokeStyle = 'black';
        return context.stroke();
      }
    };
    Selector.prototype.selectRegion = function(start, end) {
      var e, i, x, xs, y, ys, _ref, _ref2, _results;
      xs = [start[0], end[0]].sort();
      ys = [start[1], end[1]].sort();
      _ref = BvR.arena.entities;
      _results = [];
      for (i in _ref) {
        e = _ref[i];
        _ref2 = e.position, x = _ref2[0], y = _ref2[1];
        _results.push(e.flags.selected = x > xs[0] && x < xs[1] && y > ys[0] && y < ys[1]);
      }
      return _results;
    };
    return Selector;
  })();
  r = new Ring();
  r.position = [100, 100];
  r.move([200, 300]);
  r.draw();
  b = new Bling();
  b.position = [500, 100];
  b.draw();
  BvR = {
    arena: new Arena(),
    selector: new Selector()
  };
  BvR.arena.addEntity(r);
  BvR.arena.addEntity(b);
}).call(this);
