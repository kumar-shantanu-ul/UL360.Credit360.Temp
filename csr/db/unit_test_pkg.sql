CREATE OR REPLACE PACKAGE CSR.unit_test_pkg AS

TYPE T_TESTS IS TABLE OF VARCHAR2(100);

PROCEDURE StartTest(
	in_test_name		IN	VARCHAR2
);

PROCEDURE EndTest;

PROCEDURE TestFail (
	in_message			IN	VARCHAR2
);

PROCEDURE TestFail (
	in_assertion		IN	VARCHAR2,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertIsNull(
	in_actual			IN	VARCHAR2,
	in_message			IN	VARCHAR2
);
PROCEDURE AssertIsNull(
	in_actual			IN	NUMBER,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertIsNotNull(
	in_actual			IN	VARCHAR2,
	in_message			IN	VARCHAR2
);
PROCEDURE AssertIsNotNull(
	in_actual			IN	NUMBER,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertIsTrue(
	in_actual			IN	BOOLEAN,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertIsFalse(
	in_actual			IN	BOOLEAN,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertAreEqual(
	in_expected			IN	VARCHAR2,
	in_actual			IN	VARCHAR2,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertAreEqual(
	in_expected			IN	NUMBER,
	in_actual			IN	NUMBER,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertAreEqual(
	in_expected			IN	DATE,
	in_actual			IN	DATE,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertAreEqual(
	in_expected			IN	CLOB,
	in_actual			IN	CLOB,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertNotEqual(
	in_expected			IN	VARCHAR2,
	in_actual			IN	VARCHAR2,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertNotEqual(
	in_expected			IN	NUMBER,
	in_actual			IN	NUMBER,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertNotEqual(
	in_expected			IN	DATE,
	in_actual			IN	DATE,
	in_message			IN	VARCHAR2
);

PROCEDURE AssertNotEqual(
	in_expected			IN	CLOB,
	in_actual			IN	CLOB,
	in_message			IN	VARCHAR2
);

PROCEDURE RunTests(
	in_pkg				IN VARCHAR2,
	in_site_name		IN VARCHAR2 DEFAULT 'rag.credit360.com'
);

PROCEDURE RunTests(
	in_pkg				IN VARCHAR2,
	in_tests			IN T_TESTS,
	in_site_name		IN VARCHAR2 DEFAULT 'rag.credit360.com'
);


-- Helper functions to get some simple base data for tests
FUNCTION GetOrCreateMeasure (
	in_name							IN	VARCHAR2,
	in_std_measure_conversion_id	IN	measure.std_measure_conversion_id%TYPE DEFAULT NULL,
	in_custom_field					IN	measure.custom_field%TYPE DEFAULT NULL
) RETURN security_pkg.T_SID_ID;

FUNCTION AddMeasureConversion (
	in_measure_sid					IN	measure.measure_sid%TYPE,	
	in_description					IN	measure_conversion.description%TYPE,
	in_std_measure_conversion_id	IN	std_measure_conversion.std_measure_conversion_id%TYPE

) RETURN measure.std_measure_conversion_id%TYPE;

FUNCTION GetOrCreateInd (
	in_lookup_key					IN	VARCHAR2,
	in_measure_name					IN	VARCHAR2 DEFAULT 'MEASURE_1',
	in_parent_sid					IN	security_pkg.T_SID_ID DEFAULT NULL
) RETURN security_pkg.T_SID_ID;

FUNCTION SetIndicatorValue(
	in_ind_sid					IN security.security_pkg.T_SID_ID,
	in_region_sid				IN security.security_pkg.T_SID_ID,
	in_period_start				IN val.period_start_dtm%TYPE,
	in_period_end				IN val.period_end_dtm%TYPE,
	in_val_number				IN val.val_number%TYPE
) RETURN val.val_id%TYPE;

FUNCTION SetIndicatorText(
	in_ind_sid					IN security.security_pkg.T_SID_ID,
	in_region_sid				IN security.security_pkg.T_SID_ID,
	in_period_start				IN val.period_start_dtm%TYPE,
	in_period_end				IN val.period_end_dtm%TYPE,
	in_text						IN val.note%TYPE
) RETURN val.val_id%TYPE;

FUNCTION GetOrCreateRole (
	in_lookup_key		IN	VARCHAR2
) RETURN security_pkg.T_SID_ID;

FUNCTION GetOrCreateRegion (
	in_lookup_key			IN	VARCHAR2,
	in_parent_region_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_region_type			IN	region.region_type%TYPE	DEFAULT csr_data_pkg.REGION_TYPE_NORMAL
) RETURN security_pkg.T_SID_ID;

FUNCTION GetOrCreateUser (
	in_name				IN	VARCHAR2,
	in_group_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_password			IN  VARCHAR2 DEFAULT NULL
) RETURN security_pkg.T_SID_ID;

FUNCTION GetOrCreateUserAndProfile (
	in_primary_key				IN csr.user_profile.primary_key%TYPE,
	in_first_name				IN csr.user_profile.first_name%TYPE,
	in_last_name				IN csr.user_profile.last_name%TYPE,
	in_email_address			IN csr.user_profile.email_address%TYPE,
	in_work_phone_number		IN csr.user_profile.work_phone_number%TYPE,
	in_date_of_birth			IN csr.user_profile.date_of_birth%TYPE,
	in_gender					IN csr.user_profile.gender%TYPE,
	in_job_title				IN csr.user_profile.job_title%TYPE,
	in_employment_type			IN csr.user_profile.employment_type%TYPE,
	in_manager_primary_key		IN csr.user_profile.manager_primary_key%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION GetUserGuidFromSid (
	in_user_sid			IN	csr.csr_user.csr_user_sid%TYPE
) RETURN csr.csr_user.guid%TYPE;

FUNCTION GetOrCreateDeleg (
	in_name				IN	VARCHAR2,
	in_regions			IN	security_pkg.T_SID_IDS,
	in_inds				IN	security_pkg.T_SID_IDS
) RETURN security_pkg.T_SID_ID;

FUNCTION GetOrCreateAudit (
	in_name				IN	VARCHAR2,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,	
	in_survey_sid 		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_audit_dtm		IN	DATE DEFAULT DATE '2010-01-01'
) RETURN security_pkg.T_SID_ID;

FUNCTION GetOrCreateAuditWithFlow (
	in_name				IN	VARCHAR2,
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,
	in_survey_sid 		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_audit_type_name	IN	VARCHAR2 DEFAULT 'AUDIT_TYPE_WITH_FLOW',
	in_audit_dtm		IN	DATE DEFAULT DATE '2010-01-01'
) RETURN security_pkg.T_SID_ID;

FUNCTION GetOrCreateAuditWithInvType (
	in_name					IN	VARCHAR2,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_aud_coord_sid		IN	security_pkg.T_SID_ID,
	in_inv_user_sid			IN	security_pkg.T_SID_ID,
	out_flow_item_id		OUT	NUMBER,
	out_flow_inv_type_id	OUT NUMBER
) RETURN security_pkg.T_SID_ID;

FUNCTION GetOrCreateNonComplianceTypeId (
	in_name				IN	VARCHAR2,
	in_is_flow_capability_enabled	NUMBER	DEFAULT 1
) RETURN NUMBER;

FUNCTION GetOrCreateNonComplianceId (
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_name						IN	VARCHAR2,
	in_non_compliance_type_id	IN  NUMBER DEFAULT NULL
) RETURN NUMBER;

FUNCTION GetOrCreateNonComplianceId (
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_name						IN	VARCHAR2,
	in_non_compliance_type_id	IN  NUMBER DEFAULT NULL,
	in_tag_ids					IN	security_pkg.T_SID_IDS
) RETURN NUMBER;

FUNCTION GetOrCreateGroup (
	in_group_name		IN	Security_Pkg.T_SO_NAME
) RETURN NUMBER;

FUNCTION GetOrCreateDelegPlan (
	in_name					IN	VARCHAR2,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_root_regions			IN	security_pkg.T_SID_IDS,
	in_roles				IN	security_pkg.T_SID_IDS,
	in_start_date			IN	DATE,
	in_end_date				IN	DATE,
	in_schedule_xml			IN	CLOB,
	in_dynamic				IN	NUMBER DEFAULT 1,
	in_period_set_id		IN	NUMBER DEFAULT 1,
	in_period_interval_id	IN	NUMBER DEFAULT 1,
	in_reminder_offset		IN	NUMBER DEFAULT 5,
	in_region_selection		IN	VARCHAR2 DEFAULT CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
	in_tag_id				IN	NUMBER DEFAULT NULL,
	in_region_type			IN	NUMBER DEFAULT NULL,
	in_selected_regions		IN	security_pkg.T_SID_IDS DEFAULT security_pkg.T_SID_IDS()
) RETURN security_pkg.T_SID_ID;

PROCEDURE SetSelectionForDelegPlan(
	in_name					IN	VARCHAR2,
	in_root_regions			IN	security_pkg.T_SID_IDS,
	in_region_selection		IN	VARCHAR2 DEFAULT CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
	in_tag_id				IN	NUMBER DEFAULT NULL,
	in_region_type			IN	NUMBER DEFAULT NULL
);

PROCEDURE SetScheduleForDelegPlan (
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_deleg_templates	IN	security_pkg.T_SID_IDS,
	in_roles			IN	security_pkg.T_SID_IDS,
	in_schedule_xml		IN	deleg_plan_date_schedule.schedule_xml%type DEFAULT NULL,
	in_reminder_offset	IN 	deleg_plan_date_schedule.reminder_offset%type DEFAULT NULL
);

FUNCTION GetOrCreateTagGroup (
	in_lookup_key			IN	VARCHAR2,
	in_multi_select			IN	NUMBER,
	in_applies_to_inds		IN	NUMBER,
	in_applies_to_regions	IN	NUMBER,
	in_tag_members			IN	VARCHAR2,
	in_mandatory			IN	NUMBER DEFAULT 0,
	in_applies_to_suppliers	IN	NUMBER DEFAULT 0
) RETURN NUMBER;

FUNCTION GetOrCreateTag (
	in_lookup_key			IN	VARCHAR2,
	in_tag_group_id			IN	NUMBER
) RETURN NUMBER;

FUNCTION GetOrCreateMenu(
	in_so_name					IN	VARCHAR2,
	in_name						IN	VARCHAR2,
	in_action					IN	VARCHAR2,
	in_pos						IN	NUMBER,
	in_parent_sid				IN	security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'menu'),
	in_parent_path				IN	VARCHAR2 DEFAULT 'menu',
	in_admin_group_sid			IN	security.security_pkg.T_SID_ID DEFAULT GetOrCreateGroup('Administrators')
) RETURN security.security_pkg.T_SID_ID;

FUNCTION GetOrCreateWebResource(
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	in_name					IN	VARCHAR2
) RETURN security.security_pkg.T_SID_ID;

PROCEDURE GetOrCreateWorkflow (
	in_label						IN	flow.label%TYPE,
	in_flow_alert_class				IN	flow.flow_alert_class%TYPE,
	out_sid							OUT	security.security_pkg.T_SID_ID
);

PROCEDURE GetOrCreateWorkflowState (
	in_flow_sid						IN	flow.flow_sid%TYPE,
	in_state_label					IN	flow_state.label%TYPE,
	in_state_lookup_key				IN	flow_state.lookup_key%TYPE,
	out_flow_state_id				OUT	flow_state.flow_state_id%TYPE
);

/* Create site helpers */

PROCEDURE CreateCommonMenu;
PROCEDURE CreateCommonWebResources;
PROCEDURE EnableAudits;

PROCEDURE CreateAuditsNoWf(
	in_no_of_audits					IN	NUMBER DEFAULT 10
);

PROCEDURE CreateAuditType(
	in_label						IN internal_audit_type.label%TYPE,
	in_flow_sid						IN internal_audit_type.flow_sid%TYPE DEFAULT NULL,
	in_audit_contact_role_sid		IN internal_audit_type.audit_contact_role_sid%TYPE DEFAULT NULL,
	in_auditor_role_sid				IN internal_audit_type.auditor_role_sid%TYPE DEFAULT NULL,
	out_audit_type_id				OUT internal_audit_type.internal_audit_type_id%TYPE
);

PROCEDURE CreateAudit(
	in_label						IN	VARCHAR2,
	in_audit_type_id				IN	internal_audit_type.internal_audit_type_id%TYPE,
	out_sid							OUT	security.security_pkg.T_SID_ID
);

PROCEDURE EnableChain;

FUNCTION GetOrCreatePeriodSet
RETURN NUMBER;

PROCEDURE SetFlowCapability(
	in_flow_capability	NUMBER,
	in_flow_state_id 	NUMBER,
	in_permission_set	NUMBER,
	in_role_sid			NUMBER DEFAULT NULL,
	in_group_sid		NUMBER DEFAULT NULL
);

/*
This SP is expected to be used by the ELC Incident Exporter class for testing purposes.
See UL360.Credit360\csr\Credit360.ExportImport\Automated\Export\Exporters\ELC\IncidentExporter.cs
*/
PROCEDURE GetELCIncidentData(
	in_instance_id			IN 	NUMBER,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR
); 

PROCEDURE AnonymiseUser(
	in_user_sid				IN	csr.csr_user.csr_user_sid%TYPE
);

PROCEDURE DeactivateUser(
	in_user_sid				IN	csr.csr_user.csr_user_sid%TYPE
);

END;
/