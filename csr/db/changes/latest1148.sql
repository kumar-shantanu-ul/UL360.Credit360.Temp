-- Please update version.sql too -- this keeps clean builds in sync
define version=1148
@update_header

grant insert,select,update,delete on csrimp.deleg_plan_deleg_region_deleg to web_user;
revoke select on csr.v$customer_lang from csrimp;
revoke select,references on aspen2.translation_set from csr cascade constraints;
grant select,references on aspen2.translation_set to csr;

@../csrimp/imp_body

@update_tail

