CREATE OR REPLACE PACKAGE BODY CSR.factor_set_group_pkg AS

PROCEDURE CheckPermissions(
	in_msg_on_err	IN	VARCHAR2
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security.Security_pkg.ERR_ACCESS_DENIED, in_msg_on_err);
	END IF;
END;

PROCEDURE CheckCapabilities
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;
END;

PROCEDURE GetFactorSetGroups(
	out_factor_set_groups	OUT SYS_REFCURSOR
)AS
BEGIN
	CheckCapabilities;

	OPEN out_factor_set_groups FOR
		SELECT factor_set_group_id, name, custom
		  FROM factor_set_group
		 ORDER BY custom ASC, 
			REGEXP_SUBSTR(LOWER(name), '^\D*') NULLS FIRST, 
			TO_NUMBER(REGEXP_SUBSTR(LOWER(name), '[0-9]+')) NULLS FIRST, 
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(name), '[0-9]+', 1, 2))) NULLS FIRST,
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(name), '[0-9]+', 1, 3))) NULLS FIRST;
END;

PROCEDURE GetFactorSetGroup(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckCapabilities;

	OPEN out_cur FOR
		SELECT factor_set_group_id, name, custom
		  FROM factor_set_group
		 WHERE factor_set_group_id = in_factor_set_group_id;
END;

PROCEDURE RenameFactorSetGroup(
	in_factor_set_group_id	IN factor_set_group.factor_set_group_id%TYPE,
	in_new_name				IN factor_set_group.name%TYPE
) AS
BEGIN
	CheckPermissions('You do not have permission to rename factor set groups');
	
	UPDATE factor_set_group
	   SET name = in_new_name
	 WHERE factor_set_group_id = in_factor_set_group_id;
END;

PROCEDURE DeleteFactorSetGroup(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE
) AS
	v_cnt	NUMBER;
BEGIN
	
	CheckPermissions('You do not have permission to edit factor set groups');
	
	SELECT COUNT(factor_set_group_id)
	  INTO v_cnt	
	  FROM (
		SELECT factor_set_group_id
		  FROM std_factor_set
		 WHERE factor_set_group_id = in_factor_set_group_id
		 UNION
		SELECT factor_set_group_id
		  FROM custom_factor_set
		 WHERE factor_set_group_id = in_factor_set_group_id
	);
	
	IF v_cnt > 0 THEN 
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
			'Factor sets exist for this factor set group '||in_factor_set_group_id);
	END IF;
	
	BEGIN
		DELETE FROM factor_set_group
		 WHERE factor_set_group_id = in_factor_set_group_id;
	EXCEPTION
		WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
				'Factor sets exist for this factor set group '||in_factor_set_group_id);
	END;

END;

PROCEDURE SaveFactorSetGroup(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE,
	in_name					IN	factor_set_group.name%TYPE,
	in_custom				IN	factor_set_group.custom%TYPE,
	out_factor_set_group	OUT	SYS_REFCURSOR
) AS
	v_fsg_id	factor_set_group.factor_set_group_id%TYPE;
BEGIN

	CheckPermissions('You do not have permission to edit factor set groups.');
	
	v_fsg_id := in_factor_set_group_id;
	
	BEGIN
		IF v_fsg_id IS NULL THEN
			INSERT INTO factor_set_group(factor_set_group_id, name, custom)
			VALUES (factor_set_grp_id_seq.nextval, in_name, in_custom)
			RETURNING factor_set_group_id INTO v_fsg_id;
		ELSE
			UPDATE factor_set_group
			   SET name = in_name,
				 custom = in_custom
			 WHERE factor_set_group_id = v_fsg_id;
			
			IF SQL%ROWCOUNT = 0 THEN
				RAISE_APPLICATION_ERROR(security.Security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to edit this factor set group '||v_fsg_id);
			END IF;
		END IF;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS, 'Factor set group of same name already exists.');
	END;
	
	GetFactorSetGroup(v_fsg_id, out_factor_set_group);
END;

PROCEDURE GetFactorSetsForGroup(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security.security_pkg.T_SID_ID;
BEGIN
	CheckPermissions('Access denied');
	
	v_app_sid := security.security_pkg.getApp;
	
	OPEN out_cur FOR
		WITH plm AS (
			SELECT std_factor_set_id, custom_factor_set_id, LISTAGG(name, ', ') WITHIN GROUP (ORDER BY name) profile
			  FROM (
				SELECT DISTINCT pf.std_factor_set_id, pf.custom_factor_set_id, p.name
				  FROM emission_factor_profile_factor pf
				  JOIN emission_factor_profile p ON pf.profile_id = p.profile_id)
			 GROUP BY std_factor_set_id, custom_factor_set_id
		)
		SELECT sfs.std_factor_set_id factor_set_id, sfs.factor_set_group_id, sfs.name factor_set_name, sfs.created_by_sid, NVL(cuc.full_name, 'Unknown') created_by, sfs.created_dtm, sfs.info_note, 
			sfs.published is_published, sfs.published_by_sid, NVL(cup.full_name, 'Unknown') published_by, sfs.published_dtm, DECODE(sfsa.app_sid, NULL, 0, 1) is_active, 0 is_custom,
			plm.profile, 
			REGEXP_SUBSTR(LOWER(sfs.name), '^\D*') order_by1, TO_NUMBER(REGEXP_SUBSTR(LOWER(sfs.name), '[0-9]+')) order_by2, TO_NUMBER(REGEXP_SUBSTR(LOWER(sfs.name), '[0-9]+', 1, 2)) order_by3, TO_NUMBER(REGEXP_SUBSTR(LOWER(sfs.name), '[0-9]+', 1, 3)) order_by4
		  FROM std_factor_set sfs
		  LEFT JOIN csr_user cuc ON sfs.created_by_sid = cuc.csr_user_sid
		  LEFT JOIN csr_user cup ON sfs.published_by_sid = cup.csr_user_sid
		  LEFT JOIN std_factor_set_active sfsa ON sfs.std_factor_set_id = sfsa.std_factor_set_id AND sfsa.app_sid = v_app_sid
		  LEFT JOIN plm ON sfs.std_factor_set_id = plm.std_factor_set_id
		 WHERE factor_set_group_id = in_factor_set_group_id
		 UNION ALL 
		SELECT cfs.custom_factor_set_id factor_set_id, cfs.factor_set_group_id, cfs.name factor_set_name, cfs.created_by_sid, NVL(cuc.full_name, 'Unknown') created_by, cfs.created_dtm, cfs.info_note,
			1 is_published, NULL published_by_sid, NULL published_by, NULL published_dtm, 1 is_active, 1 is_custom, plm.profile, 
			REGEXP_SUBSTR(LOWER(cfs.name), '^\D*') order_by1, TO_NUMBER(REGEXP_SUBSTR(LOWER(cfs.name), '[0-9]+')) order_by2, TO_NUMBER(REGEXP_SUBSTR(LOWER(cfs.name), '[0-9]+', 1, 2)) order_by3, TO_NUMBER(REGEXP_SUBSTR(LOWER(cfs.name), '[0-9]+', 1, 3)) order_by4
		  FROM custom_factor_set cfs
		  LEFT JOIN csr_user cuc ON cfs.created_by_sid = cuc.csr_user_sid
		  LEFT JOIN plm ON cfs.custom_factor_set_id = plm.custom_factor_set_id
		 WHERE factor_set_group_id = in_factor_set_group_id
		   AND cfs.app_sid = v_app_sid
		 ORDER BY order_by1 NULLS FIRST, order_by2 NULLS FIRST, order_by3 NULLS FIRST, order_by4 NULLS FIRST;
END;

PROCEDURE GetFactorSetsForGroupPaged(
	in_factor_set_group_id	IN	factor_set_group.factor_set_group_id%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	out_total_rows			OUT	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security.security_pkg.T_SID_ID;
BEGIN
	CheckPermissions('Access denied');
	
	v_app_sid := security.security_pkg.getApp;
	
	SELECT COUNT(factor_set_group_id)
	  INTO out_total_rows
	  FROM (
		SELECT factor_set_group_id
		  FROM std_factor_set
		 WHERE factor_set_group_id = in_factor_set_group_id
		 UNION ALL
		SELECT factor_set_group_id
		  FROM custom_factor_set
		 WHERE factor_set_group_id = in_factor_set_group_id
		   AND app_sid = v_app_sid
		
		);
		
	OPEN out_cur FOR
		--Profile List Map
		WITH plm AS (
			SELECT  std_factor_set_id, custom_factor_set_id, LISTAGG(name, ', ') WITHIN GROUP (ORDER BY name) profile
			  FROM (
				SELECT DISTINCT pf.std_factor_set_id, pf.custom_factor_set_id, p.name
				  FROM emission_factor_profile_factor pf
				  JOIN emission_factor_profile p ON pf.profile_id = p.profile_id)
			 GROUP BY std_factor_set_id, custom_factor_set_id
		)
		SELECT factor_set_id, factor_set_group_id, factor_set_name, created_by_sid, created_by, created_dtm, 
				is_published, published_by_sid, published_by, published_dtm, is_active, is_custom, profile
		  FROM (
				SELECT factor_set_id, factor_set_group_id, factor_set_name, created_by_sid, created_by, created_dtm, 
						is_published, published_by_sid, published_by, published_dtm, is_active, is_custom, profile, rownum rn
				  FROM (
					SELECT sfs.std_factor_set_id factor_set_id, sfs.factor_set_group_id, sfs.name factor_set_name, sfs.created_by_sid, NVL(cuc.full_name, 'Unknown') created_by, sfs.created_dtm, sfs.info_note, 
						sfs.published is_published, sfs.published_by_sid, NVL(cup.full_name, 'Unknown') published_by, sfs.published_dtm, DECODE(sfsa.app_sid, NULL, 0, 1) is_active, 0 is_custom,
						plm.profile, 
						REGEXP_SUBSTR(LOWER(sfs.name), '^\D*') order_by1, TO_NUMBER(REGEXP_SUBSTR(LOWER(sfs.name), '[0-9]+')) order_by2, TO_NUMBER(REGEXP_SUBSTR(LOWER(sfs.name), '[0-9]+', 1, 2)) order_by3, TO_NUMBER(REGEXP_SUBSTR(LOWER(sfs.name), '[0-9]+', 1, 3)) order_by4 
					  FROM std_factor_set sfs
					  LEFT JOIN csr_user cuc ON sfs.created_by_sid = cuc.csr_user_sid
					  LEFT JOIN csr_user cup ON sfs.published_by_sid = cup.csr_user_sid
					  LEFT JOIN std_factor_set_active sfsa ON sfs.std_factor_set_id = sfsa.std_factor_set_id AND sfsa.app_sid = v_app_sid
					  LEFT JOIN plm ON sfs.std_factor_set_id = plm.std_factor_set_id
					 WHERE factor_set_group_id = in_factor_set_group_id
					 UNION ALL
					SELECT cfs.custom_factor_set_id factor_set_id, cfs.factor_set_group_id, cfs.name factor_set_name, cfs.created_by_sid, NVL(cuc.full_name, 'Unknown') created_by, cfs.created_dtm, cfs.info_note, 
						0 is_published, NULL published_by_sid, NULL published_by, NULL published_dtm, 1 is_active, 1 is_custom, plm.profile, 
						REGEXP_SUBSTR(LOWER(cfs.name), '^\D*') order_by1, TO_NUMBER(REGEXP_SUBSTR(LOWER(cfs.name), '[0-9]+')) order_by2, TO_NUMBER(REGEXP_SUBSTR(LOWER(cfs.name), '[0-9]+', 1, 2)) order_by3, TO_NUMBER(REGEXP_SUBSTR(LOWER(cfs.name), '[0-9]+', 1, 3)) order_by4
					  FROM custom_factor_set cfs
					  LEFT JOIN csr_user cuc ON cfs.created_by_sid = cuc.csr_user_sid
					  LEFT JOIN plm ON cfs.custom_factor_set_id = plm.custom_factor_set_id
					 WHERE factor_set_group_id = in_factor_set_group_id
					   AND cfs.app_sid = v_app_sid
					 ORDER BY order_by1 NULLS FIRST, order_by2 NULLS FIRST, order_by3 NULLS FIRST, order_by4 NULLS FIRST
					)
				 WHERE rownum < in_start_row + in_page_size
			)
		 WHERE rn >= in_start_row;
END;

PROCEDURE GetFactorSet(
	in_factor_set_id		IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security.security_pkg.T_SID_ID;
BEGIN
	CheckPermissions('Access denied');
	
	v_app_sid := security.security_pkg.getApp;
	
	OPEN out_cur FOR
		SELECT sfs.std_factor_set_id factor_set_id, sfs.factor_set_group_id, sfs.name factor_set_name, sfs.created_by_sid, NVL(cuc.full_name, 'Unknown') created_by, sfs.created_dtm, sfs.info_note, 
			sfs.published is_published, sfs.published_by_sid, NVL(cup.full_name, 'Unknown') published_by, sfs.published_dtm, DECODE(sfsa.app_sid, NULL, 0, 1) is_active, 0 is_custom
		  FROM std_factor_set sfs
		  LEFT JOIN csr_user cuc ON sfs.created_by_sid = cuc.csr_user_sid
		  LEFT JOIN csr_user cup ON sfs.published_by_sid = cup.csr_user_sid
		  LEFT JOIN std_factor_set_active sfsa ON sfs.std_factor_set_id = sfsa.std_factor_set_id AND sfsa.app_sid = v_app_sid
		 WHERE sfs.std_factor_set_id = in_factor_set_id
		 UNION ALL 
		SELECT cfs.custom_factor_set_id factor_set_id, cfs.factor_set_group_id, cfs.name factor_set_name, cfs.created_by_sid, NVL(cuc.full_name, 'Unknown') created_by, cfs.created_dtm, cfs.info_note,
			1 is_published, NULL published_by_sid, NULL published_by, NULL published_dtm, 1 is_active, 1 is_custom
		  FROM custom_factor_set cfs
		  LEFT JOIN csr_user cuc ON cfs.created_by_sid = cuc.csr_user_sid
		 WHERE custom_factor_set_id = in_factor_set_id
		   AND cfs.app_sid = v_app_sid;
END;

PROCEDURE SetFactorSetVisibility(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE,
	in_visible			IN	NUMBER
)
AS
BEGIN
	SetFactorSetActive(
		in_factor_set_id => in_factor_set_id,
		in_active => in_visible
	);
END;

PROCEDURE SetFactorSetActive(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE,
	in_active			IN	NUMBER
)
AS
	v_profiles			VARCHAR2(1024);
	v_factor_set_name	VARCHAR2(1024);
BEGIN
	CheckPermissions('Access denied');

	IF in_active = 1 THEN
	
		BEGIN
			INSERT INTO std_factor_set_active (std_factor_set_id)
			VALUES (in_factor_set_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN 
				NULL; --It's already there!
		END;
	ELSIF in_active = 0 THEN
		
		SELECT stragg(p.name)
		  INTO v_profiles		
		  FROM emission_factor_profile p
		 WHERE EXISTS (
			SELECT NULL 
			  FROM emission_factor_profile_factor 
			 WHERE std_factor_set_id = in_factor_set_id 
			   AND profile_id = p.profile_id
		);
		
		SELECT name
		  INTO v_factor_set_name
		  FROM std_factor_set
		 WHERE std_factor_set_id = in_factor_set_id;
		
		IF v_profiles IS NOT NULL THEN 
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
				'Factor set "'||v_factor_set_name||'" cannot be deactivated as it is used in the following profiles: '||v_profiles);
		END IF;
	
		DELETE FROM std_factor_set_active
		 WHERE std_factor_set_id = in_factor_set_id
		   AND app_sid = security.security_pkg.getApp;	 
	END IF;
END;

PROCEDURE DeleteFactorSet(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE,
	in_is_custom		IN	NUMBER
)
AS
	v_ignore		security.security_pkg.T_SID_ID;
	v_published		NUMBER(1);
	v_in_use		NUMBER(1);
	v_app_sid		security.security_pkg.T_SID_ID;
BEGIN
	CheckPermissions('Access denied');
	
	v_app_sid := security.security_pkg.getApp;
		
	security.security_pkg.SetApp(NULL);
	
	IF in_is_custom = 1 THEN
		SELECT DISTINCT cfs.custom_factor_set_id, DECODE(p.custom_factor_set_id, NULL, 0, 1)  
		  INTO v_ignore, v_in_use
		  FROM custom_factor_set cfs
		  LEFT JOIN emission_factor_profile_factor p ON cfs.custom_factor_set_id = p.custom_factor_set_id
		 WHERE cfs.custom_factor_set_id = in_factor_set_id;
		 
		IF v_in_use = 1 THEN 
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
				'Profiles exist for this factor set '||in_factor_set_id);
		ELSE
			UPDATE factor f SET custom_factor_id = NULL 
			 WHERE custom_factor_id in (
				SELECT custom_factor_id 
				  FROM custom_factor
				 WHERE custom_factor_set_id = in_factor_set_id);
			
			DELETE FROM custom_factor
			 WHERE custom_factor_set_id = in_factor_set_id;
			 
			DELETE FROM custom_factor_set
			 WHERE custom_factor_set_id = in_factor_set_id;
		END IF;
	ELSE
		SELECT DISTINCT sfs.std_factor_set_id, sfs.published, DECODE(p.std_factor_set_id, NULL, 0, 1)  
		  INTO v_ignore, v_published, v_in_use
		  FROM std_factor_set sfs
		  LEFT JOIN emission_factor_profile_factor p ON sfs.std_factor_set_id = p.std_factor_set_id
		 WHERE sfs.std_factor_set_id = in_factor_set_id;
		 
		IF v_published = 1 THEN 
			RAISE_APPLICATION_ERROR(security.Security_pkg.ERR_ACCESS_DENIED, 
				'The factor set '||in_factor_set_id||' is published so cannot be deleted');

		ELSIF v_in_use = 1 THEN 
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
				'Profiles exist for this factor set '||in_factor_set_id);
		ELSE
			UPDATE factor f SET std_factor_id = NULL 
			 WHERE std_factor_id in (
				SELECT std_factor_id 
				  FROM std_factor
				 WHERE std_factor_set_id = in_factor_set_id);
			
			DELETE FROM std_factor
			 WHERE std_factor_set_id = in_factor_set_id;
			
			DELETE FROM std_factor_set_active
			 WHERE std_factor_set_id = in_factor_set_id;
			 
			DELETE FROM std_factor_set
			 WHERE std_factor_set_id = in_factor_set_id;
		END IF;
	END IF;
	
	security.security_pkg.SetApp(v_app_sid);
END;

PROCEDURE PublishFactorSet(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE
)
AS
BEGIN
	CheckPermissions('Access denied');
	
	IF NOT csr_data_pkg.CheckCapability('Can publish std factor set') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Can publish std factor set" capability');
	END IF;
	
	UPDATE std_factor_set
	   SET published = 1, published_by_sid = security.security_pkg.getSid, published_dtm = sysdate
	 WHERE std_factor_set_id = in_factor_set_id
	   AND published = 0;
	   
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id 			=> security.security_pkg.getAct,
		in_audit_type_id 	=> csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		in_app_sid 			=> security.security_pkg.getApp,
		in_object_sid 		=> security.security_pkg.getSid,
		in_description  	=> 'Published factor set {0}',
		in_param_1 			=> in_factor_set_id,
		in_sub_object_id 	=> in_factor_set_id
	);
END;

PROCEDURE SetFactorSetVisibilityGlobal(
	in_std_factor_set_id	IN std_factor_set.std_factor_set_id%TYPE,
	in_visible				IN std_factor_set.visible%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;

	UPDATE std_factor_set
	   SET visible = in_visible
	 WHERE std_factor_set_id = in_std_factor_set_id;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_std_factor_set_id,
		'Changed Factor Set ' || in_std_factor_set_id || ' visibility to ' || in_visible);
END;


PROCEDURE UnpublishFactorSet(
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE
)
AS
	v_initial_act		security.security_pkg.T_ACT_ID;
	v_initial_app		security.security_pkg.T_SID_ID;
	v_initial_user		security.security_pkg.T_SID_ID;
	v_initial_company	security.security_pkg.T_SID_ID;
	v_act				security.security_pkg.T_ACT_ID;
	v_inuse_app_sid		security.security_pkg.T_SID_ID;
BEGIN
	CheckPermissions('Access denied');
	
	IF NOT csr_data_pkg.CheckCapability('Can publish std factor set') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Can publish std factor set" capability');
	END IF;
	
	-- Is in use in any app
	v_initial_act := security.security_pkg.getAct;
	v_initial_app := security.security_pkg.getApp;
	v_initial_user := security.security_pkg.getSid;
	v_initial_company := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	BEGIN
		security.user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 5000, NULL, v_act);
		
		SELECT MIN(app_sid)
		  INTO v_inuse_app_sid
		  FROM emission_factor_profile_factor
		 WHERE std_factor_set_id = in_factor_set_id;
		
		security.user_pkg.logoff(v_act);
	EXCEPTION
		WHEN OTHERS THEN -- Acts as a finally statement
			security.security_pkg.SetACTAndSID(v_initial_act, v_initial_user);
			IF v_initial_company IS NOT NULL THEN
				security.security_pkg.SetContext('CHAIN_COMPANY', v_initial_company);
			END IF;
			RAISE;
	END;
	
	security.security_pkg.SetACTAndSID(v_initial_act, v_initial_user);
	security.security_pkg.SetApp(v_initial_app);
	IF v_initial_company IS NOT NULL THEN
		security.security_pkg.SetContext('CHAIN_COMPANY', v_initial_company);
	END IF;

	IF v_inuse_app_sid IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Factor set in use by app with sid: ' || v_inuse_app_sid);
	END IF;
	-- End is in use
	
	UPDATE std_factor_set
	   SET published = 0, published_by_sid = NULL, published_dtm = NULL
	 WHERE std_factor_set_id = in_factor_set_id
	   AND published = 1;
	
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id 			=> v_initial_act,
		in_audit_type_id 	=> csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		in_app_sid 			=> v_initial_app,
		in_object_sid 		=> v_initial_user,
		in_description  	=> 'Unpublished factor set {0}',
		in_param_1 			=> in_factor_set_id,
		in_sub_object_id 	=> in_factor_set_id
	);
END;

PROCEDURE SetFactorSetsActiveOnMigration
AS
BEGIN

	FOR r IN (
		SELECT DISTINCT(stdset.std_factor_set_id)
		  FROM std_factor stdf
		  JOIN (SELECT DISTINCT(std_factor_id)
				  FROM factor) factor ON stdf.std_factor_id = factor.std_factor_id
		  JOIN std_factor_set stdset ON stdf.std_factor_set_id = stdset.std_factor_set_id
	)
	LOOP
		SetFactorSetActive(
			in_factor_set_id => r.std_factor_set_id,
			in_active => 1
		);
	END LOOP;

END;

PROCEDURE UpdateStdFactorSetInfoNote(
	in_factor_set_id			IN std_factor_set.std_factor_set_id%TYPE,
	in_info_note				IN std_factor_set.info_note%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;
	
	UPDATE std_factor_set 
	   SET info_note = in_info_note
	 WHERE std_factor_set_id = in_factor_set_id
	   AND ((in_info_note IS NOT NULL AND info_note IS NULL) 
			 OR (in_info_note IS NULL AND info_note IS NOT NULL)
			 OR DBMS_LOB.COMPARE(in_info_note, info_note) = -1
	);

	IF SQL%ROWCOUNT > 0 THEN
		csr_data_pkg.WriteAuditLogEntry(
			in_act_id 			=> security_pkg.getact,
			in_audit_type_id 	=> csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			in_app_sid 			=> security.security_pkg.getApp,
			in_object_sid 		=> security.security_pkg.getSid,
			in_description  	=> 'Updated info note for factor set {0}',
			in_param_1 			=> in_factor_set_id,
			in_sub_object_id 	=> in_factor_set_id
		);
	END IF;
END;

END factor_set_group_pkg;
/
