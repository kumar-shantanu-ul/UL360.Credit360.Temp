-- Please update version.sql too -- this keeps clean builds in sync
define version=668
@update_header

ALTER TABLE csr.METER_LIVE_DATA ADD (
	TZ_OFFSET                NUMBER(4, 2)      NULL
)
;

ALTER TABLE csr.METER_ORPHAN_DATA ADD (
	TZ_OFFSET                NUMBER(4, 2)      NULL
)
;

BEGIN
	UPDATE csr.meter_orphan_data SET tz_offset = 0;
	UPDATE csr.meter_live_data SET tz_offset = 0;
	COMMIT;
END;
/

ALTER TABLE csr.METER_LIVE_DATA MODIFY (
	TZ_OFFSET                NUMBER(4, 2)      NOT NULL
)
;

ALTER TABLE csr.METER_ORPHAN_DATA MODIFY (
	TZ_OFFSET                NUMBER(4, 2)      NOT NULL
)
;

@../meter_monitor_pkg
@../meter_monitor_body

@update_tail
