-- Please update version.sql too -- this keeps clean builds in sync
define version=3284
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_AUDIT_PERMISSIBLE_NCT AS
	OBJECT (
		AUDIT_SID					NUMBER(10),
		NON_COMPLIANCE_TYPE_ID		NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CSR.T_AUDIT_PERMISSIBLE_NCT_TABLE AS
	TABLE OF CSR.T_AUDIT_PERMISSIBLE_NCT;
/

-- Alter tables
ALTER TABLE CSR.NON_COMPLIANCE_TYPE ADD FLOW_CAPABILITY_ID NUMBER(10, 0);

ALTER TABLE CSR.NON_COMPLIANCE_TYPE ADD CONSTRAINT FK_NON_COMP_TYP_CAPAB
	FOREIGN KEY (APP_SID, FLOW_CAPABILITY_ID)
	REFERENCES CSR.CUSTOMER_FLOW_CAPABILITY(APP_SID, FLOW_CAPABILITY_ID)
;

CREATE INDEX csr.ix_non_complianc_flow_capabili ON csr.non_compliance_type (app_sid, flow_capability_id);

ALTER TABLE CSRIMP.NON_COMPLIANCE_TYPE ADD FLOW_CAPABILITY_ID NUMBER(10, 0);

ALTER TABLE CSRIMP.NON_COMPLIANCE_TYPE ADD CONSTRAINT FK_NON_COMP_TYP_CAPAB
	FOREIGN KEY (CSRIMP_SESSION_ID, FLOW_CAPABILITY_ID)
	REFERENCES CSRIMP.CUSTOMER_FLOW_CAPABILITY(CSRIMP_SESSION_ID, FLOW_CAPABILITY_ID)
;
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
@../audit_pkg
@../audit_body
@../schema_body
@../csrimp/imp_body
@../unit_test_pkg
@../unit_test_body
@../chain/chain_body
@../non_compliance_report_body

@update_tail
