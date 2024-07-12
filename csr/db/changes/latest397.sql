-- Please update version.sql too -- this keeps clean builds in sync
define version=397
@update_header

ALTER TABLE ALL_METER ADD ( 
	CRC_METER		NUMBER(1,0)		DEFAULT 0	NOT NULL,
	CHECK (CRC_METER IN (0,1))
);

ALTER TABLE UTILITY_INVOICE ADD (
	CONSUMPTION		NUMBER(10,0)
);

@../create_views
 
@update_tail
