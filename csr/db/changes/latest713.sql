-- Please update version.sql too -- this keeps clean builds in sync
define version=713
@update_header

ALTER TABLE csr.LOGISTICS_ERROR_LOG ADD ORACLE_USER VARCHAR2(255) NOT NULL;

@update_tail
