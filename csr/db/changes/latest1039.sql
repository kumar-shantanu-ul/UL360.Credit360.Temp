-- Please update version.sql too -- this keeps clean builds in sync
define version=1039
@update_header

ALTER TABLE CSR.SNAPSHOT ADD (
	CHART_TEMPLATE_ROOT_SID    NUMBER(10, 0)
);


@..\snapshot_body


@update_tail
