-- Please update version.sql too -- this keeps clean builds in sync
define version=1147
@update_header

alter table csrimp.ind drop column description;

grant select,references on aspen2.translation_set to csr with grant option;
grant select on csr.v$customer_lang to csrimp;

@../csrimp/imp_body

@update_tail

