-- Please update version.sql too -- this keeps clean builds in sync
define version=2836
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
-- Rename the capability for existing sites. 
BEGIN
	FOR r IN (
	  SELECT sid_id capability_sid, application_sid_id app_sid, c.host
	    FROM SECURITY.SECURABLE_OBJECT so
	    JOIN csr.customer c ON c.APP_SID = so.APPLICATION_SID_ID
	   WHERE CLASS_ID = (SELECT class_id FROM security.securable_object_class WHERE LOWER(class_name) = 'csrcapability')
	     AND LOWER(so.name) = 'manually import cms data import instances'
	)
	LOOP
					
		security.user_pkg.logonadmin(r.host);
		
		UPDATE security.securable_object
		   SET name = 'Manually import automated import instances'
		 WHERE sid_id = r.capability_sid;    
		
		security.user_pkg.logonadmin();
		--DBMS_OUTPUT.PUT_LINE('Renamed '||r.capability_sid);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Packages ***
@..\automated_export_import_body
@..\automated_import_body

@update_tail
