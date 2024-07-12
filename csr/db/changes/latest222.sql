-- Please update version.sql too -- this keeps clean builds in sync
define version=222
@update_header

alter table audit_log add (remote_addr varchar2(40) default SYS_CONTEXT('SECURITY', 'REMOTE_ADDR'));

@update_tail