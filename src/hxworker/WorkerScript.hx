package hxworker;

#if neko
import neko.vm.Mutex;
#elseif cpp
import cpp.vm.Mutex;
#elseif java
import java.vm.Mutex;
#end

import hxworker.Worker;

#if haxe3
private typedef Hash<T> = haxe.ds.StringMap<T>;
#end

class WorkerScript {

	#if flash
	var channelOut : flash.system.MessageChannel;
	var channelIn : flash.system.MessageChannel;
	#elseif !js
	var workersMutex : Mutex;
	public var worker : Worker;
	#end
	
	var workers : Hash<Worker>;
	
	public function new() {
		workers = new Hash();
		#if flash
		channelIn = flash.system.Worker.current.getSharedProperty( Worker.TO_SUB );
		channelOut = flash.system.Worker.current.getSharedProperty( Worker.FROM_SUB );
		channelIn.addEventListener( flash.events.Event.CHANNEL_MESSAGE, onMessage );
		#elseif !js
		workersMutex = new Mutex();
		#end
	}
	// here we receive a message from main (parent)
	public function onMessage( e : Dynamic ) : Void {
		#if js
		handleOnMessage( e.data );
		#elseif flash
		while( channelIn.messageAvailable )
			handleOnMessage( channelIn.receive() );
		#else
		handleOnMessage( e );
		#end
	}
	function onError( e : Dynamic ) : Void {}
	function handleOnMessage( data : Dynamic ) : Void {}
	// this call posts data from a child worker, to main (parent)
	public function post( cmd : String, args : Array<Dynamic> ) : Void {
		#if js
		postMessage( Worker.compress(cmd, args) );
		#elseif flash
		channelOut.send( Worker.compress(cmd, args) );
		#else
		worker.sendFromSub( Worker.compress(cmd, args) );
		#end
	}
	function handleWorkerMessage( data : Dynamic, wid : String ) {}
	#if js
	function postMessage( msg : Dynamic ) : Void {
		untyped __js__("self.postMessage( msg )");
	}
	#end
	
	function setWorker( id : String, worker : Worker ) {
		#if !(js || flash) workersMutex.acquire(); #end
		workers.set(id, worker);
		#if !(js || flash) workersMutex.release(); #end
	}
	
	function getWorker( id : String ) {
		var worker = null;
		#if !(js || flash) workersMutex.acquire(); #end
		worker = workers.get(id);
		#if !(js || flash) workersMutex.release(); #end
		return worker;
	}
	
	function hasWorker( id : String ) {
		var has = false;
		#if !(js || flash) workersMutex.acquire(); #end
		has = workers.exists(id);
		#if !(js || flash) workersMutex.release(); #end
		return has;
	}
	
	// make sure all script fields are added here
	// TODO use a macro for this
	public function export() {
		#if js
		
		var script = this;
		untyped __js__("self.onmessage = script.onMessage");
		untyped __js__("self.onerror = script.onError");
		untyped __js__("self.post = script.post");
		untyped __js__("self.handleOnMessage = script.handleOnMessage");
		untyped __js__("self.handleWorkerMessage = script.handleWorkerMessage");
		untyped __js__("self.new = script.new");
		untyped __js__("self.setWorker = script.setWorker");
		untyped __js__("self.getWorker = script.getWorker");
		untyped __js__("self.hasWorker = script.hasWorker");
		untyped __js__("self.workers = script.workers");
		
		#end
	}

}