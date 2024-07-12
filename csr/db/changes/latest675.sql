-- Please update version.sql too -- this keeps clean builds in sync
define version=675
@update_header

ALTER TABLE csr.METER_ORPHAN_DATA ADD (
	UOM		VARCHAR2(256)
);


BEGIN
	-- *ALL* data we have received so far has the UOM 'KWH'
	UPDATE csr.meter_orphan_data SET uom = 'KWH';
	COMMIT;
END;
/

ALTER TABLE csr.METER_ORPHAN_DATA MODIFY (
	UOM		VARCHAR2(256)	NOT NULL
);


@../measure_pkg
@../meter_monitor_pkg

@../measure_body
@../meter_monitor_body

@update_tail
