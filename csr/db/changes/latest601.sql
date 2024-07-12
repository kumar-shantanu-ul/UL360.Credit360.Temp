-- Please update version.sql too -- this keeps clean builds in sync
define version=601
@update_header

alter table csr.delegation_ind drop constraint CK_DELEG_IND_VISIBLE ;

alter table csr.delegation_ind add CONSTRAINT CK_DELEG_IND_VISIBLE CHECK (VISIBILITY IN ('SHOW','READONLY','HIDE'));

@update_tail
