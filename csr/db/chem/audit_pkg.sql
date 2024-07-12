CREATE OR REPLACE PACKAGE CHEM.AUDIT_PKG
AS

PROCEDURE WriteUsageLogEntry(
	in_substance_id		IN	usage_audit_log.substance_id%TYPE,
	in_delegation_sid	IN	usage_audit_log.root_delegation_sid%TYPE,
	in_region_sid		IN	usage_audit_log.region_sid%TYPE,
	in_start_dtm		IN	usage_audit_log.start_dtm%TYPE,
	in_end_dtm			IN	usage_audit_log.end_dtm%TYPE,
	in_description		IN	usage_audit_log.description%TYPE,
	in_param_1			IN	usage_audit_log.param_1%TYPE,
	in_param_2			IN	usage_audit_log.param_2%TYPE
);

PROCEDURE CheckAndWriteUsageLogEntry(
	in_substance_id		IN	usage_audit_log.substance_id%TYPE,
	in_delegation_sid	IN	usage_audit_log.root_delegation_sid%TYPE,
	in_region_sid		IN	usage_audit_log.region_sid%TYPE,
	in_start_dtm		IN	usage_audit_log.start_dtm%TYPE,
	in_end_dtm			IN	usage_audit_log.end_dtm%TYPE,
	in_description		IN	usage_audit_log.description%TYPE,
	in_param_1			IN	usage_audit_log.param_1%TYPE,
	in_param_2			IN	usage_audit_log.param_2%TYPE
);

PROCEDURE GetUsageLogEntries(
	in_delegation_sid	IN	usage_audit_log.root_delegation_sid%TYPE,
	in_region_sid		IN	usage_audit_log.region_sid%TYPE,
	in_start_dtm		IN	usage_audit_log.start_dtm%TYPE,
	in_end_dtm			IN	usage_audit_log.end_dtm%TYPE,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE WriteSubstanceLogEntry(
	in_substance_id		IN	substance_audit_log.substance_id%TYPE,
	in_description		IN	substance_audit_log.description%TYPE,
	in_param_1			IN	substance_audit_log.param_1%TYPE,
	in_param_2			IN	substance_audit_log.param_2%TYPE
);

PROCEDURE CheckAndWriteSubLogEntry(
	in_substance_id		IN	substance_audit_log.substance_id%TYPE,
	in_description		IN	substance_audit_log.description%TYPE,
	in_param_1			IN	substance_audit_log.param_1%TYPE,
	in_param_2			IN	substance_audit_log.param_2%TYPE
);

PROCEDURE GetSubLogEntries(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllUsageLogEntries(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END;
/