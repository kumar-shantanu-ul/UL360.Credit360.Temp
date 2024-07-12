CREATE OR REPLACE PACKAGE BODY CSR.user_cover_pkg
IS

-- NOTE - there are unit tests for this package in csr/db/tests - you should consider adding tests for any
-- new functionality and adding / modifying tests for any bug fixes / change in functionality

PROCEDURE AddUserCover (
	in_user_being_covered_sid	IN security_pkg.T_SID_ID, 
	in_user_giving_cover_sid	IN security_pkg.T_SID_ID, 
	in_start_date				IN user_cover.start_dtm%TYPE,
	in_end_date					IN user_cover.end_dtm%TYPE, 
	out_user_cover_id			OUT user_cover.user_cover_id%TYPE
) AS
	v_user_cover_id				user_cover.user_cover_id%TYPE;
	v_user_giving_cover_name	csr_user.full_name%TYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_being_covered_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting cover on user sid '||in_user_being_covered_sid);
	END IF;
	
	INSERT INTO user_cover (user_cover_id, user_giving_cover_sid, user_being_covered_sid, start_dtm, end_dtm) 
		 VALUES (user_cover_id_seq.NEXTVAL, in_user_giving_cover_sid, in_user_being_covered_sid, in_start_date, in_end_date)
		RETURNING  user_cover_id INTO v_user_cover_id;
		
	-- <audit>		
	SELECT full_name INTO v_user_giving_cover_name FROM csr_user WHERE app_sid = security_pkg.getApp AND csr_user_sid = in_user_giving_cover_sid;
		
	IF in_end_date IS NULL THEN
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, security_pkg.getApp, in_user_being_covered_sid,
			'User cover added - {0} covering from {1}', v_user_giving_cover_name, in_start_date, NULL, NULL);	
	ELSE
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, security_pkg.getApp, in_user_being_covered_sid,
			'User cover added - {0} covering from {1} until {2}', v_user_giving_cover_name, in_start_date, in_end_date, NULL);
	END IF;

	out_user_cover_id := v_user_cover_id;

END;


PROCEDURE UpdateUserCover (
	in_user_cover_id			IN user_cover.user_cover_id%TYPE, 
	in_start_date				IN user_cover.start_dtm%TYPE,
	in_end_date					IN user_cover.end_dtm%TYPE
) AS
	v_user_being_covered_sid	security_pkg.T_SID_ID;
	v_user_giving_cover_sid		security_pkg.T_SID_ID;
	v_user_giving_cover_name	csr_user.full_name%TYPE;
BEGIN

	SELECT user_being_covered_sid, user_giving_cover_sid
	  INTO v_user_being_covered_sid, v_user_giving_cover_sid
	  FROM user_cover 
	 WHERE app_sid = security_pkg.getApp
	   AND user_cover_id = in_user_cover_id;
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_user_being_covered_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting cover on user sid '||v_user_being_covered_sid);
	END IF;
	
	UPDATE user_cover SET
		start_dtm = in_start_date,
		end_dtm = in_end_date,
		cover_terminated = 0
	 WHERE app_sid = security_pkg.getApp
	   AND user_cover_id = in_user_cover_id;
	   
	-- <audit>		
	SELECT full_name INTO v_user_giving_cover_name FROM csr_user WHERE app_sid = security_pkg.getApp AND csr_user_sid = v_user_giving_cover_sid;
		
	IF in_end_date IS NULL THEN
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, security_pkg.getApp, v_user_being_covered_sid,
			'User cover updated - {0} covering from {1}', v_user_giving_cover_name, in_start_date, NULL, NULL);	
	ELSE
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, security_pkg.getApp, v_user_being_covered_sid,
			'User cover updated - {0} covering from {1} until {2}', v_user_giving_cover_name, in_start_date, in_end_date, NULL);
	END IF;

END;


PROCEDURE DeleteUserCover (
	in_user_cover_id			IN user_cover.user_cover_id%TYPE
) 
AS
	v_user_being_covered_sid	security_pkg.T_SID_ID;
	v_user_giving_cover_sid		security_pkg.T_SID_ID;
	v_user_giving_cover_name	csr_user.full_name%TYPE;
BEGIN

	SELECT user_being_covered_sid, user_giving_cover_sid 
	  INTO v_user_being_covered_sid, v_user_giving_cover_sid
	  FROM user_cover 
	 WHERE app_sid = security_pkg.getApp
	   AND user_cover_id = in_user_cover_id;
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_user_being_covered_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting cover on user sid '||v_user_being_covered_sid);
	END IF;
	
	UPDATE user_cover 
	   SET cover_terminated = 1 
	 WHERE app_sid = security_pkg.getApp 
	   AND user_cover_id = in_user_cover_id;
	   
	-- <audit>		
	SELECT full_name INTO v_user_giving_cover_name FROM csr_user WHERE app_sid = security_pkg.getApp AND csr_user_sid = v_user_giving_cover_sid;
		
	csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, security_pkg.getApp, v_user_being_covered_sid,
		'User cover deleted - {0}', v_user_giving_cover_name, NULL, NULL, NULL);	
			
END;

PROCEDURE DeleteMissingUserCover (
	in_user_being_covered_sid	IN	security_pkg.T_SID_ID,
	in_current_user_cover_ids	IN  security_pkg.T_SID_IDS
)
AS
	v_current_user_cover_ids	security.T_SID_TABLE;
BEGIN
	v_current_user_cover_ids := security_pkg.SidArrayToTable(in_current_user_cover_ids);

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_being_covered_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting cover on user sid '||in_user_being_covered_sid);
	END IF;

	FOR r IN (
		SELECT user_cover_id 
		  FROM user_cover 
		 WHERE app_sid = security_pkg.getApp
		   AND user_being_covered_sid = in_user_being_covered_sid
		   AND user_cover_id NOT IN (
				SELECT column_value FROM TABLE(v_current_user_cover_ids)
		   )
	) LOOP
		DeleteUserCover(r.user_cover_id);
	END LOOP;
END;

-- get the schedule of cover for a user
PROCEDURE GetCoverForUser (
	in_user_being_covered_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_being_covered_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user sid '||in_user_being_covered_sid);
	END IF;	
	

	-- TO DO if we do user container changes checks DISCUSSED With LEE 
	-- check the "list contents" permission of parent of each userand only return what you can see (DETERMINISTIC FUNC)
	-- AND THEN check the read for/write to access if links showm,

	OPEN out_cur FOR 
		SELECT  uc.app_sid, uc.user_cover_id, 
				uc.user_giving_cover_sid, gc.full_name, uc.start_dtm, uc.end_dtm
		  FROM user_cover uc 
		  JOIN csr_user gc ON uc.app_sid = gc.app_sid AND uc.user_giving_cover_sid = gc.csr_user_sid 
		 WHERE uc.app_sid = security_pkg.getApp
		   AND uc.cover_terminated = 0
		   AND uc.user_being_covered_sid = in_user_being_covered_sid;

END;

PROCEDURE GetCurrentCoveringUsers (
	in_user_being_covered_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security - potentially this is useful to anyone seeing a user on a screen - chances are the logged
	-- on user won't have read access on all users (and nor should they).
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.full_name, cu.email
		  FROM csr_user cu
		  JOIN user_cover uc ON cu.csr_user_sid = uc.user_giving_cover_sid
		 WHERE uc.user_being_covered_sid = in_user_being_covered_sid
		   AND uc.cover_terminated = 0
		   AND uc.start_dtm < SYSDATE
		   AND (uc.end_dtm IS NULL OR uc.end_dtm > SYSDATE);
END;


PROCEDURE GetAppsWithCover(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT host, c.app_sid, c.scheduled_tasks_disabled
		  FROM customer c, user_cover uc
		 WHERE c.app_sid = uc.app_sid;
END;


PROCEDURE GetUserCoverForApp(
	out_current_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_stop_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_fully_end_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	-- Note: we need to process all current cover each time this job/task runs - as a user may have been linked to more delegations
	-- or removed from delegations since last run
	OPEN out_current_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid, start_dtm, end_dtm, cover_terminated
		  FROM user_cover
		 WHERE cover_terminated = 0
		   AND start_dtm <= SYSDATE
		   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
		   AND app_sid = security_pkg.getApp
		 ORDER BY user_giving_cover_sid; 
		 
	-- all cover that had started - but the dates had been updated so now in the future
	OPEN out_stop_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid, start_dtm, end_dtm, cover_terminated
		  FROM user_cover
		 WHERE cover_terminated = 0
		   AND start_dtm > SYSDATE
		   AND app_sid = security_pkg.getApp
		   AND alert_sent_dtm IS NOT NULL;
		   
	-- all cover that has expired OR any "terminated" cover (deleted early)
	OPEN out_fully_end_cur FOR	
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid, start_dtm, end_dtm, cover_terminated
		  FROM user_cover
		 WHERE (cover_terminated = 1
		    OR end_dtm <= SYSDATE)
		   AND app_sid = security_pkg.getApp;
	
END;


PROCEDURE StartOrRefreshCover (
	in_user_cover_id				IN 		user_cover.user_cover_id%TYPE,
	out_cur							OUT		security_pkg.T_OUTPUT_CUR
)
AS
	v_user_giving_cover_sid			security_pkg.T_SID_ID;
	v_user_being_covered_sid		security_pkg.T_SID_ID;
	v_user_being_covered_name		csr_user.full_name%TYPE;
	v_user_giving_cover_name		csr_user.full_name%TYPE;
	v_dummy							security_pkg.T_OUTPUT_CUR;
BEGIN

	SELECT user_giving_cover_sid, user_being_covered_sid
	  INTO v_user_giving_cover_sid, v_user_being_covered_sid
	  FROM user_cover
	 WHERE app_sid = security_pkg.getApp
	   AND user_cover_id = in_user_cover_id
	   AND cover_terminated = 0;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_user_being_covered_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied starting/refreshing cover for user sid '||v_user_being_covered_sid);
	END IF;
	   
	SELECT full_name INTO v_user_being_covered_name FROM csr_user WHERE app_sid = security_pkg.getApp AND csr_user_sid = v_user_being_covered_sid;
	SELECT full_name INTO v_user_giving_cover_name FROM csr_user WHERE app_sid = security_pkg.getApp AND csr_user_sid = v_user_giving_cover_sid;
	
	-- find all delegations the covered user is part of that the user giving cover already isn't part of already
	
	-- Cover delegations
	-- NB. this exclusion covers the case where the user giving cover is part of the delegation in their own right or 
	-- part of the delegation where they are just covering
	FOR r IN (
        SELECT delegation_sid
          FROM delegation_user du1
         WHERE app_sid = security_pkg.getApp
           AND user_sid = v_user_being_covered_sid
		   AND du1.inherited_from_sid = du1.delegation_sid
		   	-- NB. this exclusion covers the case where the user giving cover is part of the delegation in their own right or 
			-- part of the delegation where they are just covering
           AND delegation_sid NOT IN (
                SELECT delegation_sid 
                  FROM delegation_user du2
                 WHERE app_sid = security_pkg.getApp
                   AND user_sid = v_user_giving_cover_sid
                   AND delegation_sid = du1.delegation_sid
				   AND du2.inherited_from_sid = du2.delegation_sid
            )
			AND delegation_sid NOT IN (
				SELECT delegation_sid
				  FROM delegation_user_cover
				 WHERE user_giving_cover_sid = v_user_giving_cover_sid
			)
	) 
	LOOP
		delegation_pkg.UNSEC_AddUser(security_pkg.getAct, r.delegation_sid, v_user_giving_cover_sid);
		INSERT INTO delegation_user_cover (user_cover_id, delegation_sid, user_being_covered_sid, user_giving_cover_sid)
			 VALUES (in_user_cover_id, r.delegation_sid, v_user_being_covered_sid, v_user_giving_cover_sid);
		
		-- <audit>
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_DELEGATION, security_pkg.getApp, r.delegation_sid,
			'Delegation cover started - {0} ({1}) covering {2}', v_user_giving_cover_name, v_user_giving_cover_sid, v_user_being_covered_name, NULL);
	END LOOP;
	
	-- Cover audits
	FOR r IN (
		SELECT ia.internal_audit_sid
		  FROM internal_audit ia
		  LEFT JOIN audit_user_cover auc
		    ON ia.internal_audit_sid = auc.internal_audit_sid
		   AND auc.user_being_covered_sid = v_user_being_covered_sid
		   AND auc.user_giving_cover_sid = v_user_giving_cover_sid
		   AND auc.user_cover_id = in_user_cover_id
		 WHERE auditor_user_sid = v_user_being_covered_sid
		   AND auc.internal_audit_sid IS NULL -- Exclude audits we've already processed
	) LOOP
		INSERT INTO audit_user_cover (user_cover_id, internal_audit_sid, user_being_covered_sid, user_giving_cover_sid)
		VALUES (in_user_cover_id, r.internal_audit_sid, v_user_being_covered_sid, v_user_giving_cover_sid);
	END LOOP;
	
	-- Cover issues
	FOR r IN (
		SELECT DISTINCT i.issue_id
		  FROM issue i
		  LEFT JOIN issue_involvement ii ON i.issue_id = ii.issue_id
		  LEFT JOIN issue_involvement iic ON i.issue_id = iic.issue_id AND iic.user_sid = v_user_giving_cover_sid
		  LEFT JOIN issue_user_cover iuc ON i.issue_id = iuc.issue_id AND iuc.user_giving_cover_sid = v_user_being_covered_sid
		 WHERE i.closed_dtm IS NULL
		   AND i.deleted = 0
		   AND ii.user_sid = v_user_being_covered_sid
		   AND iic.issue_id IS NULL -- exclude issues user is already involved in
		   AND iuc.issue_id IS NULL -- exclude issues where cover user is covering a cover user
	) LOOP
		BEGIN
			INSERT INTO issue_user_cover (user_cover_id, issue_id, user_being_covered_sid, user_giving_cover_sid)
			VALUES (in_user_cover_id, r.issue_id, v_user_being_covered_sid, v_user_giving_cover_sid);
			
			csr.issue_pkg.AddUser(security_pkg.GetAct, r.issue_id, v_user_giving_cover_sid, v_dummy);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- User has been covered before, and then removed manually from this issue - leave removed
		END;
	END LOOP;
	
	-- include issues where cover user is already involved but will become the issue owner
	INSERT INTO issue_user_cover (user_cover_id, issue_id, user_being_covered_sid, user_giving_cover_sid)
	SELECT in_user_cover_id, i.issue_id, v_user_being_covered_sid, v_user_giving_cover_sid
	  FROM issue i
	 WHERE i.owner_user_sid = v_user_being_covered_sid
	   AND i.closed_dtm IS NULL
	   AND i.deleted = 0
	   AND NOT EXISTS (
		SELECT *
		  FROM issue_user_cover iuc
		 WHERE iuc.issue_id = i.issue_id
		   AND user_giving_cover_sid = v_user_giving_cover_sid
		   AND user_being_covered_sid = v_user_being_covered_sid
	);
	
	-- update owner, so long as the owner isn't a cover user
	UPDATE issue
	   SET owner_user_sid = v_user_giving_cover_sid
	 WHERE owner_user_sid = v_user_being_covered_sid
	   AND closed_dtm IS NULL
	   AND deleted = 0
	   AND (issue_id, owner_user_sid) NOT IN (
		SELECT issue_id, user_giving_cover_sid
		  FROM issue_user_cover
		);
	
	-- Cover groups
	FOR r IN (
		SELECT being.group_sid_id group_sid
		  FROM security.group_members being
		  JOIN security.securable_object so ON being.group_sid_id = so.sid_id
		  LEFT JOIN security.group_members giving
		    ON being.group_sid_id = giving.group_sid_id AND giving.member_sid_id = v_user_giving_cover_sid
		  LEFT JOIN group_user_cover guc
		    ON being.group_sid_id = guc.group_sid AND being.member_sid_id = guc.user_giving_cover_sid
		 WHERE being.member_sid_id = v_user_being_covered_sid
		   AND so.class_id = security.class_pkg.GetClassId('CSRUserGroup')
		   AND giving.group_sid_id IS NULL -- exclude groups user has already
		   AND guc.user_cover_id IS NULL -- exclude groups that user beign covered has only because they are coving someone else
	) LOOP
		BEGIN
			INSERT INTO group_user_cover (user_cover_id, group_sid, user_being_covered_sid, user_giving_cover_sid)
			VALUES (in_user_cover_id, r.group_sid, v_user_being_covered_sid, v_user_giving_cover_sid);
			
			security.group_pkg.AddMember(security_pkg.GetAct, v_user_giving_cover_sid, r.group_sid);
			
			-- audit log
			csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, security_pkg.getApp, v_user_giving_cover_sid,
				'Group cover started - {0} ({1}) covering {2}', securableobject_pkg.GetName(security_pkg.getAct, r.group_sid), r.group_sid, v_user_being_covered_name, NULL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Group has been covered before, and then removed manually - leave removed
		END;
	END LOOP;
	
	-- Cover roles
	FOR r in (
		SELECT DISTINCT being.region_sid, being.role_sid -- make distinct as rrm table allows the same role more than once for the same region/user
		  FROM region_role_member being
		  JOIN role r ON being.role_sid = r.role_sid
		  LEFT JOIN region_role_member giving
		    ON being.role_sid = giving.role_sid AND being.region_sid = giving.region_sid AND giving.user_sid = v_user_giving_cover_sid
		  LEFT JOIN role_user_cover ruc
		    ON being.inherited_from_sid = ruc.region_sid AND being.user_sid = ruc.user_giving_cover_sid AND being.role_sid = ruc.role_sid
		 WHERE r.is_system_managed = 0
		   AND being.user_sid = v_user_being_covered_sid
		   AND being.region_sid = being.inherited_from_sid
		   AND giving.user_sid IS NULL -- exclude roles user has already
		   AND ruc.user_cover_id IS NULL -- exclude roles that user has inherited from another cover
	) LOOP
		BEGIN
			INSERT INTO role_user_cover (user_cover_id, role_sid, region_sid, user_being_covered_sid, user_giving_cover_sid)
			VALUES (in_user_cover_id, r.role_sid, r.region_sid, v_user_being_covered_sid, v_user_giving_cover_sid);
			
			role_pkg.AddRoleMemberForRegion(r.role_sid, r.region_sid, v_user_giving_cover_sid);
			
			-- audit log
			csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_REGION_ROLE_CHANGED, security_pkg.getApp, r.role_sid,
				'Role cover started - {0} ({1}) covering {2}', v_user_giving_cover_name, v_user_giving_cover_sid, v_user_being_covered_name, NULL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Role has been covered before, and then removed manually - leave removed
		END;
	END LOOP;
	
	-- Workflow involvement cover
	
	-- Add cover so long as the user isn't already involved.
	FOR r IN (
		SELECT being.flow_item_id, being.flow_involvement_type_id
		  FROM flow_item_involvement being
		  LEFT JOIN flow_item_involvement giving
		    ON giving.user_sid = v_user_giving_cover_sid
		   AND giving.flow_item_id = being.flow_item_id
		   AND giving.flow_involvement_type_id = being.flow_involvement_type_id
		  LEFT JOIN flow_involvement_cover fic 
		    ON fic.flow_involvement_type_id = being.flow_involvement_type_id
		   AND fic.flow_item_id = being.flow_item_id
		   AND fic.user_being_covered_sid = being.user_sid
		   AND fic.user_giving_cover_sid = v_user_giving_cover_sid
		 WHERE fic.user_cover_id IS NULL
		   AND giving.user_sid IS NULL
		   AND being.user_sid = v_user_being_covered_sid
	)
	LOOP
		BEGIN
			INSERT INTO flow_item_involvement (flow_item_id, flow_involvement_type_id, user_sid)
			VALUES (r.flow_item_id, r.flow_involvement_type_id, v_user_giving_cover_sid);
			-- For now, don't log this.
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		
		INSERT INTO flow_involvement_cover (user_cover_id, user_being_covered_sid, user_giving_cover_sid, 
			flow_involvement_type_id, flow_item_id)
		VALUES (in_user_cover_id, v_user_being_covered_sid, v_user_giving_cover_sid, r.flow_involvement_type_id,
			r.flow_item_id);
	END LOOP;
	
	-- TO DO - but where a user is not added to cover all users when covering multiple users on same delegation (so alert mail is only sent for one of the users being covered)
	-- Fix is something like this but can't quite get it right - going to release and log bug
	/*
				-- delegation user in own right
                SELECT du2.delegation_sid 
                  FROM delegation_user du2
                 WHERE du2.app_sid = security_pkg.getApp
                   AND du2.user_sid = v_user_giving_cover_sid
                   AND du2.delegation_sid = du1.delegation_sid
				   AND (du2.delegation_sid) NOT IN (
					SELECT delegation_sid
					  FROM delegation_user_cover duc
					 WHERE duc.app_sid = security_pkg.getApp 
					   --AND user_being_covered_sid  = v_user_being_covered_sid
					   AND duc.user_giving_cover_sid = v_user_giving_cover_sid
					   AND duc.delegation_sid = du1.delegation_sid
				   )
			)
			AND delegation_sid NOT IN (
				-- delegation user giving cover to this user specfically
				SELECT duc.delegation_sid 
                  FROM delegation_user_cover duc
				 WHERE duc.app_sid = security_pkg.getApp 
				   AND duc.user_being_covered_sid  = v_user_being_covered_sid
				   AND duc.user_giving_cover_sid = v_user_giving_cover_sid
				   AND duc.delegation_sid = du1.delegation_sid
            )
	*/
	-- TO DO - cover gets chained within a delegation
	-- A covers B
	-- B covers C
	-- C covers D
	-- If A is added as a user B and C d D end up covering
	
	
	-- TO DO - only mails the last user in a list 
	OPEN out_cur FOR
		SELECT 	user_being_covered_sid, 
				v_user_being_covered_name user_being_covered_name, 
				user_giving_cover_sid, 
				v_user_giving_cover_name user_giving_cover_name,
				CASE
					WHEN alert_sent_dtm IS NULL THEN 1
					ELSE 0
				END send_alert, -- are we adding cover where there was none before for this coverer and coveree pair
				start_dtm, 
				end_dtm
		  FROM user_cover uc
		 WHERE user_cover_id = in_user_cover_id
		   AND uc.app_sid = security_pkg.getApp;
	
END;


PROCEDURE StopCover (
	in_user_cover_id	IN user_cover.user_cover_id%TYPE
)
AS
	v_user_giving_cover_sid		security_pkg.T_SID_ID;
	v_user_being_covered_sid	security_pkg.T_SID_ID;
	v_user_being_covered_name	csr_user.full_name%TYPE;
	v_user_giving_cover_name	csr_user.full_name%TYPE;

BEGIN

	SELECT user_giving_cover_sid, user_being_covered_sid
	  INTO v_user_giving_cover_sid, v_user_being_covered_sid
	  FROM user_cover
	 WHERE app_sid = security_pkg.getApp
	   AND user_cover_id = in_user_cover_id;
		
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_user_being_covered_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied stopping cover for user sid '||v_user_being_covered_sid);
	END IF;
	
	-- find all current cover related to this cover id in delegations
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation_user_cover
		 WHERE app_sid = security_pkg.getApp
		   AND user_cover_id = in_user_cover_id
	) LOOP
	
		ClearUserCoverIfLastOne(r.delegation_sid, v_user_being_covered_sid, v_user_giving_cover_sid);

		-- <audit>		
		SELECT full_name INTO v_user_being_covered_name FROM csr_user WHERE app_sid = security_pkg.getApp AND csr_user_sid = v_user_being_covered_sid;
		SELECT full_name INTO v_user_giving_cover_name FROM csr_user WHERE app_sid = security_pkg.getApp AND csr_user_sid = v_user_giving_cover_sid;
		 
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_DELEGATION, security_pkg.getApp, r.delegation_sid,
			'Delegation cover stopped - {0} ({1}) covering {2}', v_user_giving_cover_name, v_user_giving_cover_sid, v_user_being_covered_name, NULL);
		
	END LOOP;
	
	-- find all cover in audits
	DELETE FROM audit_user_cover
	 WHERE user_cover_id = in_user_cover_id;
		
	-- restore original auditor as owner of issues
	UPDATE issue
	   SET owner_user_sid = v_user_being_covered_sid
	 WHERE owner_user_sid = v_user_giving_cover_sid
	   AND raised_by_user_sid != v_user_giving_cover_sid
	   AND issue_id IN (
		SELECT issue_id
		  FROM issue_user_cover
		 WHERE user_cover_id = in_user_cover_id
		);
	
	-- Remove issue user cover row, but leave users as involved?
	DELETE FROM issue_user_cover
	 WHERE user_cover_id = in_user_cover_id;
	
	-- remove group cover
	FOR r IN (
		SELECT group_sid
		  FROM group_user_cover
		 WHERE user_cover_id = in_user_cover_id
	) LOOP
		security.group_pkg.DeleteMember(security_pkg.GetAct, v_user_giving_cover_sid, r.group_sid);
		
		-- audit log
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, security_pkg.getApp, v_user_giving_cover_sid,
			'Group cover ended - {0} ({1}) covering {2}', securableobject_pkg.GetName(security_pkg.getAct, r.group_sid), r.group_sid, v_user_being_covered_name, NULL);

	END LOOP;
	
	DELETE FROM group_user_cover
	 WHERE user_cover_id = in_user_cover_id;
	
	
	-- remove role cover
	DELETE FROM region_role_member
	 WHERE user_sid = v_user_giving_cover_sid
	   AND (app_sid, role_sid, inherited_from_sid) IN (
		SELECT app_sid, role_sid, region_sid
		  FROM role_user_cover
		 WHERE user_cover_id = in_user_cover_id
	 );
	
	FOR r IN (
		SELECT ruc.role_sid, ruc.region_sid
		  FROM role_user_cover ruc
		  LEFT JOIN (
			SELECT role_sid, user_sid
			  FROM region_role_member 
			 WHERE inherited_from_sid = region_sid
		  )rrm ON ruc.user_giving_cover_sid = rrm.user_sid AND ruc.role_sid = rrm.role_sid
		  WHERE rrm.user_sid IS NULL
		    AND ruc.user_cover_id = in_user_cover_id
	 )
	LOOP
		group_pkg.DeleteMember(security_pkg.GetAct, v_user_giving_cover_sid, r.role_sid);

		-- audit log
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getAct, csr_data_pkg.AUDIT_TYPE_REGION_ROLE_CHANGED, security_pkg.getApp, r.role_sid,
			'Role cover stopped - {0} ({1}) covering {2}', v_user_giving_cover_name, v_user_giving_cover_sid, v_user_being_covered_name, NULL);
	END LOOP;
	
	DELETE FROM role_user_cover
	 WHERE user_cover_id = in_user_cover_id;
	
	FOR r IN (
		SELECT fic.*
		  FROM (
			-- Get any cover that is derived from in_user_cover_id - we want to remove any involvement
			-- that only exists from someone covering another cover user.
			SELECT user_cover_id		
			  FROM csr.user_cover
			  CONNECT BY NOCYCLE PRIOR user_giving_cover_sid = user_being_covered_sid
			  START WITH user_cover_id = in_user_cover_id
			) a
		  -- We rely on nothing being added to flow_involvement_cover if the coverer was already involved.
		  JOIN csr.flow_involvement_cover fic
		    ON fic.user_cover_id = a.user_cover_id
	) LOOP	
		DELETE FROM csr.flow_item_involvement
		 WHERE flow_item_id = r.flow_item_id
		   AND flow_involvement_type_id = r.flow_involvement_type_id
		   AND user_sid = r.user_giving_cover_sid;
	
		DELETE FROM csr.flow_involvement_cover
		 WHERE user_cover_id = r.user_cover_id;
		 
		-- For now, don't log this. Do we log the user cover itself? In which case logging might not be needed at
		-- all here, but it depends on what we want to use the logging for.
	 END LOOP;
END;

PROCEDURE ClearUserCoverIfLastOne(
	in_delegation_sid			IN security_pkg.T_SID_ID,
	in_user_being_covered_sid	IN security_pkg.T_SID_ID, 
	in_user_giving_cover_sid	IN security_pkg.T_SID_ID 
)
AS
	v_cnt_cover_for_other_users	NUMBER;
	v_cnt_deleted				NUMBER;
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_being_covered_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied stopping cover for user sid '||in_user_being_covered_sid);
	END IF;
	   
	DELETE FROM delegation_user_cover 
	 WHERE delegation_sid = in_delegation_sid 
	   AND app_sid = security_pkg.getApp 
	   AND user_giving_cover_sid = in_user_giving_cover_sid
	   AND user_being_covered_sid = in_user_being_covered_sid;
	   
	v_cnt_deleted := SQL%ROWCOUNT;
	
	SELECT COUNT(*) INTO v_cnt_cover_for_other_users 
	  FROM delegation_user_cover 
	 WHERE delegation_sid = in_delegation_sid
	   AND app_sid = security_pkg.getApp 
	   AND user_giving_cover_sid = in_user_giving_cover_sid;
	
	-- If we just cleared some cover (meaning they weren't part of the delegation in their own right)
	-- AND the user providing cover on this delegation isn't covering anyone else then remove them fully from the delegation
	IF (v_cnt_deleted > 0) AND (v_cnt_cover_for_other_users = 0) THEN
		delegation_pkg.DeleteUser(security_pkg.GetAct, in_delegation_sid, in_user_giving_cover_sid);
	END IF;

END;

PROCEDURE FullyEndCover(
	in_user_cover_id	IN user_cover.user_cover_id%TYPE
)
AS
BEGIN

	-- Sec check in stop cover
	StopCover(in_user_cover_id);
	
	DELETE FROM user_cover 
	 WHERE user_cover_id = in_user_cover_id 
	   AND app_sid = security_pkg.getApp;
END;

PROCEDURE MarkAlertSent(
	in_user_cover_id	IN user_cover.user_cover_id%TYPE
)
AS
BEGIN
	UPDATE user_cover
	   SET alert_sent_dtm = SYSDATE
	 WHERE user_cover_id = in_user_cover_id;
END;

PROCEDURE MarkAlertUnSent(
	in_user_cover_id	IN user_cover.user_cover_id%TYPE
)
AS
BEGIN
	-- Called when start_dtm of existing cover set to the future, un-set alert
	-- sent flag so that alert goes out when cover re-starts
	UPDATE user_cover
	   SET alert_sent_dtm = NULL
	 WHERE user_cover_id = in_user_cover_id;
END;


END;
/
