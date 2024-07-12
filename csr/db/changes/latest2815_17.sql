-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=17
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

BEGIN
	-- Log out of any specific app from previous blocks
	security.user_pkg.LogonAdmin;
	
	-- add group membership for any users in rrm but not in the group
	-- expected time to run on live: 27s for 657 rows
	INSERT INTO security.group_members (group_sid_id, member_sid_id)
	SELECT role_sid, user_sid
	  FROM (
		SELECT role_sid, user_sid
		  FROM (
			SELECT DISTINCT role_sid, user_sid
			  FROM csr.region_role_member
			)
		 MINUS
		SELECT group_sid_id, member_sid_id
		  FROM security.group_members
		);
	
END;
/

-- ** New package grants **

-- *** Packages ***
@..\role_pkg
@..\role_body

@update_tail
