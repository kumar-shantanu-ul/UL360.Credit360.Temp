-- Please update version.sql too -- this keeps clean builds in sync
define version=3241
define minor_version=0
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
-- update gresb sites to use new page.
BEGIN
	FOR r IN (SELECT m.sid_id, c.name
				FROM security.menu m
				JOIN security.securable_object so ON so.sid_id = m.sid_id
				JOIN security.securable_object so2 ON so2.sid_id = so.parent_sid_id
				JOIN csr.customer c ON c.app_sid = so2.application_sid_id
			   WHERE LOWER(m.action) LIKE '%gresb/responselist%' 
			      OR LOWER(m.action) LIKE '%gresb/entityList%'
			   ORDER BY c.name)
	LOOP
		dbms_output.put_line('Updating '||r.name);
		UPDATE security.securable_object
		   SET name = 'csr_property_gresb_entitylist'
		 WHERE sid_id = r.sid_id;
		UPDATE security.menu
		   SET action = '/csr/site/property/gresb/entityList.acds'
		 WHERE sid_id = r.sid_id;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
