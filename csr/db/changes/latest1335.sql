-- Please update version.sql too -- this keeps clean builds in sync
define version=1335
@update_header

delete from cms.sys_schema where oracle_schema='GT';

@update_tail
