-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
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
DECLARE
	v_portlet_id			NUMBER := 2; -- Table Portlet
BEGIN
	UPDATE csr.portlet
	   SET default_state = TO_CLOB('{"includeExcelValueLinks":true}')
	 WHERE portlet_id = v_portlet_id;

	security.user_pkg.LogOnAdmin();
	FOR s IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
			  JOIN csr.tab_portlet tp on c.app_sid = tp.app_sid
			  JOIN csr.customer_portlet cp on tp.customer_portlet_sid = cp.customer_portlet_sid
			  JOIN csr.portlet p on cp.portlet_id = p.portlet_id
			 WHERE p.portlet_id = v_portlet_id
			   AND NVL(INSTR(tp.state, 'includeExcelValueLinks'), 0) = 0
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogOnAdmin(s.host);

		UPDATE csr.tab_portlet
		   SET state = CASE WHEN NVL(LENGTH(state), 0) = 0 THEN TO_CLOB('{"includeExcelValueLinks":true}') ELSE SUBSTR(state, 0, LENGTH(state) - 1) || ',"includeExcelValueLinks":true}' END
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tab_portlet_id IN (
			SELECT tp.tab_portlet_id
			  FROM csr.tab_portlet tp
			  JOIN csr.customer_portlet cp on tp.customer_portlet_sid = cp.customer_portlet_sid
			  JOIN csr.portlet p on cp.portlet_id = p.portlet_id
			 WHERE tp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND p.portlet_id = v_portlet_id
			   AND NVL(INSTR(tp.state, 'includeExcelValueLinks'), 0) = 0
		);

		security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
