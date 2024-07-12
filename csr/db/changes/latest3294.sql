-- Please update version.sql too -- this keeps clean builds in sync
define version=3294
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_count			NUMBER;
BEGIN
	FOR i IN (
		SELECT *
		  FROM all_indexes
		 WHERE UPPER(owner) = 'CSR'
		   AND UPPER(index_name) IN ('IDX_VAL_CHANGE_USER_DATE', 'IDX_VAL_CHANGE_SOURCE_TYPE')
	) LOOP
		EXECUTE IMMEDIATE 'DROP INDEX csr.'||i.index_name;
	END LOOP;

	FOR f IN (
		SELECT *
		  FROM all_constraints
		 WHERE UPPER(owner) = 'CSR'
		   AND UPPER(constraint_name) IN ('REFSOURCE_TYPE206','REFCSR_USER1045')
		   AND constraint_type = 'R'
		   AND status = 'ENABLED'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.'||f.table_name||' DISABLE CONSTRAINT '||f.constraint_name;
	END LOOP;

	FOR r IN (
		SELECT *
		  FROM all_tab_columns
		 WHERE UPPER(owner) IN ('CSR','CSRIMP')
		   AND UPPER(table_name) = 'VAL_CHANGE'
		   AND UPPER(column_name) = 'VAL_CHANGE_ID'
		   AND data_precision = 10
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.val_change MODIFY val_change_id NUMBER(12)';
	END LOOP;
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

@update_tail
