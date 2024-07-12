CREATE OR REPLACE PACKAGE BODY csr.region_certificate_pkg AS

/* This was pulled out of compliance_body - should be moved somewhere common */
FUNCTION INTERNAL_IsSuperAdmin RETURN BOOLEAN
AS
BEGIN
	RETURN csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct);
END;

FUNCTION INTERNAL_IsInAdminGroup RETURN BOOLEAN
AS
BEGIN
	RETURN (user_pkg.IsUserInGroup(
		security_pkg.GetAct,
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp(), 'Groups/Administrators')) = 1);
END;

FUNCTION INTERNAL_IsAdmin RETURN BOOLEAN
AS
BEGIN
	RETURN (INTERNAL_IsSuperAdmin OR INTERNAL_IsInAdminGroup);
END;

PROCEDURE INTERNAL_AssertAdmin
AS
BEGIN
	IF NOT (INTERNAL_IsAdmin) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied. Only BuiltinAdministrator, super admins or members of the administrator group can access this.'
		);
	END IF;
END;

-- basedata sps superadmin ONLY
PROCEDURE SaveCertification (
	in_certification_id				IN	certification.certification_id%TYPE,
	in_name							IN	certification.name%TYPE,
	in_external_id					IN	certification.external_id%TYPE,
	in_type_lookup_key				IN	certification_type.lookup_key%TYPE
)
AS
	v_type_id						certification_type.certification_type_id%TYPE;
BEGIN
	IF NOT (INTERNAL_IsSuperAdmin) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied. Only SuperAdmins can add certificate basedata.'
		);
	END IF;

	BEGIN
		SELECT certification_type_id 
		  INTO v_type_id
		  FROM csr.certification_type
		 WHERE lookup_key = in_type_lookup_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'No certificate type with the lookup '|| in_type_lookup_key ||' could be found.');
	END;

	INSERT INTO certification (certification_id, certification_type_id, external_id, name)
	VALUES (in_certification_id, v_type_id, in_external_id, in_name);
END;

PROCEDURE SaveCertificationLevel (
	in_certification_id				IN	certification.certification_id%TYPE,
	in_name							IN	certification.name%TYPE,
	in_pos							IN	certification.external_id%TYPE
)
AS
BEGIN
	IF NOT (INTERNAL_IsSuperAdmin) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied. Only SuperAdmins can add certificate basedata.'
		);
	END IF;

	INSERT INTO certification_level (certification_level_id, certification_id, name, position)
	VALUES (CSR.CERT_LEVEL_ID_SEQ.NEXTVAL, in_certification_id, in_name, in_pos);
END;

PROCEDURE SaveEnergyRating (
	in_energy_rating_id				IN	energy_rating.energy_rating_id%TYPE,
	in_name							IN	energy_rating.name%TYPE,
	in_external_id					IN	energy_rating.external_id%TYPE,
	in_type_lookup_key				IN	certification_type.lookup_key%TYPE
)
AS
	v_type_id						certification_type.certification_type_id%TYPE;
BEGIN
	IF NOT (INTERNAL_IsSuperAdmin) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied. Only SuperAdmins can add certificate basedata.'
		);
	END IF;

	BEGIN
		SELECT certification_type_id 
		  INTO v_type_id
		  FROM csr.certification_type
		 WHERE lookup_key = in_type_lookup_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'No certificate type with the lookup '|| in_type_lookup_key ||' could be found.');
	END;

	INSERT INTO energy_rating (energy_rating_id, certification_type_id, external_id, name)
	VALUES (in_energy_rating_id, v_type_id, in_external_id, in_name);
END;

-- certs
PROCEDURE GetCertificatesByTypeLookup(
	in_type_lookup_key				IN	certification_type.lookup_key%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_type_id						certification_type.certification_type_id%TYPE;
BEGIN
	-- BASE DATA
	-- NO SECURITY CHECKS NEEDED
	BEGIN
		SELECT certification_type_id 
		  INTO v_type_id
		  FROM csr.certification_type
		 WHERE lookup_key = in_type_lookup_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'No certificate type with the lookup '|| in_type_lookup_key ||' could be found.');
	END;

	GetCertificatesByTypeId(v_type_id, out_cur);
END;

PROCEDURE GetCertificatesByTypeId(
	in_type_id						IN	certification_type.certification_type_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- BASE DATA
	-- NO SECURITY CHECKS NEEDED
	OPEN out_cur FOR
		SELECT certification_id, certification_type_id, external_id, name
		  FROM csr.certification
		 WHERE certification_type_id = in_type_id
		 ORDER BY certification_id;
END;

PROCEDURE GetCertificatesByRegion(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	OPEN out_cur FOR
		SELECT rc.region_certificate_id, rc.region_sid, rc.certification_id, c.external_id, c.name, rc.certification_level_id,
				cl.name certification_level_name, rc.certificate_number, rc.floor_area,
				rc.issued_dtm, rc.expiry_dtm, rc.external_certificate_id, rc.note, rc.submit_to_gresb
		  FROM csr.region_certificate rc
		  JOIN csr.certification c ON rc.certification_id = c.certification_id
		  LEFT JOIN csr.certification_level cl ON cl.certification_level_id = rc.certification_level_id
		 WHERE rc.app_sid = v_app_sid
		   AND deleted = 0
		ORDER BY region_sid, certification_id, issued_dtm DESC, expiry_dtm DESC NULLS FIRST, name, certification_level_id;
END;

PROCEDURE GetDeletedCertificatesByRegion(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	OPEN out_cur FOR
		SELECT rc.region_certificate_id, rc.region_sid, rc.certification_id, c.external_id, c.name, rc.certification_level_id,
				cl.name certification_level_name, rc.certificate_number, rc.floor_area,
				rc.issued_dtm, rc.expiry_dtm, rc.external_certificate_id, rc.note, rc.submit_to_gresb
		  FROM csr.region_certificate rc
		  JOIN csr.certification c ON rc.certification_id = c.certification_id
		  LEFT JOIN csr.certification_level cl ON cl.certification_level_id = rc.certification_level_id
		 WHERE rc.app_sid = v_app_sid
		   AND deleted = 1
		   AND external_certificate_id IS NOT NULL
		ORDER BY region_sid, certification_id, certificate_number NULLS LAST, issued_dtm DESC, expiry_dtm DESC NULLS FIRST, name, certification_level_id;
END;

PROCEDURE GetCertificatesForRegionSid(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	IF NOT property_pkg.CanViewProperty(in_region_sid) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT rc.region_certificate_id, rc.region_sid, rc.certification_id, c.external_id, c.name, rc.certification_level_id,
				cl.name certification_level_name, rc.certificate_number, rc.floor_area,
				rc.issued_dtm, rc.expiry_dtm, rc.external_certificate_id, rc.note, rc.submit_to_gresb
		  FROM csr.region_certificate rc
		  JOIN csr.certification c ON rc.certification_id = c.certification_id
		  LEFT JOIN csr.certification_level cl ON cl.certification_level_id = rc.certification_level_id
		 WHERE rc.region_sid = in_region_sid
		   AND rc.app_sid = v_app_sid
		   AND rc.deleted = 0
		 ORDER BY certificate_number NULLS LAST, issued_dtm DESC, expiry_dtm DESC NULLS FIRST, name, certification_level_name;
END;

PROCEDURE GetDeletedCertificatesForRegionSid(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	IF NOT property_pkg.CanViewProperty(in_region_sid) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT rc.region_certificate_id, rc.region_sid, rc.certification_id, c.external_id, c.name, rc.certification_level_id,
				cl.name certification_level_name, rc.certificate_number, rc.floor_area,
				rc.issued_dtm, rc.expiry_dtm, rc.external_certificate_id, rc.note, rc.submit_to_gresb
		  FROM csr.region_certificate rc
		  JOIN csr.certification c ON rc.certification_id = c.certification_id
		  LEFT JOIN csr.certification_level cl ON cl.certification_level_id = rc.certification_level_id
		 WHERE rc.region_sid = in_region_sid
		   AND rc.app_sid = v_app_sid
		   AND rc.deleted = 1
		   AND external_certificate_id IS NOT NULL
		 ORDER BY certificate_number NULLS LAST, issued_dtm DESC, expiry_dtm DESC NULLS FIRST, name, certification_level_name;
END;

PROCEDURE GetCertificateLevels(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	OPEN out_cur FOR
		SELECT certification_level_id, certification_id, position, name
		  FROM csr.certification_level
		 ORDER BY certification_level_id, certification_id, position;
END;

PROCEDURE GetCertificateLevelsByCertificationId(
	in_certification_id						IN	certification_level.certification_id%TYPE,
	out_cur									OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	OPEN out_cur FOR
		SELECT certification_level_id, name
		  FROM csr.certification_level
		 WHERE certification_id = in_certification_id
		 ORDER BY certification_level_id, certification_id;
END;

PROCEDURE AddCertificateForRegion(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_certification_id				IN  region_certificate.certification_id%TYPE,
	in_certification_level_id		IN  region_certificate.certification_level_id%TYPE,
	in_certificate_number			IN  region_certificate.certificate_number%TYPE,
	in_floor_area					IN  region_certificate.floor_area%TYPE,
	in_expiry_dtm					IN  region_certificate.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_certificate.issued_dtm%TYPE,
	in_note							IN  region_certificate.note%TYPE,
	in_submit_to_gresb				IN  region_certificate.submit_to_gresb%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_is_editable					NUMBER;
	v_is_readable					BOOLEAN;
BEGIN
	v_is_readable := property_pkg.CanViewProperty(in_region_sid, v_is_editable);

	IF v_is_editable = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	INSERT INTO csr.region_certificate (app_sid, region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
	VALUES (v_app_sid, csr.region_certificate_id_seq.NEXTVAL, in_region_sid, in_certification_id, in_certification_level_id, in_certificate_number, in_floor_area, in_issued_dtm, in_expiry_dtm, in_note, in_submit_to_gresb);
END;

PROCEDURE UpdateCertificateForRegion(
	in_region_certificate_id		IN	region_certificate.region_certificate_id%TYPE,
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_certification_id				IN  region_certificate.certification_id%TYPE,
	in_certification_level_id		IN  region_certificate.certification_level_id%TYPE,
	in_certificate_number			IN  region_certificate.certificate_number%TYPE,
	in_floor_area					IN  region_certificate.floor_area%TYPE,
	in_expiry_dtm					IN  region_certificate.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_certificate.issued_dtm%TYPE,
	in_note							IN  region_certificate.note%TYPE,
	in_submit_to_gresb				IN  region_certificate.submit_to_gresb%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_is_editable					NUMBER;
	v_is_readable					BOOLEAN;
BEGIN
	v_is_readable := property_pkg.CanViewProperty(in_region_sid, v_is_editable);

	IF v_is_editable = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	UPDATE csr.region_certificate
	   SET certificate_number = in_certificate_number,
		   certification_level_id = in_certification_level_id,
		   floor_area =  in_floor_area,
		   issued_dtm = in_issued_dtm,
		   expiry_dtm = in_expiry_dtm,
		   note = in_note,
		   submit_to_gresb = in_submit_to_gresb
	 WHERE app_sid = v_app_sid
	   AND region_certificate_id = in_region_certificate_id;
END;

PROCEDURE AdminUpsertCertificateForRegion(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_certification_id				IN  region_certificate.certification_id%TYPE,
	in_certification_level_id		IN  region_certificate.certification_level_id%TYPE,
	in_certificate_number			IN  region_certificate.certificate_number%TYPE,
	in_floor_area					IN  region_certificate.floor_area%TYPE,
	in_expiry_dtm					IN  region_certificate.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_certificate.issued_dtm%TYPE,
	in_note							IN  region_certificate.note%TYPE,
	in_submit_to_gresb				IN  region_certificate.submit_to_gresb%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	UPDATE csr.region_certificate
	   SET certificate_number = in_certificate_number,
		   floor_area =  in_floor_area,
		   expiry_dtm = in_expiry_dtm,
		   issued_dtm = in_issued_dtm,
		   note = in_note,
		   submit_to_gresb = in_submit_to_gresb
	WHERE app_sid = v_app_sid
	  AND region_sid = in_region_sid
	  AND certification_id = in_certification_id
	  AND certification_level_id = in_certification_level_id;
	
	IF SQL%ROWCOUNT = 0 THEN
		BEGIN
			INSERT INTO csr.region_certificate (app_sid, region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
			VALUES (v_app_sid, csr.region_certificate_id_seq.NEXTVAL, in_region_sid, in_certification_id, in_certification_level_id, in_certificate_number, in_floor_area, in_issued_dtm, in_expiry_dtm, in_note, in_submit_to_gresb);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A certificate with id: '|| in_certification_id ||' and level ' || in_certification_level_id || ' is already assigned to this region.');
		END;
	END IF;
END;

PROCEDURE SetExternalCertificateId(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_external_certification_id	IN  certification.external_id%TYPE,
	in_certification_level_name		IN  certification_level.name%TYPE,
	in_floor_area					IN  region_certificate.floor_area%TYPE,
	in_external_certificate_id		IN  region_certificate.external_certificate_id%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_is_editable					NUMBER;
	v_is_readable					BOOLEAN;
	v_certification_id				region_certificate.certification_id%TYPE;
	v_certification_level_id		region_certificate.certification_level_id%TYPE;
BEGIN
	v_is_readable := property_pkg.CanViewProperty(in_region_sid, v_is_editable);

	IF v_is_editable = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	SELECT certification_id
	  INTO v_certification_id
	  FROM csr.certification
	 WHERE external_id = in_external_certification_id;

	IF in_certification_level_name IS NOT NULL THEN
		SELECT certification_level_id
		  INTO v_certification_level_id
		  FROM csr.certification_level
		 WHERE certification_id = v_certification_id
		   AND name = in_certification_level_name;
	END IF;

	UPDATE csr.region_certificate
	   SET external_certificate_id = in_external_certificate_id,
		   floor_area = in_floor_area
	 WHERE app_sid = v_app_sid
	   AND region_sid = in_region_sid
	   AND certification_id = v_certification_id
	   AND NVL(certification_level_id, -1) = NVL(v_certification_level_id, -1)
	   AND (external_certificate_id IS NULL OR external_certificate_id = in_external_certificate_id);

	IF SQL%ROWCOUNT = 0 THEN
		AdminUpsertCertificateForRegion(
			in_region_sid					=> in_region_sid,
			in_certification_id				=> v_certification_id,
			in_certification_level_id		=> v_certification_level_id,
			in_certificate_number			=> NULL,
			in_floor_area					=> in_floor_area,
			in_expiry_dtm					=> NULL,
			in_issued_dtm					=> NULL,
			in_note							=> NULL,
			in_submit_to_gresb				=> 0
		);
		UPDATE csr.region_certificate
		   SET external_certificate_id = in_external_certificate_id
		 WHERE app_sid = v_app_sid
		   AND region_sid = in_region_sid
		   AND certification_id = v_certification_id
		   AND NVL(certification_level_id, -1) = NVL(v_certification_level_id, -1)
		   AND external_certificate_id IS NULL;
	END IF;
END;

PROCEDURE DeleteCertificateForRegion(
	in_region_certificate_id		IN	region_certificate.region_certificate_id%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_region_sid					security.security_pkg.T_SID_ID;
	v_is_editable					NUMBER;
	v_is_readable					BOOLEAN;
BEGIN
	SELECT region_sid
	  INTO v_region_sid
	  FROM csr.region_certificate
	 WHERE region_certificate_id = in_region_certificate_id;

	IF v_region_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'No region certificate found for '||in_region_certificate_id);
	END IF;

	v_is_readable := property_pkg.CanViewProperty(v_region_sid, v_is_editable);

	IF v_is_editable = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||v_region_sid);
	END IF;

	UPDATE csr.region_certificate
	   SET deleted = 1
	 WHERE app_sid = v_app_sid
	   AND region_certificate_id = in_region_certificate_id;
	
	-- Hard-delete record if never submitted to gresb
	DELETE from csr.region_certificate
	 WHERE app_sid = v_app_sid
	   AND region_certificate_id = in_region_certificate_id
	   AND deleted = 1
	   AND external_certificate_id IS NULL;
END;

PROCEDURE AdminDeleteCertificatesForRegion(
	in_region_sid					IN	region_certificate.region_sid%TYPE,
	in_region_certificate_id		IN  region_certificate.region_certificate_id%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	UPDATE csr.region_certificate
	   SET deleted = 1
	 WHERE app_sid = v_app_sid
	   AND region_sid = in_region_sid
	   AND region_certificate_id = in_region_certificate_id;
END;

PROCEDURE AdminCleanupDeletedCertificatesForRegion(
	in_region_sid					IN	region_certificate.region_sid%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	DELETE FROM csr.region_certificate
	 WHERE app_sid = v_app_sid
	   AND region_sid = in_region_sid
	   AND deleted = 1;
END;

-- energy ratings 
FUNCTION INTERNAL_EnergyRatingsMarkedForSubmission (
	in_region_sid					IN	region_energy_rating.region_sid%TYPE
) RETURN NUMBER
AS
	v_cnt							NUMBER(10);
BEGIN
	SELECT COUNT(region_sid)
	  INTO v_cnt
	  FROM csr.region_energy_rating
	 WHERE region_sid = in_region_sid
	   AND submit_to_gresb = 1;

	RETURN v_cnt;
END;

PROCEDURE GetEnergyRatingsByTypeLookup(
	in_type_lookup_key				IN	certification_type.lookup_key%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_type_id						certification_type.certification_type_id%TYPE;
BEGIN
	-- BASE DATA
	-- NO SECURITY CHECKS NEEDED
	BEGIN
		SELECT certification_type_id 
		  INTO v_type_id
		  FROM csr.certification_type
		 WHERE lookup_key = in_type_lookup_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'No certificate type with the lookup '|| in_type_lookup_key ||' could be found.');
	END;

	GetEnergyRatingsByTypeId(v_type_id, out_cur);
END;

PROCEDURE GetEnergyRatingsByTypeId(
	in_type_id						IN	certification_type.certification_type_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- BASE DATA
	-- NO SECURITY CHECKS NEEDED
	OPEN out_cur FOR
		SELECT energy_rating_id, certification_type_id, external_id, name
		  FROM csr.energy_rating
		 WHERE certification_type_id = in_type_id
		 ORDER BY energy_rating_id;
END;

PROCEDURE GetEnergyRatingsForRegionSid(
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	IF NOT property_pkg.CanViewProperty(in_region_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT rer.region_energy_rating_id, rer.region_sid, rer.energy_rating_id, er.external_id, er.name, rer.floor_area, 
			rer.issued_dtm, rer.expiry_dtm, rer.note, rer.submit_to_gresb
		  FROM csr.region_energy_rating rer
		  JOIN csr.energy_rating er ON rer.energy_rating_id = er.energy_rating_id
		 WHERE rer.region_sid = in_region_sid
		   AND rer.app_sid = v_app_sid
		 ORDER BY region_sid, energy_rating_id, issued_dtm DESC, expiry_dtm DESC NULLS FIRST, name;
END;

PROCEDURE GetEnergyRatingsByRegion(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	OPEN out_cur FOR
		SELECT rer.region_energy_rating_id, rer.region_sid, rer.energy_rating_id, er.external_id, er.name, rer.floor_area, 
			rer.issued_dtm, rer.expiry_dtm, rer.note, rer.submit_to_gresb
		  FROM csr.region_energy_rating rer
		  JOIN csr.energy_rating er ON rer.energy_rating_id = er.energy_rating_id
		 WHERE rer.app_sid = v_app_sid
		 ORDER BY region_sid, energy_rating_id, issued_dtm DESC, expiry_dtm DESC NULLS FIRST, name;
END;

PROCEDURE AddEnergyRatingForRegion(
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_energy_rating_id				IN  region_energy_rating.energy_rating_id%TYPE,
	in_floor_area					IN  region_energy_rating.floor_area%TYPE,
	in_expiry_dtm					IN  region_energy_rating.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_energy_rating.issued_dtm%TYPE,
	in_note							IN  region_energy_rating.note%TYPE,
	in_submit_to_gresb				IN  region_energy_rating.submit_to_gresb%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_is_editable					NUMBER;
	v_is_readable					BOOLEAN;
	v_submittable_ers				NUMBER;
BEGIN
	v_is_readable := property_pkg.CanViewProperty(in_region_sid, v_is_editable);

	IF v_is_editable = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	IF in_submit_to_gresb = 1 THEN
		v_submittable_ers := INTERNAL_EnergyRatingsMarkedForSubmission(in_region_sid);
		IF v_submittable_ers > 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Only one Energy Rating can be submitted to GRESB for this region.');
		END IF;
	END IF;

	INSERT INTO csr.region_energy_rating (app_sid, region_energy_rating_id, region_sid, energy_rating_id, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
	VALUES (v_app_sid, CSR.REGION_ENERGY_RATING_ID_SEQ.NEXTVAL, in_region_sid, in_energy_rating_id, in_floor_area, in_issued_dtm, in_expiry_dtm, in_note, in_submit_to_gresb);
END;

PROCEDURE UpdateEnergyRatingForRegion(
	in_region_energy_rating_id		IN	region_energy_rating.region_energy_rating_id%TYPE,
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_energy_rating_id				IN  region_energy_rating.energy_rating_id%TYPE,
	in_floor_area					IN  region_energy_rating.floor_area%TYPE,
	in_expiry_dtm					IN  region_energy_rating.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_energy_rating.issued_dtm%TYPE,
	in_note							IN  region_energy_rating.note%TYPE,
	in_submit_to_gresb				IN  region_energy_rating.submit_to_gresb%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_is_editable					NUMBER;
	v_is_readable					BOOLEAN;
	v_submittable_ers				NUMBER;
BEGIN
	v_is_readable := property_pkg.CanViewProperty(in_region_sid, v_is_editable);

	IF v_is_editable = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	IF in_submit_to_gresb = 1 THEN
		v_submittable_ers := INTERNAL_EnergyRatingsMarkedForSubmission(in_region_sid);
		IF v_submittable_ers > 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Only one Energy Rating can be submitted to GRESB for this region.');
		END IF;
	END IF;

	UPDATE csr.region_energy_rating 
	   SET energy_rating_id = in_energy_rating_id,
		   floor_area =  in_floor_area,
		   expiry_dtm = in_expiry_dtm,
		   issued_dtm = in_issued_dtm,
		   note = in_note,
		   submit_to_gresb = in_submit_to_gresb
	 WHERE app_sid = v_app_sid
	   AND region_energy_rating_id = in_region_energy_rating_id;
END;

PROCEDURE AdminUpsertEnergyRatingForRegion(
	in_region_energy_rating_id		IN	region_energy_rating.region_energy_rating_id%TYPE,
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_energy_rating_id				IN  region_energy_rating.energy_rating_id%TYPE,
	in_floor_area					IN  region_energy_rating.floor_area%TYPE,
	in_expiry_dtm					IN  region_energy_rating.expiry_dtm%TYPE,
	in_issued_dtm					IN  region_energy_rating.issued_dtm%TYPE,
	in_note							IN  region_energy_rating.note%TYPE,
	in_submit_to_gresb				IN  region_energy_rating.submit_to_gresb%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	IF in_submit_to_gresb = 1 THEN
		UPDATE csr.region_energy_rating SET submit_to_gresb = 0 WHERE region_sid = in_region_sid;
	END IF;

	IF in_region_energy_rating_id = 0 THEN
		INSERT INTO csr.region_energy_rating (app_sid, region_energy_rating_id, region_sid, energy_rating_id, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
		VALUES (v_app_sid, CSR.REGION_ENERGY_RATING_ID_SEQ.NEXTVAL, in_region_sid, in_energy_rating_id, in_floor_area, in_issued_dtm, in_expiry_dtm, in_note, in_submit_to_gresb);
	ELSE
		-- There can be only one. Per region.
		UPDATE csr.region_energy_rating 
		   SET energy_rating_id = in_energy_rating_id,
			   floor_area =  in_floor_area,
			   expiry_dtm = in_expiry_dtm,
			   issued_dtm = in_issued_dtm,
			   note = in_note,
			   submit_to_gresb = in_submit_to_gresb
		 WHERE app_sid = v_app_sid
		   AND region_sid = in_region_sid
		   AND region_energy_rating_id = in_region_energy_rating_id;
	END IF;
END;

PROCEDURE DeleteEnergyRatingForRegion(
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_region_energy_rating_id		IN  region_energy_rating.region_energy_rating_id%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_is_editable					NUMBER;
	v_is_readable					BOOLEAN;
BEGIN
	v_is_readable := property_pkg.CanViewProperty(in_region_sid, v_is_editable);

	IF v_is_editable = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	DELETE FROM csr.region_energy_rating
	 WHERE app_sid = v_app_sid
	   AND region_sid = in_region_sid
	   AND region_energy_rating_id = in_region_energy_rating_id;
END;


PROCEDURE AdminDeleteEnergyRatingForRegion(
	in_region_sid					IN	region_energy_rating.region_sid%TYPE,
	in_region_energy_rating_id		IN  region_energy_rating.region_energy_rating_id%TYPE
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_AssertAdmin;

	DELETE FROM csr.region_energy_rating
	 WHERE app_sid = v_app_sid
	   AND region_sid = in_region_sid
	   AND region_energy_rating_id = in_region_energy_rating_id;
END;
END;
/
