-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	TYPE t_varchar2_array		IS TABLE OF VARCHAR2(30);
	v_owner						VARCHAR2(30) := 'SURVEYS';
	v_table_name				VARCHAR2(30);
	v_object_list				t_varchar2_array;
	v_object_rename_to_list		t_varchar2_array;

	FUNCTION ColumnExists(
		in_owner			IN	all_tab_columns.owner%TYPE,
		in_table_name		IN	all_tab_columns.table_name%TYPE,
		in_column_name		IN	all_tab_columns.column_name%TYPE
	) RETURN BOOLEAN
	AS
		v_count					NUMBER(10);
	BEGIN
		SELECT COUNT(*) 
		  INTO v_count
		  FROM all_tab_columns
		 WHERE owner = UPPER(in_owner)
		   AND table_name = UPPER(in_table_name)
		   AND column_name = UPPER(in_column_name);

		RETURN v_count != 0;
	END;

	FUNCTION ConstraintExists(
		in_owner			IN	all_constraints.owner%TYPE,
		in_table_name		IN	all_constraints.table_name%TYPE,
		in_constraint_name	IN	all_constraints.constraint_name%TYPE
	) RETURN BOOLEAN
	AS
		v_count					NUMBER(10);
	BEGIN
		SELECT COUNT(*) 
		  INTO v_count
		  FROM all_constraints
		 WHERE owner = UPPER(in_owner)
		   AND table_name = UPPER(in_table_name)
		   AND constraint_name = UPPER(in_constraint_name); 
		
		RETURN v_count != 0;
	END;

	FUNCTION IndexExists(
		in_owner			IN	all_indexes.owner%TYPE,
		in_index_name		IN	all_indexes.index_name%TYPE
	) RETURN BOOLEAN
	AS
		v_count					NUMBER(10);
	BEGIN
		SELECT COUNT(*) 
		  INTO v_count
		  FROM all_indexes
		 WHERE owner = UPPER(in_owner)
		   AND index_name = UPPER(in_index_name); 
		
		RETURN v_count != 0;
	END;
	
	FUNCTION TableExists(
		in_owner			IN	all_tables.owner%TYPE,
		in_table_name		IN	all_tables.table_name%TYPE
	) RETURN BOOLEAN
	AS
		v_count					NUMBER(10);
	BEGIN
		SELECT COUNT(*) 
		  INTO v_count
		  FROM all_tables
		 WHERE owner = UPPER(in_owner)
		   AND table_name = UPPER(in_table_name); 
		
		RETURN v_count != 0;
	END;
	
	PROCEDURE RenameColumns(
		in_owner					IN	all_tab_columns.owner%TYPE,
		in_table_name				IN	all_tab_columns.table_name%TYPE,
		in_column_list				IN	t_varchar2_array,
		in_column_rename_to_list	IN	t_varchar2_array
	)
	AS
	BEGIN
		FOR i IN 1 .. in_column_list.COUNT
		LOOP
			IF ColumnExists(in_owner, in_table_name, in_column_list(i)) THEN
				EXECUTE IMMEDIATE 'ALTER TABLE '||in_owner||'.'||in_table_name||' RENAME COLUMN '|| in_column_list(i)||' TO '||in_column_rename_to_list(i);
			END IF;
		END LOOP;		
	END;

	PROCEDURE RenameConstraints(
		in_owner						IN	all_constraints.owner%TYPE,
		in_table_name					IN	all_constraints.table_name%TYPE,
		in_constraint_list				IN	t_varchar2_array,
		in_constraint_rename_to_list	IN	t_varchar2_array
	)
	AS
	BEGIN
		FOR i IN 1 .. in_constraint_list.COUNT
		LOOP
			IF ConstraintExists(in_owner, in_table_name, in_constraint_list(i)) THEN
				EXECUTE IMMEDIATE 'ALTER TABLE '||in_owner||'.'||in_table_name||' RENAME CONSTRAINT '|| in_constraint_list(i)||' TO '||in_constraint_rename_to_list(i);
			END IF;
		END LOOP;		
	END;

	PROCEDURE RenameIndexes(
		in_owner					IN	all_indexes.owner%TYPE,
		in_index_list				IN	t_varchar2_array,
		in_index_rename_to_list		IN	t_varchar2_array
	)
	AS
	BEGIN
		FOR i IN 1 .. in_index_list.COUNT
		LOOP
			IF IndexExists(in_owner, in_index_list(i)) THEN
				EXECUTE IMMEDIATE 'ALTER INDEX '||in_owner||'.'||in_index_list(i)||' RENAME '|| ' TO '||in_index_rename_to_list(i);
			END IF;
		END LOOP;		
	END;
	
	PROCEDURE RenameTables(
		in_owner 					IN	all_tables.owner%TYPE,
		in_table_list				IN	t_varchar2_array,
		in_table_rename_to_list		IN	t_varchar2_array
	)
	AS
	BEGIN
		FOR i IN 1 .. in_table_list.COUNT
		LOOP
			IF TableExists(in_owner, in_table_list(i)) THEN
				EXECUTE IMMEDIATE 'ALTER TABLE '||in_owner||'.'||in_table_list(i)||' RENAME '|| ' TO '||in_table_rename_to_list(i);
			END IF;
		END LOOP;		
	END;
BEGIN
	-- rename columns response_submission
	v_table_name := 'RESPONSE_SUBMISSION';
	v_object_list := t_varchar2_array('SUBMISSION_ID', 'SUBMITTED_DTM', 'SUBMITTED_BY_USER_SID');
	v_object_rename_to_list := t_varchar2_array('SNAPSHOT_ID', 'SNAPSHOT_DTM', 'SNAPSHOT_BY_USER_SID');

	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	
	-- rename columns response
	v_table_name := 'RESPONSE';
	v_object_list := t_varchar2_array('LATEST_SUBMISSION_ID');
	v_object_rename_to_list := t_varchar2_array('LATEST_SNAPSHOT_ID');

	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);

	-- rename columns answer
	v_table_name := 'ANSWER';
	v_object_list := t_varchar2_array('SUBMISSION_ID');
	v_object_rename_to_list := t_varchar2_array('SNAPSHOT_ID');

	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	
	-- rename columns submission_file
	v_table_name := 'SUBMISSION_FILE';
	v_object_list := t_varchar2_array('SUBMISSION_ID', 'SUBMISSION_FILE_ID');
	v_object_rename_to_list := t_varchar2_array('SNAPSHOT_ID', 'SNAPSHOT_FILE_ID');

	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);

	-- rename columns answer_file
	v_table_name := 'ANSWER_FILE';
	v_object_list := t_varchar2_array('SUBMISSION_FILE_ID');
	v_object_rename_to_list := t_varchar2_array('SNAPSHOT_FILE_ID');

	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);

	-- rename constraints response_submission
	v_table_name := 'RESPONSE_SUBMISSION';
	v_object_list := t_varchar2_array('FK_RESPONSE_SUB_SURVEY_VERSION', 'FK_SUBMISSION_RESPONSE', 'FK_SUBMISSION_USER', 'PK_SURVEY_RESPONSE_SUBMISSION');
	v_object_rename_to_list := t_varchar2_array('FK_RESPONSE_SNAP_SURVEY_VER', 'FK_SNAPSHOT_RESPONSE', 'FK_SNAPSHOT_USER', 'PK_SURVEY_RESPONSE_SNAPSHOT');

	RenameConstraints(v_owner, v_table_name, v_object_list, v_object_rename_to_list);

	-- rename constraints response
	v_table_name := 'RESPONSE';
	v_object_list := t_varchar2_array('FK_RESPONSE_SUBMISSION');
	v_object_rename_to_list := t_varchar2_array('FK_RESPONSE_SNAPSHOT');

	RenameConstraints(v_owner, v_table_name, v_object_list, v_object_rename_to_list);

	-- rename constraints answer
	v_table_name := 'ANSWER';
	v_object_list := t_varchar2_array('FK_SUBMISSION_ANSWER');
	v_object_rename_to_list := t_varchar2_array('FK_SNAPSHOT_ANSWER');

	RenameConstraints(v_owner, v_table_name, v_object_list, v_object_rename_to_list);

	-- rename constraints submission_file
	v_table_name := 'SUBMISSION_FILE';
	v_object_list := t_varchar2_array('FK_SUBMISSION_FILE_RESPONSE', 'FK_SUB_FILE_CUSTOMER', 'FK_SUB_FILE_UPLOADED_USER', 'PK_SUBMISSION_FILE');
	v_object_rename_to_list := t_varchar2_array('FK_SNAPSHOT_FILE_RESPONSE', 'FK_SNAPSHOT_FILE_CUSTOMER', 'FK_SNAPSHOT_FILE_UPLOADED_USER', 'PK_SNAPSHOT_FILE');

	RenameConstraints(v_owner, v_table_name, v_object_list, v_object_rename_to_list);

	-- rename indexes
	v_object_list := t_varchar2_array('IX_RESPONSE_SUBM_SUBMITTED_BY_', 'IX_RESPONSE_SUB_SURVEY_VERSION', 'IX_RESPONSE_SURVEY', 'UK_ANSWER_SUBMISSION');
	v_object_rename_to_list := t_varchar2_array('IX_RESPONSE_SNAP_SUBMITTED_BY_', 'IX_RESPONSE_SNAP_SURVEY_VER', 'IX_RESPONSE_SNAP_SURVEY', 'UK_ANSWER_SNAPSHOT');

	RenameIndexes(v_owner, v_object_list, v_object_rename_to_list);	

	-- rename tables
	v_object_list := t_varchar2_array('RESPONSE_SUBMISSION', 'SUBMISSION_FILE');
	v_object_rename_to_list := t_varchar2_array('RESPONSE_SNAPSHOT', 'SNAPSHOT_FILE');

	RenameTables(v_owner, v_object_list, v_object_rename_to_list);	
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
--@../surveys/survey_pkg
--@../surveys/integration_pkg

--@../surveys/survey_body
--@../surveys/integration_body

@update_tail
