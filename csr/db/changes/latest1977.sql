-- Please update version.sql too -- this keeps clean builds in sync
define version=1977
@update_header

ALTER TABLE CSR.TEAMROOM_EVENT ADD (LOCATION VARCHAR2(1000));

@update_tail
