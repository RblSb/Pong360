package game;

import kha.graphics2.Graphics;
import kha.Color;
import Types.Point;
using kha.graphics2.GraphicsExtension;
using Utils.MathExtension;

class Ball {
	
	var game:Game;
	public var color:Color;
	public var angle(default, null):Float;
	public var velocity(default, null):Float;
	public var radius(default, null):Float;
	var x:Float;
	var y:Float;
	var speed:Point;
	
	public function new(game:Game) {
		this.game = game;
		init();
	}
	
	public function init():Void {
		this.radius = game.radius * 0.1;
		color = game.lineColor;
		x = Screen.w/2;
		y = Screen.h/2;
		angle = Std.random(360).toRad();
		velocity = radius / 8;
		speed = {
			x: Math.cos(angle) * velocity,
			y: Math.sin(angle) * velocity
		}
	}
	
	public function onResize():Void {
		var oldRadius = radius;
		radius = game.radius * 0.1;
		var diff = radius / oldRadius;
		y *= diff;
		setSpeed(velocity * diff);
	}
	
	public function update():Void {
		x += speed.x;
		y += speed.y;
		
		if (getRange() - radius > game.radius) {
			var alpha = color.A - 0.05;
			if (alpha > 0) color.A = alpha;
			else game.newGame();
		}
	}
	
	public function getRange():Float {
		return Math.sqrt(Math.pow(x - Screen.w/2, 2) + Math.pow(y - Screen.h/2, 2));
	}
	
	public function getAng():Float {
		var ang = Math.atan2(Screen.h/2 - y, Screen.w/2 - x).toDeg() - 180;
		if (ang < 0) ang += 360;
		return ang;
	}
	
	public function setVector(ang:Float):Void {
		if (ang < 0) ang += 360;
		ang = ang % 360;
		angle = ang.toRad();
		speed = {
			x: Math.cos(angle) * velocity,
			y: Math.sin(angle) * velocity
		}
	}
	
	public function setSpeed(velocity:Float):Void {
		this.velocity = velocity;
		speed = {
			x: Math.cos(angle) * velocity,
			y: Math.sin(angle) * velocity
		}
	}
	
	public function draw(g:Graphics):Void {
		g.color = color;
		g.fillCircle(x, y, radius);
	}
	
}
