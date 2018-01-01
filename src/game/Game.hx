package game;

import kha.Framebuffer;
import kha.graphics2.Graphics;
import kha.input.Mouse;
import kha.Assets;
import Screen.Pointer;
import Types.Range;
using kha.graphics2.GraphicsExtension;
using Utils.MathExtension;

class Game extends Screen {
	
	var colors = [0xFF0CADF1, 0xFFF30247, 0xFFFDEE39, 0xFF98FFFD, 0xFFFE97FF, 0xFFB72FFF,  0xFF70BD15, 0xFFCA3200];
	var players:Array<Player> = [];
	var balls:Array<Ball> = [];
	public var lineColor(default, null) = 0xFF7F7F7F;
	public var radius(default, null):Float;
	public var lineW(default, null):Float;
	var pauseText:String;
	var started:Bool;
	var moveX = 0;
	var fontSize:Int;
	var savedMaxScore:Int;
	var maxScore:Int;
	var score:Int;
	
	public function new() {
		super();
	}
	
	public function init():Void {
		if (!Screen.touch) {
			Mouse.get().removeFromLockChange(onMouseLock, onMouseLockError);
			Mouse.get().notifyOnLockChange(onMouseLock, onMouseLockError);
		}
		
		resize();
		
		var sets = Settings.read();
		savedMaxScore = sets.maxScore;
		maxScore = savedMaxScore;
		if (Screen.touch) pauseText = "Touch to Start";
		else pauseText = "Click to Start";
		started = false;
		
		newGame();
	}
	
	inline function onMouseLock():Void {
		started = true;
	}
	
	inline function onMouseLockError():Void {
		var tryAgain = "Click again?";
		if (pauseText == tryAgain) pauseText = "Sorry, your browser too old";
		else pauseText = tryAgain;
	}
	
	inline function resize():Void {
		radius = Math.min(Screen.w, Screen.h) / 2.2;
		lineW = radius * 0.007;
		if (lineW < 1) lineW = 1;
		fontSize = Std.int(30 * lineW / 5) * 5;
	}
	
	public function newGame():Void {
		if (maxScore > savedMaxScore) {
			Settings.set({maxScore: maxScore});
			savedMaxScore = maxScore;
		}
		players = [
			for (i in 0...2) new Player(this, colors[i])
		];
		updatePlayers();
		balls = [new Ball(this)];
		score = 0;
	}
	
	public function increaseScore():Void {
		score++;
		if (maxScore < score) maxScore = score;
		
		if (players.length == colors.length) return;
		if (score < (players.length - 1) * 5) return;
		players.push(new Player(this, colors[players.length]));
		updatePlayers();
	}
	
	function updatePlayers():Void {
		var len = players.length;
		for (i in 0...len) {
			var length = 360 / len / 5;
			var addAng = 360 / len * i;
			var range:Range = {
				min: 360 / len * i,
				max: 360 / len * (i + 1)
			}
			players[i].setLength(length);
			players[i].setBounds(addAng, range);
			players[i].onMouseMove(moveX); //pointers[0]
		}
	}
	
	override function onResize():Void {
		resize();
		for (player in players) player.onResize();
		for (ball in balls) ball.onResize();
	}
	
	override function onMouseDown(p:Pointer):Void {
		if (Screen.touch) {
			started = true;
			return;
		}
		if (!Mouse.get().isLocked()) Mouse.get().lock();
	}
	
	override function onMouseMove(p:Pointer):Void {
		moveX -= p.moveX;
		if (moveX < 0) moveX = 0;
		else if (moveX > 360) moveX = 360;
		for (player in players) player.onMouseMove(moveX);
	}
	
	override function onUpdate():Void {
		if (!started) return;
		for (ball in balls) {
			ball.update();
			for (player in players) player.collision(ball);
		}
	}
	
	override function onRender(frame:Framebuffer):Void {
		var g = frame.g2;
		g.begin(true, 0xFF171717);
		g.color = lineColor;
		g.drawCircle(Screen.w/2, Screen.h/2, this.radius, lineW);
		drawPlayerLines(g);
		if (!started) drawPause(g);
		else {
			drawScore(g);
			for (player in players) player.draw(g);
			for (ball in balls) ball.draw(g);
		}
		debugScreen(g);
		g.end();
	}
	
	inline function drawPause(g:Graphics):Void {
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = fontSize;
		g.color = lineColor;
		var x = Screen.w/2 - g.font.width(g.fontSize, pauseText)/2;
		var y = Screen.h/2 - g.font.height(g.fontSize)/2;
		g.drawString(pauseText, x, y);
	}
	
	inline function drawPlayerLines(g:Graphics):Void {
		var max = Math.max(Screen.w, Screen.h) / 2;
		var len = players.length;
		g.color = 0xFF505050;
		for (i in 0...len) {
			var ang = (360 / len * (i + 1) + 90).toRad();
			g.drawLine(
				Screen.w/2 + Math.sin(ang) * radius,
				Screen.h/2 + Math.cos(ang) * radius,
				Screen.w/2 + Math.sin(ang) * max,
				Screen.h/2 + Math.cos(ang) * max, lineW
			);
		}
	}
	
	inline function drawScore(g:Graphics):Void {
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = fontSize;
		g.color = lineColor;
		var txt = "" + score;
		var x = Screen.w/2 - g.font.width(g.fontSize, txt)/2;
		var y = Screen.h/2 - g.font.height(g.fontSize)/2;
		g.drawString(txt, x, y);
		g.drawString("Max Score: " + maxScore, 0, 0);
	}
	
}
