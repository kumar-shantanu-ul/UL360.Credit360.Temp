CREATE OR REPLACE PACKAGE csr.compliance_setup_pkg AS

PROCEDURE UpdateDefaultWorkflow(
	in_flow_sid						security.security_pkg.T_SID_ID,
	in_class						flow.flow_alert_class%TYPE
);

PROCEDURE UpdatePermitWorkflow(
	in_flow_sid						security.security_pkg.T_SID_ID,
	in_class						flow.flow_alert_class%TYPE
);

PROCEDURE UpdatePermApplicationWorkflow(
	in_flow_sid						security.security_pkg.T_SID_ID,
	in_class						flow.flow_alert_class%TYPE
);

PROCEDURE UpdatePermitConditionWorkflow(
	in_flow_sid						security.security_pkg.T_SID_ID,
	in_class						flow.flow_alert_class%TYPE
);

END compliance_setup_pkg;
/