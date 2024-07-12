CREATE OR REPLACE PACKAGE BODY CSR.RULESET_PKG AS

-- changing the underlying rule needs to trigger re-running

-- Securable object callbacks for CAUSE_SET (a cause_set is something like 'Health and Safety')
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM ruleset_run_finding
	 WHERE ruleset_sid = in_sid_id;
	 
	DELETE FROM ruleset_run
	 WHERE ruleset_sid = in_sid_id;
	 
	DELETE FROM ruleset_member
	 WHERE ruleset_sid = in_sid_id;
	 
	DELETE FROM ruleset
	 WHERE ruleset_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE CloneRuleSet(
	in_name 						IN  security_pkg.T_SO_NAME,
	in_clone_ruleset_sid			IN  security_pkg.T_SID_ID,   
	in_new_reporting_period_sid		IN  security_pkg.T_SID_ID,
	out_new_ruleset_sid				OUT security_pkg.T_SID_ID
)
AS
	v_period_set_id					ruleset.period_set_id%TYPE;
	v_period_interval_id			ruleset.period_interval_id%TYPE;
BEGIN
	SELECT period_set_id, period_interval_id 
	  INTO v_period_set_id, v_period_interval_id
	  FROM ruleset
	 WHERE ruleset_sid = in_clone_ruleset_sid;

	CreateRuleSet(in_name, in_new_reporting_period_sid, v_period_set_id, v_period_interval_id, 1, out_new_ruleset_sid);
	
	INSERT INTO ruleset_member (ruleset_sid, ind_sid)
		SELECT out_new_ruleset_sid, ind_sid
		  FROM ruleset_member
		 WHERE ruleset_sid = in_clone_ruleset_sid;

	INSERT INTO ruleset_run (ruleset_sid, region_sid, last_run_dtm)
		SELECT out_new_ruleset_sid, region_sid, NULL
		  FROM ruleset_run
		 WHERE ruleset_sid = in_clone_ruleset_sid;
END;

PROCEDURE CreateRuleSet(
	in_name						IN	security_pkg.T_SO_NAME,
	in_reporting_period_sid		IN  security_pkg.T_SID_ID   		DEFAULT null,
	in_period_set_id			IN 	ruleset.period_set_id%TYPE 		DEFAULT 1,
	in_period_interval_id		IN 	ruleset.period_interval_id%TYPE DEFAULT 4,
    in_enabled                  IN  NUMBER                  		DEFAULT 1,
    out_ruleset_sid             OUT	security_pkg.T_SID_ID
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
	v_reporting_period_sid	security_pkg.T_SID_ID;
BEGIN
	v_parent_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, security_pkg.getApp, 'RuleSets');

	 IF in_reporting_period_sid IS NULL THEN
	 	-- default
		SELECT current_reporting_period_sid
		  INTO v_reporting_period_sid
		  FROM customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 ELSE
	 	v_reporting_period_sid := in_reporting_period_sid;
	 END IF;

	-- security check gets done in here
	securableobject_pkg.CreateSO(security_pkg.getACT,
		v_parent_sid, 
		class_pkg.getClassID('CSRRuleSet'),
		REPLACE(in_name,'/','\'), --'
		out_ruleset_sid);	
	
	csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp, 
		out_ruleset_sid,
		'Created ruleset "{0}"', 
		in_name);

	INSERT INTO ruleset (ruleset_sid, name, reporting_period_sid,
		period_set_id, period_interval_id, enabled)
	VALUES (out_ruleset_sid, in_name, v_reporting_period_sid,
		in_period_set_id, in_period_interval_id, in_enabled);
END;

PROCEDURE CreateRuleSetReturnCursor(
	in_name						IN	security_pkg.T_SO_NAME,
	in_reporting_period_sid		IN  security_pkg.T_SID_ID   		DEFAULT null,
	in_period_set_id			IN 	ruleset.period_set_id%TYPE 		DEFAULT 1,
	in_period_interval_id		IN 	ruleset.period_interval_id%TYPE DEFAULT 4,
    in_enabled                  IN  NUMBER                  		DEFAULT 1,
    out_cur                     OUT	SYS_REFCURSOR
)
AS
    v_out_ruleset_sid           security_pkg.T_SID_ID;
BEGIN
    CreateRuleSet(in_name, in_reporting_period_sid, in_period_set_id,
    	in_period_interval_id, in_enabled, v_out_ruleset_sid);
    
    OPEN out_cur FOR
        SELECT rs.ruleset_sid, rs.name, rs.reporting_period_sid, rp.name AS reporting_period,
        	   rs.period_set_id, rs.period_interval_id, rs.enabled
          FROM ruleset rs
          JOIN reporting_period rp ON rp.reporting_period_sid = rs.reporting_period_sid
         WHERE rs.ruleset_sid = v_out_ruleset_sid;
END;

PROCEDURE UpdateRuleSet(
	in_ruleset_sid				IN	security_pkg.T_SID_ID,
    in_name                 	IN  VARCHAR2,
	in_reporting_period_sid		IN  security_pkg.T_SID_ID,
	in_period_set_id			IN 	ruleset.period_set_id%TYPE 		DEFAULT 1,
	in_period_interval_id		IN 	ruleset.period_interval_id%TYPE DEFAULT 4,
    in_enabled              	IN  NUMBER                    		DEFAULT NULL,
    out_cur                 	OUT	SYS_REFCURSOR
)
AS
	CURSOR c IS
		SELECT rs.app_sid, so.name, period_set_id, period_interval_id,
			   rp.name reporting_period_name
		  FROM ruleset rs
		  JOIN security.securable_object so ON rs.ruleset_sid = so.sid_id
		  JOIN reporting_period rp ON rs.reporting_period_sid = rp.reporting_period_sid
		 WHERE ruleset_sid = in_ruleset_sid;
	r 	c%ROWTYPE;
	v_reporting_period_name	reporting_period.name%TYPE;
BEGIN
	-- check for write on the ruleset
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ruleset_sid, Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have sufficient permissions on the ruleset object with sid '||in_ruleset_sid);
	END IF;
	
	OPEN c;
	FETCH c INTO r;
	CLOSE c;

	SELECT name
	  INTO v_reporting_period_name
	  FROM reporting_period
	 WHERE reporting_period_sid = in_reporting_period_sid;
	
	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ruleset_sid, 'Reporting Period', r.reporting_period_name, v_reporting_period_name);
	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ruleset_sid, 'Name', r.name, in_name);
	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ruleset_sid, 'Period set', r.period_set_id, in_period_set_id);
	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ruleset_sid, 'Period interval', r.period_interval_id, in_period_interval_id);
		
	UPDATE ruleset
	   SET reporting_period_sid = in_reporting_period_sid,
           name = in_name,
		   period_set_id = in_period_set_id,
		   period_interval_id = in_period_interval_id,
           enabled = nvl(in_enabled, enabled)
	 WHERE ruleset_sid = in_ruleset_sid;
     
    OPEN out_cur FOR
        SELECT rs.ruleset_sid, rs.name, rs.reporting_period_sid, rp.name AS reporting_period,
        	   rs.period_set_id, rs.period_interval_id, rs.enabled
          FROM ruleset rs
          JOIN reporting_period rp ON rp.reporting_period_sid = rs.reporting_period_sid
         WHERE rs.ruleset_sid = in_ruleset_sid;
END;

PROCEDURE SetRuleSetMembers(
	in_ruleset_sid		IN	security_pkg.T_SID_ID,
	in_ind_sids			IN 	security_pkg.T_SID_IDS
)
AS
	t_ind_sids			security.T_SID_TABLE;
BEGIN
	-- check for write on the ruleset
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ruleset_sid, Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have sufficient permissions on the ruleset object with sid '||in_ruleset_sid);
	END IF;

	t_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);

	-- what are we deleting?
	FOR r IN (
		SELECT i.ind_sid, i.description
		  FROM (
			SELECT ind_sid
			  FROM ruleset_member
			 WHERE ruleset_sid = in_ruleset_sid
			 MINUS
			SELECT column_value
			  FROM TABLE(t_ind_sids)
		  )x 
		  JOIN v$ind i ON x.ind_sid = i.ind_sid
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp, 
			in_ruleset_sid, 'Deleted ruleset indicator "{0}"', r.ind_sid);

		DELETE FROM ruleset_run_finding 
		 WHERE ruleset_sid = in_ruleset_sid
		   AND ind_sid = r.ind_sid;

		DELETE FROM ruleset_member
		 WHERE ruleset_sid = in_ruleset_sid
		   AND ind_sid = r.ind_sid;
	END LOOP;

	-- now insert stuff
	FOR r IN (
		SELECT i.ind_sid, i.description
		  FROM (
			 SELECT column_value ind_sid
			   FROM TABLE(t_ind_sids)
			  MINUS
			 SELECT ind_sid
			   FROM ruleset_member
              WHERE ruleset_sid = in_ruleset_sid
		  )x 
		  JOIN v$ind i ON x.ind_sid = i.ind_sid
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp, 
			in_ruleset_sid, 'Added ruleset indicator "{0}"', r.ind_sid);

		INSERT INTO ruleset_member (ruleset_sid, ind_sid)
			VALUES (in_ruleset_sid, r.ind_sid);
	END LOOP;

	-- mark for re-running
	UPDATE ruleset_run  
	   SET last_run_dtm = NULL
	 WHERE ruleset_sid = in_ruleset_sid;
END;

PROCEDURE AddRun(
	in_ruleset_sid		IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- check for write on the ruleset
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ruleset_sid, Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have sufficient permissions on the ruleset object with sid '||in_ruleset_sid);
	END IF;

	BEGIN
		INSERT INTO ruleset_run (ruleset_sid, region_sid)
			VALUES (in_ruleset_sid, in_region_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN 
			NULL;
	END;
END;

PROCEDURE StartRunFinding(
	in_ruleset_sid		IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID	
)
AS
BEGIN

	-- paranoia - what if we forget to add the region_sid to this?
	-- might take this out later
	BEGIN
		INSERT INTO ruleset_run (ruleset_sid, region_sid)
			VALUES (in_ruleset_sid, in_region_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN 
			NULL;
	END;

	-- unsecured - permissions not really relevant
	UPDATE ruleset_run_finding
	   SET is_currently_valid = 0
	 WHERE ruleset_sid = in_ruleset_sid
	   AND region_sid = in_region_sid;

	-- clean out if they've not actually entered anything yet
	DELETE FROM ruleset_run_finding
	 WHERE ruleset_sid = in_ruleset_sid
	   AND region_sid = in_region_sid
	   AND is_currently_valid = 0
	   AND explanation IS NULL 
	   AND explained_dtm IS NULL;
END;

PROCEDURE AddRunFinding(
	in_ruleset_sid				IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_finding_key				IN	ruleset_run_finding.finding_key%TYPE,
	in_start_dtm				IN 	ruleset_run_finding.start_dtm%TYPE,
	in_end_dtm 					IN 	ruleset_run_finding.end_dtm%TYPE,
	in_label					IN 	ruleset_run_finding.label%TYPE,
	in_val_number				IN  ruleset_run_finding.entry_val_number%TYPE,
	in_measure_conversion_id	IN  ruleset_run_finding.entry_measure_conversion_id%TYPE,
	in_param_1					IN 	ruleset_run_finding.param_1%TYPE DEFAULT NULL,
	in_param_2					IN 	ruleset_run_finding.param_2%TYPE DEFAULT NULL,
	in_param_3					IN 	ruleset_run_finding.param_3%TYPE DEFAULT NULL
)
AS
BEGIN
	-- unsecured - permissions not really relevant
	BEGIN
		INSERT INTO ruleset_run_finding(ruleset_sid, region_sid, ind_sid, finding_key, label, 
			start_dtm, end_dtm,
			param_1, param_2, param_3, is_currently_valid, 
			entry_val_number, entry_measure_conversion_id)
		VALUES (in_ruleset_sid, in_region_sid, in_ind_sid, in_finding_key, in_label,
			in_start_dtm, in_end_dtm,
			in_param_1, in_param_2, in_param_3, 1,
			in_val_number, in_measure_conversion_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ruleset_run_finding
			   SET label = in_label, param_1 = in_param_1, param_2 = in_param_2, param_3 = in_param_3,
			   	is_currently_valid = 1, entry_val_number = in_val_number, 
			   	entry_measure_conversion_id = in_measure_conversion_id
			 WHERE ruleset_sid = in_ruleset_sid
			   AND region_sid = in_region_sid
			   AND ind_sid = in_ind_sid
			   AND finding_key = in_finding_key
			   AND start_dtm = in_start_dtm
			   AND end_dtm = in_end_dtm;
	END;
END;

PROCEDURE GetRulesetsForCurrentPeriod(
	out_cur  	OUT  SYS_REFCURSOR
)
AS
BEGIN
	-- unsecured since it'll barf if they try and access rulesets that they don't have permissions on
	OPEN out_cur FOR
		SELECT ruleset_sid
		  FROM ruleset rs
		  	JOIN customer c ON rs.app_sid = c.app_sid AND rs.reporting_period_sid = c.current_reporting_period_sid;
END;

PROCEDURE SetRulesetsForIndicator(
	in_ind_sid		            IN	security_pkg.T_SID_ID,
	in_ruleset_sids			    IN 	security_pkg.T_SID_IDS
)
AS
	t_ruleset_sids			security.T_SID_TABLE;
BEGIN
	t_ruleset_sids := security_pkg.SidArrayToTable(in_ruleset_sids);

	-- what are we deleting?
	FOR r IN (
        SELECT ruleset_sid
          from ruleset rs
         -- select rulesets that are not in the incoming list
         where rs.ruleset_sid not in (select column_value from table(t_ruleset_sids))
           -- and the indicator is in the ruleset
           -- we only need this line because we have to record each deletion in the audit log
           and exists (select * from ruleset_member rm where rm.ruleset_sid = rs.ruleset_sid and rm.ind_sid = in_ind_sid)
    )
    LOOP
        -- check for write on the ruleset
        IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ind_sid, Security_Pkg.PERMISSION_WRITE) THEN
            RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have sufficient permissions on the ruleset object with sid ' || r.ruleset_sid);
        END IF;
        
    	csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp, 
		r.ruleset_sid, 'Deleted ruleset indicator "{0}"', in_ind_sid);

		DELETE FROM ruleset_run_finding 
		 WHERE ruleset_sid = r.ruleset_sid
		   AND ind_sid = in_ind_sid;

		DELETE FROM ruleset_member
		 WHERE ruleset_sid = r.ruleset_sid
		   AND ind_sid = in_ind_sid;

        -- mark for re-running
        UPDATE ruleset_run  
           SET last_run_dtm = NULL
         WHERE ruleset_sid = r.ruleset_sid;
     END LOOP;

	-- now insert stuff
	FOR r IN (
        SELECT ruleset_sid
          from ruleset rs
         -- select rulesets that are in the incoming list
         where rs.ruleset_sid in (select column_value from table(t_ruleset_sids))
           -- and the indicator is not in the ruleset
           and not exists (select * from ruleset_member rm where rm.ruleset_sid = rs.ruleset_sid and rm.ind_sid = in_ind_sid)
    )
	LOOP
        -- check for write on the ruleset
        IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ind_sid, Security_Pkg.PERMISSION_WRITE) THEN
            RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have sufficient permissions on the ruleset object with sid ' || r.ruleset_sid);
        END IF;

		csr_data_pkg.WriteAuditLogEntry(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp, 
			r.ruleset_sid, 'Added ruleset indicator "{0}"', in_ind_sid);

		INSERT INTO ruleset_member (ruleset_sid, ind_sid)
			VALUES (r.ruleset_sid, in_ind_sid);

        -- mark for re-running
        UPDATE ruleset_run  
           SET last_run_dtm = NULL
         WHERE ruleset_sid = r.ruleset_sid;
     END LOOP;
END;

PROCEDURE GetRulesets(
	out_cur  	OUT  SYS_REFCURSOR
)
AS
BEGIN
	-- unsecured since it'll barf if they try and access rulesets that they don't have permissions on
	OPEN out_cur FOR
		SELECT rs.ruleset_sid, rs.name, rs.reporting_period_sid, rp.name AS reporting_period,
			   rs.period_set_id, rs.period_interval_id, rs.enabled
		  FROM ruleset rs
     LEFT JOIN reporting_period rp ON rp.reporting_period_sid = rs.reporting_period_sid;
END;

PROCEDURE GetRulesetsForIndicator(
	in_ind_sid		IN 	security_pkg.T_SID_ID,
	out_cur  	    OUT  SYS_REFCURSOR
)
AS
BEGIN
	-- unsecured since it'll barf if they try and access rulesets that they don't have permissions on
	OPEN out_cur FOR
		SELECT rs.ruleset_sid, rs.name, rs.reporting_period_sid, rp.name AS reporting_period,
			   rs.period_set_id, rs.period_interval_id, rs.enabled
		  FROM ruleset rs
     LEFT JOIN ruleset_member rm ON rm.ruleset_sid = rs.ruleset_sid      
     LEFT JOIN reporting_period rp ON rp.reporting_period_sid = rs.reporting_period_sid
         WHERE rm.ind_sid = in_ind_sid;
END;

PROCEDURE GetIndicatorsForRuleSet(
	in_ruleset_sid		IN 	security_pkg.T_SID_ID,
	out_cur  	        OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ind_sid
		  FROM ruleset_member
         WHERE ruleset_sid = in_ruleset_sid;
END;

PROCEDURE GetRunFindings(
	in_ruleset_sid		IN 	security_pkg.T_SID_ID,
	in_region_sid		IN 	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- check for read on the ruleset and the region
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ruleset_sid, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have read permissions on the ruleset object with sid '||in_ruleset_sid);
	END IF;
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have read permissions on the region object with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT rrf.ind_sid, i.description ind_description, rrf.finding_key, rrf.region_sid, rrf.ruleset_sid,
			   rrf.entry_val_number, rrf.entry_measure_conversion_id, 
			   r.period_set_id, r.period_interval_id, rrf.start_dtm, rrf.end_dtm,
			   NVL(mc.description, m.description) entry_measure_description,
			   NVL(i.format_mask, m.format_mask) format_mask,
			   rrf.label, rrf.param_1 param1, rrf.param_2 param2, rrf.param_3 param3, rrf.explanation, 
			   rrf.explained_by_user_sid, cue.email explained_by_user_email, cue.full_name explained_by_user_full_name, rrf.explained_dtm, 
			   rrf.approved_by_user_sid, cua.email approved_by_user_email, cua.full_name approved_by_user_full_name, rrf.approved_dtm 
	  	  FROM ruleset_run_finding rrf
	  	  JOIN ruleset r ON r.app_sid = rrf.app_sid AND r.ruleset_sid = rrf.ruleset_sid
		  JOIN v$ind i ON rrf.ind_sid = i.ind_sid AND rrf.app_sid = i.app_sid
	  	  JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
	  	  LEFT JOIN measure_conversion mc ON rrf.entry_measure_conversion_id = mc.measure_conversion_id AND rrf.app_sid = mc.app_sid
	  	  LEFT JOIN csr_user cue ON rrf.explained_by_user_sid = cue.csr_user_sid AND rrf.app_sid = cue.app_sid
	  	  LEFT JOIN csr_user cua ON rrf.approved_by_user_sid = cua.csr_user_sid AND rrf.app_sid = cua.app_sid
	  	 WHERE rrf.ruleset_sid = in_ruleset_sid
	  	   AND rrf.region_sid = in_region_sid
	  	   AND is_currently_valid = 1;
END;

PROCEDURE ExplainFinding(
	in_ruleset_sid	IN 	security_pkg.T_SID_ID,
	in_region_sid	IN 	security_pkg.T_SID_ID,
	in_ind_sid		IN 	security_pkg.T_SID_ID,
	in_start_dtm	IN 	ruleset_run_finding.start_dtm%TYPE,
	in_finding_key  IN 	ruleset_run_finding.finding_key%TYPE,
	in_explanation  IN  ruleset_run_finding.explanation%TYPE
)
AS
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ruleset_sid, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have read permissions on the ruleset object with sid '||in_ruleset_sid);
	END IF;
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have read permissions on the region object with sid '||in_region_sid);
	END IF;

	UPDATE ruleset_run_finding
	   SET explanation = in_explanation,
	   	   explained_by_user_sid = CASE WHEN in_explanation IS NULL THEN NULL ELSE SYS_CONTEXT('SECURITY','SID') END,
	   	   explained_dtm = CASE WHEN in_explanation IS NULL THEN NULL ELSE SYSDATE END,
	   	   approved_by_user_sid = null,
	   	   approved_dtm = null
	 WHERE ruleset_sid = in_ruleset_sid
	   AND region_sid = in_region_sid
	   AND ind_sid = in_ind_sid
	   AND finding_key = in_finding_key
	   AND start_dtm = in_start_dtm;
END;

PROCEDURE GetRegionsToProcess(
	in_ruleset_sid		IN 	security_pkg.T_SID_ID,
	out_cur         	OUT SYS_REFCURSOR
)
AS
BEGIN
	-- we don't check region as that gets checked when fetching the necessary data to apply the ruleset
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ruleset_sid, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have read permissions on the ruleset object with sid '||in_ruleset_sid);
	END IF;

	OPEN out_cur FOR
		SELECT region_sid 
		  FROM ruleset_run 
		 WHERE last_run_dtm is null 
		   AND ruleset_sid = in_ruleset_sid
		 ORDER BY region_sid;
END;

PROCEDURE GetRun(
	in_ruleset_sid		IN 	security_pkg.T_SID_ID,
	out_cur         	OUT SYS_REFCURSOR,
	out_inds_cur		OUT SYS_REFCURSOR,
	out_ind_rules_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(security_pkg.getACT, in_ruleset_sid, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have read permissions on the ruleset object with sid '||in_ruleset_sid);
	END IF;
	
	OPEN out_cur for
		SELECT rp.name, rp.start_dtm, rp.end_dtm, rs.period_set_id, rs.period_interval_id
		  FROM ruleset rs
		  JOIN reporting_period rp ON rs.reporting_period_sid = rp.reporting_period_sid AND rs.app_sid = rp.app_sid
		 WHERE rs.ruleset_sid = in_ruleset_sid;

	OPEN out_inds_cur FOR
		SELECT rm.ind_sid, i.description, i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   NVL(i.divisibility, m.divisibility) divisibility
		  FROM ruleset_member rm
		  JOIN v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
		  LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		 WHERE rm.ruleset_sid = in_ruleset_sid;

	OPEN out_ind_rules_cur FOR
		SELECT ivr.ind_sid, ivr.expr, ivr.message, ivr.ind_validation_rule_id, ivr.type
		  FROM ruleset_member rm
		  JOIN ind_validation_rule ivr ON rm.ind_sid = ivr.ind_sid AND rm.app_sid = ivr.app_sid
		 WHERE rm.ruleset_sid = in_ruleset_sid
		 ORDER BY ivr.ind_sid, ivr.position;
END;

END;
/
