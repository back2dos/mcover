package massive.mcover;

import massive.mcover.data.Statement;
import massive.mcover.data.Branch;
import massive.mcover.data.AllClasses;


class CoverageClientMock implements CoverageClient
{
	public var allClasses:AllClasses;

	/**
	 * Handler which if present, is called when the client has completed generating its results.
	 */
	public var completionHandler(default, default):CoverageClient -> Void;


	public function new()
	{
		
	}

	public function report(allClasses:AllClasses):Void
	{
		this.allClasses = allClasses;

		var timer = massive.munit.util.Timer.delay(reportComplete, 50);

		return null;
	}

	function reportComplete()
	{
		if(completionHandler != null)
		{
			completionHandler(this);
		}
	}

}