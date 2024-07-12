-- Please update version.sql too -- this keeps clean builds in sync
define version=271
@update_header

ALTER TABLE CUSTOMER ADD (
	HELPER_ASSEMBLY          VARCHAR2(255)
);

@..\csr_app_body

@update_tail