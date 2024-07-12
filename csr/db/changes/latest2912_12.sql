-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

	DELETE FROM chain.filter_value fv
	 WHERE EXISTS (
		SELECT app_sid, filter_value_id 
		  FROM (
				SELECT app_sid, filter_value_id, 
					ROW_NUMBER() OVER 
					(PARTITION BY app_sid, filter_field_id, num_value, str_value, start_dtm_value, end_dtm_value, region_sid, user_sid, min_num_val, 
						max_num_val, compound_filter_id_value, saved_filter_sid_value, period_set_id, period_interval_id, start_period_id, filter_type, null_filter 
					ORDER BY app_sid, filter_value_id) rn
				  FROM chain.filter_value
			)
		 WHERE rn > 1 AND app_sid = fv.app_sid AND filter_value_id = fv.filter_value_id);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
