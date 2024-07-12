-- Please update version.sql too -- this keeps clean builds in sync
define version=3430
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	FOR r IN (
		SELECT owner
		  FROM dba_tab_columns
		 WHERE UPPER(owner) IN ('CSR','CSRIMP')
		   AND UPPER(table_name) = 'INTERNAL_AUDIT'
		   AND UPPER(column_name) = 'AUDITOR_NAME'
		   AND data_length != 256
		)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.internal_audit MODIFY auditor_name VARCHAR2(256)';
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
@../csrimp/imp_body
@../schema_body

@update_tail
