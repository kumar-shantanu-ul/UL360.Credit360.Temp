CREATE OR REPLACE PACKAGE csr.permit_data_import_pkg AS
PROCEDURE GetAllPermitTypes (
	out_cur 					OUT SYS_REFCURSOR
);

PROCEDURE GetActivityTypeUsage(
	out_not_deleteable_types		out NUMBER
);

PROCEDURE TrashAllActivityTypes;

PROCEDURE ImportActivityTypeRow(
	in_type					IN  compliance_activity_type.description%type,
	in_sub_type 			IN  compliance_activity_sub_type.description%type,
	in_position				IN  compliance_activity_type.pos%type,
	out_successful 			OUT NUMBER
);

PROCEDURE GetApplicationTypeUsage(
	out_not_deleteable_types		out NUMBER
);

PROCEDURE TrashAllApplicationTypes;

PROCEDURE ImportApplicationTypeRow(
	in_type					IN  compliance_activity_type.description%type,
	in_sub_type 			IN  compliance_activity_sub_type.description%type,
	in_position				IN  compliance_activity_type.pos%type,
	out_successful 			OUT NUMBER
	
);

PROCEDURE GetConditionTypeUsage(
	out_not_deleteable_types		out NUMBER
);

PROCEDURE TrashAllConditionTypes;

PROCEDURE ImportConditionTypeRow(
	in_type					IN  compliance_activity_type.description%type,
	in_sub_type 			IN  compliance_activity_sub_type.description%type,
	in_position				IN  compliance_activity_type.pos%type,
	out_successful 			OUT NUMBER
	
);

PROCEDURE GetPermitTypeUsage(
	out_not_deleteable_types		out NUMBER
);

PROCEDURE TrashAllPermitTypes;

PROCEDURE ImportPermitTypeRow(
	in_type					IN  compliance_activity_type.description%type,
	in_sub_type 			IN  compliance_activity_sub_type.description%type,
	in_position				IN  compliance_activity_type.pos%type,
	out_successful 			OUT NUMBER
	
);

PROCEDURE ImportPermit(
	in_title						IN  compliance_permit.title%type,
	in_region_sid					IN  region.region_sid%type,
	in_activity_details				IN  compliance_permit.activity_details%type,
	in_activity_type				IN  compliance_activity_type.description%type,
	in_activity_sub_type			IN  compliance_activity_sub_type.description%type,
	in_activity_start_date			IN  compliance_permit.activity_start_dtm%type,
	in_activity_end_date 			IN  compliance_permit.activity_end_dtm%type,
	in_permit_type					IN  compliance_permit_type.description%type,
	in_permit_sub_type				IN  compliance_permit_sub_type.description%type,
	in_permit_start_date			IN  compliance_permit.permit_start_dtm%type,
	in_permit_end_date				IN  compliance_permit.permit_end_dtm%type,
	in_reference					IN  compliance_permit.permit_reference%type,
	in_commissioning_req			IN  VARCHAR2,
	in_commision_date				IN  compliance_permit.site_commissioning_dtm%type,
	in_workflow_state				IN  flow_state.lookup_key%type,
	in_allow_update					IN  NUMBER,
	out_status_code					OUT NUMBER

);

PROCEDURE ImportCondition(
	in_permit_reference				IN  compliance_permit.permit_reference%type,
	in_condition_title				IN  compliance_item.title%type,
	in_details						IN  compliance_item.details%type,
	in_condition_type				IN  compliance_condition_type.description%type,
	in_condition_sub_type			IN  compliance_condition_sub_type.description%type,
	in_condition_reference			IN  compliance_item.reference_code%type,
	in_workflow_state 				IN  flow_state.lookup_key%type,
	in_allow_update					IN  NUMBER,
	out_status_code					OUT NUMBER
);
END permit_data_import_pkg;
/