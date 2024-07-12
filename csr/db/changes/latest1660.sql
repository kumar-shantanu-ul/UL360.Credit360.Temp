-- Please update version.sql too -- this keeps clean builds in sync
define version=1660
@update_header

ALTER TABLE csr.meter_list_cache
ADD (
    first_reading_dtm	DATE,
	reading_count		NUMBER(24, 10)
);

@../meter_body
@../property_body

@update_tail


