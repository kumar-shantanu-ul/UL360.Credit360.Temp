-- Please update version.sql too -- this keeps clean builds in sync
define version=1438
@update_header

ALTER TABLE CHAIN.REFERENCE_ID_LABEL ADD  COMPANY_TYPE_ID      NUMBER(10, 0);

ALTER TABLE CHAIN.REFERENCE_ID_LABEL ADD CONSTRAINT FK_REF_ID_LABEL_COMP_TYP 
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CSR.QS_CAMPAIGN ADD(
	SKIP_OVERLAPPING_REGIONS     NUMBER(1, 0)     DEFAULT 0 NOT NULL
)
;

ALTER TABLE CSRIMP.QS_CAMPAIGN ADD(
	SKIP_OVERLAPPING_REGIONS     NUMBER(1, 0)     NOT NULL
)
;

DROP TABLE CSR.TEMP_DATES;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_DATES (
	column_value 			DATE,
	eff_date				DATE,
	CONSTRAINT PK_TEMP_DATES PRIMARY KEY (column_value)
) ON COMMIT DELETE ROWS;

grant execute on csr.role_pkg to chain;

grant select, update, references on csr.role to chain;

@..\campaign_pkg
@..\chain\chain_pkg
@..\chain\helper_pkg

@..\audit_body
@..\campaign_body
@..\chain\company_body
@..\chain\company_user_body
@..\chain\helper_body
@..\chain\setup_body
@..\csrimp\imp_body
@..\schema_body

@update_tail
