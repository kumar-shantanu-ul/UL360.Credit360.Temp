-- Please update version.sql too -- this keeps clean builds in sync
define version=2153
@update_header

ALTER TABLE csr.teamroom_type ADD (helper_pkg VARCHAR2(255));

@update_tail
