-- Please update version.sql too -- this keeps clean builds in sync
define version=2793
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
CREATE OR REPLACE VIEW csr.v$issue_user AS
	SELECT ii.app_sid, ii.issue_id, user_sid, MIN(ii.from_role) from_role
	  FROM (
		SELECT ii.app_sid, ii.issue_id, NVL(ii.user_sid, rrm.user_sid) user_sid,
			   CASE WHEN ii.role_sid IS NOT NULL THEN 1 ELSE 0 END from_role
		  FROM issue_involvement ii
		  JOIN issue i
			ON i.app_sid = ii.app_sid
		   AND i.issue_id = ii.issue_id
		  LEFT JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_sid
		   AND rrm.role_sid = ii.role_sid
		 UNION
		SELECT ii.app_sid, ii.issue_id, rrm.user_sid, 1 from_role
		  FROM issue_involvement ii
		  JOIN issue i ON i.app_sid = ii.app_sid AND i.issue_id = ii.issue_id
		  JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_2_sid
		   AND rrm.role_sid = ii.role_sid
		 UNION
		SELECT i.app_sid, i.issue_id, rrm.user_sid, 1 from_role
		  FROM issue i
		  JOIN region_role_member rrm ON rrm.app_sid = i.app_sid AND rrm.region_sid = i.region_sid AND rrm.role_sid = i.assigned_to_role_sid
		) ii
	 GROUP BY ii.app_sid, ii.issue_id, ii.user_sid;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@../issue_body

@update_tail
