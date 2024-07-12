-- Please update version.sql too -- this keeps clean builds in sync
define version=339
@update_header

ALTER TABLE METER_SOURCE_TYPE ADD (
	ARBITRARY_PERIOD           NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	CHECK (ARBITRARY_PERIOD IN (0,1))
);

BEGIN
	UPDATE meter_source_type
	   SET arbitrary_period = 1
	 WHERE meter_source_type_id = 2;
END;
/

@update_tail
