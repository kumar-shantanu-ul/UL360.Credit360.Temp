-- Please update version.sql too -- this keeps clean builds in sync
define version=3336
define minor_version=6
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
DECLARE
    v_flashMapPortletId csr.portlet.portlet_id%TYPE;
BEGIN
	-- Find the portlet we want to delete
    SELECT PORTLET_ID INTO v_flashMapPortletId
    FROM CSR.PORTLET
    WHERE TYPE = 'Credit360.Portlets.Map';
    
	-- Find all the customer portlets that use that portlet
    FOR cp IN (
        SELECT customer_portlet_sid
        FROM CSR.CUSTOMER_PORTLET
        WHERE PORTLET_ID = v_flashMapPortletId
        )
    LOOP
		-- Delete all instances of those customer portlets
        DELETE FROM CSR.TAB_PORTLET
        WHERE CUSTOMER_PORTLET_SID = cp.customer_portlet_sid;
        
		-- Delete the customer portlet
        DELETE FROM CSR.CUSTOMER_PORTLET
        WHERE CUSTOMER_PORTLET_SID = cp.customer_portlet_sid;
    END LOOP;
    
	-- Finally, delete the portlet itself
    DELETE FROM CSR.PORTLET
    WHERE PORTLET_ID = v_flashMapPortletId;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
