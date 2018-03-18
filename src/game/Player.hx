package game;

import kha.graphics2.Graphics;
import kha.Color;
import Screen.Pointer;
import Types.Range;
using kha.graphics2.GraphicsExtension;
using Utils.MathExtension;

class Player {
	
	var game:Game;
	var angle = 0.0;
	var addAng = 0.0;
	var length = 20.0;
	var radius:Float;
	var lineW:Float;
	var color:Color;
	var range:Range;
	
	public function new(game:Game, color=0xFFFFFFFF) {
		this.game = game;
		this.color = color;
		onResize();
	}
	
	public function onResize():Void {
		radius = game.radius;
		lineW = game.lineW * 3;
	}
	
	public function setLength(length:Float):Void {
		this.length = length;
	}
	
	public function setBounds(addAng:Float, range:Range):Void {
		this.addAng = addAng;
		this.range = range;
	}
	
	public function onMouseMove(sAngle:Float):Void {
		angle = (range.max - range.min - length) / 360 * sAngle;
		angle += addAng;
	}
	
	public function onMouseMoveAlt(p:Pointer):Void {
		angle = Math.atan2(Screen.h/2 - p.y, Screen.w/2 - p.x).toDeg() + 180;
		angle += 360 - length/2 + addAng;
		angle = angle % 360;
		
		if (range == null) return;
		if (angle < range.min || angle > range.max - length) {
			var dist = Utils.distAng(angle, range.min);
			var dist2 = Utils.distAng(angle, range.max - length);
			
			if (Math.abs(dist) < Math.abs(dist2)) angle = range.min;
			else angle = range.max - length;
		}
	}
	
	public function collision(ball:Ball) {
		var range = ball.getRange();
		if (range > radius - ball.radius && range < radius) {
			var dist = Utils.distAng(angle + length/2, ball.getAng());
			
			if (Math.abs(dist).toRad() * radius < (length/2).toRad() * radius + ball.radius) {
				var ratio = Math.abs(dist) / length * 5;
				var newAng = angle + dist * ratio + 180;
				ball.setVector(newAng);
				
				if (ball.color != color) {
					ball.color = color;
					ball.setSpeed(ball.velocity + game.radius/1800);
					game.increaseScore();
				}
			}
		}
	}
	
	public function draw(g:Graphics):Void {
		g.color = color;
		g.drawArc(Screen.w/2, Screen.h/2, radius, angle.toRad(), (angle + length).toRad(), lineW);
	}
	
}
