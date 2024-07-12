define version=2237
@update_header

ALTER TABLE CSR.internal_audit_type ADD (
	VALIDITY_MONTHS           NUMBER(10)
);

@../audit_pkg
@../audit_body
@../quick_survey_pkg
@../quick_survey_body

@update_tail
