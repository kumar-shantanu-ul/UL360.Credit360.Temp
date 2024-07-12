-- Please update version.sql too -- this keeps clean builds in sync
define version=1646
@update_header

grant insert,select,update,delete on cms.imp_ind_expressions to web_user;

@update_tail
