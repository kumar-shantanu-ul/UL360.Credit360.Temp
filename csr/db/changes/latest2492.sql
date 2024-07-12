-- Please update version.sql too -- this keeps clean builds in sync
define version=2492
@update_header

BEGIN
	INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 21, 'Survey change');
END;
/

@../csr_data_pkg
@../csr_data_body
@../quick_survey_pkg
@../quick_survey_body

@update_tail
