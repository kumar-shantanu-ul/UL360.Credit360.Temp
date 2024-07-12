-- Please update version.sql too -- this keeps clean builds in sync
define version=2033
@update_header

ALTER TABLE CSR.FUND MODIFY ( COMPANY_SID NULL );

@update_tail
