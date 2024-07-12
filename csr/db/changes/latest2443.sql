-- Please update version.sql too -- this keeps clean builds in sync
define version=2443
@update_header

alter table csrimp.scenario add data_source_sp varchar2(100);

@..\schema_body
@..\csrimp\imp_body

@update_tail