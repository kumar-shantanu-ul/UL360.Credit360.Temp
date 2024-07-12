CREATE OR REPLACE PACKAGE BODY cms.test_cms_register_table_pkg AS

v_site_name							VARCHAR(200);
m_table_name						VARCHAR2(30) := 'MANAGED_TABLE_TEST';
m_enum_table_name					VARCHAR2(30) := 'MANAGED_TABLE_ENUM_TEST';
m_schema							VARCHAR2(30) := 'RAG';
m_initial_row_count					NUMBER(10) := 3;
m_table_column_count				NUMBER(10) := 6;

-- Private
PROCEDURE CleanupCmsTables
AS
BEGIN	
	cms.tab_pkg.DropTable(in_oracle_schema => m_schema, in_oracle_table => m_table_name, in_drop_physical => TRUE);
	cms.tab_pkg.DropTable(in_oracle_schema => m_schema, in_oracle_table => m_enum_table_name, in_drop_physical => TRUE);
END;

-- Private
PROCEDURE CreateCmsTables
AS
BEGIN
	EXECUTE IMMEDIATE 'CREATE TABLE '||m_schema||'.'||m_enum_table_name||' ('||
		'id 				NUMBER(10) NOT NULL, '||
		'label 				VARCHAR2(255) NOT NULL, '||
		'pos				NUMBER(10), '||
		'hidden				NUMBER(1), '||
		'constraint pk_'||m_enum_table_name||' primary key (id))';
	
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_enum_table_name||' (id, label, pos, hidden) VALUES (-1, ''DONT SELECT!'', 1, 1)';
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_enum_table_name||' (id, label, pos, hidden) VALUES (1, ''Yes'', 1, 0)';
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_enum_table_name||' (id, label, pos, hidden) VALUES (2, ''No'', 1, 0)';
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_enum_table_name||' (id, label, pos, hidden) VALUES (3, ''Maybe'', 1, 0)';

	EXECUTE IMMEDIATE 'CREATE TABLE '||m_schema||'.'||m_table_name||' ('||
		'id 				NUMBER(10) NOT NULL, '||
		'col_with_default 	VARCHAR2(255) DEFAULT ''Some default text'' NOT NULL, '||
		'mandatory_col 		VARCHAR2(255) NOT NULL, '||
		'optional_col 		VARCHAR2(255), '||
		'unique_col			NUMBER(10) NOT NULL, '||
		'enum_col			NUMBER(10), '||
		'constraint pk_'||m_table_name||' primary key (id), '||
		'constraint uk_'||m_table_name||' unique (unique_col), '||
		'constraint chk_'||m_table_name||' check (enum_col > 0), '||
		'constraint fk_'||m_table_name||' foreign key (enum_col) '||
		'	references '||m_schema||'.'||m_enum_table_name||'(id))';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||m_schema||'.'||m_table_name||'.ID IS ''auto''';
	EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||m_schema||'.'||m_table_name||'.ENUM_COL IS ''enum,enum_desc_col=label,enum_pos_col=pos,enum_hidden_col=hidden''';
	
	FOR i IN 1 .. m_initial_row_count LOOP
		EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_table_name||' (id, mandatory_col, unique_col, enum_col) VALUES ('||i||', ''Mandatory text '||i||''', '||i||', 1)';
	END LOOP;
END;

-- Private
PROCEDURE CheckTableMetaData(
	in_tab_sid						security.security_pkg.T_SID_ID,
	in_managed						NUMBER
)
AS
	v_count							NUMBER(10);
	v_id							NUMBER(10);
	v_id_col_sid					NUMBER(10);
	v_unique_col_sid				NUMBER(10);
	v_enum_col_sid					NUMBER(10);
BEGIN
	SELECT COUNT(*) INTO v_count FROM cms.tab WHERE oracle_schema = m_schema AND oracle_table = m_table_name AND managed = in_managed AND tab_sid = in_tab_sid;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.tab record after registering');
	
	-- could expand this to test other columns in cms.tab_column and the comment parsing...
	SELECT COUNT(*), MIN(column_sid) INTO v_count, v_id_col_sid FROM cms.tab_column WHERE tab_sid = in_tab_sid AND oracle_column = 'ID';
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.tab_column row for column ID');
	SELECT COUNT(*) INTO v_count FROM cms.tab_column WHERE tab_sid = in_tab_sid AND oracle_column = 'COL_WITH_DEFAULT';
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.tab_column row for column COL_WITH_DEFAULT');
	SELECT COUNT(*) INTO v_count FROM cms.tab_column WHERE tab_sid = in_tab_sid AND oracle_column = 'MANDATORY_COL';
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.tab_column row for column MANDATORY_COL');
	SELECT COUNT(*) INTO v_count FROM cms.tab_column WHERE tab_sid = in_tab_sid AND oracle_column = 'OPTIONAL_COL';
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.tab_column row for column OPTIONAL_COL');
	SELECT COUNT(*), MIN(column_sid) INTO v_count, v_unique_col_sid FROM cms.tab_column WHERE tab_sid = in_tab_sid AND oracle_column = 'UNIQUE_COL';
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.tab_column row for column UNIQUE_COL');
	SELECT COUNT(*), MIN(column_sid) INTO v_count, v_enum_col_sid FROM cms.tab_column WHERE tab_sid = in_tab_sid AND oracle_column = 'ENUM_COL';
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.tab_column row for column ENUM_COL');
	
	SELECT COUNT(*) INTO v_count FROM cms.tab_column WHERE tab_sid = in_tab_sid;
	csr.unit_test_pkg.AssertAreEqual(m_table_column_count, v_count, 'Extra cms.tab_columns record after registering');
	
	-- pk
	SELECT COUNT(*), MIN(uk_cons_id) INTO v_count, v_id FROM cms.uk_cons WHERE tab_sid = in_tab_sid AND constraint_owner = m_schema AND constraint_name = 'PK_'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.uk_cons record for primary key constraint PK_'||m_table_name);
	SELECT COUNT(*) INTO v_count FROM cms.uk_cons_col WHERE uk_cons_id = v_id AND column_sid = v_id_col_sid;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.uk_cons_col record for primary key constraint PK_'||m_table_name||', ID column with sid'||v_id_col_sid);
	SELECT COUNT(*) INTO v_count FROM cms.uk_cons_col WHERE uk_cons_id = v_id;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Extra cms.uk_cons_col records for primary key constraint PK_'||m_table_name);
	
	SELECT COUNT(*) INTO v_count FROM cms.tab WHERE tab_sid = in_tab_sid AND pk_cons_id = v_id;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing pk_cons_id on cms.tab');
	
	-- uk
	SELECT COUNT(*), MIN(uk_cons_id) INTO v_count, v_id FROM cms.uk_cons WHERE tab_sid = in_tab_sid AND constraint_owner = m_schema AND constraint_name = 'UK_'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.uk_cons record for unique constraint UK_'||m_table_name);
	SELECT COUNT(*) INTO v_count FROM cms.uk_cons_col WHERE uk_cons_id = v_id AND column_sid = v_unique_col_sid;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.uk_cons_col record for unique constraint UK_'||m_table_name||', UNIQUE_COL columnwith sid'||v_unique_col_sid);
	SELECT COUNT(*) INTO v_count FROM cms.uk_cons_col WHERE uk_cons_id = v_id;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Extra cms.uk_cons_col records for unique constraint UK_'||m_table_name);
	
	SELECT COUNT(*) INTO v_count FROM cms.ck_cons WHERE tab_sid = in_tab_sid AND constraint_owner = m_schema AND constraint_name = 'CHK_'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.ck_cons record for check constraint CHK_'||m_table_name);
	
	SELECT COUNT(*) INTO v_count FROM cms.fk_cons WHERE tab_sid = in_tab_sid AND constraint_owner = m_schema AND constraint_name = 'FK_'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing cms.fk_cons record for foreign key constraint FK_'||m_table_name);
END;

-- Private
PROCEDURE TestManagedTable (
	in_managed_version				IN  NUMBER
)
AS
	v_count							NUMBER(10);
	v_row_count						NUMBER(10) := m_initial_row_count;
	v_history_row_count				NUMBER(10) := m_initial_row_count;
	v_tab_sid						security.security_pkg.T_SID_ID;
	check_constraint_violated		EXCEPTION;
	PRAGMA EXCEPTION_INIT(check_constraint_violated, -2290);
	cannot_insert_null_exception	EXCEPTION;
	PRAGMA EXCEPTION_INIT(cannot_insert_null_exception, -1400);
	integrity_constraint_violated	EXCEPTION;
	PRAGMA EXCEPTION_INIT(integrity_constraint_violated, -2291);
BEGIN	
	SELECT COUNT(*) INTO v_count FROM all_tables WHERE owner = m_schema AND table_name = m_table_name;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Registered table not converted to view');
	
	SELECT COUNT(*) INTO v_count FROM all_views WHERE owner = m_schema AND view_name = m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Registered table not converted to view');
	
	SELECT COUNT(*) INTO v_count FROM all_tables WHERE owner = m_schema AND table_name = 'C$'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Registered table not creating C$ table');
	
	SELECT COUNT(*) INTO v_count FROM all_views WHERE owner = m_schema AND view_name = 'H$'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Registered table not creating H$ view');

	SELECT COUNT(*) INTO v_count FROM all_triggers WHERE owner = m_schema AND trigger_name IN (
						'I$'||m_table_name, 'U$'||m_table_name, 'D$'||m_table_name,
						'J$'||m_table_name, 'V$'||m_table_name, 'E$'||m_table_name);
	csr.unit_test_pkg.AssertAreEqual(6, v_count, 'Registered table not creating triggers');
	
	SELECT COUNT(*) INTO v_count FROM all_objects WHERE owner = m_schema AND object_name = 'T$'||m_table_name AND object_type IN ('PACKAGE', 'PACKAGE BODY');
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Registered table not creating package');
	
	v_tab_sid := cms.tab_pkg.GetTableSid(in_oracle_schema => m_schema, in_oracle_table=> m_table_name);
	
	CheckTableMetaData(v_tab_sid, 1);
	
	-- select
	SELECT COUNT(*) INTO v_count FROM cms.tab WHERE tab_sid = v_tab_sid AND managed_version = in_managed_version;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Incorrect managed_version after registering table');
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Managed view not returning all original rows');
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Managed table adding additional rows on registration');
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Managed table adding additional history rows on registration');

	-- insert
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_table_name||' (id, mandatory_col, unique_col) VALUES (4, ''Mandatory text 4'', 4)';
	v_row_count := v_row_count + 1;
	v_history_row_count := v_history_row_count + 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Insert into managed view not working');
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Insert into managed view did not create history view row');
	
	-- read, including default column
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 4 AND mandatory_col = ''Mandatory text 4'' AND unique_col = 4 AND col_with_default = ''Some default text''') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Reading a new row with a default column from managed view failed');
	
	-- update
	EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.'||m_table_name||' SET mandatory_col = ''Some updated text 4'' WHERE id = 4';
	v_history_row_count := v_history_row_count + 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Updating a row in the managed view changed the record count');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 4 AND mandatory_col = ''Some updated text 4''') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Updating a row in the managed view did not update the record record');
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Updating a row in the managed view did not create a history view row');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name||' WHERE id = 4 AND mandatory_col = ''Mandatory text 4'' AND retired_dtm IS NOT NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Updating a row in the managed view did not create a history view row for the old record');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name||' WHERE id = 4 AND mandatory_col = ''Some updated text 4'' AND retired_dtm IS NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Updating a row in the managed view did not create a history view row for the new record');
	
	-- delete
	EXECUTE IMMEDIATE 'DELETE FROM '||m_schema||'.'||m_table_name||' WHERE id = 4';
	v_row_count := v_row_count - 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Deleting a row in the managed view did not remove it from the view');
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Deleting a row in the managed view did not update the history view as expected');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name||' WHERE id = 4 AND retired_dtm IS NULL AND vers < 0') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Deleting a row in the managed view did not update the history view as expected');
	
	-- Test scenarios of updating C$ directly, incl. changing key
	-- insert directly into c$ table an inactive row -vers
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.c$'||m_table_name||' (id, mandatory_col, unique_col, changed_by, vers, retired_dtm) VALUES (100, ''Mandatory text 100'', 100, 3, -1, NULL)';
	v_history_row_count := v_history_row_count + 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Insert inactive row (-vers) into c$ table appearing in view');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Insert inactive row (-vers) into c$ table did not appear in history view');
	
	-- insert directly into c$ table an inactive row retired_dtm set
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.c$'||m_table_name||' (id, mandatory_col, unique_col, changed_by, vers, retired_dtm) VALUES (101, ''Mandatory text 101'', 101, 3, 1, SYSTIMESTAMP)';
	v_history_row_count := v_history_row_count + 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Insert inactive row (retired_dtm) into c$ table appearing in view');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Insert inactive row (retired_dtm) into c$ table did not appear in history view');
	
	-- insert directly into c$ table an active row
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.c$'||m_table_name||' (id, mandatory_col, unique_col, changed_by, vers, retired_dtm) VALUES (102, ''Mandatory text 102'', 102, 3, 1, NULL)';
	v_row_count := v_row_count + 1;
	v_history_row_count := v_history_row_count + 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Insert active row into c$ table did not appear in view');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Insert active row into c$ table did not create history view row');
	
	-- update an active row in c$
	EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.c$'||m_table_name||' SET mandatory_col = ''Updated active row text'' WHERE id = 1 AND vers > 0 AND retired_dtm IS NULL';
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 1 AND mandatory_col = ''Updated active row text''') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'An update to an active row in the c$ table did not update the row in the view');
	
	-- update an inactive row in c$ -vers	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 4 AND vers < 0') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.c$'||m_table_name||' SET mandatory_col = ''Updated inactive row text that should not update'' WHERE id = 4 AND vers < 0';
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 4 AND mandatory_col = ''Updated inactive row text that should not update''') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'An update to an inactive row in the c$ table updated the row in the view (vers)');	
	
	-- update an inactive row in c$ retired_dtm set	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 4 AND vers > 0 AND retired_dtm IS NOT NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.c$'||m_table_name||' SET mandatory_col = ''Updated inactive row text that should not update'' WHERE id = 4 AND vers > 0 AND retired_dtm IS NOT NULL';
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 4 AND mandatory_col = ''Updated inactive row text that should not update''') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'An update to an inactive row in the c$ table updated the row in the view (retired)');	
	
	-- update an active row to make it inactive -vers
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 1 AND vers > 0 AND retired_dtm IS NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.c$'||m_table_name||' SET vers = -vers WHERE id = 1 AND vers > 0 AND retired_dtm IS NULL';
	v_row_count := v_row_count - 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 1') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'An update to an active row in the c$ table to make it inactive did not remove it from view (vers)');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'An update to an active row in the c$ table to make it inactive did not remove it from view (vers)');
	
	-- update an active row to make it inactive retired_dtm
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 2 AND vers > 0 AND retired_dtm IS NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.c$'||m_table_name||' SET retired_dtm = SYSTIMESTAMP WHERE id = 2 AND vers > 0 AND retired_dtm IS NULL';
	v_row_count := v_row_count - 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 2') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'An update to an active row in the c$ table to make it inactive did not remove it from view (retired_dtm)');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'An update to an active row in the c$ table to make it inactive did not remove it from view (retired_dtm)');
	
	-- update an inactive row to make it active +vers
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 1 AND vers < 0 AND retired_dtm IS NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.c$'||m_table_name||' SET vers = -vers WHERE id = 1 AND vers < 0 AND retired_dtm IS NULL';
	v_row_count := v_row_count + 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 1') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'An update to an inactive row in the c$ table to make it active did not add it to the view (vers)');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'An update to an inactive row in the c$ table to make it active did not add it to the view (vers)');
	
	-- update an inactive row to make it active retired_dtm nulled
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 2 AND vers > 0 AND retired_dtm IS NOT NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.c$'||m_table_name||' SET retired_dtm = NULL WHERE id = 2 AND vers > 0 AND retired_dtm IS NOT NULL';
	v_row_count := v_row_count + 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 2') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'An update to an inactive row in the c$ table to make it active did not add it to the view (retired_dtm)');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'An update to an inactive row in the c$ table to make it active did not add it to the view (retired_dtm)');
	
	-- delete inactive row -vers
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 100 AND vers < 0 AND retired_dtm IS NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'DELETE FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 100 AND vers < 0 AND retired_dtm IS NULL';
	v_history_row_count := v_history_row_count - 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 100') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'A delete of an inactive row in the c$ table made it appear in the view (vers)');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'A delete of an inactive row in the c$ table changed the view count (vers)');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'A delete of an inactive row in the c$ table did not remove it from the history view (vers)');
	
	-- delete inactive row retired_dtm
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 101 AND vers > 0 AND retired_dtm IS NOT NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'DELETE FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 101 AND vers > 0 AND retired_dtm IS NOT NULL';
	v_history_row_count := v_history_row_count - 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 101') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'A delete of an inactive row in the c$ table made it appear in the view (retired_dtm)');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'A delete of an inactive row in the c$ table changed the view count (retired_dtm)');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'A delete of an inactive row in the c$ table did not remove it from the history view (retired_dtm)');
	
	-- delete active row
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 102 AND vers > 0 AND retired_dtm IS NULL') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Cannot find row to test with');	
	EXECUTE IMMEDIATE 'DELETE FROM '||m_schema||'.c$'||m_table_name||' WHERE id = 102 AND vers > 0 AND retired_dtm IS NULL';
	v_row_count := v_row_count - 1;
	v_history_row_count := v_history_row_count - 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name||' WHERE id = 102') INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'A delete of an active row in the c$ table did not remove it from the view');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'A delete of an active row in the c$ table did not lower the view count');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'A delete of an active row in the c$ table did not remove it from the history view');
	
	-- insert of a row after delete
	EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.c$'||m_table_name||' (id, mandatory_col, unique_col, changed_by, vers, retired_dtm) VALUES (102, ''Mandatory text 102'', 102, 3, 1, NULL)';
	v_row_count := v_row_count + 1;
	v_history_row_count := v_history_row_count + 1;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Insert active row into c$ table after a delete did not appear in view');	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Insert active row into c$ table after a delete did not create history view row');
		
	-- pk violation
	BEGIN
		EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_table_name||' (id, mandatory_col, unique_col) VALUES (3, ''Mandatory text 5'', 5)';
		csr.unit_test_pkg.TestFail('PK violation failed to raise exception');
	EXCEPTION
		WHEN cms.tab_pkg.UK_VIOLATION THEN
			NULL; -- expected		
	END;
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Failed PK insert affected view count');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Failed PK insert affected history view count');
	
	-- uk violation
	BEGIN
		EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_table_name||' (id, mandatory_col, unique_col) VALUES (5, ''Mandatory text 5'', 3)';
		csr.unit_test_pkg.TestFail('UK violation failed to raise exception');
	EXCEPTION
		WHEN cms.tab_pkg.UK_VIOLATION THEN
			NULL; -- expected		
	END;
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Failed UK insert affected view count');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Failed UK insert affected history view count');
	
	-- check violation
	BEGIN
		EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_table_name||' (id, mandatory_col, unique_col, enum_col) VALUES (5, ''Mandatory text 5'', 5, -1)';
		csr.unit_test_pkg.TestFail('Check constraint violation failed to raise exception');
	EXCEPTION
		WHEN check_constraint_violated THEN
			NULL; -- expected		
	END;
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Failed check constraint insert affected view count');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Failed check constraint insert affected history view count');
	
	-- mandatory_column violation
	BEGIN
		EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_table_name||' (id, unique_col) VALUES (5, 5)';
		csr.unit_test_pkg.TestFail('Mandatory column violation failed to raise exception');
	EXCEPTION
		WHEN cannot_insert_null_exception THEN
			NULL; -- expected		
	END;
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Failed mandatory column insert affected view count');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Failed mandatory column  insert affected history view count');
	
	-- fk violation
	BEGIN
		EXECUTE IMMEDIATE 'INSERT INTO '||m_schema||'.'||m_table_name||' (id, mandatory_col, unique_col, enum_col) VALUES (5, ''Mandatory text 5'', 5, 1000)';
		csr.unit_test_pkg.TestFail('FK constraint violation failed to raise exception');
	EXCEPTION
		WHEN integrity_constraint_violated THEN
			NULL; -- expected		
	END;
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Failed fk constraint insert affected view count');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Failed fk constraint insert affected history view count');
	
	-- updating pk fails
	BEGIN
		EXECUTE IMMEDIATE 'UPDATE '||m_schema||'.'||m_table_name||' SET id = 5 WHERE unique_col = 3';
		csr.unit_test_pkg.TestFail('PK modification failed to raise exception');
	EXCEPTION
		WHEN cms.tab_pkg.PK_MODIFIED THEN
			NULL; -- expected		
	END;
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_row_count, v_count, 'Failed PK modification insert affected view count');
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.h$'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(v_history_row_count, v_count, 'Failed PK modification insert affected history view count');
END;

PROCEDURE With_ManagedV1
AS
BEGIN
	CreateCmsTables;
	
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => m_schema, 
		in_oracle_table => m_table_name, 
		in_managed => TRUE, 
		in_managed_version => cms.tab_pkg.MNGD_VERS_HISTORY_IN_ONE_TABLE,
		in_allow_entire_schema => TRUE
	);

	TestManagedTable(cms.tab_pkg.MNGD_VERS_HISTORY_IN_ONE_TABLE);
END;

PROCEDURE With_ManagedV2
AS
	v_count						NUMBER(10);
	v_view_count				NUMBER(10);
	v_q_count					NUMBER(10);
	v_cons_name_before			VARCHAR2(30);
	v_cons_name_after			VARCHAR2(30);
BEGIN
	CreateCmsTables;
	
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => m_schema, 
		in_oracle_table => m_table_name, 
		in_managed => TRUE, 
		in_managed_version => cms.tab_pkg.MNGD_VERS_SPLIT_HISTORY_TABLE,
		in_allow_entire_schema => TRUE
	);

	TestManagedTable(cms.tab_pkg.MNGD_VERS_SPLIT_HISTORY_TABLE);
	
	SELECT COUNT(*) INTO v_count FROM all_tables WHERE owner = m_schema AND table_name = 'Q$'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Register table not creating Q$ table');

	SELECT COUNT(*) INTO v_count FROM all_triggers WHERE owner = m_schema AND trigger_name IN (
						'K$'||m_table_name, 'W$'||m_table_name, 'F$'||m_table_name);
	csr.unit_test_pkg.AssertAreEqual(3, v_count, 'Register table not creating v2 triggers');
	
	-- Test that Q$ count equals view count
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_view_count;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.q$'||m_table_name) INTO v_q_count;	
	csr.unit_test_pkg.AssertAreEqual(v_view_count, v_q_count, 'Counts different between q$ table and view');
	
	-- Test that refreshing doesn't recreate q$ with no change
	SELECT constraint_name INTO v_cons_name_before FROM all_constraints WHERE owner = m_schema AND table_name = 'Q$'||m_table_name AND constraint_type = 'P';
	cms.tab_pkg.RecreateView(in_oracle_schema => m_schema, in_oracle_table => m_table_name);
	SELECT constraint_name INTO v_cons_name_after FROM all_constraints WHERE owner = m_schema AND table_name = 'Q$'||m_table_name AND constraint_type = 'P';
	csr.unit_test_pkg.AssertAreEqual(v_cons_name_before, v_cons_name_after, 'RecreateView recreated the q$ table even though there weren''t any changes');
	
	-- Test that refreshing does recreate when col changed 
	EXECUTE IMMEDIATE ('ALTER TABLE '||m_schema||'.C$'||m_table_name||' MODIFY enum_col NUMBER(12)');
	SELECT constraint_name INTO v_cons_name_before FROM all_constraints WHERE owner = m_schema AND table_name = 'Q$'||m_table_name AND constraint_type = 'P';
	cms.tab_pkg.RecreateView(in_oracle_schema => m_schema, in_oracle_table => m_table_name);
	SELECT constraint_name INTO v_cons_name_after FROM all_constraints WHERE owner = m_schema AND table_name = 'Q$'||m_table_name AND constraint_type = 'P';
	csr.unit_test_pkg.AssertNotEqual(v_cons_name_before, v_cons_name_after, 'RecreateView did not recreate the q$ table even though a column was modified');
	
	-- Test adding column via SP
	SELECT constraint_name INTO v_cons_name_before FROM all_constraints WHERE owner = m_schema AND table_name = 'Q$'||m_table_name AND constraint_type = 'P';
	cms.tab_pkg.AddColumn(
		in_oracle_schema	=> m_schema,
		in_oracle_table		=> m_table_name,
		in_oracle_column	=> 'NEW_COL_TEST_Q_UDPATES',
		in_type				=> 'VARCHAR2(255)'
	);
	SELECT constraint_name INTO v_cons_name_after FROM all_constraints WHERE owner = m_schema AND table_name = 'Q$'||m_table_name AND constraint_type = 'P';
	csr.unit_test_pkg.AssertNotEqual(v_cons_name_before, v_cons_name_after, 'Adding a column via tab_pkg.AddColumn did not recreate the q$ table');
	-- check that the new col is on the q$ table...
	SELECT COUNT(*) INTO v_count FROM all_tab_columns WHERE owner = m_schema AND table_name = 'Q$'||m_table_name AND column_name = 'NEW_COL_TEST_Q_UDPATES';
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'AddColumn did not add new column to q$ table');
END;

PROCEDURE With_ManagedV1_UpgradeToV2
AS
	v_count						NUMBER(10);
	v_view_count				NUMBER(10);
	v_q_count					NUMBER(10);
BEGIN
	CreateCmsTables;
	
	-- register v1
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => m_schema, 
		in_oracle_table => m_table_name, 
		in_managed => TRUE, 
		in_managed_version => cms.tab_pkg.MNGD_VERS_HISTORY_IN_ONE_TABLE,
		in_allow_entire_schema => TRUE
	);
	
	-- upgrade to v2
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => m_schema, 
		in_oracle_table => m_table_name, 
		in_managed => TRUE, 
		in_managed_version => cms.tab_pkg.MNGD_VERS_SPLIT_HISTORY_TABLE,
		in_allow_entire_schema => TRUE
	);
	
	TestManagedTable(cms.tab_pkg.MNGD_VERS_SPLIT_HISTORY_TABLE);
	
	SELECT COUNT(*) INTO v_count FROM cms.tab WHERE tab_sid = cms.tab_pkg.GetTableSid(in_oracle_schema => m_schema, in_oracle_table=> m_table_name) AND managed_version = cms.tab_pkg.MNGD_VERS_SPLIT_HISTORY_TABLE;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Incorrect managed_version after upgrading table');
	
	SELECT COUNT(*) INTO v_count FROM all_tables WHERE owner = m_schema AND table_name = 'Q$'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Upgrading table to managed v2 not creating Q$ table');

	SELECT COUNT(*) INTO v_count FROM all_triggers WHERE owner = m_schema AND trigger_name IN (
						'K$'||m_table_name, 'W$'||m_table_name, 'F$'||m_table_name);
	csr.unit_test_pkg.AssertAreEqual(3, v_count, 'Upgrading table to managed v2 not creating v2 triggers');
	
	-- Test that Q$ count equals view count
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_view_count;
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.q$'||m_table_name) INTO v_q_count;	
	csr.unit_test_pkg.AssertAreEqual(v_view_count, v_q_count, 'Counts different between q$ table and view');
END;

PROCEDURE With_ManagedV1_NoV2Created
AS
	v_count				NUMBER(10);
BEGIN
	CreateCmsTables;
	
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => m_schema, 
		in_oracle_table => m_table_name, 
		in_managed => TRUE, 
		in_managed_version => cms.tab_pkg.MNGD_VERS_HISTORY_IN_ONE_TABLE,
		in_allow_entire_schema => TRUE
	);
	
	SELECT COUNT(*) INTO v_count FROM all_tables WHERE owner = m_schema AND table_name = 'Q$'||m_table_name;
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Register table creating Q$ table for v1 registration');
	
	SELECT COUNT(*) INTO v_count FROM all_triggers WHERE owner = m_schema AND trigger_name IN (
						'K$'||m_table_name, 'W$'||m_table_name, 'F$'||m_table_name);
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Register table creating v2 triggers for v1 registration');
END;

PROCEDURE With_Unmanaged
AS
	v_count				NUMBER(10);
BEGIN
	CreateCmsTables;
	
	cms.tab_pkg.RegisterTable(
		in_oracle_schema => m_schema, 
		in_oracle_table => m_table_name, 
		in_managed => FALSE,
		in_allow_entire_schema => TRUE
	);
	
	CheckTableMetaData(cms.tab_pkg.GetTableSid(in_oracle_schema => m_schema, in_oracle_table=> m_table_name), 0);
	
	EXECUTE IMMEDIATE ('SELECT COUNT(*) FROM '||m_schema||'.'||m_table_name) INTO v_count;
	csr.unit_test_pkg.AssertAreEqual(m_initial_row_count, v_count, 'Registering table changed original row count');
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE SetUp
AS
BEGIN
	-- Safest to log on once per test (instead of in StartupFixture) because we unset
	-- the user sid futher down (otherwise any permission test on any ACT returns true)
	
	security.user_pkg.logonadmin(v_site_name);
	
	CleanupCmsTables;
	
	-- Remove built in admin sid from user context - otherwise we can't check the permissions
	-- of test-built acts (security_pkg.IsAdmin checks sys_context sid before passed act)
	security_pkg.SetContext('SID', NULL);
END;

PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	CleanupCmsTables;
END;

END;
/
