CREATE OR REPLACE PACKAGE BODY cms.test_calc_xml_pkg AS

v_site_name						VARCHAR2(200);
v_state							calc_xml_pkg.SQLGenerationState;

-- private
PROCEDURE CallGenerateCalc(
	in_calc							IN	VARCHAR2
)
AS
BEGIN
	calc_xml_pkg.GenerateCalc(v_state, dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(dbms_xmldom.newdomdocument(sys.xmltype.createXML(in_calc)))));
END;

-- private
PROCEDURE TestGenerateCalc(
	in_test_name					IN	VARCHAR2,
	in_calc							IN	VARCHAR2,
	in_expected_col_sql				IN	VARCHAR2,
	in_expected_from_sql			IN	VARCHAR2	DEFAULT '',
	in_expected_where_sql			IN	VARCHAR2	DEFAULT ''
)
AS
BEGIN
	CallGenerateCalc(in_calc);

	-- dbms_output.put_line('>   col_sql = ' || v_state.col_sql);
	-- dbms_output.put_line('>   from_sql = ' || v_state.from_sql);
	-- dbms_output.put_line('>   where_sql = ' || v_state.where_sql);

	csr.unit_test_pkg.AssertAreEqual(in_expected_col_sql, dbms_lob.substr(v_state.col_sql, 4000), in_test_name || ' (col)');
	csr.unit_test_pkg.AssertAreEqual(in_expected_from_sql, dbms_lob.substr(v_state.from_sql, 4000), in_test_name || ' (from)');
	csr.unit_test_pkg.AssertAreEqual(in_expected_where_sql, dbms_lob.substr(v_state.where_sql, 4000), in_test_name || ' (where)');
END;

-- private
PROCEDURE CleanUp
AS
BEGIN
	-- Unregister table if there is one
	FOR r IN (SELECT NULL FROM DUAL WHERE EXISTS (SELECT NULL FROM app_schema_table WHERE ORACLE_SCHEMA = 'RAG' AND ORACLE_TABLE = 'CALC_XML_TABLE'))
	LOOP
		tab_pkg.UnregisterTable(
			in_oracle_schema => 'RAG',
			in_oracle_table => 'CALC_XML_TABLE');
	END LOOP;

	-- Drop table if there is one
	FOR r IN (SELECT NULL FROM DUAL WHERE EXISTS (SELECT NULL FROM ALL_TABLES WHERE OWNER = 'RAG' AND TABLE_NAME = 'CALC_XML_TABLE'))
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE rag.calc_xml_table';
	END LOOP;
END;

PROCEDURE TestGenerateCalcWithAdd
AS
BEGIN
	TestGenerateCalc('Adding two numbers',
	                 '<add><left><number>1</number></left><right><number>3</number></right></add>',
	                 '(1)+(3)');
END;

PROCEDURE TestGenerateCalcWithCeil
AS
BEGIN
	TestGenerateCalc('Ceil of a number', '<ceil><number>2.6</number></ceil>', 'ceil(2.6)');
END;

PROCEDURE TestGenerateCalcWithChoose
AS
BEGIN
	TestGenerateCalc('Choose',
	                 '<choose><when><condition><test op="="><left><number>1</number></left><right><number>2</number></right></test></condition><then><number>1</number></then><else><number>0</number></else></when></choose>',
	                 'CASE WHEN 1 = 2 THEN 1 END');
END;

PROCEDURE TestGenerateCalcWithChooseO
AS
BEGIN
	TestGenerateCalc('Choose',
	                 '<choose>' ||
	                     '<when><condition><test op="="><left><number>1</number></left><right><number>2</number></right></test></condition><then><number>1</number></then><else><number>0</number></else></when>' ||
	                     '<otherwise><number>3</number></otherwise>' ||
	                 '</choose>',
	                 'CASE WHEN 1 = 2 THEN 1 ELSE 3 END');
END;

-- Private
PROCEDURE CreateCalcXmlTable
AS
BEGIN
	CleanUp;

	-- create a simple CMS table
	EXECUTE IMMEDIATE 'CREATE TABLE rag.calc_xml_table (column_that_does_exist		NUMBER(10)		NULL)';

	tab_pkg.RegisterTable(
		in_oracle_schema => 'RAG',
		in_oracle_table => 'CALC_XML_TABLE',
		in_managed => FALSE);

	-- put the table sid in the state
	SELECT tab_sid
	  INTO v_state.tab_sid
	  FROM tab
	 WHERE oracle_schema = 'RAG'
	   AND oracle_table = 'CALC_XML_TABLE';
END;

PROCEDURE TestGenerateCalcWithColumn
AS
BEGIN
	CreateCalcXmlTable;

	TestGenerateCalc('Column that does exist', '<column name="column_that_does_exist"/>', 'COLUMN_THAT_DOES_EXIST'); 

	CleanUp;
END;

PROCEDURE TestGenerateCalcWithColumnGone
AS
BEGIN
	CreateCalcXmlTable;

	BEGIN
		CallGenerateCalc('<column name="column_that_does_not_exist"/>');

		csr.unit_test_pkg.TestFail('Expected the previous line to throw an exception');
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -20001 THEN -- we're expecting -20001
				RAISE;
			END IF;
	END;

	CleanUp;
END;

PROCEDURE TestGenerateCalcWithConcat
AS
BEGIN
	TestGenerateCalc('Concatenating two numbers',
	                 '<concat><left><number>1</number></left><right><number>2</number></right></concat>',
	                 '(TO_CHAR(1) || TO_CHAR(2))');
END;

PROCEDURE TestGenerateCalcWithDivide
AS
BEGIN
	TestGenerateCalc('Dividing two numbers',
	                 '<divide><left><number>2</number></left><right><number>3</number></right></divide>',
	                 '(2)/(3)');
END;

PROCEDURE TestGenerateCalcWithFloor
AS
BEGIN
	TestGenerateCalc('Floor of a number',
	                 '<floor><number>2.6</number></floor>',
	                 'floor(2.6)');
END;

PROCEDURE TestGenerateCalcWithIf
AS
BEGIN
	TestGenerateCalc('Simple if',
	                 '<if><condition><test op="="><left><number>1</number></left><right><number>2</number></right></test></condition><then><number>1</number></then><else><number>0</number></else></if>',
	                 'CASE WHEN 1 = 2 THEN 1 ELSE 0 END');
END;

PROCEDURE TestGenerateCalcWithMeasureC
AS
BEGIN
	CreateCalcXmlTable;

	TestGenerateCalc('Measure conversion',
	                 '<measure-conversion name="column_that_does_exist" to-base="no"/>',
	                 'POWER((COLUMN_THAT_DOES_EXIST - NVL(mc1.c, 0)) / NVL(mc1.a, 1), 1 / NVL(mc1.b, 1))',
	                 ', csr.measure_conversion mc1',
	                 'i."" = mc1.measure_conversion_id(+) '); -- why i.""?

	CleanUp;
END;

PROCEDURE TestGenerateCalcWithMultiply
AS
BEGIN
	TestGenerateCalc('Multiplying two numbers',
	                 '<multiply><left><number>2</number></left><right><number>3</number></right></multiply>',
	                 '(2)*(3)');
END;

PROCEDURE TestGenerateCalcWithNull
AS
BEGIN
	TestGenerateCalc('A null', '<null/>', 'NULL');
END;

PROCEDURE TestGenerateCalcWithNvl
AS
BEGIN
	TestGenerateCalc('Nvl',
	                 '<nvl><left><number>1</number></left><right><number>2</number></right></nvl>',
	                 'nvl(1,2)');
END;

PROCEDURE TestGenerateCalcWithNumber
AS
BEGIN
	TestGenerateCalc('A number', '<number>0</number>', '0');
END;

PROCEDURE TestGenerateCalcWithPower
AS
BEGIN
	TestGenerateCalc('Raising a number to a power',
	                 '<power><left><number>2</number></left><right><number>3</number></right></power>',
	                 'power(2,3)');
END;

PROCEDURE TestGenerateCalcWithRound
AS
BEGIN
	TestGenerateCalc('Rounding a number',
	                 '<round><left><number>3.1415</number></left><right><number>2</number></right></round>',
	                 'round(3.1415,2)');
END;

PROCEDURE TestGenerateCalcWithString
AS
BEGIN
	TestGenerateCalc('A string', '<string>test</string>', q'['test']');
END;

PROCEDURE TestGenerateCalcWithSubtract
AS
BEGIN
	TestGenerateCalc('Subtracting two numbers',
	                 '<subtract><left><number>5</number></left><right><number>1</number></right></subtract>',
	                 '(5)-(1)');
END;

PROCEDURE TestGenerateCalcWithSysdate
AS
BEGIN
	TestGenerateCalc('A sysdate', '<sysdate/>', 'SYSDATE');
END;

PROCEDURE TestGenerateCalcWithTrunc
AS
BEGIN
	TestGenerateCalc('Truncating a number',
	                 '<trunc><left><number>3.1415</number></left><right><number>2</number></right></trunc>',
	                 'trunc(3.1415,2)');
END;

PROCEDURE SetUp
AS
BEGIN
	-------------------
	-- populate v_state
	-------------------

	v_state.tab_sid := 1;
	v_state.tab_num := 1;
	v_state.needs_rid := FALSE;
	dbms_lob.createtemporary(v_state.col_sql, TRUE, dbms_lob.call);
	dbms_lob.createtemporary(v_state.from_sql, TRUE, dbms_lob.call);
	dbms_lob.createtemporary(v_state.where_sql, TRUE, dbms_lob.call);

	---------
	-- log in
	---------

	-- It's safest to log in once per test as well
	security.user_pkg.logonadmin(v_site_name);
	
	-- Un-set the Built-in admin's user sid from the session,
	-- otherwise all permissions tests against any ACT will return true
	-- because of the internal workings of security pkgs
	security_pkg.SetContext('SID', NULL);
END;

PROCEDURE TearDown
AS
BEGIN
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE TearDownFixture
AS
BEGIN
	CleanUp;
END;

END;
/

