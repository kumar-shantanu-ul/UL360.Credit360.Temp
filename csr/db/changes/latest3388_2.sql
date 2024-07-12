-- Please update version.sql too -- this keeps clean builds in sync
define version=3388
define minor_version=2
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
BEGIN
	-- There were two fixes required for delegation permissions.
	---- 1. The first is that the "insert step before" action did not add the delegator permission to the step after the new step, meaning users could not approve their child delegation.
	---- 2. The second is that when delegating the permissions were delegated to children before the delegator permission is added to the child delegation, meaning grand+ children only have delegee permission.
	FOR r IN (
		SELECT d.app_sid, d.delegation_sid parent, du.deleg_permission_set pps, cd.delegation_sid child, cdu.deleg_permission_set cps, du.user_sid
		  FROM csr.delegation d
		  JOIN csr.delegation_user du ON d.app_sid = du.app_sid AND d.delegation_sid = du.delegation_sid AND du.inherited_from_sid = d.delegation_sid
		  JOIN csr.delegation cd ON d.app_sid = cd.app_sid AND d.delegation_sid = cd.parent_sid
		  LEFT JOIN csr.delegation_user cdu ON cd.app_sid = cdu.app_sid AND cd.delegation_sid = cdu.delegation_sid AND du.user_sid = cdu.user_sid AND cdu.inherited_from_sid = du.delegation_sid
		 WHERE (cdu.deleg_permission_set IS NULL OR cdu.deleg_permission_set < du.deleg_permission_set) -- NULL for 1. because never added. Child delegation having less permissions for 2.
		 ORDER BY app_sid
	) LOOP
		
		MERGE INTO csr.delegation_user du
		USING (
			SELECT app_sid, delegation_sid, r.user_sid user_sid, r.parent parent
			  FROM csr.delegation
			 START WITH delegation_sid = r.child
		   CONNECT BY PRIOR delegation_sid = parent_sid
		  ) u
		   ON (u.app_sid = du.app_sid AND u.user_sid = du.user_sid AND u.delegation_sid = du.delegation_sid and u.parent = du.inherited_from_sid)
		 WHEN MATCHED THEN
			UPDATE SET deleg_permission_set = 11
		 WHEN NOT MATCHED THEN
			INSERT (app_sid, delegation_sid, user_sid, deleg_permission_set, inherited_from_sid)
			VALUES (u.app_sid, u.delegation_sid, u.user_sid, 11, u.parent);	
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
