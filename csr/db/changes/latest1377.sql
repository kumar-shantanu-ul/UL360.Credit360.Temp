-- Please update version.sql too -- this keeps clean builds in sync
define version=1377
@update_header

ALTER TABLE CSR.METER_ORPHAN_DATA MODIFY (
	UOM		VARCHAR2(256)	NULL
);

@../meter_monitor_pkg
@../meter_monitor_body
@../actions/importer_pkg
@../actions/importer_body

@update_tail
