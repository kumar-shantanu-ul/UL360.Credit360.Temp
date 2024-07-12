-- Please update version.sql too -- this keeps clean builds in sync
define version=1003
@update_header

ALTER TABLE csr.dataview_ind_member
	ADD DATAVIEW_IND_ID	NUMBER(10, 0)	NULL;

@update_tail
