-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=45
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.customer add calc_start_dtm date default date '1990-01-01' not null;
alter table csr.customer add calc_end_dtm date default date '2021-01-01' not null;
alter table csrimp.customer add calc_start_dtm date not null;
alter table csrimp.customer add calc_end_dtm date not null;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../calc_pkg
@../calc_body
@../aggregate_ind_body
@../approval_dashboard_body
@../audit_body
@../csr_app_body
@../customer_body
@../flow_report_body
@../like_for_like_body
@../property_body
@../quick_survey_body
@../region_body
@../region_metric_body
@../schema_body
@../stored_calc_datasource_body
@../supplier_body
@../util_script_body
@../csrimp/imp_body

@update_tail
