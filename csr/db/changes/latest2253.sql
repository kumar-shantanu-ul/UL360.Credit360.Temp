-- Please update version.sql too -- this keeps clean builds in sync
define version=2253
@update_header

DROP INDEX CSR.UK_METER_ORPHAN_DATA;
CREATE UNIQUE INDEX CSR.UK_METER_ORPHAN_DATA ON CSR.METER_ORPHAN_DATA(APP_SID, SERIAL_ID, START_DTM, UOM);
    	
@update_tail
