-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=37
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSRIMP.qs_expr_non_compl_action MODIFY ASSIGN_TO_ROLE_SID NULL;

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.chain_dedupe_rule DROP COLUMN IS_FUZZY';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-00904: "IS_FUZZY": invalid identifier
		IF SQLCODE <> -904 THEN
			RAISE;
		END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail
