-- Please update version.sql too -- this keeps clean builds in sync
define version=3288
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR r IN (
		SELECT issue_id, parent_id
		  FROM csr.issue
		 WHERE issue_type_id = 1 --csr.csr_data_pkg.ISSUE_DATA_ENTRY
		   AND deleted = 0
		   AND parent_id IS NOT NULL
		   AND issue_sheet_value_id IS NULL
	) LOOP
		UPDATE csr.issue
		   SET issue_sheet_value_id = (
				SELECT issue_sheet_value_id
				  FROM csr.issue
				 WHERE issue_id = r.parent_id
			)
		 WHERE issue_id = r.issue_id;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../issue_body
@../tests/issue_test_pkg
@../tests/issue_test_body

@update_tail
