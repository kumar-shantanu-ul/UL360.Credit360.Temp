-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- backup the data that's gonna be removed from imp_val and region_metric_val
-- first make sure we aren't logged into an app_sid
EXEC security.user_pkg.LogonAdmin;

CREATE TABLE csr.FB87487_region_metric_val AS 
SELECT *
  FROM (
	SELECT app_sid, region_metric_val_id, region_sid, ind_sid, effective_dtm, entered_by_sid, entered_dtm, val, note, 
	       FIRST_VALUE(region_metric_val_id) OVER (
					PARTITION BY app_sid, region_sid, ind_sid, TRUNC(effective_dtm, 'DD') 
					    ORDER BY entered_dtm DESC, region_metric_val_id DESC
			) keep_region_metric_val_id
	  FROM csr.region_metric_val
  ) 
 WHERE region_metric_val_id != keep_region_metric_val_id;
 
-- stick a pk on it to speed up queries below
ALTER TABLE csr.FB87487_region_metric_val ADD CONSTRAINT pk_FB87487_region_metric_val PRIMARY KEY (app_sid, region_metric_val_id);

CREATE TABLE csr.FB87487_imp_val
AS
SELECT * 
  FROM csr.imp_val
 WHERE set_region_metric_val_id IS NOT NULL
  AND (app_sid, set_region_metric_val_id) IN (
		SELECT app_sid, region_metric_val_id
		  FROM csr.FB87487_region_metric_val
 );

-- remove duplicate region_metric_val records
-- this removes/changes tens of thousands of records, please review it thoroughly :)
DECLARE
BEGIN
	UPDATE csr.imp_val
	   SET set_region_metric_val_id = NULL
	 WHERE (app_sid, imp_val_id) IN (
		SELECT app_sid, imp_val_id
		  FROM csr.FB87487_imp_val
	);

	DELETE FROM csr.region_metric_val rmv
	 WHERE (app_sid, region_metric_val_id) IN (
		SELECT app_sid, region_metric_val_id
		  FROM csr.FB87487_region_metric_val
	);

	UPDATE csr.region_metric_val
	   SET effective_dtm = TRUNC(effective_dtm, 'DD')
	 WHERE effective_dtm != TRUNC(effective_dtm, 'DD');
END;
/

-- add constraints that make sure that we won't be affected by this bug again
ALTER TABLE csr.region_metric_val ADD CONSTRAINT CK_REGION_METRIC_VAL_EFF_DTM CHECK (effective_dtm = TRUNC(effective_dtm, 'DD'));
ALTER TABLE csrimp.region_metric_val ADD CONSTRAINT CK_REGION_METRIC_VAL_EFF_DTM CHECK (effective_dtm = TRUNC(effective_dtm, 'DD'));

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

@update_tail
