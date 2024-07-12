CREATE OR REPLACE PACKAGE chain.dashboard_pkg
IS

PROCEDURE GetInvitationSummary (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductWorkSummary (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireSummary (
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

END dashboard_pkg;
/

