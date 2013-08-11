import hxworker.Worker;

#if flash
@:file("task.swf") class TaskByteArray extends flash.utils.ByteArray {}
#end

class Main {
	
	var id : Int = 0;
	var workers : Map<String, Worker>;
	
	public static function main() {
		#if js
		haxe.Log.trace = function(msg:String, ?pos:haxe.PosInfos) {
			msg = StringTools.htmlEscape(msg).split("\n").join("<br/>").split("\t").join("&nbsp;&nbsp;&nbsp;&nbsp;");
			js.Browser.document.getElementById("haxe:trace").innerHTML += msg + "<br/>";
		}
		#end
		new Main();
	}
	
	public function new() {
		workers = new Map();
		doTask( Std.string(id++), "doThing1" );
		doTask( Std.string(id++), "doThing2" );
		doTask( Std.string(id++), "doThing3" );
		#if (cpp || neko)
		while( workers.iterator().hasNext() )
			Sys.sleep(0.5);
		#end
	}
	
	function doTask( wid : String, taskName : String, ?args : Array<Dynamic> ) {
		var input = #if js "task.js" #elseif flash new TaskByteArray() #else Task #end;
		var worker = new Worker( input, handleWorkerMessage, handleWorkerError );
		workers.set(wid, worker);
		try {
			postToWorker( wid, "workerId", [wid] );
			postToWorker( wid, taskName, args );
		} catch( e : Dynamic )
			trace("worker error: " + Std.string(e));
	}
	
	function handleWorkerMessage( data : Dynamic ) {
		var msg = Worker.uncompress( data );
		switch( msg.cmd ) {
			case "log":
				trace("log: " + msg.args[0]);
			case "result":
				trace("result: " + Std.string(msg.args));
				var id = Std.string(msg.args[0]);
				workers.get(id).terminate();
				workers.remove(id);
			default: trace("Task: sub worker msg received: cmd = " + msg.cmd + " args = " + Std.string(msg.args));
		}
	}
	
	inline function handleWorkerError( msg : String ) {
		trace("worker error: " + msg);
	}
	
	inline function postToWorker( id : String, cmd : String, ?args : Array<Dynamic> ) {
		workers.get(id).call( cmd, args );
	}
}
