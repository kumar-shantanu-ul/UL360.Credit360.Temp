-- Please update version.sql too -- this keeps clean builds in sync
define version=2301
@update_header


ALTER TABLE CSR.LIVE_DATA_DURATION ADD (
    IS_MINUTES               NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (IS_MINUTES = 0 OR (IS_MINUTES  = 1 AND IS_HOURS = 0 AND IS_WEEKS = 0 AND IS_MONTHS = 0))
);

@../meter_monitor_body

@update_tail
