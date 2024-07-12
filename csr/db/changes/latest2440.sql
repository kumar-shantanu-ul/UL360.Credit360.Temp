-- Please update version.sql too -- this keeps clean builds in sync
define version=2440
@update_header

ALTER TABLE CSR.FUND MODIFY ( COMPANY_SID NOT NULL );

@update_tail
