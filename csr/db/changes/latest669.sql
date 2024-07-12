-- Please update version.sql too -- this keeps clean builds in sync
define version=669
@update_header

CREATE INDEX csr.IDX_METER_LIVE_RAW ON csr.METER_LIVE_DATA(APP_SID, METER_RAW_DATA_ID);

@update_tail
