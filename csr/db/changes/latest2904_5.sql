-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=5
@update_header

@@latest2904_5_packages
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
	report_sid    security.security_pkg.T_SID_ID;
BEGIN
	-- check for customers with reports menu item
	FOR r IN (
		SELECT c.host
		  FROM security.securable_object so
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE sid_id IN (
					SELECT sid_id 
					  FROM security.menu 
					WHERE LOWER(action) LIKE '%csr/site/auditlog/reports.acds%')
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		BEGIN
			-- check for corresponding SO
			report_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'SqlReports/csr.csr_data_pkg.GenerateAuditReport');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				dbms_output.put_line('fixing '|| r.host);
				csr.temp_sqlreport_pkg.EnableReport('csr.csr_data_pkg.GenerateAuditReport');
		END;

	END LOOP;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

DROP PACKAGE csr.temp_sqlreport_pkg;

@update_tail
