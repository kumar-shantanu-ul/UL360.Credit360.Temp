-- Please update version.sql too -- this keeps clean builds in sync
define version=2273
@update_header

ALTER TABLE CSR.INITIATIVE_METRIC_STATE_IND ADD (
	NET_PERIOD		NUMBER(10, 0)		NULL
);

@../initiative_aggr_pkg
@../initiative_aggr_body

@update_tail
