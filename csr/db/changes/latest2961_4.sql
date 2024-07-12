-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

DECLARE
	PROCEDURE DropSequence(
		in_sequence_name	VARCHAR2
	)
	AS
	BEGIN
		EXECUTE IMMEDIATE 'DROP SEQUENCE CSR.'||in_sequence_name;
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE <> -2289 THEN
				-- -2289 == sequence does not exist
				RAISE;
			END IF;
	END;
BEGIN
	DropSequence('AUT_EXP_INS_FILE_ID_SEQ');
	DropSequence('AUT_EXPORT_IND_CONF_ID_SEQ');
	DropSequence('CHANGE_STEP_ID_SEQ');
	DropSequence('ERROR_LOG_ID_SEQ');
	DropSequence('FACTOR_SET_ID_SEQ');
	DropSequence('FUND_MGR_CONTACT_ID_SEQ');
	DropSequence('IND_ASSERTION_ID_SEQ');
	DropSequence('ISSUE_URL_ID_SEQ');
	DropSequence('MGMT_COMPANY_ID');
	DropSequence('PENDING_VAL_COMMENT_ID_SEQ');
	DropSequence('REASON_ID');
	DropSequence('SCHEDULE_ID_SEQ');
	DropSequence('STD_MEASURE_ID_SEQ');
	DropSequence('TARGET_ID_SEQ');
	DropSequence('UTILITY_INVOICE_COMMENT_ID_SEQ');
END;
/

-- Alter tables

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

@update_tail
