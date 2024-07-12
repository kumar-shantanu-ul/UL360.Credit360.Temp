-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_PROJECT_INITIATIVE_METRIC(
    INITIATIVE_METRIC_ID    NUMBER(10) NOT NULL,
    POS                     NUMBER(10),
    INPUT_DP                NUMBER(10),
    INFO_TEXT               VARCHAR2(4000)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_INIT_METRIC_FLOW_STATE(
    INITIATIVE_METRIC_ID    NUMBER(10) NOT NULL,
    FLOW_STATE_ID           NUMBER(10) NOT NULL,
    MANDATORY               NUMBER(1),
    VISIBLE                 NUMBER(1)
) ON COMMIT DELETE ROWS;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT app_sid, flow_sid
			  FROM csr.initiative_project
	) LOOP
		BEGIN
		  INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
			   VALUES (r.app_sid, 'initiatives');
		EXCEPTION
		  WHEN OTHERS THEN
			NULL;
		END;
		
		UPDATE csr.flow
		   SET flow_alert_class = 'initiatives'
		 WHERE flow_alert_class IS NULL
		   AND app_sid = r.app_sid
		   AND flow_sid = r.flow_sid;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../initiative_project_pkg
@../initiative_project_body
@../initiative_metric_body

@update_tail
