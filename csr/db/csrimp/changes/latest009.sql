-- Please update version.sql too -- this keeps clean builds in sync
define version=9
@update_header

alter table csrimp.customer add INCL_INACTIVE_REGIONS NUMBER(1) DEFAULT 0;

@../imp_body.sql

@update_tail
