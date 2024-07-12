-- Please update version.sql too -- this keeps clean builds in sync
define version=1187
@update_header

grant insert,select,update,delete on csrimp.delegation_ind_description to web_user;

@update_tail
