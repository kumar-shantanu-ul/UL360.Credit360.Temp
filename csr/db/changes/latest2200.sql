-- Please update version.sql too -- this keeps clean builds in sync
define version=2200
@update_header

ALTER TABLE CSRIMP.METER_SOURCE_TYPE ADD (
	REGION_DATE_CLIPPING	NUMBER(1)	DEFAULT 0	NOT NULL,
	IS_CALCULATED_SUB_METER	NUMBER(1)	DEFAULT 0	NOT NULL,
	REQ_APPROVAL			NUMBER(1)	DEFAULT 0	NOT NULL,
	FLOW_SID				NUMBER(10),
	DESCENDING				NUMBER(1)	DEFAULT 0	NOT NULL,
	ALLOW_RESET				NUMBER(1)	DEFAULT 0	NOT NULL,
	CHECK (REGION_DATE_CLIPPING IN (0,1)),
	CHECK (IS_CALCULATED_SUB_METER IN(0,1)),
	CHECK (REQ_APPROVAL IN(0,1)),
	CHECK (DESCENDING IN(0,1)),
	CHECK (ALLOW_RESET IN(0,1))
);

ALTER TABLE CSRIMP.METER_READING ADD (
	REQ_APPROVAL			NUMBER(1)	DEFAULT 0	NOT NULL,
	ACTIVE					NUMBER(1)	DEFAULT 1	NOT NULL,
	IS_DELETE				NUMBER(1)	DEFAULT 0	NOT NULL,
	REPLACES_READING_ID		NUMBER(10),
	APPROVED_DTM			DATE,
	APPROVED_BY_SID			NUMBER(10),
	FLOW_ITEM_ID			NUMBER(10),
	BASELINE_VAL			NUMBER(24, 10),
	CHECK (REQ_APPROVAL IN(0,1)),
	CHECK (ACTIVE IN(0,1)),
	CHECK (IS_DELETE IN(0,1))
);

@../schema_pkg
@../schema_body
@../csrimp/imp_body

@../csr_app_body
@../region_body
@../meter_body
@../energy_star_body
	
@update_tail
