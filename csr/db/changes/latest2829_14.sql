-- Please update version.sql too -- this keeps clean builds in sync
define version=2829
define minor_version=14
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
	-- Log out of any app
	security.user_pkg.LogonAdmin;
END;
/

-- Restore any missing RRM rows caused by the bug in FB76391
-- We must add any RRMs on any suppliers where a user has the role on the purchaser (region_sid = inherited_from_sid)
-- and that supplier region's child regions, but where there isn't alrady a RRM row
-- Takes 20s on brio affecting 11677 rows
INSERT INTO csr.region_role_member (app_sid, region_sid, inherited_from_sid, role_sid, user_sid)
WITH rrm AS (
SELECT sr.app_sid, ss.region_sid, ps.region_sid inherited_from_sid, rrm.role_sid, rrm.user_sid
  FROM chain.supplier_relationship sr
  JOIN csr.supplier ps ON sr.app_sid = ps.app_sid AND sr.purchaser_company_sid = ps.company_sid
  JOIN csr.supplier ss ON sr.app_sid = ss.app_sid AND sr.supplier_company_sid = ss.company_sid
  JOIN csr.region_role_member rrm ON ps.app_sid = rrm.app_sid AND ps.region_sid = rrm.region_sid
  JOIN chain.company_type_role ctr ON rrm.app_sid = ctr.app_sid AND rrm.role_sid = ctr.role_sid
 WHERE ps.region_sid IS NOT NULL
   AND ss.region_sid IS NOT NULL
   AND rrm.region_sid = rrm.inherited_from_sid
   AND ctr.cascade_to_supplier = 1
   AND sr.deleted = 0
   AND sr.active = 1
)
SELECT r.app_sid, r.region_sid, rrm.inherited_from_sid, rrm.role_sid, rrm.user_sid
  FROM (
	SELECT app_sid, connect_by_root region_sid root_region_sid, region_sid, active
	  FROM csr.region
	 START WITH region_sid IN (SELECT region_sid FROM rrm)
   CONNECT BY PRIOR app_sid = app_sid AND prior region_sid = parent_sid
	) r
	JOIN rrm ON r.app_sid = rrm.app_sid AND r.root_region_sid = rrm.region_sid
 WHERE r.active = 1
   AND NOT EXISTS (
    SELECT *
      FROM csr.region_role_member
     WHERE app_sid = rrm.app_sid
       AND region_sid = r.region_sid
       AND role_sid = rrm.role_sid
       AND user_sid = rrm.user_sid
   )
;
-- ** New package grants **

-- *** Packages ***
@..\chain\filter_body
@..\region_body

@update_tail
