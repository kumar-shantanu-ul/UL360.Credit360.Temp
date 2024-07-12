-- Please update version.sql too -- this keeps clean builds in sync
define version=2891
define minor_version=0
define is_combined=1
@update_header

-- *** DDL ***

DECLARE
    column_exists EXCEPTION;
    null_not_nullable EXCEPTION;
    constraint_exists EXCEPTION;
    null_fail EXCEPTION;
	invalid_identifier EXCEPTION;
    PRAGMA exception_init (column_exists , -01430);
    PRAGMA exception_init (null_not_nullable , -01442);
    PRAGMA exception_init (constraint_exists , -02275);
    PRAGMA exception_init (null_fail , -01451);
    PRAGMA exception_init (invalid_identifier , -00904);
BEGIN

	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.PLUGIN ADD R_SCRIPT_PATH VARCHAR2(1024)';
		EXCEPTION WHEN column_exists THEN NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS DROP COLUMN EDIT_COMPANY_USE_POSTCODE_DATA';
		EXCEPTION WHEN invalid_identifier THEN NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.ISSUE_SUPPLIER DROP COLUMN SUPPLIER_SID';
		EXCEPTION WHEN invalid_identifier THEN NULL;
	END;

	FOR r IN (SELECT 1 FROM ALL_TAB_COLUMNS WHERE OWNER='CSRIMP' AND TABLE_NAME='CMS_TAB_COLUMN' AND COLUMN_NAME='OWNER_PERMISSION' AND NULLABLE='N')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CMS_TAB_COLUMN MODIFY OWNER_PERMISSION NULL';
	END LOOP;
	
	FOR r IN (SELECT 1 FROM ALL_TAB_COLUMNS WHERE OWNER='CSRIMP' AND TABLE_NAME='ASPEN2_TRANSLATION_SET_INCL' AND COLUMN_NAME='TO_APPLICATION' AND NULLABLE='N')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.ASPEN2_TRANSLATION_SET_INCL MODIFY TO_APPLICATION NULL';
	END LOOP;
 
END;
/



--Create types


-- Create tables

-- Alter tables
ALTER TABLE csrimp.quick_survey_expr_action
DROP CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK;

ALTER TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION
ADD CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK CHECK (
	(ACTION_TYPE = 'nc' AND QS_EXPR_NON_COMPL_ACTION_ID IS NOT NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'msg' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NOT NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NOT NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'mand_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NOT NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_p' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NOT NULL)
  );
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
GRANT UPDATE ON CSR.ISSUE TO CSRIMP;

-- *** Conditional Packages ***

-- *** Packages ***

@../schema_pkg
@../schema_body
@../csrimp/imp_body
@../../../aspen2/cms/db/tab_body

@update_tail
