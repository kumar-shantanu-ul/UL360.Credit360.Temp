-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=21
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
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (30, 'Reset compliance workflows', 'Resets the requirement and regulation workflows back to the default. Can be used to get the latest updates made to the default workflow','ResyncDefaultComplianceFlows', NULL);

BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT app_sid, requirement_flow_sid flow_sid
		  FROM csr.compliance_options
		 UNION 
		SELECT app_sid, regulation_flow_sid flow_sid
		  FROM csr.compliance_options
	) LOOP
		UPDATE csr.flow_state
		   SET lookup_key = 'NOT_CREATED'
		 WHERE label = 'Not created'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'NEW'
		 WHERE label = 'New'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'UPDATED'
		 WHERE label = 'Updated'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'ACTION_REQUIRED'
		 WHERE label = 'Action Required'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'COMPLIANT'
		 WHERE label = 'Compliant'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'NOT_APPLICABLE'
		 WHERE label = 'Not Applicable'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'RETIRED'
		 WHERE label = 'Retired'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../compliance_pkg
@@../util_script_pkg

@@../compliance_body
@@../util_script_body

@update_tail
