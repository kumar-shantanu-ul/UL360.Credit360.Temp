-- Please update version.sql too -- this keeps clean builds in sync
define version=3211
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.filter_field ADD (row_or_col NUMBER(1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n, ff.column_sid, ff.period_set_id,
		   ff.period_interval_id, ff.show_other, ff.comparator, ff.row_or_col
	  FROM chain.filter f
	  JOIN chain.filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;

CREATE OR REPLACE VIEW chain.v$filter_value AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		fv.compound_filter_id_value, fv.saved_filter_sid_value, fv.pos,
		COALESCE(
			fv.description,
			CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' END,
			r.description,
			cu.full_name,
			cr.name,
			fv.str_value
		) description,
		ff.group_by_index,
		f.compound_filter_id, ff.show_all, ff.period_set_id, ff.period_interval_id, fv.start_period_id, 
		fv.filter_type, fv.null_filter, fv.colour, ff.comparator, ff.row_or_col
	  FROM chain.filter f
	  JOIN chain.filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN chain.filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg

@../chain/filter_body
@../chain/company_filter_body

@update_tail
