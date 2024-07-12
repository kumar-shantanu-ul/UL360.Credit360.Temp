-- Please update version.sql too -- this keeps clean builds in sync
define version=1210
@update_header

ALTER TABLE CSR.DELEGATION_IND DROP CONSTRAINT CK_DELEG_IND_VISIBLE;

ALTER TABLE CSR.DELEGATION_IND ADD CONSTRAINT CK_DELEG_IND_VISIBLE CHECK (
VISIBILITY IN ('SHOW','READONLY','HIDE','VALIDATE')
);

@../delegation_pkg
@../delegation_body
	
@update_tail