-- Please update version.sql too -- this keeps clean builds in sync
define version=1577
@update_header

alter table csrimp.customer add INCL_INACTIVE_REGIONS NUMBER(1) DEFAULT 0;

@../csrimp/imp_body

@update_tail
