-- Please update version.sql too -- this keeps clean builds in sync
define version=3337
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR r IN (
		SELECT tab_portlet_id
		  FROM csr.tab_portlet
		 WHERE customer_portlet_sid in (
			SELECT customer_portlet_sid
			  FROM csr.customer_portlet
			 WHERE portlet_id = 204
		)
	) LOOP
		DELETE FROM csr.TAB_PORTLET_RSS_FEED
		 WHERE tab_portlet_id = r.tab_portlet_id;
		DELETE FROM csr.TAB_PORTLET_USER_REGION
		 WHERE tab_portlet_id = r.tab_portlet_id;
		DELETE FROM csr.USER_SETTING_ENTRY
		 WHERE tab_portlet_id = r.tab_portlet_id;
		DELETE FROM csr.TAB_PORTLET
		 WHERE tab_portlet_id = r.tab_portlet_id;
	END LOOP;

	DELETE FROM csr.customer_portlet
	 WHERE portlet_id = 204;

	DELETE FROM csr.portlet WHERE portlet_id = 204;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
