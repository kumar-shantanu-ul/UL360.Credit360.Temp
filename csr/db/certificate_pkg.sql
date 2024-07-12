CREATE OR REPLACE PACKAGE csr.certificate_pkg AS

PROCEDURE GetCertsToProcess(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCertList(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddCertToList(
	in_cert_hash		IN	sso_certificate_status.cert_hash%TYPE,
	in_sso_cert_id		IN	sso_certificate_status.sso_cert_id%TYPE,
	in_host				IN	sso_certificate_status.host%TYPE,
	in_subject			IN	sso_certificate_status.subject%TYPE,
	in_not_before_dtm	IN	sso_certificate_status.not_before_dtm%TYPE,
	in_not_after_dtm	IN	sso_certificate_status.not_after_dtm%TYPE
);


END;
/