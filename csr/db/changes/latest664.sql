-- Please update version.sql too -- this keeps clean builds in sync
define version=664
@update_header

ALTER TABLE csr.meter_raw_data ADD (
	ENCODING_NAME	VARCHAR2(256)	NULL
);

BEGIN
	UPDATE csr.meter_raw_data
	   SET encoding_name = 'utf-8';
	COMMIT;
END;
/

ALTER TABLE csr.meter_raw_data MODIFY (
	ENCODING_NAME	VARCHAR(256)	NOT NULL
);

@../meter_monitor_pkg
@../meter_monitor_body

@update_tail
