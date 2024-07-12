-- Please update version.sql too -- this keeps clean builds in sync
define version=1152
@update_header

ALTER TABLE CSR.SNAPSHOT ADD (
	IS_SUPPLIER                NUMBER(1, 0)      DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_SNPSHT_IS_SUP_0_OR_1 CHECK (IS_SUPPLIER IN (0,1))
);

@..\snapshot_pkg
@..\snapshot_body

@..\csr_data_body
@..\quick_survey_body
@..\tag_body
@..\region_body
@..\chain\setup_body
@..\chain\company_body



@update_tail
