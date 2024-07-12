-- Please update version.sql too -- this keeps clean builds in sync
define version=2929
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.region_metric_val DROP CONSTRAINT FK_REGION_METRIC_VAL_REGION_M;
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_REGION_M
	FOREIGN KEY (app_sid, ind_sid, measure_sid)
	REFERENCES csr.region_metric(app_sid, ind_sid, measure_sid)
    DEFERRABLE INITIALLY DEFERRED
;
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
@../indicator_body

@update_tail
