-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=31
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
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.tab_portlet t
	   SET t.state = REPLACE(t.state, 'Property Compliance RAG Status', 'Site Compliance RAG Status')
	 WHERE t.tab_portlet_id IN (
		SELECT tp.tab_portlet_id 
		  FROM csr.tab_portlet tp
		  JOIN csr.customer_portlet cp ON tp.app_sid = cp.app_sid AND tp.customer_portlet_sid = cp.customer_portlet_sid
		 WHERE cp.portlet_id = 1048
		   AND dbms_lob.instr(tp.state, 'Property Compliance RAG Status') > 0
	);
	
	UPDATE csr.tab_portlet
	   SET state = REPLACE(state, 'Surveys waiting reply', 'Surveys awaiting reply')
	 WHERE tab_portlet_id IN (
		SELECT tp.tab_portlet_id 
		  FROM csr.tab_portlet tp
		  JOIN csr.customer_portlet cp ON tp.app_sid = cp.app_sid AND tp.customer_portlet_sid = cp.customer_portlet_sid
		 WHERE cp.portlet_id = 1025
		   AND dbms_lob.instr(tp.state, 'Surveys waiting reply') > 0
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_body

@update_tail
