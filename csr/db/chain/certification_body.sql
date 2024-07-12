CREATE OR REPLACE PACKAGE BODY CHAIN.certification_pkg
IS

PROCEDURE GetCertificationTypes (
	out_cert_types_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_audit_types_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cert_types_cur FOR
		SELECT certification_type_id, label, lookup_key, product_requirement_type_id
		  FROM certification_type
		 ORDER BY LOWER(label);

	OPEN out_audit_types_cur FOR
		SELECT iat.internal_audit_type_id, iat.label, cat.certification_type_id
		  FROM csr.internal_audit_type iat
		  JOIN cert_type_audit_type cat
			ON iat.app_sid = cat.app_sid
		   AND iat.internal_audit_type_id = cat.internal_audit_type_id
		ORDER BY LOWER(iat.label);
END;

PROCEDURE GetCertificationsForCompany (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_certification_type_id		IN	v$supplier_certification.certification_id%TYPE,
	in_get_only_latest				IN	NUMBER DEFAULT 1,
	out_certifications_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	IF v_company_sid = in_company_sid THEN
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.VIEW_CERTIFICATIONS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'View certifications access denied to company '||v_company_sid);
		END IF;
	ELSE
		IF NOT type_capability_pkg.CheckCapability(v_company_sid, in_company_sid, chain_pkg.VIEW_CERTIFICATIONS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'View certifications on company '||in_company_sid||' access denied to company '||v_company_sid);
		END IF;
	END IF;

	OPEN out_certifications_cur FOR
		SELECT c.certification_id, c.certification_type_id, c.company_sid, ct.label certification_type_label, c.valid_from_dtm, c.expiry_dtm, act.label result, c.internal_audit_sid
		  FROM (
				SELECT sc.certification_id, sc.certification_type_id, sc.internal_audit_sid, sc.company_sid, sc.valid_from_dtm, sc.expiry_dtm,
					   sc.audit_closure_type_id, ROW_NUMBER() OVER(PARTITION BY sc.company_sid, sc.certification_type_id ORDER BY sc.valid_from_dtm DESC) rn
				  FROM v$supplier_certification sc 
				 WHERE sc.company_sid = in_company_sid
				) c
		  JOIN certification_type ct ON ct.certification_type_id = c.certification_type_id
		  LEFT JOIN csr.audit_closure_type act ON act.audit_closure_type_id = c.audit_closure_type_id
		 WHERE (in_get_only_latest = 0 OR rn = 1)
		   AND (in_certification_type_id IS NULL OR ct.certification_type_id = in_certification_type_id)
		 ORDER BY c.valid_from_dtm DESC;
END;

PROCEDURE SaveCertificationType (
	in_cert_type_id			IN	certification_type.certification_type_id%TYPE,
	in_label				IN	certification_type.label%TYPE,
	in_lookup_key			IN	certification_type.lookup_key%TYPE,
	in_requirement_type_id	IN	certification_type.product_requirement_type_id%TYPE,
	in_audit_type_ids		IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_cert_type_id			certification_type.certification_type_id%TYPE;
	v_split_char			VARCHAR(1) := ',';
	v_table					ASPEN2.T_SPLIT_NUMERIC_TABLE := ASPEN2.T_SPLIT_NUMERIC_TABLE();
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit certification types');
	END IF;
	
	IF NVL(in_cert_type_id, -1) =-1 THEN
		INSERT INTO certification_type(certification_type_id, label, lookup_key, product_requirement_type_id)
		VALUES (certification_type_id_seq.NEXTVAL, in_label, in_lookup_key, in_requirement_type_id)
		RETURNING certification_type_id INTO v_cert_type_id;
	ELSE
		UPDATE certification_type
		   SET label = in_label,
			   lookup_key = in_lookup_key,
			   product_requirement_type_id = in_requirement_type_id
		 WHERE certification_type_id = in_cert_type_id;
		 
		v_cert_type_id := in_cert_type_id;
	END IF;

	v_table := aspen2.utils_pkg.SplitNumericString(in_audit_type_ids, v_split_char);
	
	DELETE FROM cert_type_audit_type
	 WHERE certification_type_id = v_cert_type_id
	   AND app_sid = security_pkg.GetApp
	   AND internal_audit_type_id NOT IN (SELECT t.ITEM FROM TABLE(v_table) t);
	
	INSERT INTO cert_type_audit_type(certification_type_id, internal_audit_type_id)
		SELECT	v_cert_type_id certification_type_id,
				t.ITEM internal_audit_type_id
			FROM TABLE(v_table) t
			WHERE t.ITEM NOT IN (SELECT internal_audit_type_id FROM cert_type_audit_type WHERE certification_type_id = v_cert_type_id);

	OPEN out_cur FOR
		SELECT certification_type_id, label, lookup_key, product_requirement_type_id
		  FROM certification_type
		 WHERE certification_type_id = v_cert_type_id;
END;


PROCEDURE DeleteCertificationType (
	in_cert_type_id			IN	certification_type.certification_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete certification types');
	END IF;

	DELETE FROM cert_type_audit_type
	 WHERE certification_type_id = in_cert_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM certification_type
	 WHERE certification_type_id = in_cert_type_id
	   AND app_sid = security_pkg.GetApp;
END;


END certification_pkg;
/
