-- Please update version.sql too -- this keeps clean builds in sync
define version=3238
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
/*
 * Index was created directly on Saas database. Ensure that
 * it exists ion all environments.
 */
DECLARE
	v_exists	NUMBER := 0;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'IX_INTAPI_COMPAN_GROUP_SID_ID';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'CREATE INDEX csr.ix_intapi_compan_group_sid_id ON csr.intapi_company_user_group (group_sid_id)';
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

@update_tail
