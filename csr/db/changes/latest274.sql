-- Please update version.sql too -- this keeps clean builds in sync
define version=274
@update_header

alter table delegation_ind modify description varchar2(1023);
		
@update_tail
