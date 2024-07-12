-- Please update version.sql too -- this keeps clean builds in sync
define version=2986
define minor_version=10
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
	security.user_pkg.logonAdmin;
	
	FOR x IN (
		SELECT sr.app_sid, sr.substance_id, sr.region_sid, s.ref 
		  FROM chem.substance_region sr
		  JOIN chem.substance s ON s.substance_id =sr.substance_id
		   AND s.app_sid = sr.app_sid
		  JOIN csr.flow_item fi ON fi.flow_item_id = sr.flow_item_id 
		   AND fi.app_sid = sr.app_sid
		 WHERE (s.app_sid, s.substance_id) IN (
			SELECT app_sid, substance_id 
			  FROM chem.substance 
			 WHERE is_central=0)
		   AND (fi.app_sid, fi.current_state_id) NOT IN (
				SELECT app_sid, flow_state_id 
				  FROM csr.flow_state 
				 WHERE lookup_key='APPROVAL_NOT_REQUIRED')
		   AND local_ref IS NULL)
	LOOP
		UPDATE chem.substance_region
		   SET local_ref = x.ref
		 WHERE substance_id = x.substance_id
		   AND region_sid = x.region_sid
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chem/substance_body

@update_tail
