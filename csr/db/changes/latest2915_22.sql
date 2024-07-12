-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=22
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
	
    INSERT INTO csr.region_type_tag_group (app_sid, region_type, tag_group_id)
	     SELECT DISTINCT tgm.app_sid, r.region_type, tgm.tag_group_id 
		   FROM csr.tag_group_member tgm
		   JOIN csr.region_tag rt ON tgm.app_sid = rt.app_sid AND rt.tag_id = tgm.tag_id
		   JOIN csr.region r ON rt.app_sid = r.app_sid AND r.region_sid = rt.region_sid
		  WHERE (tgm.app_sid, tgm.tag_group_id) IN (
				SELECT DISTINCT app_sid, tag_group_id 
				  FROM csr.region_type_tag_group
			  )
		    AND (tgm.app_sid,r.region_type,tgm.tag_group_id) NOT IN (
				SELECT DISTINCT app_sid,region_type,tag_group_id 
				  FROM csr.region_type_tag_group
			  );
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../property_body
@../tag_body
@update_tail
