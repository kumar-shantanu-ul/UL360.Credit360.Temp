-- Please update version.sql too -- this keeps clean builds in sync
define version=192
@update_header

ALTER TABLE CUSTOMER ADD (CASCADE_REJECT NUMBER(1) DEFAULT 0 NOT NULL);

-- this is how it used to work, but in future we'll just go one step
UPDATE CUSTOMER SET CASCADE_REJECT = 1;

@..\csr_data_pkg
@..\csr_data_body
@..\sheet_body

@update_tail
