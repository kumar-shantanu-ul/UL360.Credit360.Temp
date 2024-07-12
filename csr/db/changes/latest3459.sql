define version=3459
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;













UPDATE csr.tag_group_description
   SET name = 'RBA Audit Type'
 WHERE tag_group_id IN (SELECT tag_group_id FROM csr.tag_group WHERE lookup_key = 'RBA_AUDIT_CATEGORY');
 
UPDATE csr.tag_group
   SET lookup_key = 'RBA_AUDIT_TYPE'
 WHERE lookup_key = 'RBA_AUDIT_CATEGORY';
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_www_root						security.security_pkg.T_SID_ID;
	v_csr_resource_sid				security.security_pkg.T_SID_ID;
	v_sasso_resource_sid			security.security_pkg.T_SID_ID;
	v_ssopage_resource_sid			security.security_pkg.T_SID_ID;
	v_everyone_sid					security.security_pkg.T_SID_ID;
	v_sso_site						NUMBER;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act);
	-- Ensure that csr\sasso and csr\sasso\singlesignon.acds resources exist.
	-- An issue in another latest script broke the script that creates these resources.
	-- We also want to ensure for already created SSO sites that
	-- we do not create the singlesignon.acds resource as this is removed when the SSO site is created
	-- by the EnableSuperadminSsoSite stored procedure
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Groups/Everyone');
		SELECT COUNT(*) INTO v_sso_site
		  FROM aspen2.application
		 WHERE app_sid = r.application_sid_id
		   AND aspen2.application.logon_url = '/csr/sasso/login/superadminlogin.acds';
		BEGIN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
			v_csr_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'csr');
			
			BEGIN
				v_sasso_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_csr_resource_sid, 'sasso');
				IF v_sso_site = 0 THEN
					BEGIN
						v_ssopage_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_sasso_resource_sid, 'singlesignon.acds');
					EXCEPTION
						WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
							
							security.web_pkg.CreateResource(v_act, v_www_root, v_sasso_resource_sid, 'singlesignon.acds', v_ssopage_resource_sid);
							
							security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_ssopage_resource_sid), -1, 
								security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
					END;
				END IF;		
			
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act, v_www_root, v_csr_resource_sid, 'sasso', v_sasso_resource_sid);
					IF v_sso_site = 0 THEN					
						security.web_pkg.CreateResource(v_act, v_www_root, v_sasso_resource_sid, 'singlesignon.acds', v_ssopage_resource_sid);
						security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_ssopage_resource_sid), -1, 
							security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
					END IF;
			END;
			
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;
	END lOOP;
	security.user_pkg.LogOff(v_act);
END;
/
DECLARE
	v_tag_group_id					csr.tag_group.tag_group_id%TYPE;
    v_audit_type_id                 NUMBER;
	PROCEDURE AddTag(
		in_tag_group_id 				IN	NUMBER,
		in_name    						IN  VARCHAR2,
		in_lookup_key					IN	VARCHAR2,
		in_pos							IN	NUMBER
	)
	AS
		v_tag_id						csr.tag.tag_id%TYPE;
	BEGIN
		INSERT INTO csr.tag (tag_id, lookup_key, parent_id)
		VALUES (csr.tag_id_seq.nextval, in_lookup_key, NULL)
		RETURNING tag_id INTO v_tag_id;
			
		INSERT INTO csr.tag_description (tag_id, lang, tag)
		VALUES (v_tag_id, 'en', in_name);
		INSERT INTO csr.tag_group_member (tag_group_id, tag_id, pos, active)
		VALUES (in_tag_group_id, v_tag_id, in_pos, 1);
	END;
BEGIN
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT DISTINCT(host)
		  FROM csr.tag_group tg
		  JOIN csr.customer c ON c.app_sid = tg.app_sid
		 WHERE lookup_key = 'RBA_AUDIT_TYPE'
		   AND NOT EXISTS (
			SELECT NULL
			  FROM csr.tag_group
			 WHERE lookup_key = 'RBA_AUDIT_CAT'
			   AND app_sid = tg.app_sid
		   )
		   AND NOT EXISTS (
			SELECT NULL
			  FROM csr.tag_group_description
			 WHERE name = 'RBA Audit Category'
			   AND app_sid = tg.app_sid
		   )
	) LOOP
		security.user_pkg.logonadmin(r.host);
				
		INSERT INTO csr.tag_group (app_sid, tag_group_id, multi_select, mandatory, applies_to_audits, lookup_key)
		VALUES (security.security_pkg.GetAPP, csr.tag_group_id_seq.nextval, 0, 0, 1, 'RBA_AUDIT_CAT')
		RETURNING tag_group_id INTO v_tag_group_id;
		INSERT INTO csr.tag_group_description (app_sid, tag_group_id, lang, name)
		VALUES (security.security_pkg.GetAPP, v_tag_group_id, 'en', 'RBA Audit Category');
		
		AddTag(v_tag_group_id, 'VAP', 'RBA_VAP', 1);
		AddTag(v_tag_group_id, 'VAP: Small Business', 'RBA_VAP_SMALL_BUSINESS', 2);
		AddTag(v_tag_group_id, 'VAP: Medium Business', 'RBA_VAP_MEDIUM_BUSINESS', 3);
		AddTag(v_tag_group_id, 'Employment Site: SVAP Only', 'RBA_EMPLOYMENT_SITE_SVAP_ONLY', 4);
		AddTag(v_tag_group_id, 'Employment Site: SVAP and VAP', 'RBA_EMPLOYMENT_SITE_SVAP_AND_V', 5);
		
		SELECT internal_audit_type_id
		  INTO v_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE lookup_key = 'RBA_AUDIT_TYPE';
		
		INSERT INTO csr.internal_audit_type_tag_group (internal_audit_type_id, tag_group_id)
		VALUES (v_audit_type_id, v_tag_group_id);
		
		security.user_pkg.logonadmin;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/
DECLARE
	v_tag_group_id					csr.tag_group.tag_group_id%TYPE;
    v_audit_type_id                 NUMBER;
	PROCEDURE AddTag(
		in_tag_group_id 				IN	NUMBER,
		in_name    						IN  VARCHAR2,
		in_lookup_key					IN	VARCHAR2,
		in_pos							IN	NUMBER
	)
	AS
		v_tag_id						csr.tag.tag_id%TYPE;
	BEGIN
		INSERT INTO csr.tag (tag_id, lookup_key, parent_id)
		VALUES (csr.tag_id_seq.nextval, in_lookup_key, NULL)
		RETURNING tag_id INTO v_tag_id;
			
		INSERT INTO csr.tag_description (tag_id, lang, tag)
		VALUES (v_tag_id, 'en', in_name);
		INSERT INTO csr.tag_group_member (tag_group_id, tag_id, pos, active)
		VALUES (in_tag_group_id, v_tag_id, in_pos, 1);
	END;
BEGIN
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT DISTINCT(host)
		  FROM csr.tag_group tg
		  JOIN csr.customer c ON c.app_sid = tg.app_sid
		 WHERE lookup_key = 'RBA_AUDIT_TYPE'
		 AND NOT EXISTS (
			SELECT NULL
			  FROM csr.tag_group
			 WHERE lookup_key = 'RBA_AUDIT_VAP_CMA'
			   AND app_sid = tg.app_sid
		)
	) LOOP
		security.user_pkg.logonadmin(r.host);
				
		INSERT INTO csr.tag_group (app_sid, tag_group_id, multi_select, mandatory, applies_to_audits, lookup_key)
		VALUES (security.security_pkg.GetAPP, csr.tag_group_id_seq.nextval, 0, 0, 1, 'RBA_AUDIT_VAP_CMA')
		RETURNING tag_group_id INTO v_tag_group_id;
		INSERT INTO csr.tag_group_description (app_sid, tag_group_id, lang, name)
		VALUES (security.security_pkg.GetAPP, v_tag_group_id, 'en', 'RBA VAP/CMA');
		
		AddTag(v_tag_group_id, 'VAP', 'RBA_VC_VAP', 1);
		AddTag(v_tag_group_id, 'CMA', 'RBA_VC_CMA', 2);
		
		SELECT internal_audit_type_id
		  INTO v_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE lookup_key = 'RBA_AUDIT_TYPE';
		
		INSERT INTO csr.internal_audit_type_tag_group (internal_audit_type_id, tag_group_id)
		VALUES (v_audit_type_id, v_tag_group_id);
		
		security.user_pkg.logonadmin;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/








@..\enable_body
@..\..\..\security\db\oracle\user_body
@..\quick_survey_body
@..\csr_user_body



@update_tail
