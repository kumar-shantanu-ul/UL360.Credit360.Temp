-- Please update version.sql too -- this keeps clean builds in sync
define version=2889
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.filter_value ADD (
	filter_type NUMBER(10) NULL, -- Should be not-null, but can't guarantee existing data is consistent
	null_filter NUMBER(10) DEFAULT 0 NOT NULL, -- chain.filter_pkg.NULL_FILTER_ALL
    CONSTRAINT ck_null_filter_valid CHECK (
		null_filter IN (
			0, -- chain.filter_pkg.NULL_FILTER_ALL
			1, -- chain.filter_pkg.NULL_FILTER_REQUIRE_NULL
			2  -- chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
		)
	),
    CONSTRAINT ck_filter_type_valid CHECK (
		filter_type IS NULL OR filter_type IN (
			1, -- chain.filter_pkg.FILTER_VALUE_TYPE_NUMBER
			2, -- chain.filter_pkg.FILTER_VALUE_TYPE_NUMBER_RANGE
			3, -- chain.filter_pkg.FILTER_VALUE_TYPE_STRING
			4, -- chain.filter_pkg.FILTER_VALUE_TYPE_USER
			5, -- chain.filter_pkg.FILTER_VALUE_TYPE_REGION
			6, -- chain.filter_pkg.FILTER_VALUE_TYPE_DATE_RANGE
			7, -- chain.filter_pkg.FILTER_VALUE_TYPE_SAVED
			8  -- chain.filter_pkg.FILTER_VALUE_TYPE_COMPOUND
		)
	) 
);

ALTER TABLE csrimp.chain_filter_value ADD (
	filter_type NUMBER(10) NULL, 
	null_filter NUMBER(10) NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- /cvs/csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   fv.compound_filter_id_value, fv.saved_filter_sid_value, fv.pos,
		   NVL(NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END), fv.str_value) description, ff.group_by_index,
		   f.compound_filter_id, ff.show_all, ff.period_set_id, ff.period_interval_id, fv.start_period_id, 
		   fv.filter_type, fv.null_filter
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

-- *** Data changes ***
-- RLS

-- Data
UPDATE chain.filter_value 
   SET filter_type = 1 -- chain.FILTER_VALUE_TYPE_NUMBER
 WHERE num_value IS NOT NULL
   AND num_value >= 0
   AND max_num_val IS NULL
   AND min_num_val IS NULL;

UPDATE chain.filter_value 
   SET filter_type = 2 -- chain.FILTER_VALUE_TYPE_NUMBER_RANGE
 WHERE num_value IS NOT NULL
   AND num_value >= 0 
   AND max_num_val IS NOT NULL OR min_num_val IS NOT NULL;

UPDATE chain.filter_value 
   SET filter_type = 3 -- chain.FILTER_VALUE_TYPE_STRING
 WHERE str_value IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 4 -- chain.FILTER_VALUE_TYPE_USER
 WHERE user_sid IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 5 -- chain.FILTER_VALUE_TYPE_REGION
 WHERE region_sid IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 6 -- chain.FILTER_VALUE_TYPE_DATE_RANGE
 WHERE (num_value IS NOT NULL AND num_value < 0)
	OR start_period_id IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 7 -- chain.FILTER_VALUE_TYPE_SAVED
 WHERE saved_filter_sid_value IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 8 -- chain.FILTER_VALUE_TYPE_COMPOUND
 WHERE compound_filter_id_value IS NOT NULL;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../chain/filter_body

@../chain/company_filter_body

@../../../aspen2/cms/db/filter_pkg
@../../../aspen2/cms/db/filter_body

@update_tail
