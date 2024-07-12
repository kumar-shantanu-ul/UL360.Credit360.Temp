CREATE OR REPLACE PACKAGE DONATIONS.sys_Pkg
IS

FUNCTION FormatPeriod(
    in_dtm      IN DATE, 
    in_base_dtm IN DATE, 
    in_interval IN CHAR
) RETURN VARCHAR2;

FUNCTION GetSortableRebasedDate(
    in_dtm      IN DATE, 
    in_base_dtm IN DATE, 
    in_interval IN CHAR
) RETURN VARCHAR2;

PROCEDURE HasConstants(
    out_cur     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConstants(
    out_cur     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE EnableDonations(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE QueueRecalc(
	in_app_sid		security_pkg.T_SID_ID
);

PROCEDURE QueueRecalc;

PROCEDURE GetAppsToRecalc(
	out_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE BeginAppRecalc;

PROCEDURE EndAppRecalc;



END sys_Pkg;
/
