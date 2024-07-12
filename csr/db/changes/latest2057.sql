-- Please update version.sql too -- this keeps clean builds in sync
define version=2057
@update_header

ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS DROP (
	DASHBOARD_TASK_SCHEME_ID,
	DEFAULT_AUTO_APPROVE_USERS
);

ALTER TABLE CSRIMP.CHAIN_COMPANY DROP (
	AUTO_APPROVE_USERS
);

@@../schema_pkg
@@../schema_body

@@../csrimp/imp_pkg
@@../csrimp/imp_body

@update_tail
