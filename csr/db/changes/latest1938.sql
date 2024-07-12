-- Please update version.sql too -- this keeps clean builds in sync
define version=1938
@update_header

ALTER TABLE CSR.TPL_REPORT_TAG_DATAVIEW ADD (
	HIDE_IF_EMPTY	NUMBER(1)	DEFAULT 0	NOT NULL
);

@../templated_report_pkg
@../templated_report_body

@update_tail
