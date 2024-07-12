CREATE OR REPLACE PACKAGE csr.managed_content_pkg AS

PROCEDURE AssociateSid(
	in_sid_id		IN	MANAGED_CONTENT_MAP.SID%TYPE,
	in_unique_ref	IN	MANAGED_CONTENT_MAP.UNIQUE_REF%TYPE,
	in_package_ref	IN	MANAGED_CONTENT_MAP.package_REF%TYPE
);

PROCEDURE AssociateMeasureConversion(
	in_conversion_id	IN	MANAGED_CONTENT_MEASURE_CONVERSION_MAP.conversion_id%TYPE,
	in_unique_ref		IN	MANAGED_CONTENT_MEASURE_CONVERSION_MAP.UNIQUE_REF%TYPE,
	in_package_ref		IN	MANAGED_CONTENT_MEASURE_CONVERSION_MAP.package_REF%TYPE
);

PROCEDURE LoadPackageMeasures(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE LoadPackageIndicators(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE LoadPackageMeasureConversions(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE EnsureMeasureReferencesSet;

PROCEDURE EnsureIndicatorReferencesSet;

PROCEDURE EnableManagedPackagedContent(
	in_package_name	IN VARCHAR2,
	in_package_ref	IN VARCHAR2
);

PROCEDURE GetSummaryInfo(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLogRunID(
	in_package_ref	IN VARCHAR2,
	out_managed_content_unpackager_run_id OUT managed_content_unpackage_log_run.run_id%TYPE
);

PROCEDURE WriteLogMessage(
	in_run_id 		IN managed_content_unpackage_log_run.run_id%TYPE,
	in_severity		IN managed_content_unpackage_log_run.severity%TYPE,
	in_message 		IN managed_content_unpackage_log_run.message%TYPE
);

END;
/
