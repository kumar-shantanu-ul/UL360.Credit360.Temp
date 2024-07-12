-- Please update version.sql too -- this keeps clean builds in sync
define version=1939
@update_header

ALTER TABLE CSR.TAG ADD (
	EXCLUDE_FROM_DATAVIEW_GROUPING	NUMBER(1)	DEFAULT 0	NOT NULL
);

@../tag_body

@update_tail
