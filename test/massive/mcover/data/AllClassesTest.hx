package massive.mcover.data;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

class AllClassesTest extends AbstractNodeListTest
{	
	var allClasses:AllClasses;

	public function new() {super();}
	
	@BeforeClass
	override public function beforeClass():Void
	{
		super.beforeClass();
	}
	
	@AfterClass
	override public function afterClass():Void
	{
		super.afterClass();
	}
	
	@Before
	override public function setup():Void
	{
		super.setup();
		allClasses = createEmptyAllClasses();
	}
	
	@After
	override public function tearDown():Void
	{
		super.tearDown();
	}

	@Test
	public function shouldSortMissingBranchesById()
	{
		var item1 = cast(allClasses.getItemByName("item1", NodeMock), NodeMock);
		var item2 = cast(allClasses.getItemByName("item2", NodeMock), NodeMock);
		var item3 = cast(allClasses.getItemByName("item3", NodeMock), NodeMock);
		
		var item1a = cast(allClasses.getItemByName("item1a", NodeMock), NodeMock);
		
		item2.branch.id = 2;
		item3.branch.id = 4;

		var missing = allClasses.getMissingBranches();

		Assert.areEqual(0, missing[0].id);
		Assert.areEqual(0, missing[1].id);
		
		Assert.areEqual(2, missing[2].id);
		Assert.areEqual(4, missing[3].id);
	}

	@Test
	public function shouldSortMissingStatementsById()
	{
		var item1 = cast(allClasses.getItemByName("item1", NodeMock), NodeMock);
		var item2 = cast(allClasses.getItemByName("item2", NodeMock), NodeMock);
		var item3 = cast(allClasses.getItemByName("item3", NodeMock), NodeMock);
		
		var item1a = cast(allClasses.getItemByName("item1a", NodeMock), NodeMock);
		
		item2.statement.id = 2;
		item3.statement.id = 4;

		var missing = allClasses.getMissingStatements();

		Assert.areEqual(0, missing[0].id);
		Assert.areEqual(0, missing[1].id);
		
		Assert.areEqual(2, missing[2].id);
		Assert.areEqual(4, missing[3].id);
	}
	
	@Test
	public function shouldSortClassesById()
	{
		var item1 = cast(allClasses.getItemByName("item1", NodeMock), NodeMock);
		var item2 = cast(allClasses.getItemByName("item2", NodeMock), NodeMock);
		var item3 = cast(allClasses.getItemByName("item3", NodeMock), NodeMock);
		
		var item1a = cast(allClasses.getItemByName("item1a", NodeMock), NodeMock);
		
		item2.clazz.id = 2;
		item3.clazz.id = 4;

		var classes = allClasses.getClasses();

		Assert.areEqual(0, classes[0].id);
		Assert.areEqual(0, classes[1].id);
		
		Assert.areEqual(2, classes[2].id);
		Assert.areEqual(4, classes[3].id);
	}

	@Test
	public function shouldSortPackagesById()
	{

		var item1 = cast(allClasses.getItemByName("item1", Package), Package);
		var item2 = cast(allClasses.getItemByName("item2", Package), Package);
		var item3 = cast(allClasses.getItemByName("item3", Package), Package);
		
		var item1a = cast(allClasses.getItemByName("item1", Package), Package);
		
		item2.id = 2;
		item3.id = 4;
		

		var packages = allClasses.getPackages();

		Assert.areEqual(0, packages[0].id);
		Assert.areEqual(2, packages[1].id);
		Assert.areEqual(4, packages[2].id);
	}

	@Test
	public function shouldAppendFilesCountToResults()
	{
		var r = allClasses.getResults();
		assertEmptyResult(r);

		var item1 = cast(allClasses.getItemByName("item1", NodeMock), NodeMock);
		r = allClasses.getResults(false);

		Assert.areEqual(0, r.pc);
		Assert.areEqual(1, r.p);

		item1.results.sc = 1;

		r = allClasses.getResults(false);

		Assert.areEqual(1, r.pc);
		Assert.areEqual(1, r.p);	
	}

	@Test
	public function shouldAddStatementToMethod()
	{
		var block = new NodeMock().createStatement();
		block.packageName = "p";
		block.file = "f";
		block.qualifiedClassName = "c";
		block.methodName = "m";

		allClasses.addStatement(block);

		var packages = allClasses.getPackages();

		Assert.areEqual(1, packages.length);
		Assert.areEqual("p", packages[0].name);
		Assert.areEqual(1, cast(packages[0], Package).itemCount);

		var file = packages[0].getItemByName("f", File);

		Assert.areEqual(1, cast(file, File).itemCount);


		var classes = allClasses.getClasses();
		Assert.areEqual(1, classes.length);
		Assert.areEqual("c", classes[0].name);
		Assert.areEqual(1, cast(classes[0], Clazz).itemCount);

		var method = cast(classes[0].getItemByName("m", Method), Method);

		Assert.areEqual(block, method.getStatementById(0));
	}

	@Test
	public function shouldAddBlockToMethod()
	{
		var block = new NodeMock().createBranch();
		block.packageName = "p";
		block.file = "f";
		block.qualifiedClassName = "c";
		block.methodName = "m";

		allClasses.addBranch(block);

		var packages = allClasses.getPackages();

		Assert.areEqual(1, packages.length);
		Assert.areEqual("p", packages[0].name);
		Assert.areEqual(1, cast(packages[0], Package).itemCount);

		var file = packages[0].getItemByName("f", File);

		Assert.areEqual(1, cast(file, File).itemCount);


		var classes = allClasses.getClasses();
		Assert.areEqual(1, classes.length);
		Assert.areEqual("c", classes[0].name);
		Assert.areEqual(1, cast(classes[0], Clazz).itemCount);

		var method = cast(classes[0].getItemByName("m", Method), Method);

		Assert.areEqual(block, method.getBranchById(0));
	}



	@Test
	public function shouldReturnStatementById()
	{
		try
		{
			var item1 = cast(allClasses.getItemByName("item1", NodeMock), NodeMock);
			
			item1.statement.id = 1;

			allClasses.addStatement(item1.statement);

			var statement = allClasses.getStatementById(1);

			Assert.isNotNull(statement);
			Assert.areEqual(item1.statement, statement);


			statement = allClasses.getStatementById(2);
			Assert.fail("invalid statement id should throw exception.");
		}
		catch(e:String)
		{
			Assert.isTrue(true);
		}
	}

	@Test
	public function shouldReturnBranchById()
	{
		try
		{
			var item1 = cast(allClasses.getItemByName("item1", NodeMock), NodeMock);
			item1.branch.id = 1;

			allClasses.addBranch(item1.branch);

			var branch = allClasses.getBranchById(1);

			Assert.isNotNull(branch);
			Assert.areEqual(item1.branch, branch);


			branch = allClasses.getBranchById(2);
			Assert.fail("invalid branch id should throw exception.");
		}
		catch(e:String)
		{
			Assert.isTrue(true);
		}
	}

	//////////////////

	override function createEmptyNode():AbstractNode
	{
		return createEmptyNodeList();
	}

	override function createEmptyNodeList():AbstractNodeList
	{
		return createEmptyAllClasses();
	}

	function createEmptyAllClasses():AllClasses
	{
		return new AllClasses();
	}


}