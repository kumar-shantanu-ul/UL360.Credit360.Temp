-- Please update version.sql too -- this keeps clean builds in sync
define version=2435
@update_header

ALTER TABLE csrimp.chain_filter_field ADD (
	GROUP_BY_INDEX     NUMBER(1),
	SHOW_ALL           NUMBER(1),
	CONSTRAINT CHK_FLTR_FLD_SHO_ALL_0_1 CHECK (SHOW_ALL IN (0,1))
);

ALTER TABLE csrimp.score_type ADD (
	FORMAT_MASK			VARCHAR(20) --DEFAULT ('#,##0.0%') NOT NULL
);

UPDATE csrimp.score_type SET FORMAT_MASK = '#,##0.0%';

ALTER TABLE csrimp.score_type MODIFY FORMAT_MASK NOT NULL;

ALTER TABLE csrimp.qs_campaign ADD (
	filter_xml					CLOB,
	response_column_sid			NUMBER(10),
	tag_lookup_key_column_sid	NUMBER(10),
	is_system_generated			NUMBER(10), -- DEFAULT 0 NOT NULL,
	customer_alert_type_id		NUMBER(10)
);

UPDATE csrimp.qs_campaign SET is_system_generated = 0;

ALTER TABLE csrimp.qs_campaign MODIFY is_system_generated NOT NULL;

@..\schema_body
@..\csrimp\imp_body

@update_tail
