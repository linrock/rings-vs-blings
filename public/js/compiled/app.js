(function() {
  var ARENA_HEIGHT, ARENA_WIDTH, Arena, Bling, Entity, FPS, MAX_SPEED_BLING, MAX_SPEED_RING, Ring, Selection, arena, b, context, entities, r;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
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
        moving: false
      };
    }
    Entity.prototype.draw = function() {
      if (this.flags.moving) {
        this.calculateNewPosition();
      }
      context.beginPath();
      context.arc(this.position[0], this.position[1], this.radius, 2 * Math.PI, false);
      context.fillStyle = this.color;
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
      this.redrawLoop();
    }
    Arena.prototype.redrawLoop = function() {
      return this.interval = setInterval(function() {
        var e, _i, _len, _results;
        context.clearRect(0, 0, ARENA_WIDTH, ARENA_HEIGHT);
        _results = [];
        for (_i = 0, _len = entities.length; _i < _len; _i++) {
          e = entities[_i];
          _results.push(e.draw());
        }
        return _results;
      }, 1000 / FPS);
    };
    return Arena;
  })();
  Selection = (function() {
    function Selection() {
      this.start = false;
      this.end = false;
      this.bindKeys();
    }
    Selection.prototype.bindKeys = function() {
      document.onmousemove = function(e) {
        var x, y;
        x = e.x - arena.offsetLeft - arena.clientLeft;
        y = e.y - arena.offsetTop - arena.clientTop;
        this.end = [x, y];
        if (this.start) {
          return context.fillRect(this.start[0], this.start[1], this.end[0], this.end[1]);
        }
      };
      document.onmousedown = function(e) {
        var x, y;
        console.dir(arena);
        x = e.x - arena.offsetLeft - arena.clientLeft;
        y = e.y - arena.offsetTop - arena.clientTop;
        return this.start = [x, y];
      };
      return document.onmouseup = function(e) {
        var x, y;
        x = e.x - arena.offsetLeft - arena.clientLeft;
        y = e.y - arena.offsetTop - arena.clientTop;
        return this.start = false;
      };
    };
    return Selection;
  })();
  r = new Ring();
  r.position = [100, 100];
  r.move([200, 300]);
  r.draw();
  b = new Bling();
  b.position = [500, 100];
  b.draw();
  entities = [];
  entities.push(r);
  entities.push(b);
  new Arena();
  new Selection();
}).call(this);
