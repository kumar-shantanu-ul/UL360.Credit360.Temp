-- Please update version.sql too -- this keeps clean builds in sync
define version=414
@update_header


ALTER TABLE CUSTOMER ADD (
	CREATE_SHEETS_AT_PERIOD_END	NUMBER(1) DEFAULT 1 NOT NULL
);

@..\csr_data_pkg
@..\csr_data_body
@..\delegation_body

@update_tail
