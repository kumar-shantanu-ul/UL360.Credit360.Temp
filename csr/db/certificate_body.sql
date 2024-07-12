CREATE OR REPLACE PACKAGE BODY csr.certificate_pkg AS

PROCEDURE CleanUpDeletedCerts
AS
BEGIN
	DELETE FROM sso_certificate_status
	 WHERE (
		cert_hash NOT IN (
			SELECT cert_hash
			  FROM security.user_certificates
		)
		AND cert_hash IS NOT NULL
	   ) OR (
		sso_cert_id NOT IN (
			SELECT sso_cert_id
			  FROM customer_saml_sso_cert
		)
		AND sso_cert_id IS NOT NULL
	  );
END;

PROCEDURE GetCertsToProcess(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CleanUpDeletedCerts;
	
	OPEN out_cur FOR
		SELECT cs.cert, c.host, sso_cert_id, cert_hash
		  FROM (
			SELECT public_signing_cert cert, app_sid, sso_cert_id, NULL cert_hash
			  FROM csr.customer_saml_sso_cert
			UNION ALL
			SELECT cert, cu.app_sid, NULL, cert_hash
			  FROM security.user_certificates uc
			  JOIN csr.csr_user cu ON cu.csr_user_sid = uc.sid_id
			) cs JOIN csr.customer c ON c.app_sid = cs.app_sid
		  WHERE (cs.cert_hash IS NOT NULL AND cs.cert_hash NOT IN (
			SELECT cert_hash
			  FROM csr.sso_certificate_status
			 WHERE cert_hash IS NOT NULL
		  )) OR (cs.sso_cert_id IS NOT NULL AND cs.sso_cert_id NOT IN (
			SELECT sso_cert_id
			  FROM csr.sso_certificate_status
			 WHERE sso_cert_id IS NOT NULL
		  ));
END;

PROCEDURE GetCertList(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT host, subject, not_before_dtm, not_after_dtm, CASE WHEN sso_cert_id IS NULL THEN 0 ELSE 1 END is_saml
		  FROM sso_certificate_status
		 ORDER BY not_after_dtm ASC;
END;

PROCEDURE AddCertToList(
	in_cert_hash		IN	sso_certificate_status.cert_hash%TYPE,
	in_sso_cert_id		IN	sso_certificate_status.sso_cert_id%TYPE,
	in_host				IN	sso_certificate_status.host%TYPE,
	in_subject			IN	sso_certificate_status.subject%TYPE,
	in_not_before_dtm	IN	sso_certificate_status.not_before_dtm%TYPE,
	in_not_after_dtm	IN	sso_certificate_status.not_after_dtm%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO sso_certificate_status 
			(cert_hash, sso_cert_id, host, subject, not_before_dtm, not_after_dtm)
		VALUES
			(in_cert_hash, in_sso_cert_id, in_host, in_subject, in_not_before_dtm, in_not_after_dtm);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

END;
/
