package hxworker;

#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#elseif java
import java.vm.Thread;
#end

class Worker {
	
	#if flash
	public static inline var TO_SUB = "toSub";
	public static inline var FROM_SUB = "fromSub";
	#end
	
	public var type : String;
	
	#if js
	var inst : js.Worker;
	#elseif flash
	var inst : flash.system.Worker;
	var channelIn : flash.system.MessageChannel;
	var channelOut : flash.system.MessageChannel;
	#else
	var running : Bool = true;
	#end
	
	var onData : Dynamic -> Void;
	var onError : String -> Void;
	
	public function new( input : Dynamic, onData : Dynamic -> Void, onError : String -> Void, ?type : String ) {
		this.onData = onData;
		this.onError = onError;
		this.type = type;
		#if js
		
		inst = new js.Worker( input );
		inst.addEventListener( "message", function(e) { onData( e.data ); } );
		inst.addEventListener( "error", function(e) { onError( e.message ); } );
		#elseif flash
		
		inst = flash.system.WorkerDomain.current.createWorker( input );
		channelOut = flash.system.Worker.current.createMessageChannel( inst );
		channelIn = inst.createMessageChannel( flash.system.Worker.current );
		inst.setSharedProperty( TO_SUB, channelOut );
		inst.setSharedProperty( FROM_SUB, channelIn );
		channelIn.addEventListener( flash.events.Event.CHANNEL_MESSAGE, function(e) {
			while( channelIn.messageAvailable )
				onData( channelIn.receive() );
		});
		inst.start();
		#else
		
		feedMainThread = Thread.create( feedMain );
		feedMainThread.sendMessage( onData );
		
		sendErrorToMainThread = Thread.create( sendErrorToMain );
		sendErrorToMainThread.sendMessage( onError );
		
		thread = Thread.create( createInst );
		thread.sendMessage( input );
		thread.sendMessage( this );
		thread.sendMessage( sendErrorToMainThread );
		#end
	}
	
	#if !(js || flash)
	
	public inline function sendFromSub( msg : Dynamic ) {
		feedMainThread.sendMessage( msg );
	}
	
	inline function sendToSub( msg : Dynamic ) {
		thread.sendMessage( msg );
	}
	
	var thread : Thread;
	function createInst() {
		var clazz = Thread.readMessage( true );
		var worker = Thread.readMessage( true );
		var errorThread = Thread.readMessage( true );
		var inst : WorkerScript = Type.createInstance( clazz, [] );
		inst.worker = worker;
		
		while( running ) {
			try {
				var msg = Thread.readMessage( true );
				if( Std.string(msg) == "##TERMINATE##" ) break;
				inst.onMessage( msg );
			} catch( e : Dynamic ) {
				errorThread.sendMessage(e);
			}
		}
	}
	
	var sendErrorToMainThread : Thread;
	function sendErrorToMain() {
		var onError = Thread.readMessage( true );
		while( running ) {
			var msg = Thread.readMessage( true );
			if( Std.string(msg) == "##TERMINATE##" ) break;
			onError( msg );
		}
	}
	
	var feedMainThread : Thread;
	function feedMain() {
		var onData = Thread.readMessage( true );
		while( running ) {
			var msg = Thread.readMessage( true );
			if( Std.string(msg) == "##TERMINATE##" ) break;
			onData( msg );
		}
	}
	#end
	
	// data received here is passed from main (parent) to this worker
	public function call( cmd : String, ?args : Array<Dynamic> ) : Void {
		if( args == null ) args = [];
		#if js
		inst.postMessage( compress(cmd, args) );
		#elseif flash
		channelOut.send( compress(cmd, args) );
		#else
		sendToSub( compress(cmd, args) );
		#end
	}
	
	public function terminate() {
		#if (js || flash)
		inst.terminate();
		#else
		running = false;
		thread.sendMessage( "##TERMINATE##" );
		feedMainThread.sendMessage( "##TERMINATE##" );
		sendErrorToMainThread.sendMessage( "##TERMINATE##" );
		#end
	}
	
	public static inline function compress( cmd : String, args : Array<Dynamic> ) {
		#if (js || flash)
		return haxe.Serializer.run( {cmd:cmd, args:args} );
		#else
		return {cmd:cmd, args:args};
		#end
	}
	
	public static inline function uncompress( data : Dynamic ) : { cmd : String, args : Array<Dynamic> } {
		#if (js || flash)
		return haxe.Unserializer.run( data );
		#else
		return data;
		#end
	}
	
}
