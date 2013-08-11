import hxworker.Worker;

class Task extends TaskScript {
	
	public var workerId : String;
	
	var subWorkerId : Int = 0;
	
	public function new() {
		super();
		#if (js || flash)
		haxe.Serializer.USE_CACHE = true;
		#end
	}
	
	function log( msg : String ) { post("log", [msg]); }
	
	// --- for sub worker routines ---
	function doTask( wid : String, taskName : String, ?args : Array<Dynamic> ) {
		var input = #if js "task.js" #elseif flash flash.Lib.current.loaderInfo.bytes #else Task #end;
		var worker = new Worker( input, handleWorkerMessage.bind(_,wid), handleWorkerError.bind(_,wid) );
		setWorker(wid, worker);
		try {
			postToWorker( wid, "workerId", [wid] );
			postToWorker( wid, taskName, args );
		} catch( e:Dynamic )
			log("sub worker error: " + Std.string(e));
	}
	
	// here we receive a message from the sub worker with workerId wid
	override function handleWorkerMessage( data : Dynamic, wid : String ) {
		var msg = Worker.uncompress( data );
		switch( msg.cmd ) {
			case "log": log("log-from-child: " + msg.args[0]);
			case "result": post(msg.cmd, msg.args);
			default: log("Task: unhandled sub worker msg received: cmd = " + msg.cmd + " args = " + Std.string(msg.args));
		}
	}
	
	inline function handleWorkerError( msg : String, wid : String ) {
		log("worker error: wid = " + wid + " msg = " + msg);
	}
	
	inline function postToWorker( wid : String, cmd : String, ?args : Array<Dynamic> ) {
		getWorker(wid).call( cmd, args );
	}
	// ---
	
	public function doThing1() {
		log("starting: doThing1");
		var result = -1;
		post( "result", ["doThing1", result] );
	}
	
	public function doThing2() {
		log("starting: doThing2");
		var result = "JHSGFLJHDFF";
		post( "result", ["doThing2", result] );
	}
	
	public function doThing3() {
		log("starting: doThing3");
		var result = 234238;
		post( "result", ["doThing3", result] );
	}
	
	public static function main() {
		new Task().export();
	}
	
	override public function handleOnMessage(data) {
		var msg = hxworker.Worker.uncompress( data );
		switch( msg.cmd ) {
			case "workerId": workerId = msg.args[0];
			case "doThing1": doThing1();
			case "doThing2": doThing2();
			case "doThing3": doThing3();
			default: log("handleOnMessage: unhandled cmd: " + msg.cmd);
		}
	}
	
}