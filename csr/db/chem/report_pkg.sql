CREATE OR REPLACE PACKAGE chem.report_pkg AS

PROCEDURE GetMissingDestinations(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCasCodes(
	in_unconfirmed	IN	number,
	out_list_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCasRestrictions(
	out_list_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetWaiverStatus(
	in_required_only	IN	number,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMSDS(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_msds_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMSDSUploads(
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstances(
	out_list_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstancesReport(
	out_list_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUngroupedCASCodes(
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRawOutputs(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SubstCompCheckReport(
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CasGroupsReport(
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFullSheetReport(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFullReport(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditReport(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
);

END;
/
