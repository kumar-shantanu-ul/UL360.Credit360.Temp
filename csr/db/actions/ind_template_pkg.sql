CREATE OR REPLACE PACKAGE  ACTIONS.ind_template_pkg
IS

TYPE T_TEMPLATE_IDS IS TABLE OF ind_template.ind_template_id%TYPE INDEX BY PLS_INTEGER;

ERR_NO_PARENT_TASK				CONSTANT NUMBER := -20701;
NO_PARENT_TASK					EXCEPTION;
PRAGMA EXCEPTION_INIT(NO_PARENT_TASK, -20701);

ERR_CALC_ATTR_NOT_MATHCED		CONSTANT NUMBER := -20702;
CALC_ATTR_NOT_MATHCED			EXCEPTION;
PRAGMA EXCEPTION_INIT(NO_PARENT_TASK, -20702);


IND_DEP_TYPE_INDICATOR 			CONSTANT NUMBER(10) := 1;
IND_DEP_TYPE_CHILDREN 			CONSTANT NUMBER(10) := 2;


PROCEDURE CreateIndicator(
	in_template_name		IN	ind_template.name%TYPE,
	in_parent_ind_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	in_name					IN	csr.ind_description.description%TYPE,
	out_ind_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateIndicator(
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_parent_ind_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	in_name					IN	csr.ind_description.description%TYPE,
	out_ind_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateIndicator(
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_parent_ind_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	in_name					IN	csr.ind_description.description%TYPE,
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_ind_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE ConvertCalculation(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE MakeNPV(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE SetMetricsForTask(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE CreateMetric(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
);

PROCEDURE DeleteMetric(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
);

PROCEDURE DeleteProjectMetric(
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
);

PROCEDURE DeleteRootMetric(
	in_template_id			IN	ind_template.ind_template_id%TYPE
);

PROCEDURE MoveMetric(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_old_parent_sid		IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
);

PROCEDURE MoveMetrics(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_old_parent_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE SetIndicatorType(
	in_ind_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE InheritMetrics(
	in_task_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveTemplateFromProject (
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_template_name		IN	ind_template.name%TYPE
);

PROCEDURE RemoveTemplateFromProject (
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
);

PROCEDURE TriggerNPVRecalc(
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE RenameIndTemplate (
	in_name				IN	ind_template.name%TYPE,
	in_description		IN	ind_template.description%TYPE,
	in_input_label		IN	ind_template.input_label%TYPE
);

PROCEDURE RenameIndTemplate (
	in_ind_template_id	IN	ind_template.ind_template_id%TYPE,
	in_description		IN	ind_template.description%TYPE,
	in_input_label		IN	ind_template.input_label%TYPE
);

PROCEDURE SetInfoText (
	in_name				IN	ind_template.name%TYPE,
	in_info				IN	ind_template.description%TYPE
);

PROCEDURE SetInfoText (
	in_ind_template_id	IN	ind_template.ind_template_id%TYPE,
	in_info				IN	ind_template.description%TYPE
);

END ind_template_pkg;
/

