-- Please update version.sql too -- this keeps clean builds in sync
define version=718
@update_header

ALTER TABLE csr.ALL_METER ADD (
	EXPORT_LIVE_DATA_AFTER_DTM       DATE
);

ALTER TABLE csr.METER_RAW_DATA_SOURCE ADD (
	EXPORT_SYSTEM_VALUES    NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CHECK (EXPORT_SYSTEM_VALUES IN(0,1))
);

@update_tail
