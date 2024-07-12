-- Please update version.sql too -- this keeps clean builds in sync
define version=2920
define minor_version=7
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
DECLARE
	v_menu_scenario				VARCHAR(255) := '/csr/site/scenario/scenarioList.acds';
	v_web_resource				VARCHAR(255) := '/csr/site/scenario';
BEGIN
	security.user_pkg.LogOnAdmin();
	FOR s IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogOnAdmin(s.host);

		FOR s IN (
			SELECT m.sid_id AS menu_sid
			  FROM security.menu m
			  JOIN security.securable_object so ON m.sid_id = so.sid_id
			 WHERE so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
			   AND m.action = v_menu_scenario
		)
		LOOP
			security.securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), s.menu_sid);
		END LOOP;
		
		FOR t IN (
			SELECT wr.sid_id AS web_resource_sid
			  FROM security.web_resource wr
			  JOIN security.securable_object so ON wr.sid_id = so.sid_id
			 WHERE so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
			   AND (wr.path = v_web_resource)
		)
		LOOP
			security.securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), t.web_resource_sid);
		END LOOP;
		
		security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_body

@update_tail
