CREATE OR REPLACE PACKAGE csr.temp_csr_data_pkg AS
                                         
NOT_FULLY_DELEGATED 			CONSTANT NUMBER(10) := 0;
FULLY_DELEGATED_TO_ONE 			CONSTANT NUMBER(10) := 1;
FULLY_DELEGATED_TO_MANY 		CONSTANT NUMBER(10) := 2;
                                         
AUDIT_TYPE_DELEGATION 			CONSTANT NUMBER(10) := 10;

LOCK_TYPE_SHEET_CALC 			CONSTANT NUMBER(10) := 2;

FUNCTION HasUnmergedScenario(
	in_app_sid 						IN 	customer.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')	
) RETURN BOOLEAN;

PROCEDURE LockApp(
	in_lock_type 					IN 	app_lock.lock_type%TYPE,
	in_app_sid 						IN 	app_lock.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

PROCEDURE WriteAuditLogEntry(
	in_act_id 						IN 	security_pkg.T_ACT_ID,
	in_audit_type_id 				IN 	audit_log.audit_type_id%TYPE,
	in_app_sid 						IN 	security_pkg.T_SID_ID,
	in_object_sid 					IN 	security_pkg.T_SID_ID,
	in_description 					IN 	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id 				IN 	audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE WriteAuditLogEntryForSid(
	in_sid_id 						IN 	security_pkg.T_SID_ID,
	in_audit_type_id 				IN 	audit_log.audit_type_id%TYPE,
	in_app_sid 						IN 	security_pkg.T_SID_ID,
	in_object_sid 					IN 	security_pkg.T_SID_ID,
	in_description 					IN 	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id 				IN 	audit_log.sub_object_id%TYPE DEFAULT NULL
);

END temp_Csr_Data_Pkg;
/

CREATE OR REPLACE PACKAGE BODY CSR.temp_Csr_Data_Pkg AS

FUNCTION HasUnmergedScenario(
	in_app_sid 						IN 	customer.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')	
)
RETURN BOOLEAN
AS
	v_auto_unmerged_scenarios 		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_auto_unmerged_scenarios
	  FROM DUAL
	 WHERE EXISTS (SELECT 1
	 				 FROM scenario
	 				WHERE auto_update_run_sid IS NOT NULL
	 				  AND app_sid = in_app_sid);
	RETURN v_auto_unmerged_scenarios != 0;
END;

PROCEDURE LockApp(
	in_lock_type 					IN 	app_lock.lock_type%TYPE,
	in_app_sid 						IN 	app_lock.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
AS
BEGIN
	UPDATE app_lock
	   SET dummy = 1
	 WHERE lock_type = in_lock_type
	   AND app_sid = in_app_sid;
	 
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown lock type: '||in_lock_type||' for app_sid:'||in_app_sid);
	END IF;
END;

PROCEDURE WriteAuditLogEntry(
	in_act_id 						IN 	security_pkg.T_ACT_ID,
	in_audit_type_id 				IN 	audit_log.audit_type_id%TYPE,
	in_app_sid 						IN 	security_pkg.T_SID_ID,
	in_object_sid 					IN 	security_pkg.T_SID_ID,
	in_description 					IN 	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id 				IN 	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_user_sid 	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	WriteAuditLogEntryForSid(v_user_sid, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);	
END;

PROCEDURE WriteAuditLogEntryForSid(
	in_sid_id 						IN 	security_pkg.T_SID_ID,
	in_audit_type_id 				IN 	audit_log.audit_type_id%TYPE,
	in_app_sid 						IN 	security_pkg.T_SID_ID,
	in_object_sid 					IN 	security_pkg.T_SID_ID,
	in_description 					IN 	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id 				IN 	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO audit_log
		(AUDIT_DATE, AUDIT_TYPE_ID, app_sid, OBJECT_SID, USER_SID, DESCRIPTION, PARAM_1, PARAM_2, PARAM_3, SUB_OBJECT_ID)
	VALUES
		(SYSDATE, in_audit_type_id, in_app_sid, in_object_sid, in_sid_id, TruncateString(in_description,1023), TruncateString(in_param_1,2048), TruncateString(in_param_2,2048), TruncateString(in_param_3,2048), in_sub_object_id);
END;

END;
/

CREATE OR REPLACE PACKAGE CSR.temp_batch_job_pkg AS

JT_DELEGATION_SYNC					CONSTANT NUMBER := 1;

PROCEDURE Enqueue(
	in_batch_job_type_id			IN	batch_job.batch_job_type_id%TYPE,
	in_description					IN	batch_job.description%TYPE DEFAULT NULL,
	in_email_on_completion			IN	batch_job.email_on_completion%TYPE DEFAULT 0,
	in_total_work					IN	batch_job.total_work%TYPE DEFAULT 0,
	in_requesting_user				IN  batch_job.requested_by_user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_requesting_company			IN  batch_job.requested_by_company_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	in_in_order_group				IN	batch_job.in_order_group%TYPE DEFAULT NULL,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

END;
/

CREATE OR REPLACE PACKAGE BODY CSR.temp_batch_job_pkg AS

PROCEDURE Enqueue(
	in_batch_job_type_id			IN	batch_job.batch_job_type_id%TYPE,
	in_description					IN	batch_job.description%TYPE DEFAULT NULL,
	in_email_on_completion			IN	batch_job.email_on_completion%TYPE DEFAULT 0,
	in_total_work					IN	batch_job.total_work%TYPE DEFAULT 0,
	in_requesting_user				IN  batch_job.requested_by_user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_requesting_company			IN  batch_job.requested_by_company_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	in_in_order_group				IN	batch_job.in_order_group%TYPE DEFAULT NULL,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_priority						batch_job.priority%TYPE;
BEGIN
	SELECT NVL(bjtac.priority, bjt.priority) priority
	  INTO v_priority
	  FROM batch_job_type bjt
	  LEFT JOIN batch_job_type_app_cfg bjtac ON bjt.batch_job_type_id = bjtac.batch_job_type_id
	 WHERE bjt.batch_job_type_id = in_batch_job_type_id;

	-- no security: this is a utility function that other code should call, and that
	-- code should be doing the security checks
	INSERT INTO batch_job
		(batch_job_id, description, batch_job_type_id, email_on_completion, total_work,
		 requested_by_user_sid, requested_by_company_sid, priority, in_order_group)
	VALUES
		(batch_job_id_seq.nextval, in_description, in_batch_job_type_id, in_email_on_completion,
		 in_total_work, in_requesting_user, in_requesting_company, v_priority, in_in_order_group)
	RETURNING
		batch_job_id INTO out_batch_job_id;
END;

END;
/


CREATE OR REPLACE PACKAGE CSR.Temp_Deleg_Plan_Pkg AS

PROCEDURE AddApplyPlanJob(
	in_deleg_plan_sid				IN	deleg_plan_job.deleg_plan_sid%TYPE DEFAULT NULL,
	in_is_dynamic_plan				IN	deleg_plan_job.is_dynamic_plan%TYPE DEFAULT 1,
	in_overwrite_dates				IN	deleg_plan_job.overwrite_dates%TYPE DEFAULT 0,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE AddJob(
	in_delegation_sid				IN	deleg_plan_job.delegation_sid%TYPE DEFAULT NULL,
	in_deleg_plan_sid				IN	deleg_plan_job.deleg_plan_sid%TYPE DEFAULT NULL,
	in_is_dynamic_plan				IN	deleg_plan_job.is_dynamic_plan%TYPE DEFAULT 1,
	in_overwrite_dates				IN	deleg_plan_job.overwrite_dates%TYPE DEFAULT 0,
	in_dynamic_change				IN  BOOLEAN DEFAULT FALSE,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

END;
/

CREATE OR REPLACE PACKAGE BODY CSR.Temp_Deleg_Plan_Pkg AS

PROCEDURE AddApplyPlanJob(
	in_deleg_plan_sid				IN	deleg_plan_job.deleg_plan_sid%TYPE DEFAULT NULL,
	in_is_dynamic_plan				IN	deleg_plan_job.is_dynamic_plan%TYPE DEFAULT 1,
	in_overwrite_dates				IN	deleg_plan_job.overwrite_dates%TYPE DEFAULT 0,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	AddJob(
		in_deleg_plan_sid	=> in_deleg_plan_sid,
		in_is_dynamic_plan	=> in_is_dynamic_plan,
		in_overwrite_dates	=> in_overwrite_dates,
		out_batch_job_id	=> out_batch_job_id
	);
END;

PROCEDURE AddJob(
	in_delegation_sid				IN	deleg_plan_job.delegation_sid%TYPE DEFAULT NULL,
	in_deleg_plan_sid				IN	deleg_plan_job.deleg_plan_sid%TYPE DEFAULT NULL,
	in_is_dynamic_plan				IN	deleg_plan_job.is_dynamic_plan%TYPE DEFAULT 1,
	in_overwrite_dates				IN	deleg_plan_job.overwrite_dates%TYPE DEFAULT 0,
	in_dynamic_change				IN  BOOLEAN DEFAULT FALSE,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_batch_job_id					batch_job.batch_job_id%TYPE;
	v_description					VARCHAR2(4000);
	v_request_as_user_sid			security_pkg.T_SID_ID;
BEGIN
	IF in_dynamic_change THEN
		v_request_as_user_sid := security_pkg.SID_BUILTIN_ADMINISTRATOR;
	ELSE
		v_request_as_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	END IF;

	FOR r IN (SELECT batch_job_id
				FROM batch_job
			   WHERE batch_job_type_id = temp_batch_job_pkg.JT_DELEGATION_SYNC
				 AND completed_dtm IS NULL
				 AND processing = 0
				 AND requested_by_user_sid = v_request_as_user_sid
				 AND batch_job_id IN (
						SELECT batch_job_id
						  FROM deleg_plan_job
						 WHERE (in_delegation_sid IS NOT NULL AND delegation_sid = in_delegation_sid)
							OR (in_deleg_plan_sid IS NOT NULL AND deleg_plan_sid = in_deleg_plan_sid AND
								in_is_dynamic_plan = is_dynamic_plan))
				 FOR UPDATE) LOOP

		UPDATE deleg_plan_job
		   SET overwrite_dates = GREATEST(overwrite_dates, in_overwrite_dates)
		 WHERE batch_job_id = r.batch_job_id;

		out_batch_job_id := r.batch_job_id;
		RETURN;
	END LOOP;

	IF in_delegation_sid IS NOT NULL THEN
		SELECT name
		  INTO v_description
		  FROM delegation
		 WHERE delegation_sid = in_delegation_sid;
	ELSE
		SELECT name
		  INTO v_description
		  FROM deleg_plan
		 WHERE deleg_plan_sid = in_deleg_plan_sid;
	END IF;

	temp_batch_job_pkg.Enqueue(
		in_batch_job_type_id		=> temp_batch_job_pkg.JT_DELEGATION_SYNC,
		in_description				=> v_description,
		in_requesting_user			=> v_request_as_user_sid,
		out_batch_job_id			=> v_batch_job_id
	);

	INSERT INTO deleg_plan_job
		(batch_job_id, delegation_sid, deleg_plan_sid, is_dynamic_plan, overwrite_dates)
	VALUES
		(v_batch_job_id, in_delegation_sid, in_deleg_plan_sid, in_is_dynamic_plan, in_overwrite_dates);

	out_batch_job_id := v_batch_job_id;
END;

END;
/

CREATE OR REPLACE PACKAGE csr.Temp_Delegation_Pkg AS

PROCEDURE SetRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_regions_list		IN	VARCHAR2,
	in_mandatory_list	IN	VARCHAR2
);

FUNCTION IsFullyDelegated(
	in_delegation_sid	IN security_pkg.T_SID_ID
) RETURN NUMBER;

END;
/

CREATE OR REPLACE PACKAGE BODY csr.Temp_Delegation_Pkg AS

PROCEDURE SetRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_regions_list		IN	VARCHAR2,
	in_mandatory_list	IN	VARCHAR2
)
AS
	t_regions				T_SPLIT_TABLE;
	t_mandatories			T_SPLIT_TABLE;
	v_parent_sid			security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_is_fully_delegated	NUMBER;
	v_split_regions			NUMBER;
BEGIN
	-- check permissions - Running as latest
	-- IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		-- RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	-- END IF;

	t_regions := Utils_Pkg.splitString(in_regions_list, ',');

	-- get parent sid
	SELECT parent_sid, app_sid
	  INTO v_parent_sid, v_app_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	-- add jobs for all indicators in the delegations we are changing
	IF temp_csr_data_pkg.HasUnmergedScenario THEN
		temp_csr_data_pkg.LockApp(temp_csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
		  		 FROM delegation_ind di, delegation d
		  		WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		  		  AND di.delegation_sid IN (
		  		  		SELECT delegation_sid
		  		  		  FROM delegation
		  		  		   	   START WITH delegation_sid = in_delegation_sid
		  		  		   	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid)
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	-- <audit>
	-- loop through deleg and child delegs and record deleting regions (can't have a region on a child delegation not on parent)
	FOR r IN (
        SELECT d.delegation_sid, dr.region_sid, dr.description
          FROM delegation d, v$delegation_region dr
         WHERE d.delegation_sid = dr.delegation_sid
         	   START WITH d.delegation_sid = in_delegation_sid AND dr.region_sid IN
            	(SELECT region_sid
			       FROM delegation_region
			      WHERE delegation_sid = in_delegation_sid
			     MINUS
			 	 SELECT TO_NUMBER(item)
			   	   FROM TABLE(t_regions)) -- regions to remove
       		   CONNECT BY PRIOR d.app_sid = d.app_sid
       		   		  AND PRIOR d.delegation_sid = d.parent_sid
           	   		  AND PRIOR dr.region_sid = dr.aggregate_to_region_sid
           	   		  AND PRIOR dr.delegation_sid = d.parent_sid
	)
	LOOP
		temp_csr_data_pkg.WriteAuditLogEntry(in_act_id, temp_csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, r.delegation_sid,
			'Removed region "{0}" ({1})', r.description, r.region_sid);
	END LOOP;

	-- delete stuff from us and all descendants (leaves sheet_values etc for safety)
	DELETE FROM delegation_region_description
	 WHERE (delegation_sid, region_sid) IN (
        SELECT dr.delegation_sid, dr.region_sid
          FROM delegation d, delegation_region dr
         WHERE d.delegation_sid = dr.delegation_sid
         	   START WITH d.delegation_sid = in_delegation_sid AND dr.region_sid IN
            	(SELECT region_sid
			       FROM delegation_region
			      WHERE delegation_sid = in_delegation_sid
			     MINUS
			 	 SELECT TO_NUMBER(item)
			   	   FROM TABLE(t_regions)) -- regions to remove
       		   CONNECT BY PRIOR d.app_sid = d.app_sid
       		   		  AND PRIOR d.delegation_sid = d.parent_sid
           	   		  AND PRIOR dr.region_sid = dr.aggregate_to_region_sid
           	   		  AND PRIOR dr.delegation_sid = d.parent_sid);

	DELETE FROM delegation_region
	 WHERE ROWID IN (
        SELECT dr.ROWID
          FROM delegation d, delegation_region dr
         WHERE d.delegation_sid = dr.delegation_sid
         	   START WITH d.delegation_sid = in_delegation_sid AND dr.region_sid IN
            	(SELECT region_sid
			       FROM delegation_region
			      WHERE delegation_sid = in_delegation_sid
			     MINUS
			 	 SELECT TO_NUMBER(item)
			   	   FROM TABLE(t_regions)) -- regions to remove
       		   CONNECT BY PRIOR d.app_sid = d.app_sid
       		   		  AND PRIOR d.delegation_sid = d.parent_sid
           	   		  AND PRIOR dr.region_sid = dr.aggregate_to_region_sid
           	   		  AND PRIOR dr.delegation_sid = d.parent_sid);

	SELECT COUNT(*)
	  INTO v_split_regions
	  FROM delegation_region
	 WHERE delegation_sid = in_delegation_sid
	   AND aggregate_to_region_sid != region_sid;

	IF v_app_sid = v_parent_sid OR v_split_regions > 0 THEN
		-- <audit>
		-- record adding region to this delegation - get descriptions from region table
		FOR r IN (
		 	SELECT r.region_sid, r.description
			  FROM v$region r,
			 	   (SELECT TO_NUMBER(item) region_sid
			 	      FROM TABLE(t_regions)
					 MINUS
			 		SELECT region_sid
			 		  FROM delegation_region
			 		 WHERE delegation_sid = in_delegation_sid)t
			 WHERE t.region_sid = r.region_sid
		)
		LOOP
			temp_csr_data_pkg.WriteAuditLogEntry(in_act_id, temp_csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid,
				'Added region "{0}" ({1})', r.description, r.region_sid);
		END LOOP;
	ELSE
		-- record adding region to this delegation - get descriptions from delegation_region table
		FOR r IN (
		 	SELECT dr.region_sid, dr.description
			  FROM v$delegation_region dr,
			 		(SELECT TO_NUMBER(item) region_sid
			 		   FROM TABLE(t_regions)
					 MINUS
			 		 SELECT region_sid
			 		   FROM delegation_region
			 		  WHERE delegation_sid = in_delegation_sid) t
			 WHERE t.region_sid = dr.region_sid
			   AND dr.delegation_sid = v_parent_sid
		)
		LOOP
			temp_csr_data_pkg.WriteAuditLogEntry(in_act_id, temp_csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid,
				'Added region "{0}" ({1})', r.description, r.region_sid);
		END LOOP;
	END IF;

	-- what's new? (take pos + description from parent_sid)
	IF v_app_sid = v_parent_sid THEN
		-- top level
		INSERT INTO delegation_region (delegation_sid, region_sid, pos, aggregate_to_region_sid, visibility)
			SELECT in_delegation_sid, r.region_sid, r.pos, r.region_sid, 'SHOW'
			  FROM region r,
				 	(SELECT TO_NUMBER(item) region_sid
				 	   FROM TABLE(t_regions)
					 MINUS
				 	 SELECT region_sid
				 	   FROM delegation_region
				 	  WHERE delegation_sid = in_delegation_sid) t
					  WHERE t.region_sid = r.region_sid;
	ELSE
		-- it's slightly different if our regions are children
		IF v_split_regions > 0 THEN
			INSERT INTO delegation_region (delegation_sid, region_sid, pos, aggregate_to_region_sid, visibility)
			 	SELECT in_delegation_sid, r.region_sid, r.pos, r.parent_sid, 'SHOW' -- TODO: assumes that this goes to parent - be careful
				  FROM region r,
					 	(SELECT TO_NUMBER(item) region_sid
					 	   FROM TABLE(t_regions)
						 MINUS
					 	 SELECT region_sid
					 	   FROM delegation_region
					 	  WHERE delegation_sid = in_delegation_sid) t
				 WHERE t.region_sid = r.region_sid;
		ELSE
			INSERT INTO delegation_region (delegation_sid, region_sid, pos, aggregate_to_region_sid, visibility)
				SELECT in_delegation_sid, dr.region_sid, dr.pos, dr.region_sid, dr.visibility
				  FROM delegation_region dr,
					   (SELECT TO_NUMBER(item) region_sid
					      FROM TABLE(t_regions)
						MINUS
					    SELECT region_sid
					      FROM delegation_region
					     WHERE delegation_sid = in_delegation_sid)t
				 WHERE t.region_sid = dr.region_sid
				   AND dr.delegation_sid = v_parent_sid;

			INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
				SELECT in_delegation_sid, drd.region_sid, drd.lang, drd.description
				  FROM delegation_region_description drd,
					   (SELECT TO_NUMBER(item) region_sid
					      FROM TABLE(t_regions)
						MINUS
					    SELECT region_sid
					      FROM delegation_region
					     WHERE delegation_sid = in_delegation_sid) t
				 WHERE t.region_sid = drd.region_sid
				   AND drd.delegation_sid = v_parent_sid;
		END IF;
	END IF;

	t_mandatories := Utils_Pkg.splitstring(in_mandatory_list, ',');
	UPDATE delegation_region
	   SET mandatory = 0
	 WHERE delegation_sid = in_delegation_sid
	   AND mandatory != 0;

	UPDATE delegation_region
	   SET mandatory = 1
	 WHERE delegation_sid = in_delegation_sid
	   AND region_sid IN (SELECT item FROM TABLE (t_mandatories))
	   AND mandatory != 1;

	-- Clean up any delegations left empty (the UI should have checked for this and asked about it)
	FOR r IN (SELECT delegation_sid
			    FROM delegation d
               WHERE NOT EXISTS (
               			SELECT NULL
               			  FROM delegation_region dr
               			 WHERE d.delegation_sid = dr.delegation_sid)
					  CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
					  START WITH delegation_sid = in_delegation_sid
			   ORDER BY LEVEL DESC
	) LOOP
		SecurableObject_pkg.DeleteSO(in_act_id, r.delegation_sid);
	END LOOP;

	v_is_fully_delegated := temp_delegation_pkg.isFullyDelegated(in_delegation_sid);
	UPDATE delegation
	   SET fully_delegated = v_is_fully_delegated
	 WHERE delegation_sid = in_delegation_sid;

	-- After a region is added to sub delegation, update parent's fully-delegated status
	IF v_app_sid != v_parent_sid THEN
		v_is_fully_delegated := temp_delegation_pkg.isFullyDelegated(v_parent_sid);
		UPDATE delegation
		   SET fully_delegated = v_is_fully_delegated
		 WHERE delegation_sid = v_parent_sid;
	END IF;
END;

FUNCTION IsFullyDelegated(
	in_delegation_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_region_sid					security_pkg.T_SID_ID;
	v_ind_sid						security_pkg.T_SID_ID;
	v_num							NUMBER(10);
	v_not_found						BOOLEAN;
	CURSOR c IS
	  SELECT region_sid, di.ind_sid
	    FROM delegation_region dr
        JOIN delegation_ind di ON di.app_sid = dr.app_sid AND di.delegation_sid = dr.delegation_sid
        JOIN ind i ON i.app_sid = di.app_sid AND i.ind_sid = di.ind_sid
        LEFT JOIN delegation_grid dg ON dg.app_sid = i.app_sid AND dg.ind_sid = i.ind_sid
        LEFT JOIN delegation_plugin dp ON dp.app_sid = i.app_sid AND dp.ind_sid = i.ind_sid
	   WHERE dr.delegation_sid = in_delegation_sid
         AND (
          i.measure_sid IS NOT NULL
          OR
          dg.ind_sid IS NOT NULL
          OR
          dp.ind_sid IS NOT NULL
		) -- we dont' care about cross-headers (i.e. container nodes with no UoM), but we do care about delegations with just grids on them
		 AND NOT (
			di.meta_role IS NOT NULL
			AND
			di.visibility = 'HIDE'
		) -- ignore hidden user performance score inds, they are usually added to the top level delegation only
	 MINUS
	  SELECT aggregate_to_region_sid, ind_sid
	    FROM delegation_region dr, delegation_ind di, delegation d
	   WHERE dr.app_sid = di.app_sid
	     AND dr.app_sid = d.app_sid
	     AND di.app_sid = d.app_sid
	     AND dr.delegation_sid = d.delegation_sid
	     AND di.delegation_sid = d.delegation_sid
		 AND d.parent_sid = in_delegation_sid;
BEGIN
	OPEN c;
	FETCH c INTO v_region_sid, v_ind_sid;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		-- do some more checks
		SELECT COUNT(*) INTO v_num
		  FROM delegation d
		 WHERE d.parent_sid = in_delegation_sid;
		IF v_num > 1 THEN
			RETURN temp_csr_data_pkg.FULLY_DELEGATED_TO_MANY; -- more than 1 sub delegation
		ELSIF v_num = 1 THEN
			RETURN temp_csr_data_pkg.FULLY_DELEGATED_TO_ONE; -- everything delegated to one person
		ELSE
			RETURN temp_csr_data_pkg.NOT_FULLY_DELEGATED; -- No sub delegations so top level delegation
		END IF;
	ELSE
		RETURN temp_csr_data_pkg.NOT_FULLY_DELEGATED;
	END IF;
END;
END;
/
