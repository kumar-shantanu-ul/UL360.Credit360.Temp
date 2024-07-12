-- Please update version.sql too -- this keeps clean builds in sync
define version=2986
define minor_version=0
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
	v_property_region_sid		csr.SPACE.property_region_sid%TYPE; 
BEGIN
	security.user_pkg.logonAdmin;
	FOR x IN (
		SELECT DISTINCT c.app_sid, c.host 
		  FROM csr.lease_postit lp 
		  JOIN csr.customer c ON c.app_sid=lp.app_sid)
	LOOP
		security.user_pkg.logonAdmin(x.host);
		FOR y IN (
			SELECT app_sid, lease_id, postit_id
			  FROM csr.lease_postit)
		LOOP
			SELECT MIN(property_region_sid)
			  INTO v_property_region_sid
			  FROM csr.lease_space ls
			  JOIN csr.space s ON s.region_sid = ls.space_region_sid AND ls.app_sid = s.app_sid
			 WHERE ls.lease_id = y.lease_id 
			   AND ls.app_sid= y.app_sid;
		
			IF v_property_region_sid IS NOT NULL THEN 
				UPDATE csr.postit 
				   SET secured_via_sid = v_property_region_sid
				 WHERE postit_id = y.postit_id 
				   AND app_sid= y.app_sid;
			END IF;
		END LOOP;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../property_body

@update_tail
