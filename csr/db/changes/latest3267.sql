-- Please update version.sql too -- this keeps clean builds in sync
define version=3267
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- Conditionally alter table that was changed in a latest script (latest2927_23) but not in create_schema.
DECLARE
	v_null		VARCHAR(255);
BEGIN
	SELECT nullable
	  INTO v_null
	FROM all_tab_columns
	WHERE owner = 'CSR'
	  AND table_name = 'QS_EXPR_NON_COMPL_ACTION'
	  AND column_name = 'ASSIGN_TO_ROLE_SID';
	
	IF v_null = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.qs_expr_non_compl_action MODIFY ASSIGN_TO_ROLE_SID NULL';
	END IF;
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

@update_tail
