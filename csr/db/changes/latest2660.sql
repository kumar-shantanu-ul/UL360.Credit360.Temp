--Please update version.sql too -- this keeps clean builds in sync
define version=2660
@update_header

alter table aspen2.application add default_script varchar2(512);

@../../../aspen2/db/aspenapp_body

@update_tail
