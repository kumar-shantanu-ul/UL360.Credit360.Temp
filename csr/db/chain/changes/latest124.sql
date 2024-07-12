define version=124
@update_header

ALTER TABLE chain.FILTER_FIELD DROP COLUMN FILTER_COMPARATOR_ID;
ALTER TABLE chain.FILTER_FIELD DROP COLUMN FILTER_VALUE_TYPE_ID;

ALTER TABLE chain.FILTER_FIELD ADD COMPARATOR VARCHAR2(64);

ALTER TABLE chain.FILTER_VALUE ADD (
	NUM_VALUE          NUMBER(10, 0),
    STR_VALUE          VARCHAR2(255),
    DTM_VALUE          DATE
);

DROP TABLE chain.FILTER_COMPARATOR;
DROP TABLE chain.FILTER_NUM_VALUE;
DROP TABLE chain.FILTER_STR_VALUE;
DROP TABLE chain.FILTER_VALUE_TYPE;

CREATE OR REPLACE VIEW chain.v$filter_value AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value, fv.num_value, fv.dtm_value
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');

@..\chain_pkg
@..\filter_pkg
@..\filter_body


@update_tail
