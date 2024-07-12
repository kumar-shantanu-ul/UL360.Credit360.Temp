-- Please update version.sql too -- this keeps clean builds in sync
define version=1073
@update_header

grant select,insert,update,delete on csr.deleg_ind_form_expr to csrimp;
grant select,insert,update,delete on csr.form_expr to csrimp;

@..\csrimp\imp_body

@update_tail