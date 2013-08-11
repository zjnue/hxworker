class TaskScript extends hxworker.WorkerScript {

	public function new() {
		super();
	}
	
	override public function export() {
		super.export();
		#if js
		
		var script = this;
		untyped __js__("self.workerId = script.workerId");
		untyped __js__("self.subWorkerId = script.subWorkerId");
		untyped __js__("self.log = script.log");
		untyped __js__("self.doTask = script.doTask");
		untyped __js__("self.handleWorkerError = script.handleWorkerError");
		untyped __js__("self.postToWorker = script.postToWorker");
		untyped __js__("self.doThing1 = script.doThing1");
		untyped __js__("self.doThing2 = script.doThing2");
		untyped __js__("self.doThing3 = script.doThing3");
		
		#end
	}
}
