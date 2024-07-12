-- Please update version.sql too -- this keeps clean builds in sync
define version=1651
@update_header

ALTER TABLE CSR.ROUTE_STEP MODIFY WORK_DAYS_OFFSET NUMBER(10);

@update_tail
