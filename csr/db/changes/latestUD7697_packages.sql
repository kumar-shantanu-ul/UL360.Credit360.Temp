CREATE OR REPLACE PACKAGE csr.temp_csr_data_pkg AS

IT_APPLIES_TO_AUDIT				CONSTANT NUMBER(10) := 1;

IAT_OPENED						CONSTANT NUMBER(10) := 0;
IAT_ASSIGNED					CONSTANT NUMBER(10) := 1;
IAT_EMAILED_CORRESPONDENT		CONSTANT NUMBER(10) := 2;
IAT_RESOLVED					CONSTANT NUMBER(10) := 3;
IAT_CLOSED						CONSTANT NUMBER(10) := 4;
IAT_REOPENED					CONSTANT NUMBER(10) := 5;
IAT_DUE_DATE_CHANGED			CONSTANT NUMBER(10) := 6;
IAT_EMAILED_USER				CONSTANT NUMBER(10) := 7;
IAT_PRIORITY_CHANGED			CONSTANT NUMBER(10) := 8;
IAT_REJECTED					CONSTANT NUMBER(10) := 9;
IAT_LABEL_CHANGED				CONSTANT NUMBER(10) := 10;
IAT_EMAILED_ROLE				CONSTANT NUMBER(10) := 11;
IAT_EMAIL_RECEIVED				CONSTANT NUMBER(10) := 12;
IAT_ESCALATED					CONSTANT NUMBER(10) := 13;
IAT_ACCEPTED					CONSTANT NUMBER(10) := 14;
IAT_RETURNED					CONSTANT NUMBER(10) := 15;
IAT_PENDING_ASSIGN_CONF			CONSTANT NUMBER(10) := 16;
IAT_DESCRIPTION_CHANGED			CONSTANT NUMBER(10) := 17;
IAT_FORECAST_DATE_CHANGED		CONSTANT NUMBER(10) := 18;
IAT_RAG_STARUS_CHANGED			CONSTANT NUMBER(10) := 19;
IAT_EXPLAINED_VARIANCE			CONSTANT NUMBER(10) := 20;
IAT_OWNER_CHANGED				CONSTANT NUMBER(10) := 21;
IAT_REGION_CHANGED				CONSTANT NUMBER(10) := 22;
IAT_CRIT_CHANGED				CONSTANT NUMBER(10) := 23;
IAT_DELETED						CONSTANT NUMBER(10) := 24;

NON_COMP_CLOSURE_MANUAL			CONSTANT NUMBER(10) := 1;
NON_COMP_CLOSURE_AUTOMATIC		CONSTANT NUMBER(10) := 2;
NON_COMP_CLOSURE_ALWAYS_CLOSED	CONSTANT NUMBER(10) := 3;

PROCEDURE LockApp(
	in_lock_type					IN	app_lock.lock_type%TYPE,
	in_app_sid						IN	app_lock.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

FUNCTION SQL_CheckCapability(
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER;

FUNCTION SQL_CheckCapability(
    in_act_Id                   	IN  security_pkg.T_ACT_ID,
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER;

FUNCTION CheckCapability(
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN;

FUNCTION CheckCapability(
	in_act_id      					IN 	security_pkg.T_ACT_ID,
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN;

END temp_csr_data_pkg;
/


CREATE OR REPLACE PACKAGE BODY csr.temp_csr_data_pkg AS

PROCEDURE LockApp(
	in_lock_type					IN	app_lock.lock_type%TYPE,
	in_app_sid						IN	app_lock.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
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

FUNCTION SQL_CheckCapability(
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER
AS
BEGIN
	IF CheckCapability(SYS_CONTEXT('SECURITY','ACT'), in_capability) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION SQL_CheckCapability(
    in_act_Id                   	IN  security_pkg.T_ACT_ID,
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER
AS
BEGIN
	IF CheckCapability(in_act_id, in_capability) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION CheckCapability(
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN
AS
BEGIN
    RETURN CheckCapability(SYS_CONTEXT('SECURITY','ACT'), in_capability);
END;

FUNCTION CheckCapability(
	in_act_id      					IN 	security_pkg.T_ACT_ID,
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN
AS
    v_allow_by_default      capability.allow_by_default%TYPE;
	v_capability_sid        security_pkg.T_SID_ID;
BEGIN
    -- this also serves to check that the capability is valid
    BEGIN
        SELECT allow_by_default
          INTO v_allow_by_default
          FROM capability
         WHERE LOWER(name) = LOWER(in_capability);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
	END;
	
	BEGIN
		-- get sid of capability to check permission
		v_capability_sid := securableobject_pkg.GetSIDFromPath(in_act_id, SYS_CONTEXT('SECURITY','APP'), '/Capabilities/' || in_capability);
		-- check permissions....
		RETURN Security_Pkg.IsAccessAllowedSID(in_act_id, v_capability_sid, security_pkg.PERMISSION_WRITE);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
            IF v_allow_by_default = 1 THEN
                RETURN TRUE; -- let them do it if it's not configured
            ELSE
                RETURN FALSE;
            END IF;
	END;
END;

END;
/


CREATE OR REPLACE PACKAGE csr.temp_audit_pkg AS

PROCEDURE UpdateNonCompClosureStatus (
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE
);

END temp_audit_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_audit_pkg AS

PROCEDURE UpdateNonCompClosureStatus (
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE
)
AS
	v_closure_behaviour			non_compliance_type.closure_behaviour_id%TYPE;
	v_open_issue_count			NUMBER;
	v_total_issue_count			NUMBER;
BEGIN
	BEGIN
		SELECT nct.closure_behaviour_id
		  INTO v_closure_behaviour
		  FROM non_compliance nc
		  JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
		 WHERE nc.non_compliance_id = in_non_compliance_id;
	EXCEPTION
		WHEN no_data_found THEN
			v_closure_behaviour := NULL;
	END;

	IF v_closure_behaviour = temp_csr_data_pkg.NON_COMP_CLOSURE_ALWAYS_CLOSED THEN
		UPDATE non_compliance
		   SET is_closed = 1
		 WHERE non_compliance_id = in_non_compliance_id;
	ELSIF v_closure_behaviour = temp_csr_data_pkg.NON_COMP_CLOSURE_AUTOMATIC THEN
		SELECT COUNT(*), COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END)
		  INTO v_total_issue_count, v_open_issue_count
		  FROM issue_non_compliance inc
		  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
		 WHERE i.deleted = 0
		   AND inc.non_compliance_id = in_non_compliance_id;

		UPDATE non_compliance
		   SET is_closed = CASE WHEN v_open_issue_count = 0 AND v_total_issue_count > 0 THEN 1 ELSE 0 END
		 WHERE non_compliance_id = in_non_compliance_id;
	END IF;
END;

END;
/



CREATE OR REPLACE PACKAGE csr.temp_batch_job_pkg AS

JT_DATA_BUCKET_AGG_IND				CONSTANT NUMBER := 93;

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

END temp_batch_job_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_batch_job_pkg AS

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





CREATE OR REPLACE PACKAGE csr.temp_aggregate_ind_pkg AS

PROCEDURE TriggerDataBucketJob(
	in_aggregate_ind_group_id	IN	batch_job_data_bucket_agg_ind.aggregate_ind_group_id%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
);

END temp_aggregate_ind_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_aggregate_ind_pkg AS

PROCEDURE TriggerDataBucketJob(
	in_aggregate_ind_group_id	IN	batch_job_data_bucket_agg_ind.aggregate_ind_group_id%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_bucket_sid		data_bucket.data_bucket_sid%TYPE;
BEGIN
	
	SELECT data_bucket_sid
	  INTO v_bucket_sid
	  FROM aggregate_ind_group
	 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_bucket_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot trigger data bucket job for aggregate ind group '||in_aggregate_ind_group_id||' because it does not have a linked data bucket.');
	END IF;
	
	BEGIN
		SELECT batch_job_id
		  INTO out_batch_job_id
		  FROM agg_ind_data_bucket_pending_job
		 WHERE data_bucket_sid = v_bucket_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			temp_batch_job_pkg.Enqueue(
				in_batch_job_type_id	=> temp_batch_job_pkg.JT_DATA_BUCKET_AGG_IND,
				out_batch_job_id		=> out_batch_job_id);

			INSERT INTO batch_job_data_bucket_agg_ind
				(batch_job_id, data_bucket_sid, aggregate_ind_group_id)
			VALUES
				(out_batch_job_id, v_bucket_sid, in_aggregate_ind_group_id);
			
			INSERT INTO agg_ind_data_bucket_pending_job
				(batch_job_id, data_bucket_sid)
			VALUES
				(out_batch_job_id, v_bucket_sid);
	END;
END;

END;
/






CREATE OR REPLACE PACKAGE csr.temp_calc_pkg AS

PROCEDURE AddCalcJobsForAggregateIndGroup(
	in_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
);

PROCEDURE AddJobsForAggregateIndGroup(
	in_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
);

PROCEDURE AddJobsForAggregateIndGroup(
	in_name							aggregate_ind_group.name%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
);

END temp_calc_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_calc_pkg AS

PROCEDURE AddCalcJobsForAggregateIndGroup(
	in_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;	
BEGIN
	temp_csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	SELECT LEAST(calc_end_dtm, GREATEST(calc_start_dtm, NVL(in_start_dtm, calc_start_dtm))),
		   LEAST(calc_end_dtm, GREATEST(calc_start_dtm, NVL(in_end_dtm, calc_end_dtm)))
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	MERGE /*+ALL_ROWS*/ INTO aggregate_ind_calc_job aicj
	USING (SELECT 1
			 FROM dual) r
		   ON (aicj.aggregate_ind_group_id = in_aggregate_ind_group_id)
		 WHEN MATCHED THEN
			UPDATE
			   SET aicj.start_dtm = LEAST(aicj.start_dtm, v_calc_start_dtm),
				   aicj.end_dtm = GREATEST(aicj.end_dtm, v_calc_end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (aicj.aggregate_ind_group_id, aicj.start_dtm, aicj.end_dtm)
			VALUES (in_aggregate_ind_group_id, v_calc_start_dtm, v_calc_end_dtm);
END;

PROCEDURE AddJobsForAggregateIndGroup(
	in_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
	v_bucket_sid					aggregate_ind_group.data_bucket_sid%TYPE;
	v_batch_job_id					batch_job.batch_job_id%TYPE;
BEGIN

	SELECT data_bucket_sid
	  INTO v_bucket_sid
	  FROM aggregate_ind_group
	 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF v_bucket_sid IS NULL THEN
		temp_calc_pkg.AddCalcJobsForAggregateIndGroup(
			in_aggregate_ind_group_id		=> in_aggregate_ind_group_id,
			in_start_dtm					=> in_start_dtm,
			in_end_dtm						=> in_end_dtm
		);
	ELSE
		temp_aggregate_ind_pkg.TriggerDataBucketJob(
			in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
			out_batch_job_id 			=> v_batch_job_id
		);
	END IF;
	
END;

PROCEDURE AddJobsForAggregateIndGroup(
	in_name							aggregate_ind_group.name%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
)
AS
	v_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	BEGIN
		SELECT aggregate_ind_group_id
		  INTO v_aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND upper(name) = upper(in_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'No aggregate_ind_group of name: '||in_name);
	END;
	
	AddJobsForAggregateIndGroup(v_aggregate_ind_group_id, in_start_dtm, in_end_dtm);
END;

END;
/




CREATE OR REPLACE PACKAGE csr.temp_issue_pkg AS

PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
);

PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  BOOLEAN,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
);

PROCEDURE LogAction (
	in_issue_action_type_id			IN  NUMBER,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_log_id					IN  issue_log.issue_log_id%TYPE DEFAULT NULL,
	in_user_sid						IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_user_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_correspondent_id				IN  correspondent.correspondent_id%TYPE DEFAULT NULL,
	out_issue_action_log_id			OUT issue_action_log.issue_action_log_id%TYPE
);

PROCEDURE LogAction (
	in_issue_action_type_id			IN  NUMBER,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_log_id					IN  issue_log.issue_log_id%TYPE DEFAULT NULL,
	in_user_sid						IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_user_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_correspondent_id				IN  correspondent.correspondent_id%TYPE DEFAULT NULL
);

PROCEDURE AddUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE AddUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_is_an_owner			IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION IsAccessAllowed(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN;

FUNCTION IsOwner(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN;

END temp_issue_pkg;
/


CREATE OR REPLACE PACKAGE BODY csr.temp_issue_pkg AS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

PROCEDURE INTERNAL_CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_issue_id			IN	issue.issue_id%TYPE
)
AS
	v_helper_pkg		issue_type.helper_pkg%TYPE;
BEGIN
	-- call helper proc if there is one, to setup custom forms
	BEGIN
		SELECT it.helper_pkg
		  INTO v_helper_pkg
		  FROM issue i
		  JOIN issue_type it
		    ON i.issue_type_id = it.issue_type_id
		 WHERE i.issue_id = in_issue_id
		   AND i.app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN no_data_found THEN
			null;
	END;
	
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1);end;'
				USING in_issue_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE INTERNAL_CreateRefID_Issue(
	in_issue_id		IN	security_pkg.T_SID_ID
)
AS
	v_issue_ref_helper_func		csr.issue_type.internal_issue_ref_helper_func%TYPE;
	v_generated_number			NUMBER;
BEGIN
	-- Get the helper function to generate id
	SELECT it.internal_issue_ref_helper_func
	  INTO v_issue_ref_helper_func
	  FROM issue i
	  JOIN issue_type it
		ON it.issue_type_id = i.issue_type_id AND it.app_sid = i.app_sid
	 WHERE i.app_sid = security.security_pkg.GetApp
	   AND i.issue_id = in_issue_id;
	
	IF v_issue_ref_helper_func IS NOT NULL THEN	
		--todo: use PROC_NOT_FOUND (-06550) instead
		IF aspen2.utils_pkg.INTERNAL_FunctionExists(v_issue_ref_helper_func) THEN
			
			EXECUTE IMMEDIATE 'BEGIN :1 := ' || v_issue_ref_helper_func || '; END;' USING IN OUT v_generated_number; 	

			UPDATE csr.issue
			   SET issue_ref = v_generated_number
			 WHERE app_sid = security.security_pkg.GetApp
			   AND issue_id = in_issue_id;	
		ELSE 
			RAISE_APPLICATION_ERROR(-20001, 'Defined helper function could not be found: ' ||v_issue_ref_helper_func || ' (see csr.issue_type.internal_issue_ref_helper_func)' );
		END IF;
	END IF;
	
END;

PROCEDURE INTERNAL_StatusChanged (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_issue_action_type_id		IN  NUMBER
)
AS
	v_issue_type_id				issue.issue_type_id%TYPE;
	v_raised_dtm				issue.raised_dtm%TYPE;
	v_resolved_dtm				issue.resolved_dtm%TYPE;
	v_manual_completion_dtm		issue.manual_completion_dtm%TYPE;
	v_rejected_dtm				issue.rejected_dtm%TYPE;
	v_min_audit_dtm				internal_audit.audit_dtm%TYPE;
	v_max_audit_dtm				internal_audit.audit_dtm%TYPE;
	v_issue_non_compliance_id	issue.issue_non_compliance_id%TYPE;
	v_applies_to_audit			issue_type.applies_to_audit%TYPE;
BEGIN
	SELECT i.issue_type_id, i.raised_dtm, i.resolved_dtm, i.manual_completion_dtm, i.rejected_dtm, i.issue_non_compliance_id, it.applies_to_audit
	  INTO v_issue_type_id, v_raised_dtm, v_resolved_dtm, v_manual_completion_dtm, v_rejected_dtm, v_issue_non_compliance_id, v_applies_to_audit
	  FROM issue i
	  JOIN issue_type it ON i.issue_type_id = it.issue_type_id
	 WHERE issue_id = in_issue_id;
	
	IF v_manual_completion_dtm IS NOT NULL THEN
		-- Manual completion date takes precedence over resolved date.
		v_resolved_dtm := v_manual_completion_dtm;
	END IF;

	IF v_applies_to_audit = temp_csr_data_pkg.IT_APPLIES_TO_AUDIT THEN
		FOR r IN (
			SELECT non_compliance_id
			  FROM issue_non_compliance
			 WHERE issue_non_compliance_id = v_issue_non_compliance_id
		) LOOP
			temp_audit_pkg.UpdateNonCompClosureStatus(r.non_compliance_id);
		END LOOP;
	END IF;
	
	FOR r IN (
		SELECT aggregate_ind_group_id
		  FROM issue_type_aggregate_ind_grp
		 WHERE issue_type_id = v_issue_type_id
	) LOOP
		IF v_applies_to_audit = temp_csr_data_pkg.IT_APPLIES_TO_AUDIT THEN
			BEGIN
				SELECT MIN(ia.audit_dtm), MAX(ia.audit_dtm)
				  INTO v_min_audit_dtm, v_max_audit_dtm
				  FROM internal_audit ia
				  JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid
				  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id
				  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
				 WHERE i.issue_id = in_issue_id;
				
				-- Issue might not have a non_compliance_id yet
				IF v_min_audit_dtm IS NOT NULL THEN
					temp_calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id,
						TRUNC(LEAST(v_raised_dtm, v_min_audit_dtm), 'MONTH'),
						ADD_MONTHS(TRUNC(GREATEST(NVL(v_resolved_dtm, v_raised_dtm), v_max_audit_dtm), 'MONTH'), 1));
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
		ELSE
			temp_calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id,
				TRUNC(NVL(LEAST(v_rejected_dtm, v_resolved_dtm, v_raised_dtm), v_raised_dtm), 'MONTH'),
				ADD_MONTHS(TRUNC(NVL(LEAST(v_rejected_dtm, v_resolved_dtm, v_raised_dtm), v_raised_dtm), 'MONTH'), 1));
		END IF;
	END LOOP;
	
	-- call helper procedures on certain events
	IF in_issue_action_type_id = temp_csr_data_pkg.IAT_OPENED THEN	
		INTERNAL_CallHelperPkg('IssueOpened', in_issue_id);
		INTERNAL_CreateRefID_Issue(in_issue_id);
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_CLOSED THEN
		INTERNAL_CallHelperPkg('IssueClosed', in_issue_id);
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_RESOLVED THEN
		INTERNAL_CallHelperPkg('IssueResolved', in_issue_id);
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_REJECTED THEN
		INTERNAL_CallHelperPkg('IssueRejected', in_issue_id);
	END IF;		
END;

PROCEDURE INTERNAL_AddUserLogEntry(
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  BOOLEAN,
	in_prevent_reopen			IN  BOOLEAN,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS	
	v_issue_log_count			NUMBER;
	v_dummy_cur					SYS_REFCURSOR;
BEGIN
	-- if this isn't system generated, then mark all previous entries as read
	IF in_is_system_generated = 0 THEN
		INSERT INTO issue_log_read
			(issue_log_id, csr_user_sid)
			SELECT issue_log_id, in_user_sid
			  FROM issue_log
			 WHERE issue_id = in_issue_id
			 MINUS -- subtract stuff they've read to avoid constraint violations
			SELECT issue_log_id, in_user_sid -- bit overkill since it subtracts all things a user has read
			  FROM issue_log_read
			 WHERE csr_user_sid = in_user_sid;
	END IF;
	
	INSERT INTO issue_log
		(issue_log_id, issue_id, message, logged_by_user_sid, logged_dtm, is_system_generated,
			param_1, param_2, param_3)
	VALUES
		(issue_log_id_seq.nextval, in_issue_id, in_message, in_user_sid, SYSDATE, in_is_system_generated,
			in_param_1, in_param_2, in_param_3)
	RETURNING issue_log_id
	     INTO out_issue_log_id;
		 
	SELECT COUNT(*)
	  INTO v_issue_log_count
	  FROM issue_log
	 WHERE issue_id = in_issue_id;
		 
	UPDATE issue
	   SET first_issue_log_id = CASE WHEN v_issue_log_count = 1 THEN out_issue_log_id ELSE first_issue_log_id END,
	       last_issue_log_id = out_issue_log_id
	 WHERE issue_id = in_issue_id
	   AND app_sid = security_pkg.GetApp;
	     
	IF NOT in_prevent_reopen THEN
		UPDATE issue 
		   SET resolved_by_user_sid = null, 
				resolved_dtm = null,
				closed_by_user_sid = null,
				closed_dtm = null,
				rejected_by_user_sid = null,
				rejected_dtm = null,
				correspondent_notified = 0,
				manual_completion_dtm = null,
				manual_comp_dtm_set_dtm = null
		 WHERE issue_id = in_issue_id
		   AND (resolved_by_user_sid IS NOT NULL OR closed_by_user_sid IS NOT NULL OR rejected_by_user_sid IS NOT NULL);

		IF SQL%ROWCOUNT > 0 THEN
			LogAction(csr_data_pkg.IAT_REOPENED, in_issue_id, out_issue_log_id);
			INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_REOPENED);
		END IF;
	END IF;
	
	IF NOT in_prevent_reassign THEN

		AddUser(security_pkg.GetAct, in_issue_id, in_user_sid, v_dummy_cur);

		UPDATE issue
		   SET assigned_to_user_sid = in_user_sid,
			   assigned_to_role_sid = NULL
		 WHERE issue_id = in_issue_id
		   AND assigned_to_role_sid IS NOT NULL;

		IF SQL%ROWCOUNT > 0 THEN
			LogAction(csr_data_pkg.IAT_ASSIGNED, in_issue_id, out_issue_log_id);
		END IF;
	END IF;
END;

PROCEDURE INTERNAL_AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  BOOLEAN,
	in_prevent_reopen			IN  BOOLEAN,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
	v_user_sid			security_pkg.T_SID_ID := 3;
BEGIN
	INTERNAL_AddUserLogEntry(v_user_sid, in_issue_id, in_is_system_generated, in_message, in_param_1, in_param_2, in_param_3, in_prevent_reassign, in_prevent_reopen, out_issue_log_id);
END;

PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  BOOLEAN,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	INTERNAL_AddLogEntry(in_act_id, in_issue_id, in_is_system_generated, in_message, in_param_1, in_param_2, in_param_3, in_prevent_reassign, FALSE, out_issue_log_id);
END;

PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
BEGIN
	AddLogEntry(in_act_id, in_issue_id, in_is_system_generated, in_message, in_param_1, in_param_2, in_param_3, in_is_system_generated = 1, out_issue_log_id);
END;

PROCEDURE LogAction (
	in_issue_action_type_id			IN  NUMBER,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_log_id					IN  issue_log.issue_log_id%TYPE DEFAULT NULL,
	in_user_sid						IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_user_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_correspondent_id				IN  correspondent.correspondent_id%TYPE DEFAULT NULL,
	out_issue_action_log_id			OUT issue_action_log.issue_action_log_id%TYPE
)
AS
	v_assigned_to_user_sid			security_pkg.T_SID_ID;
	v_assigned_to_role_sid			security_pkg.T_SID_ID;
	v_owned_by_sid					security_pkg.T_SID_ID;
	v_user_sid						security_pkg.T_SID_ID DEFAULT in_user_sid;
	v_old_due_dtm					issue_action_log.old_due_dtm%TYPE;
	v_new_due_dtm					issue_action_log.new_due_dtm%TYPE;
	v_old_forecast_dtm				issue_action_log.old_due_dtm%TYPE;
	v_new_forecast_dtm				issue_action_log.new_due_dtm%TYPE;
	v_old_priority_id				issue_action_log.old_priority_id%TYPE;
	v_new_priority_id				issue_action_log.new_priority_id%TYPE;
	v_old_label						issue_action_log.old_label%TYPE;
	v_new_label						issue_action_log.new_label%TYPE;
	v_old_description				issue_action_log.old_description%TYPE;
	v_new_description				issue_action_log.new_description%TYPE;
	v_old_region_sid				issue_action_log.old_region_sid%TYPE;
	v_new_region_sid				issue_action_log.new_region_sid%TYPE;
	v_new_man_comp_dtm_set_dtm		issue_action_log.new_manual_comp_dtm_set_dtm%TYPE;
	v_new_manual_comp_dtm			issue_action_log.new_manual_comp_dtm%TYPE;
BEGIN
	IF v_user_sid IS NULL AND in_correspondent_id IS NULL THEN
		v_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	END IF;
	
	-- if it's an assignment action, look at who the issue is assigned to
	IF in_issue_action_type_id = temp_csr_data_pkg.IAT_ASSIGNED OR
	   in_issue_action_type_id = temp_csr_data_pkg.IAT_PENDING_ASSIGN_CONF THEN
	
		SELECT assigned_to_user_sid, assigned_to_role_sid
		  INTO v_assigned_to_user_sid, v_assigned_to_role_sid
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
		
		INTERNAL_CallHelperPkg('IssueAssigned', in_issue_id);
		   
	-- if it's an owner changing action, look at who the issue is owned by
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_OWNER_CHANGED THEN
	
		SELECT owner_user_sid
		  INTO v_owned_by_sid
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the due date, grab the change
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_DUE_DATE_CHANGED THEN
	
		SELECT last_due_dtm, due_dtm
		  INTO v_old_due_dtm, v_new_due_dtm
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the forecast date, grab the change
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_FORECAST_DATE_CHANGED THEN
	
		SELECT last_forecast_dtm, forecast_dtm
		  INTO v_old_forecast_dtm, v_new_forecast_dtm
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the priority, grab the change
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_PRIORITY_CHANGED THEN
	
		SELECT last_issue_priority_id, issue_priority_id
		  INTO v_old_priority_id, v_new_priority_id
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the label, grab the change
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_LABEL_CHANGED THEN
	
		SELECT last_label, label
		  INTO v_old_label, v_new_label
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the description, grab the change
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_DESCRIPTION_CHANGED THEN
	
		SELECT last_description, description
		  INTO v_old_description, v_new_description
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the region, grab the change
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_REGION_CHANGED THEN
	
		SELECT i.last_region_sid, i.region_sid
		  INTO v_old_region_sid, v_new_region_sid
		  FROM issue i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.issue_id = in_issue_id;
	-- We're resolving the issue. Grab the manually completed date.
	ELSIF in_issue_action_type_id = temp_csr_data_pkg.IAT_RESOLVED THEN
		SELECT manual_comp_dtm_set_dtm, manual_completion_dtm
		  INTO v_new_man_comp_dtm_set_dtm, v_new_manual_comp_dtm
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	END IF;
	
	INSERT INTO issue_action_log(
		issue_action_log_id, issue_action_type_id, issue_id, 
		issue_log_id, logged_by_user_sid, logged_by_correspondent_id, 
		assigned_to_role_sid, assigned_to_user_sid, re_user_sid, re_role_sid,
		owner_user_sid,
		old_due_dtm, new_due_dtm,
		old_forecast_dtm, new_forecast_dtm,
		old_priority_id, new_priority_id,
		old_label, new_label,
		old_description, new_description,
		old_region_sid, new_region_sid,
		new_manual_comp_dtm_set_dtm, new_manual_comp_dtm
	)
	VALUES(
		issue_action_log_id_seq.NEXTVAL, in_issue_action_type_id, in_issue_id, 
		in_issue_log_id, v_user_sid, in_correspondent_id, 
		v_assigned_to_role_sid, v_assigned_to_user_sid, in_re_user_sid, in_re_role_sid,
		v_owned_by_sid,
		v_old_due_dtm, v_new_due_dtm,
		v_old_forecast_dtm, v_new_forecast_dtm,
		v_old_priority_id, v_new_priority_id,
		v_old_label, v_new_label,
		v_old_description, v_new_description,
		v_old_region_sid, v_new_region_sid,
		v_new_man_comp_dtm_set_dtm, v_new_manual_comp_dtm
	) RETURNING issue_action_log_id INTO out_issue_action_log_id;	
END;

PROCEDURE LogAction (
	in_issue_action_type_id			IN  NUMBER,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_log_id					IN  issue_log.issue_log_id%TYPE DEFAULT NULL,
	in_user_sid						IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_user_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_correspondent_id				IN  correspondent.correspondent_id%TYPE DEFAULT NULL
)
AS
	v_action_log_id					issue_action_log.issue_action_log_id%TYPE;
BEGIN
	LogAction(in_issue_action_type_id, in_issue_id, in_issue_log_id, in_user_sid, in_re_user_sid, in_re_role_sid, in_correspondent_id, v_action_log_id);
END;

PROCEDURE AddUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	AddUser(in_act_id, in_issue_id, in_user_sid, 0, out_cur);
END;

/**
 * Links an Issue to Users in an array
 *
 * @param	in_act_id			Access token
 * @param	in_issue_id			The issue to link
 * @param	in_user_sid			User to link to
 */
PROCEDURE AddUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_is_an_owner			IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT temp_issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	
	BEGIN
		INSERT INTO issue_involvement
			(issue_id, is_an_owner, user_sid)
		VALUES
			(in_issue_id, in_is_an_owner, in_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if the user is alreaday assigned
	END;
	
	chain.filter_pkg.ClearCacheForUser (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES,
		in_user_sid => in_user_sid
	);
	
	OPEN out_cur FOR
		SELECT ii.user_sid, ii.is_an_owner, cu.user_name, cu.full_name, cu.friendly_name, cu.email,
			CASE WHEN it.owner_can_be_changed = 1 AND (i.raised_by_user_sid = cu.csr_user_sid OR csr_data_pkg.SQL_CheckCapability('Issue management') = 1) THEN 1 ELSE 0 END can_change_owner_of_issue
		  FROM csr_user cu
		  JOIN issue_involvement ii
		    ON ii.issue_id = in_issue_id 
		   AND ii.user_sid = in_user_sid
		   AND ii.user_sid = cu.csr_user_sid
		  JOIN issue i
		    ON i.app_sid = ii.app_sid 
		   AND i.issue_id = ii.issue_id
		  JOIN issue_type it
		    ON it.app_sid = ii.app_sid 
		   AND it.issue_type_id = i.issue_type_id
		 WHERE cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR;
END;

FUNCTION IsAccessAllowed(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_cnt		NUMBER(10);
BEGIN
	-- check if user is owner of issue or Built-in admin (for batch processes)
	IF IsOwner(in_act_id, in_issue_id) OR security_pkg.IsAdmin(in_act_id) THEN
		RETURN TRUE;
	END IF;
	
	-- now check capability (i.e. useful for Admins etc)
	IF temp_csr_data_pkg.CheckCapability(in_act_id, 'Issue management') THEN
		RETURN TRUE;
	END IF;

	-- okay -- if they're involved or they line manage someone who
	-- is involved then they can do stuff to an issue (apart from delete it)
	user_pkg.GetSID(in_act_id, v_user_sid);
	
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM issue i
	  JOIN csr_user cu ON i.assigned_to_user_sid = cu.csr_user_sid
	 WHERE i.issue_id = in_issue_id
	   AND (i.assigned_to_user_sid = v_user_sid
	    OR cu.line_manager_sid = v_user_sid);
	   
	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;

	-- This view includes involved roles
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM v$issue_involved_user iiu
	  JOIN csr_user cu ON iiu.user_sid = cu.csr_user_sid
	 WHERE iiu.issue_id = in_issue_id
	   AND (iiu.user_sid = v_user_sid
	    OR cu.line_manager_sid = v_user_sid);
	   
	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;
	
	-- Check involved companies
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue_involvement
	 WHERE issue_id = in_issue_id
	   AND company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY');
	
	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;
	
	-- If we have any involved users/roles then this is an issue with the new behaviour
	-- Someone with better knowledge of the system should update old issues with involved users based on action log
	-- so we can get rid of that last piece of query (I think).
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM v$issue_involved_user iiu
	 WHERE iiu.issue_id = in_issue_id;
	 
	IF v_cnt > 0 THEN
		RETURN FALSE;
	END IF;
	
	-- Old behaviour on previously assigned to roles (new behaviour keeps these
	-- as involved roles)
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue i, issue_action_log ial, region_role_member rrm
	 WHERE i.issue_id = in_issue_id
	   AND i.issue_id = ial.issue_id
	   AND i.region_sid = rrm.region_sid
	   AND ial.assigned_to_role_sid = rrm.role_sid
	   AND rrm.user_sid = v_user_sid;
	
	RETURN v_cnt > 0;
END;

FUNCTION IsOwner(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_cnt		NUMBER(10);
BEGIN
	-- okay -- if they're involved then they can do stuff to an issue (apart from delete it)
	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- are they the issue owner (by user)?
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue
	 WHERE issue_id = in_issue_id
	   AND owner_user_sid = v_user_sid;
	
	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;

	-- are they the issue owner (by role)?
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue i, region_role_member rrm
	 WHERE i.issue_id = in_issue_id
	   AND i.region_sid = rrm.region_sid
	   AND i.owner_role_sid = rrm.role_sid
	   AND rrm.user_sid = v_user_sid;

	RETURN v_cnt > 0;
END;

END;
/