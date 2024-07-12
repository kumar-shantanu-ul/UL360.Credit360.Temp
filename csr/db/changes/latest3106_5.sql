-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CHK_COMPANY_REQUEST_ACTION' AND owner = 'CHAIN' AND table_name = 'COMPANY_REQUEST_ACTION';

	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.company_request_action DROP CONSTRAINT chk_company_request_action';
	END IF;
END;
/

ALTER TABLE chain.company_request_action ADD CONSTRAINT chk_company_request_action
CHECK (action IN (1, 2, 3));
	 
	 
DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'CHK_ACTION_MATCHED' AND owner = 'CHAIN' AND table_name = 'COMPANY_REQUEST_ACTION';

	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.company_request_action DROP CONSTRAINT chk_action_matched';
	END IF;
END;
/
	 
ALTER TABLE chain.company_request_action ADD CONSTRAINT chk_action_matched
CHECK ((action = 3 AND matched_company_sid IS NOT NULL) OR matched_company_sid IS NULL);

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
@..\supplier_pkg
@..\supplier_body
@..\chain\company_dedupe_body

@update_tail
