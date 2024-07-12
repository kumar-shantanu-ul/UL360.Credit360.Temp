-- Please update version.sql too -- this keeps clean builds in sync
define version=1935
@update_header

alter table csr.TEAMROOM_ISSUE modify app_sid default SYS_CONTEXT('SECURITY','APP');

@..\csr_data_pkg
@..\teamroom_pkg
@..\teamroom_body

@update_tail
