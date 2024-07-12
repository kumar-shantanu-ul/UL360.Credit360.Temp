CREATE OR REPLACE PACKAGE CHAIN.certification_pkg
IS

PROCEDURE GetCertificationTypes (
	out_cert_types_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_audit_types_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCertificationsForCompany (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_certification_type_id		IN	v$supplier_certification.certification_id%TYPE,
	in_get_only_latest				IN	NUMBER DEFAULT 1,
	out_certifications_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveCertificationType (
	in_cert_type_id			IN	certification_type.certification_type_id%TYPE,
	in_label				IN	certification_type.label%TYPE,
	in_lookup_key			IN	certification_type.lookup_key%TYPE,
	in_requirement_type_id	IN	certification_type.product_requirement_type_id%TYPE,
	in_audit_type_ids		IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteCertificationType (
	in_cert_type_id			IN	certification_type.certification_type_id%TYPE
);

END certification_pkg;
/
