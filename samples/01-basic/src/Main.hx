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
		#if !(js || flash)
		while( workers.iterator().hasNext() )
			Sys.sleep(0.5);
		#end
	}
	
	function doTask( wid : String, taskName : String, ?args : Array<Dynamic> ) {
		var input = #if js "task.js" #elseif flash new TaskByteArray() #else Task #end;
		var worker = new Worker( input, handleWorkerMessage.bind(_,wid), handleWorkerError.bind(_,wid) );
		workers.set(wid, worker);
		try {
			postToWorker( wid, "workerId", [wid] );
			postToWorker( wid, taskName, args );
		} catch( e : Dynamic )
			trace("worker error: " + Std.string(e));
	}
	
	function handleWorkerMessage( data : Dynamic, wid : String ) {
		var msg = Worker.uncompress( data );
		switch( msg.cmd ) {
			case "log":
				trace("log: " + msg.args[0]);
			case "result":
				trace("result: wid = " + wid + " args = " + Std.string(msg.args));
				workers.get(wid).terminate();
				workers.remove(wid);
			default: trace("Main: unhandled worker msg received: cmd = " + msg.cmd + " args = " + Std.string(msg.args));
		}
	}
	
	inline function handleWorkerError( msg : String, wid : String ) {
		trace("worker error: wid = " + wid + " msg = " + msg);
	}
	
	inline function postToWorker( id : String, cmd : String, ?args : Array<Dynamic> ) {
		workers.get(id).call( cmd, args );
	}
}
