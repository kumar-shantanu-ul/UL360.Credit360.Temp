-- Please update version.sql too -- this keeps clean builds in sync
define version=1892
@update_header

ALTER TABLE CSR.METER_SOURCE_TYPE ADD(
	REGION_DATE_CLIPPING       NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	CHECK (REGION_DATE_CLIPPING IN(0,1))
);
 
@update_tail