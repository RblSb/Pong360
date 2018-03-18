package;

import kha.Framebuffer;
import kha.graphics2.Graphics;
import kha.Canvas;
import kha.Image;
import kha.Scaler;
import kha.input.Keyboard;
import kha.input.KeyCode;
import kha.input.Surface;
import kha.input.Mouse;
import kha.Scheduler;
import kha.System;
import kha.Assets;
#if kha_g4
import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
#end

//Сlass for unifying mouse/touch events and setup game screens

typedef Pointer = {
	id:Int,
	startX:Int,
	startY:Int,
	x:Int,
	y:Int,
	moveX:Int,
	moveY:Int,
	type:Int,
	isDown:Bool,
	used:Bool
}

private typedef ScreenSets = {
	?touch:Bool,
	?samplesPerPixel:Int
}
/*@:structInit
private class ScreenSets {
	@:optional public var touch = false;
	@:optional public var samplesPerPixel = 1;
}*/

class Screen {
	
	public static var screen:Screen; //current screen
	public static var w(default, null):Int; //for resize event
	public static var h(default, null):Int;
	public static var touch(default, null) = false;
	public static var samplesPerPixel(default, null) = 1;
	public static var frame:Canvas;
	static var fps = new FPS();
	static var taskId:Int;
	
	var backbuffer = createRenderTarget(1, 1);
	public var scale(default, null) = 1.0;
	public var keys:Map<KeyCode, Bool> = new Map();
	public var pointers:Map<Int, Pointer> = [
		for (i in 0...10) i => {id: i, startX: 0, startY: 0, x: 0, y: 0, moveX: 0, moveY: 0, type: 0, isDown: false, used: false}
	];
	#if kha_g4
	static var pipelineState:PipelineState;
	#end
	
	public function new() {}
	
	public static function init(?sets:ScreenSets):Void {
		w = System.windowWidth();
		h = System.windowHeight();
		#if kha_html5
		touch = untyped __js__('"ontouchstart" in window');
		#elseif (kha_android || kha_ios)
		touch = true;
		#end
		if (sets != null) {
			if (sets.touch != null) touch = sets.touch;
			if (sets.samplesPerPixel != null) samplesPerPixel = sets.samplesPerPixel;
		}
		#if kha_g4
		pipelineState = Pipeline.create();
		#end
	}
	
	static inline function createRenderTarget(w:Int, h:Int):Image {
		return Image.createRenderTarget(w, h, RGBA32, NoDepthAndStencil, samplesPerPixel);
	}
	
	public static inline function pipeline(g:Graphics):Void {
		#if kha_g4
		g.pipeline = pipelineState;
		#end
	}
	
	public function show():Void {
		if (screen != null) screen.hide();
		screen = this;
		
		taskId = Scheduler.addTimeTask(_onUpdate, 0, 1/60);
		System.notifyOnRender(_onRender);
		backbuffer = createRenderTarget(Std.int(w/scale), Std.int(h/scale));
		
		if (Keyboard.get() != null) Keyboard.get().notify(_onKeyDown, _onKeyUp, onKeyPress);
		
		if (touch && Surface.get() != null) {
			Surface.get().notify(_onTouchDown, _onTouchUp, _onTouchMove);
		} else if (Mouse.get() != null) {
			Mouse.get().notify(_onMouseDown, _onMouseUp, _onMouseMove, onMouseWheel, onMouseLeave);
		}
		for (k in keys) k = false;
		for (p in pointers) p.isDown = false;
	}
	
	public function hide():Void {
		Scheduler.removeTimeTask(taskId);
		System.removeRenderListener(_onRender);
		
		if (Keyboard.get() != null) Keyboard.get().remove(_onKeyDown, _onKeyUp, onKeyPress);
		
		if (touch && Surface.get() != null) {
			Surface.get().remove(_onTouchDown, _onTouchUp, _onTouchMove);
		} else if (Mouse.get() != null) {
			Mouse.get().remove(_onMouseDown, _onMouseUp, _onMouseMove, onMouseWheel, onMouseLeave);
		}
	}
	
	inline function _onUpdate():Void {
		if (Std.int(System.windowWidth() / scale) != w ||
			Std.int(System.windowHeight() / scale) != h) _onResize();
		onUpdate();
		fps.update();
	}
	
	inline function _onRender(framebuffer:Framebuffer):Void {
		if (scale == 1) {
			frame = framebuffer;
			onRender(frame);
			
		} else {
			frame = backbuffer;
			onRender(frame);
			
			var g = framebuffer.g2;
			g.begin(false);
			Scaler.scale(backbuffer, framebuffer, System.screenRotation);
			g.end();
		}
		var g = framebuffer.g2;
		g.begin(false);
		drawFPS(g);
		g.end();
		fps.addFrame();
	}
	
	function drawFPS(g:Graphics):Void {
		g.color = 0xFFFFFFFF;
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 24;
		var w = System.windowWidth();
		var h = System.windowHeight();
		var txt = '${fps.fps} | ${w}x${h} ${scale}x';
		var x = w - g.font.width(g.fontSize, txt);
		var y = h - g.font.height(g.fontSize);
		g.drawString(txt, x, y);
	}
	
	inline function _onResize():Void {
		w = Std.int(System.windowWidth() / scale);
		h = Std.int(System.windowHeight() / scale);
		onResize();
		if (w != backbuffer.width || h != backbuffer.height)
			backbuffer = createRenderTarget(w, h);
	}
	
	inline function _onKeyDown(key:KeyCode):Void {
		keys[key] = true;
		onKeyDown(key);
	}
	
	inline function _onKeyUp(key:KeyCode):Void {
		keys[key] = false;
		onKeyUp(key);
	}
	
	inline function _onMouseDown(button:Int, x:Int, y:Int):Void {
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].startX = x;
		pointers[0].startY = y;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = true;
		pointers[0].used = true;
		onMouseDown(pointers[0]);
	}
	
	inline function _onMouseMove(x:Int, y:Int, mx:Int, my:Int):Void {
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].moveX = mx;
		pointers[0].moveY = my;
		pointers[0].used = true;
		onMouseMove(pointers[0]);
	}
	
	inline function _onMouseUp(button:Int, x:Int, y:Int):Void {
		if (!pointers[0].used) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = false;
		onMouseUp(pointers[0]);
	}
	
	inline function _onTouchDown(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[id].startX = x;
		pointers[id].startY = y;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = true;
		pointers[id].used = true;
		onMouseDown(pointers[id]);
	}
	
	inline function _onTouchMove(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[id].moveX = x - pointers[id].x;
		pointers[id].moveY = y - pointers[id].y;
		pointers[id].x = x;
		pointers[id].y = y;
		onMouseMove(pointers[id]);
	}
	
	inline function _onTouchUp(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		if (!pointers[id].used) return;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = false;
		onMouseUp(pointers[id]);
	}
	
	public function setScale(scale:Float):Void {
		onRescale(scale);
		this.scale = scale;
	}
	
	//functions for override
	
	function onRescale(scale:Float):Void {}
	function onResize():Void {}
	function onUpdate():Void {}
	function onRender(frame:Canvas):Void {}
	
	public function onKeyDown(key:KeyCode):Void {}
	public function onKeyUp(key:KeyCode):Void {}
	public function onKeyPress(char:String):Void {}
	
	public function onMouseDown(p:Pointer):Void {}
	public function onMouseMove(p:Pointer):Void {}
	public function onMouseUp(p:Pointer):Void {}
	public function onMouseWheel(delta:Int):Void {}
	public function onMouseLeave():Void {}
	
}

private class FPS {
	
	public var fps = 0;
	var frames = 0;
	var time = 0.0;
	var lastTime = 0.0;
	
	public function new() {}
	
	public function update():Int {
		var deltaTime = Scheduler.realTime() - lastTime;
		lastTime = Scheduler.realTime();
		time += deltaTime;
		
		if (time >= 1) {
			fps = frames;
			frames = 0;
			time = 0;
		}
		return fps;
	}
	
	public inline function addFrame() frames++;
	
}

#if kha_g4
private class Pipeline {
	
	public static inline function create():PipelineState {
		var struct = new VertexStructure();
		struct.add("vertexPosition", VertexData.Float3);
		struct.add("texPosition", VertexData.Float2);
		struct.add("vertexColor", VertexData.Float4);
		
		var pipeline = new PipelineState();
		pipeline.inputLayout = [struct];
		pipeline.vertexShader = Shaders.painter_image_vert;
		pipeline.fragmentShader = Shaders.painter_image_frag;
		pipeline.blendSource = BlendingFactor.BlendOne;
		pipeline.blendDestination = BlendingFactor.BlendZero;
		pipeline.alphaBlendSource = BlendingFactor.BlendOne;
		pipeline.alphaBlendDestination = BlendingFactor.BlendZero;
		pipeline.compile();
		return pipeline;
	}
	
}
#end
