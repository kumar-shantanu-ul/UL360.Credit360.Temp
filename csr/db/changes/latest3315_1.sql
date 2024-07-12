-- Please update version.sql too -- this keeps clean builds in sync
define version=3315
define minor_version=1
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
DELETE FROM csr.customer_portlet
 WHERE portlet_id = (SELECT portlet_id 
					   FROM csr.portlet
					  WHERE LOWER(name) LIKE '%fusion chart%'
					);

DELETE FROM csr.portlet
 WHERE LOWER(name) LIKE '%fusion chart%';


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
