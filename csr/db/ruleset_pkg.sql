CREATE OR REPLACE PACKAGE CSR.RULESET_PKG AS

-- Securable object callbacks for CAUSE_SET (a cause_set is something like 'Health and Safety')
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE CreateRuleSet(
	in_name						IN	security_pkg.T_SO_NAME,
	in_reporting_period_sid		IN  security_pkg.T_SID_ID   		DEFAULT null,
	in_period_set_id			IN 	ruleset.period_set_id%TYPE 		DEFAULT 1,
	in_period_interval_id		IN 	ruleset.period_interval_id%TYPE DEFAULT 4,
    in_enabled                  IN  NUMBER                  		DEFAULT 1,
    out_ruleset_sid             OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateRuleSetReturnCursor(
	in_name						IN	security_pkg.T_SO_NAME,
	in_reporting_period_sid		IN  security_pkg.T_SID_ID   		DEFAULT null,
	in_period_set_id			IN 	ruleset.period_set_id%TYPE 		DEFAULT 1,
	in_period_interval_id		IN 	ruleset.period_interval_id%TYPE DEFAULT 4,
    in_enabled                  IN  NUMBER                  		DEFAULT 1,
    out_cur                     OUT	SYS_REFCURSOR
);

PROCEDURE CloneRuleSet(
	in_name 						IN  security_pkg.T_SO_NAME,
	in_clone_ruleset_sid			IN  security_pkg.T_SID_ID,   
	in_new_reporting_period_sid		IN  security_pkg.T_SID_ID,
	out_new_ruleset_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE UpdateRuleSet(
	in_ruleset_sid				IN	security_pkg.T_SID_ID,
    in_name                 	IN  VARCHAR2,
	in_reporting_period_sid		IN  security_pkg.T_SID_ID,
	in_period_set_id			IN 	ruleset.period_set_id%TYPE 		DEFAULT 1,
	in_period_interval_id		IN 	ruleset.period_interval_id%TYPE DEFAULT 4,
    in_enabled              	IN  NUMBER                    		DEFAULT NULL,
    out_cur                 	OUT	SYS_REFCURSOR
);

PROCEDURE SetRuleSetMembers(
	in_ruleset_sid		IN	security_pkg.T_SID_ID,
	in_ind_sids			IN 	security_pkg.T_SID_IDS
);

PROCEDURE AddRun(
	in_ruleset_sid		IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE StartRunFinding(
	in_ruleset_sid		IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID	
);

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
);

PROCEDURE SetRulesetsForIndicator(
	in_ind_sid		            IN	security_pkg.T_SID_ID,
	in_ruleset_sids			    IN 	security_pkg.T_SID_IDS
);

PROCEDURE GetRulesetsForCurrentPeriod(
	out_cur  	OUT  SYS_REFCURSOR
);

PROCEDURE GetRulesets(
	out_cur  	OUT  SYS_REFCURSOR
);

PROCEDURE GetRulesetsForIndicator(
	in_ind_sid		IN 	security_pkg.T_SID_ID,
	out_cur  	    OUT  SYS_REFCURSOR
);

PROCEDURE GetIndicatorsForRuleSet(
	in_ruleset_sid		IN 	security_pkg.T_SID_ID,
	out_cur  	        OUT  SYS_REFCURSOR
);

PROCEDURE GetRunFindings(
	in_ruleset_sid		IN 	security_pkg.T_SID_ID,
	in_region_sid		IN 	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetRegionsToProcess(
	in_ruleset_sid		IN 	security_pkg.T_SID_ID,
	out_cur         	OUT SYS_REFCURSOR
);

PROCEDURE GetRun(
	in_ruleset_sid		IN 	security_pkg.T_SID_ID,
	out_cur         	OUT SYS_REFCURSOR,
	out_inds_cur		OUT SYS_REFCURSOR,
	out_ind_rules_cur	OUT SYS_REFCURSOR
);

PROCEDURE ExplainFinding(
	in_ruleset_sid	IN 	security_pkg.T_SID_ID,
	in_region_sid	IN 	security_pkg.T_SID_ID,
	in_ind_sid		IN 	security_pkg.T_SID_ID,
	in_start_dtm	IN 	ruleset_run_finding.start_dtm%TYPE,
	in_finding_key  IN 	ruleset_run_finding.finding_key%TYPE,
	in_explanation  IN  ruleset_run_finding.explanation%TYPE
);
END;
/
