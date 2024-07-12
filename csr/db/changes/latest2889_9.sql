-- Please update version.sql too -- this keeps clean builds in sync
define version=2889
define minor_version=9
@update_header

@latest2889_9_packages

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
CREATE OR REPLACE TYPE T_NORMALISED_VAL_ROW AS 
  OBJECT ( 
	REGION_SID		NUMBER(10),
	START_DTM		DATE,
	END_DTM			DATE,
	VAL_NUMBER		NUMBER(24, 10)
  );
/
CREATE OR REPLACE TYPE T_NORMALISED_VAL_TABLE AS 
  TABLE OF T_NORMALISED_VAL_ROW;
/
BEGIN
	FOR x IN 
		(SELECT distinct c.host, c.app_sid 
		   FROM csr.region_metric_val  v
		   JOIN csr.ind i ON i.ind_sid=v.ind_sid AND i.app_sid = v.app_sid
		   JOIN csr.measure m ON m.measure_sid = i.measure_sid AND i.app_sid = m.app_sid
		   JOIN csr.customer c ON v.app_sid = c.app_sid
		  WHERE v.val = 0 AND m.custom_field = '$')
	LOOP
		security.user_pkg.logonAdmin(x.host);
		FOR y IN 
			(SELECT * 
			   FROM csr.region_metric_val  v
			   JOIN csr.ind i ON i.ind_sid=v.ind_sid AND i.app_sid = v.app_sid
			   JOIN csr.measure m ON m.measure_sid = i.measure_sid AND i.app_sid = m.app_sid
			  WHERE v.val = 0 AND m.custom_field = '$' AND v.app_sid = x.app_sid)
		LOOP
			csr.temp_region_metric_pkg.DeleteMetricValue(y.region_metric_val_id);
		END LOOP;
	END LOOP;
	security.user_pkg.logonAdmin();
END;
/

DROP TYPE T_NORMALISED_VAL_TABLE;
DROP TYPE T_NORMALISED_VAL_ROW;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
