package massive.mcover;

import massive.mcover.client.TraceClient;
import massive.mcover.CoverageClient;
import massive.mcover.CoverageEntry;
import massive.mcover.CoverageEntryCollection;

import massive.mcover.util.Timer;

interface MCoverRunner
{
	/*
	 * Handler which if present, should be called when the client has completed its processing of the results.
	 */
	var completionHandler(get_completeHandler, set_completeHandler):Float -> Void;
	
	var total(default, null):Int;
	var count(default, null):Int;

	function report():Void;
	

	/**
	 * Add a coverage clients to interpret coverage results.
	 * 
	 * @param client  client to interpret coverage results 
	 * @see massive.mcover.CoverageClient
	 * @see massive.mcover.client.PrintClient
	 */
	function addClient(client:CoverageClient):Void;
	function removeClient(client:CoverageClient):Void;
	function getClients():Array<CoverageClient>;

	/**
	* Completely resets all results, clears all clients/entries and restarts internal timers.
	**/
	function reset():Void;

	/**
	* Removes timers and contents
	*/
	function destroy():Void;
}


class MCoverRunnerImpc implements MCoverRunner
{
	/**
	 * Handler called when all clients 
	 * have completed processing the results.
	 */
	public var completionHandler(get_completeHandler, set_completeHandler):Float -> Void;
	function get_completeHandler():Float -> Void 
	{
		return completionHandler;
	}
	function set_completeHandler(value:Float -> Void):Float -> Void
	{
		return completionHandler = value;
	}

	public var total(default, null):Int;
	public var count(default, null):Int;

	var initialized:Bool;
	var clients:Array<CoverageClient>;
	var entries:IntHash<CoverageEntry>;
	var classes:Hash<CoverageEntryCollection>;
	var packages:Hash<CoverageEntryCollection>;
	
	var clientCompleteCount:Int;
	var timer:Timer;

	/**
	 * Class constructor.
	 */
	public function new()
	{
		clients = [];

		entries = new IntHash();
		classes = new Hash();
		packages = new Hash();

		reset();
	}

	/**
	 * Initializes timer to handle incoming logs on a set interval.
	 * This is to prevent logs being parsed before instance is initialized
	 * (edge case usually, but always occurs when running against MCover!!)
	 */
	public function reset()
	{
		initialized = false;
		if(timer != null) timer.stop();
		timer = new Timer(10);
		timer.run = tick;
	}

	public function report()
	{
		if(timer != null)
		{
			timer.stop();
			timer = null;
		}
		tick();//make sure to capture any pending logs

		clientCompleteCount = 0;

		if(clients.length == 0)
		{
			var client = new TraceClient();
			client.completionHandler = clientCompletionHandler;
			clients.push(client);
		}
			
		for (client in clients)
		{	
			client.report(total, count, entries, classes, packages);
		}
	}

	public function addClient(client:CoverageClient)
	{
		for(c in clients)
		{
			if(c == client) return;
		}

		client.completionHandler = clientCompletionHandler;
		clients.push(client);
	}

	public function removeClient(client:CoverageClient)
	{
		client.completionHandler = null;
		for(i in clients.length...0)
		{
			var c = clients[i];
			if(c ==client) clients.splice(i, 1);
		}
	}

	public function getClients():Array<CoverageClient>
	{
		return clients.concat([]);
	}

	public function destroy()
	{
		initialized = false;
		if(timer != null) timer.stop();
		for(c in clients)
		{
			c.completionHandler = null;
		}
	}

	///////////////////////////////////

	@IgnoreCover
	function tick()
	{
		if(!initialized)
		{
			init();
		}

		
		var tempLogs:Array<String> = [];
		#if neko
			var value = MCover.logQueue.pop(false);
			while(value != null)
			{
				tempLogs.push(value);
				value = MCover.logQueue.pop(false);
			}
		#else
			tempLogs = MCover.logQueue.concat([]);
			MCover.logQueue = [];
		#end

		for(value in tempLogs)
		{
			logEntry(value);
		}
	}

	function init()
	{
		initialized = true;
		clients = [];

		entries = new IntHash();
		classes = new Hash();
		packages = new Hash();

		parseEntries();		
		
		total = Lambda.count(entries);
		count = 0;
	}

	/**
	 * Log an individual call from within the code base.
	 * Do not call directly. The method only called via code injection by the compiler
	 * 
	 * @param	value		a string representation of a CoverageEntry
	 * @see mcover.CoverageEntry
	 */
	function logEntry(value:String)
	{		
		//trace(value);
		var temp = new CoverageEntry(value);
		
		if(!entries.exists(temp.id)) throw "Unexpected entry " + value;
		
		var entry = entries.get(temp.id);

		if(!entry.result)
		{
			count += 1;
		}
		entry.count += 1;

		for (client in clients)
		{	
			client.logEntry(entry);
		}
	}
	
	function clientCompletionHandler(client:CoverageClient):Void
	{
		if (++clientCompleteCount == clients.length)
		{
			if (completionHandler != null)
			{
				var percent:Float = count/total;
				var handler:Dynamic = completionHandler;
				Timer.delay(function() { handler(percent); }, 1);
			}
		}
	}

	function parseEntries()
	{
		var file = haxe.Resource.getString("MCover");

		if(file == null) return;
		var lines = file.split("\n");

		for(line in lines)
		{
			line = StringTools.trim(line);
			if(line.length == 0) continue;
			var entry = new CoverageEntry(line);
		
			addEntryToHashes(entry);
		}
	}

	function addEntryToHashes(entry:CoverageEntry)
	{
		entries.set(Lambda.count(entries), entry);

		var packageKey = entry.packageName != "" ?  entry.packageName : "[default]";
		if(!packages.exists(packageKey))
		{
			packages.set(packageKey, new CoverageEntryCollection(packageKey));
		}

		var pckg = packages.get(packageKey);
		pckg.addEntry(entry);

		var classKey = entry.packageName != "" ? entry.packageName + "." + entry.className : entry.className;
		if(!classes.exists(classKey))
		{
			classes.set(classKey, new CoverageEntryCollection(classKey));
		}

		var cls = classes.get(classKey);
		cls.addEntry(entry);
	}
}