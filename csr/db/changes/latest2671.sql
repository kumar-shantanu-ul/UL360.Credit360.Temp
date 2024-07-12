--Please update version.sql too -- this keeps clean builds in sync
define version=2671
@update_header

alter table csrimp.aspen2_application add default_script varchar2(512);

@../csrimp/imp_body
@../schema_body

@update_tail
