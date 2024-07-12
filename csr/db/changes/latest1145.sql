-- Please update version.sql too -- this keeps clean builds in sync
define version=1145
@update_header

grant insert,select,update,delete on csrimp.ind_description to web_user;
grant insert,select,update,delete on csrimp.dataview_ind_description to web_user;

@update_tail
