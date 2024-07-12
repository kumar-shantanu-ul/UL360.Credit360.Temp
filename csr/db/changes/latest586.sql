-- Please update version.sql too -- this keeps clean builds in sync
define version=586
@update_header

alter table delegation modify app_sid default SYS_CONTEXT('SECURITY', 'APP');

@update_tail
