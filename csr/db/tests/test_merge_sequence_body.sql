CREATE OR REPLACE PACKAGE BODY csr.test_merge_sequence_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	Trace('SetUpFixture');
	v_site_name	:= in_site_name;
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;



-- HELPER PROCS


-- Tests

PROCEDURE MergeWithInlineSequenceWithNoRecords AS
	v_test_name				VARCHAR2(100) := 'MergeWithInlineSequenceWithNoRecords';
	v_initialcount			NUMBER;
	v_finalcount			NUMBER;
	v_initialrecordcount	NUMBER;
	v_finalrecordcount		NUMBER;
BEGIN
	Trace(v_test_name);

	DELETE FROM csr.dbtest_merge;

	SELECT csr.DBTEST_MERGE_SEQ.NEXTVAL
	  INTO v_initialcount
	  FROM DUAL;

	SELECT COUNT(*)
	  INTO v_initialrecordcount
	  FROM csr.dbtest_merge;

	MERGE INTO csr.dbtest_merge dmd
	USING (
		SELECT 1 merge1, 2 merge2, 0 seq_id
		  FROM dual
	) x
	ON (dmd.merge1 = x.merge1)
	 WHEN MATCHED THEN 
	 	UPDATE
		   SET merge2 = x.merge2
	 WHEN NOT MATCHED THEN
	 	INSERT (merge1, merge2, seq_id)
	 	VALUES (x.merge1, x.merge2, DBTEST_MERGE_SEQ.NEXTVAL)
	;

	SELECT DBTEST_MERGE_SEQ.CURRVAL
	  INTO v_finalcount
	  FROM DUAL;

	unit_test_pkg.AssertIsTrue(v_finalcount = (v_initialcount + 1), 'Expected '|| (v_initialcount + 1) ||', found ' || v_finalcount);

	SELECT COUNT(*)
	  INTO v_finalrecordcount
	  FROM csr.dbtest_merge;

	unit_test_pkg.AssertIsTrue(v_finalrecordcount = (v_initialrecordcount + 1), 'Expected '|| (v_initialrecordcount + 1) ||' records, found ' || v_finalcount);
END;


PROCEDURE MergeWithInlineSequenceWithRecords AS
	v_test_name				VARCHAR2(100) := 'MergeWithInlineSequenceWithRecords';
	v_initialcount			NUMBER;
	v_finalcount			NUMBER;
	v_initialrecordcount	NUMBER;
	v_finalrecordcount		NUMBER;
BEGIN
	Trace(v_test_name);

	DELETE FROM csr.dbtest_merge;

	-- two records that will match
	INSERT INTO csr.dbtest_merge (merge1, merge2, seq_id)
	VALUES (100, 200, DBTEST_MERGE_SEQ.NEXTVAL);
	INSERT INTO csr.dbtest_merge (merge1, merge2, seq_id)
	VALUES (100, 200, DBTEST_MERGE_SEQ.NEXTVAL);

	SELECT DBTEST_MERGE_SEQ.CURRVAL
	  INTO v_initialcount
	  FROM DUAL;

	SELECT COUNT(*)
	  INTO v_initialrecordcount
	  FROM csr.dbtest_merge;

	MERGE INTO csr.dbtest_merge dmd
	USING (
		-- expecting two matches
		SELECT 100 merge1, 200 merge2, 0 seq_id
		  FROM dual
	) x
	ON (dmd.merge1 = x.merge1)
	 WHEN MATCHED THEN
	 	UPDATE
		   SET merge2 = x.merge2
	 WHEN NOT MATCHED THEN
	 	INSERT (merge1, merge2, seq_id)
	 	VALUES (x.merge1, x.merge2, DBTEST_MERGE_SEQ.NEXTVAL)
	;

	SELECT DBTEST_MERGE_SEQ.CURRVAL
	  INTO v_finalcount
	  FROM DUAL;

	-- You might expect + 0 as no records are inserted, but the seqval is updated by as many records are encountered during merge (in this case, two).
	unit_test_pkg.AssertIsTrue(v_finalcount = (v_initialcount + 2), 'Expected '|| (v_initialcount + 2) ||', found ' || v_finalcount);

	SELECT COUNT(*)
	  INTO v_finalrecordcount
	  FROM csr.dbtest_merge;

	unit_test_pkg.AssertIsTrue(v_finalrecordcount = (v_initialrecordcount), 'Expected '|| (v_initialrecordcount) ||' records, found ' || v_finalcount);
END;


PROCEDURE MergeWithJITSequenceWithNoRecords AS
	v_test_name				VARCHAR2(100) := 'MergeWithJITSequenceWithNoRecords';
	v_initialcount			NUMBER;
	v_finalcount			NUMBER;
	v_initialrecordcount	NUMBER;
	v_finalrecordcount		NUMBER;
BEGIN
	Trace(v_test_name);

	DELETE FROM csr.dbtest_merge;

	SELECT DBTEST_MERGE_SEQ.NEXTVAL
	  INTO v_initialcount
	  FROM DUAL;

	SELECT COUNT(*)
	  INTO v_initialrecordcount
	  FROM csr.dbtest_merge;

	MERGE INTO csr.dbtest_merge dmd
	USING (
		SELECT 1 merge1, 2 merge2, 0 seq_id
		  FROM dual
	) x
	ON (dmd.merge1 = x.merge1)
	 WHEN MATCHED THEN 
	 	UPDATE
		   SET merge2 = x.merge2
	 WHEN NOT MATCHED THEN
	 	INSERT (merge1, merge2, seq_id)
	 	VALUES (x.merge1, x.merge2, csr_data_pkg.JITNextVal('DBTEST_MERGE_SEQ'))
	;

	SELECT DBTEST_MERGE_SEQ.CURRVAL
	  INTO v_finalcount
	  FROM DUAL;

	-- should get one inserts triggered, hence seq should be + 1.
	unit_test_pkg.AssertIsTrue(v_finalcount = (v_initialcount + 1), 'Expected '|| (v_initialcount + 1) ||', found ' || v_finalcount);

	SELECT COUNT(*)
	  INTO v_finalrecordcount
	  FROM csr.dbtest_merge;

	unit_test_pkg.AssertIsTrue(v_finalrecordcount = (v_initialrecordcount + 1), 'Expected '|| (v_initialrecordcount + 1) ||' records, found ' || v_finalcount);
END;


PROCEDURE MergeWithJITSequenceWithRecords AS
	v_test_name				VARCHAR2(100) := 'MergeWithJITSequenceWithRecords';
	v_initialcount			NUMBER;
	v_finalcount			NUMBER;
	v_initialrecordcount	NUMBER;
	v_finalrecordcount		NUMBER;
BEGIN
	Trace(v_test_name);

	DELETE FROM csr.dbtest_merge;

	-- two records that will match
	INSERT INTO csr.dbtest_merge (merge1, merge2, seq_id)
	VALUES (100, 200, DBTEST_MERGE_SEQ.NEXTVAL);
	INSERT INTO csr.dbtest_merge (merge1, merge2, seq_id)
	VALUES (100, 200, DBTEST_MERGE_SEQ.NEXTVAL);

	SELECT DBTEST_MERGE_SEQ.CURRVAL
	  INTO v_initialcount
	  FROM DUAL;

	SELECT COUNT(*)
	  INTO v_initialrecordcount
	  FROM csr.dbtest_merge;

	MERGE INTO csr.dbtest_merge dmd
	USING (
		-- expecting two matches
		SELECT 100 merge1, 200 merge2, 0 seq_id
		  FROM dual
	) x
	ON (dmd.merge1 = x.merge1)
	 WHEN MATCHED THEN
	 	UPDATE
		   SET merge2 = x.merge2
	 WHEN NOT MATCHED THEN
	 	INSERT (merge1, merge2, seq_id)
	 	VALUES (x.merge1, x.merge2, csr_data_pkg.JITNextVal('DBTEST_MERGE_SEQ'))
	;

	SELECT DBTEST_MERGE_SEQ.CURRVAL
	  INTO v_finalcount
	  FROM DUAL;

	-- You would expect + 0 as no records are inserted.
	unit_test_pkg.AssertIsTrue(v_finalcount = (v_initialcount), 'Expected '|| (v_initialcount) ||', found ' || v_finalcount);

	SELECT COUNT(*)
	  INTO v_finalrecordcount
	  FROM csr.dbtest_merge;

	unit_test_pkg.AssertIsTrue(v_finalrecordcount = (v_initialrecordcount), 'Expected '|| (v_initialrecordcount) ||' records, found ' || v_finalcount);
END;

--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
	
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
END;

END test_merge_sequence_pkg;
/
