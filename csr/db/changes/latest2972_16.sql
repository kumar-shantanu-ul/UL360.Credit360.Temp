-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=16
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
BEGIN
	security.user_pkg.logonadmin;

	UPDATE chain.filter_value fv
	   SET end_dtm_value = end_dtm_value + 1
	 WHERE num_value = -1
	   AND end_dtm_value IS NOT NULL
	   AND EXISTS(SELECT * 
				    FROM chain.filter_field ff
				   WHERE fv.filter_field_id = ff.filter_field_id
					 AND ff.show_all = 0);
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg

@../chain/filter_body
@../audit_report_body
@../initiative_report_body
@../issue_report_body
@../meter_report_body
@../non_compliance_report_body
@../user_report_body
@../property_report_body
@../../../aspen2/cms/db/filter_body
@../compliance_body
@../comp_regulation_report_body
@../meter_list_body
@../region_metric_body

@update_tail
