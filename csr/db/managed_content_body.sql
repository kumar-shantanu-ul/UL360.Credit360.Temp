CREATE OR REPLACE PACKAGE BODY csr.managed_content_pkg AS

PROCEDURE AssertIsTemplateSite
AS
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM managed_package
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'); 
	
	IF v_count < 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Must be on a managed content template site.');
	END IF;
END;

PROCEDURE AssociateSid(
	in_sid_id			IN	MANAGED_CONTENT_MAP.SID%TYPE,
	in_unique_ref		IN	MANAGED_CONTENT_MAP.UNIQUE_REF%TYPE,
	in_package_ref		IN	MANAGED_CONTENT_MAP.package_REF%TYPE
)
AS
BEGIN

	INSERT INTO MANAGED_CONTENT_MAP
		(sid, unique_ref, package_ref)
	VALUES
		(in_sid_id, in_unique_ref, in_package_ref);

END;

-- Annoyingly, these need their own table because they aren't SIDs, so aren't 
-- unique enough. Could add a "type" column to the managed_content_map table 
-- but then we'd need to add basedata everytime we add a new SO type.
PROCEDURE AssociateMeasureConversion(
	in_conversion_id	IN	MANAGED_CONTENT_MEASURE_CONVERSION_MAP.conversion_id%TYPE,
	in_unique_ref		IN	MANAGED_CONTENT_MEASURE_CONVERSION_MAP.UNIQUE_REF%TYPE,
	in_package_ref		IN	MANAGED_CONTENT_MEASURE_CONVERSION_MAP.package_REF%TYPE
)
AS
BEGIN

	INSERT INTO MANAGED_CONTENT_MEASURE_CONVERSION_MAP
		(conversion_id, unique_ref, package_ref)
	VALUES
		(in_conversion_id, in_unique_ref, in_package_ref);

END;

PROCEDURE LoadPackageMeasures(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT measure_sid sid, description, mcm.unique_ref unique_ref
		  FROM csr.measure m
		  JOIN CSR.MANAGED_CONTENT_MAP mcm on m.measure_sid = mcm.sid
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP'); 
END;

PROCEDURE LoadPackageMeasureConversions(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT measure_conversion_id sid, description, mcmcm.unique_ref unique_ref
		  FROM csr.measure_conversion mc
		  JOIN CSR.MANAGED_CONTENT_MEASURE_CONVERSION_MAP mcmcm on mc.measure_conversion_id = mcmcm.conversion_id
		 WHERE mc.app_sid = SYS_CONTEXT('SECURITY', 'APP'); 
END;

PROCEDURE LoadPackageIndicators(
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_ind_root		csr.ind.parent_sid%TYPE;
BEGIN
	v_ind_root := Securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Indicators');
	OPEN out_cur FOR
		SELECT ind_sid sid, description, mcm.unique_ref unique_ref, case when i.calc_xml is not null then 1 else 0 end is_calc, case when i.parent_sid = v_ind_root then NULL else i.parent_sid end parent_sid, case when i.gas_type_id is not null then 1 else 0 end is_emission_factor_child
		  FROM csr.v$ind i
		  JOIN CSR.MANAGED_CONTENT_MAP mcm on i.ind_sid = mcm.sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP'); 
END;

PROCEDURE EnsureMeasureReferencesSet
AS
	v_pkg_ref			csr.managed_package.package_ref%TYPE;
BEGIN
	AssertIsTemplateSite;
	
	SELECT package_ref
	  INTO v_pkg_ref
	  FROM managed_package
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	INSERT INTO managed_content_map
	  (sid, unique_ref, package_ref)
	SELECT measure_sid, SYS_GUID(), v_pkg_ref
	  FROM measure
	 WHERE measure_sid NOT IN (
	  SELECT sid 
	    FROM managed_content_map
	 )
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- And conversions
	INSERT INTO managed_content_measure_conversion_map
		(conversion_id, unique_ref, package_ref)
	SELECT measure_conversion_id, SYS_GUID(), v_pkg_ref
	  FROM measure_conversion
	 WHERE measure_conversion_id NOT IN (
	  SELECT conversion_id
	    FROM managed_content_measure_conversion_map
	 )
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE EnsureIndicatorReferencesSet
AS
	v_pkg_ref			csr.managed_package.package_ref%TYPE;
BEGIN
	AssertIsTemplateSite;
	
	SELECT package_ref
	  INTO v_pkg_ref
	  FROM managed_package
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	INSERT INTO managed_content_map
	  (sid, unique_ref, package_ref)
	SELECT ind_sid, SYS_GUID(), v_pkg_ref
	  FROM ind
	 WHERE ind_sid not in (
	  SELECT sid 
	    FROM managed_content_map
	 )
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE Internal_TryDeleteMeasure(
	in_name			IN	csr.measure.name%TYPE,
	in_custom_field	IN	csr.measure.custom_field%TYPE
)
AS
	v_measure_sid		csr.measure.measure_sid%TYPE;
BEGIN
	BEGIN
		SELECT measure_sid
		  INTO v_measure_sid
		  FROM csr.measure
		 WHERE custom_field = in_custom_field
		   AND LOWER(name) = LOWER(in_name);
		
		security.securableobject_pkg.DeleteSO(
			in_act_id => security_pkg.GetAct, 
			in_sid_id => v_measure_sid
		);
	EXCEPTION WHEN OTHERS THEN
		-- Don't care why it failed... It's probably in use, or maybe not found.
		-- We just want to _try_ and delete it, and move on if it fails!
		NULL;
	END;
END;

PROCEDURE EnableManagedPackagedContent(
	in_package_name	IN VARCHAR2,
	in_package_ref	IN VARCHAR2
)
AS
	v_package_ref	VARCHAR2(1024);
	v_existing_ref	csr.managed_package.package_ref%TYPE;
	v_cnt			NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM ind_selection_group_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Indicator selection groups found!');
	END IF;

	-- Upsert; package name can change, but the reference cannot.
	BEGIN
		SELECT package_ref
		  INTO v_existing_ref
		  FROM managed_package
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		-- Could validate that the existing ref contains the one passed in, 
		-- but for now just going to update the row.
		UPDATE managed_package
		   SET package_name = in_package_name
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- INSERT
			IF LENGTH(in_package_ref) = 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Package ref not specified!');
			END IF;
			
			v_package_ref := in_package_ref || '-' || SYS_GUID();
			INSERT INTO managed_package (app_sid, package_name, package_ref)
			VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_package_name, in_package_ref);
	END;
	
	-- Try and delete the default measures.
	Internal_TryDeleteMeasure(
		in_name			=> 'date',
		in_custom_field => '$'
	);
	Internal_TryDeleteMeasure(
		in_name			=> 'text',
		in_custom_field => '|'
	);
	Internal_TryDeleteMeasure(
		in_name			=> 'fileupload',
		in_custom_field => '&'
	);

END;

PROCEDURE GetSummaryInfo(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, package_name, package_ref
		  FROM managed_package
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetLogRunID(
	in_package_ref	IN VARCHAR2,
	out_managed_content_unpackager_run_id OUT managed_content_unpackage_log_run.run_id%TYPE
)
AS
BEGIN
	SELECT csr.managed_content_unpackage_run_seq.nextval
	  INTO out_managed_content_unpackager_run_id
	  FROM dual;

	WriteLogMessage(out_managed_content_unpackager_run_id, 'I', 'Starting managed content unpackaging with run id: '||out_managed_content_unpackager_run_id||' for app: '||SYS_CONTEXT('SECURITY', 'APP')||' package ref: '||in_package_ref);
END;

PROCEDURE WriteLogMessage(
	in_run_id 		IN managed_content_unpackage_log_run.run_id%TYPE,
	in_severity		IN managed_content_unpackage_log_run.severity%TYPE,
	in_message 		IN managed_content_unpackage_log_run.message%TYPE
)
AS
BEGIN
	INSERT INTO managed_content_unpackage_log_run(app_sid, run_id, message_id, severity, msg_dtm, message)
	VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_run_id, csr.managed_content_unpackage_msg_seq.nextval, in_severity, SYSDATE, in_message);
END;

END;
/
