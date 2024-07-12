CREATE OR REPLACE PACKAGE BODY CSR.user_profile_pkg IS

FUNCTION CanViewAvatar(
	in_user_sid		IN 	 security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	-- you can always see yourself
	IF in_user_sid = SYS_CONTEXT('SECURITY','SID') THEN
		RETURN 1;
	END IF;

	-- otherwise check capability
	IF NOT csr_data_pkg.CheckCapability('View all avatars') THEN
		RETURN 0;
	END IF;

	RETURN 1;
END;

PROCEDURE GetAvatar(
	in_user_sid		IN 	 security_pkg.T_SID_ID,
	out_cur			OUT  SYS_REFCURSOR
)
AS
BEGIN
	IF CanViewAvatar(in_user_sid) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You cannot view this avatar');
	END IF;

	OPEN out_cur FOR
		SELECT avatar, avatar_last_modified_dtm, avatar_sha1, avatar_mime_type
		  FROM csr_user
		 WHERE csr_user_sid = in_user_sid;
END;


PROCEDURE GetProfilePanels (
	out_cur				OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.cs_class, p.js_include, p.js_class, pp.label
		  FROM plugin p
		  JOIN user_profile_panel pp ON p.plugin_id = pp.plugin_id
		  -- JOIN profile_panel_group ptg ON pt.plugin_id = ptg.plugin_id
		  -- JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y
		  --   ON ptg.group_sid = y.column_value
		 GROUP BY p.cs_class, p.js_include, p.js_class, pp.label, pp.pos
		 ORDER BY pp.pos;
END;

PROCEDURE GetMyFeed(
	in_start_idx		IN   NUMBER,
	in_items			IN   NUMBER,
	out_cur				OUT  SYS_REFCURSOR
)
AS
	v_dtm	DATE;
BEGIN
	v_dtm := SYSDATE;

	OPEN out_cur FOR
	    SELECT user_feed_id, action_dtm, acting_user_sid, acting_user_full_name, target_user_sid, target_user_full_name, 
            target_activity_id, target_activity, target_param_1, target_param_2, target_param_3, 
            action_text, action_url, action_label, action_img_url, v_dtm now_dtm, rn
          FROM (
            SELECT x.*, rownum rn
              FROM (
                -- activities you are following (where you didn't do something)
                SELECT uf.user_feed_id, uf.action_dtm, uf.acting_user_sid, uf.acting_user_full_name, uf.target_user_sid, uf.target_user_full_name, 
                    uf.target_activity_id, uf.target_activity, uf.target_param_1, uf.target_param_2, uf.target_param_3, 
                    uf.action_text, uf.action_url, uf.action_label, uf.action_img_url
                  FROM v$user_feed uf
                  JOIN activity_follower af ON uf.target_activity_id = af.activity_id 
                   AND af.follower_sid = SYS_CONTEXT('SECURITY','SID')
                 --WHERE acting_user_sid != SYS_CONTEXT('SECURITY','SID')
                 UNION ALL
                -- stuff done to you
                SELECT uf.user_feed_id, uf.action_dtm, uf.acting_user_sid, uf.acting_user_full_name, uf.target_user_sid, uf.target_user_full_name, 
                    uf.target_activity_id, uf.target_activity, uf.target_param_1, uf.target_param_2, uf.target_param_3, 
                    uf.action_text, uf.action_url, uf.action_label, uf.action_img_url
                  FROM v$user_feed uf
                 WHERE target_user_sid = SYS_CONTEXT('SECURITY','SID')
             )x
             ORDER BY user_feed_id DESC
         )
         WHERE rn >= in_start_idx AND rn <= in_start_idx + in_items;
END;

PROCEDURE WriteToUserFeed(
	in_user_feed_action_id	IN	user_feed_action.user_feed_action_id%TYPE,
	in_target_user_sid		IN	security_pkg.T_SID_ID DEFAULT NULL, 
	in_target_activity_id	IN	activity.activity_id%TYPE DEFAULT NULL, 
	in_target_param_1		IN  user_feed.target_param_1%TYPE DEFAULT NULL,
	in_target_param_2		IN  user_feed.target_param_2%TYPE DEFAULT NULL,
	in_target_param_3		IN  user_feed.target_param_3%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO user_feed (user_feed_id, target_user_sid, target_activity_id,
		user_feed_action_id, target_param_1, target_param_2, target_param_3)
	VALUES (user_feed_id_seq.nextval, in_target_user_sid, in_target_activity_id,
		in_user_feed_action_id, in_target_param_1, in_target_param_2, in_target_param_3);
END;



PROCEDURE SetTermCondDocs (
	in_company_type_id	IN	chain.company_type.company_type_id%TYPE,
	in_docs_to_keep		IN	security_pkg.T_SID_IDS
)
AS
	v_docs_to_keep					security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_docs_to_keep);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR chain.helper_pkg.isChainAdmin()) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetTermCondDocs can only be run as either Admin or Chain admin');
	END IF;
	
	DELETE FROM csr.term_cond_doc
	 WHERE app_sid = security_pkg.GetApp
	   AND company_type_id = in_company_type_id
	   AND doc_id NOT IN (
		SELECT column_value FROM TABLE(v_docs_to_keep)
	);
	
	FOR r IN (
		SELECT column_value FROM TABLE(v_docs_to_keep)
	)
	LOOP
		BEGIN
			INSERT INTO csr.term_cond_doc (company_type_id, doc_id) 
			VALUES (in_company_type_id, r.column_value);		
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;

PROCEDURE GetTermCondDocsForCompanyType (
	in_company_type_id	IN chain.company.company_type_id%TYPE DEFAULT 0,
	out_docs			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_docs FOR
		SELECT tcd.doc_id, tcd.filename, tcd.description, tcd.version
		  FROM csr.v$term_cond_doc tcd
		 WHERE tcd.company_type_id = in_company_type_id;
END;

PROCEDURE GetTermCondDocsForUser (
	in_user_sid				IN security_pkg.T_SID_ID,
	in_only_not_accepted 	IN INT DEFAULT 0,
	out_docs				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_is_chain_user	INT := 0;
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1) INTO v_is_chain_user
	  FROM chain.v$chain_user
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_user_sid;

	OPEN out_docs FOR
		SELECT tcd.doc_id, tcd.filename, tcd.description, tcd.version, tcd.company_type_id, 
		    (CASE WHEN tcdl.accepted_dtm IS NULL THEN 0 ELSE 1 END) AS accepted
		  FROM csr.v$term_cond_doc tcd
		  JOIN csr.csr_user cu ON cu.csr_user_sid = in_user_sid
		  LEFT JOIN csr.term_cond_doc_log tcdl ON tcdl.app_sid = security_pkg.GetApp AND tcdl.user_sid = in_user_sid AND tcdl.company_type_id = tcd.company_type_id AND tcdl.doc_id = tcd.doc_id AND tcdl.doc_version = tcd.version
		 WHERE (in_only_not_accepted = 0 OR (in_only_not_accepted = 1 AND tcdl.accepted_dtm IS NULL))
		   AND (((v_is_chain_user = 0) AND tcd.company_type_id = 0)
			OR ((v_is_chain_user = 1) AND tcd.company_type_id IN (		
			  SELECT DISTINCT c.company_type_id
				FROM chain.v$company_member vcm
				JOIN chain.company c ON c.company_sid = vcm.company_sid AND c.active = chain.chain_pkg.ACTIVE
			   WHERE vcm.app_sid = security_pkg.GetApp 
				 AND vcm.user_sid = in_user_sid)))
		 ORDER BY accepted;
END;

PROCEDURE AcceptTermCondDocsForUser (
	in_user_sid			IN csr_user.csr_user_sid%TYPE
)
AS
	v_accepted_docs 		SYS_REFCURSOR;
	v_doc_id 				csr.doc.doc_id%TYPE;
	v_filename 				csr.doc_version.filename%TYPE;
	v_description 			csr.doc_version.description%TYPE;
	v_doc_version 			csr.doc_version.version%TYPE;
	v_company_type_id 		chain.company_type.company_type_id%TYPE;
	v_accepted 				NUMBER;	
BEGIN
	GetTermCondDocsForUser(in_user_sid, 1, v_accepted_docs);

	LOOP
		FETCH v_accepted_docs INTO v_doc_id, v_filename, v_description, v_doc_version, v_company_type_id, v_accepted;
		EXIT WHEN v_accepted_docs%NOTFOUND;
		
		INSERT INTO term_cond_doc_log (user_sid, company_type_id, doc_id, doc_version)
			VALUES (in_user_sid, v_company_type_id, v_doc_id, v_doc_version);
	END LOOP;
END;

PROCEDURE ProcessStagedRowUpdate(
	in_primary_key					IN	csr.user_profile_staged_record.primary_key%TYPE,
	in_first_name					IN	csr.user_profile_staged_record.first_name%TYPE DEFAULT NULL,
	in_last_name					IN	csr.user_profile_staged_record.last_name%TYPE DEFAULT NULL,
	in_email_address				IN	csr.user_profile_staged_record.email_address%TYPE DEFAULT NULL,
	in_username						IN	csr.user_profile_staged_record.username%TYPE DEFAULT NULL,
	in_instance_step_id				IN	csr.user_profile_staged_record.instance_step_id%TYPE DEFAULT NULL,
	out_result						OUT	VARCHAR2
)
AS
	v_csr_user_sid						csr.csr_user.csr_user_sid%TYPE;
	v_set_line_mngmnt_frm_mngr_key		csr.auto_imp_user_imp_settings.set_line_mngmnt_frm_mngr_key%TYPE;
BEGIN
	BEGIN
		-- This needs to be done first because the processing will delete the staged row.
		SELECT a.set_line_mngmnt_frm_mngr_key
		  INTO v_set_line_mngmnt_frm_mngr_key
		  FROM csr.auto_imp_user_imp_settings a
		  JOIN csr.automated_import_instance_step st on a.automated_import_class_sid = st.automated_import_class_sid and a.app_sid = st.app_sid
		  JOIN csr.user_profile_staged_record u on st.auto_import_instance_step_id = u.instance_step_id and u.app_sid = st.app_sid
		 WHERE UPPER(u.primary_key) = UPPER(in_primary_key)
		   AND a.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_set_line_mngmnt_frm_mngr_key := 0;
	END;

	user_profile_pkg.ProcessIncomingRow(
		in_primary_key		=> in_primary_key,
		in_first_name		=> in_first_name,
		in_last_name		=> in_last_name,
		in_email_address	=> in_email_address,
		in_username			=> in_username,
		in_instance_step_id => in_instance_step_id,
		out_result 			=> out_result,
		out_csr_user_sid	=> v_csr_user_sid
	);
	
	IF v_csr_user_sid > 0 THEN  --if there are potential line manger links to check due to a new/updated user profile row.
		IF v_set_line_mngmnt_frm_mngr_key > 0 THEN  --if the user has specified they want to do this.
			CreateLineManagerLinksForUser(v_csr_user_sid);
		END IF;
	END IF;
	
END;

PROCEDURE ProcessIncomingRow(
	in_primary_key					IN	csr.user_profile_staged_record.primary_key%TYPE,
	in_employee_ref					IN	csr.user_profile_staged_record.employee_ref%TYPE DEFAULT NULL,
	in_payroll_ref					IN	csr.user_profile_staged_record.payroll_ref%TYPE DEFAULT NULL,
	in_first_name					IN	csr.user_profile_staged_record.first_name%TYPE DEFAULT NULL,
	in_last_name					IN	csr.user_profile_staged_record.last_name%TYPE DEFAULT NULL,
	in_middle_name					IN	csr.user_profile_staged_record.middle_name%TYPE DEFAULT NULL,
	in_friendly_name				IN	csr.user_profile_staged_record.friendly_name%TYPE DEFAULT NULL,
	in_email_address				IN	csr.user_profile_staged_record.email_address%TYPE DEFAULT NULL,
	in_username						IN	csr.user_profile_staged_record.username%TYPE DEFAULT NULL,
	in_work_phone_number			IN	csr.user_profile_staged_record.work_phone_number%TYPE DEFAULT NULL,
	in_work_phone_extension			IN	csr.user_profile_staged_record.work_phone_extension%TYPE DEFAULT NULL,
	in_home_phone_number			IN	csr.user_profile_staged_record.home_phone_number%TYPE DEFAULT NULL,
	in_mobile_phone_number			IN	csr.user_profile_staged_record.mobile_phone_number%TYPE DEFAULT NULL,
	in_manager_employee_ref			IN	csr.user_profile_staged_record.manager_employee_ref%TYPE DEFAULT NULL,
	in_manager_payroll_ref			IN	csr.user_profile_staged_record.manager_payroll_ref%TYPE DEFAULT NULL,
	in_manager_primary_key			IN	csr.user_profile_staged_record.manager_primary_key%TYPE DEFAULT NULL,
	in_employment_start_date		IN	csr.user_profile_staged_record.employment_start_date%TYPE DEFAULT NULL,
	in_employment_leave_date		IN	csr.user_profile_staged_record.employment_leave_date%TYPE DEFAULT NULL,
	in_profile_active				IN	csr.user_profile_staged_record.profile_active%TYPE DEFAULT NULL,
	in_date_of_birth				IN	csr.user_profile_staged_record.date_of_birth%TYPE DEFAULT NULL,
	in_gender						IN	csr.user_profile_staged_record.gender%TYPE DEFAULT NULL,
	in_job_title					IN	csr.user_profile_staged_record.job_title%TYPE DEFAULT NULL,
	in_contract						IN	csr.user_profile_staged_record.contract%TYPE DEFAULT NULL,
	in_employment_type				IN	csr.user_profile_staged_record.employment_type%TYPE DEFAULT NULL,
	in_pay_grade					IN	csr.user_profile_staged_record.pay_grade%TYPE DEFAULT NULL,
	in_business_area_ref			IN	csr.user_profile_staged_record.business_area_ref%TYPE DEFAULT NULL,
	in_business_area_code			IN	csr.user_profile_staged_record.business_area_code%TYPE DEFAULT NULL,
	in_business_area_name			IN	csr.user_profile_staged_record.business_area_name%TYPE DEFAULT NULL,
	in_business_area_description	IN	csr.user_profile_staged_record.business_area_description%TYPE DEFAULT NULL,
	in_division_ref					IN	csr.user_profile_staged_record.division_ref%TYPE DEFAULT NULL,
	in_division_code				IN	csr.user_profile_staged_record.division_code%TYPE DEFAULT NULL,
	in_division_name				IN	csr.user_profile_staged_record.division_name%TYPE DEFAULT NULL,
	in_division_description			IN	csr.user_profile_staged_record.division_description%TYPE DEFAULT NULL,
	in_department					IN	csr.user_profile_staged_record.department%TYPE DEFAULT NULL,
	in_number_hours					IN	csr.user_profile_staged_record.number_hours%TYPE DEFAULT NULL,
	in_country						IN	csr.user_profile_staged_record.country%TYPE DEFAULT NULL,
	in_location						IN	csr.user_profile_staged_record.location%TYPE DEFAULT NULL,
	in_building						IN	csr.user_profile_staged_record.building%TYPE DEFAULT NULL,
	in_cost_centre_ref				IN	csr.user_profile_staged_record.cost_centre_ref%TYPE DEFAULT NULL,
	in_cost_centre_code				IN	csr.user_profile_staged_record.cost_centre_code%TYPE DEFAULT NULL,
	in_cost_centre_name				IN	csr.user_profile_staged_record.cost_centre_name%TYPE DEFAULT NULL,
	in_cost_centre_description		IN	csr.user_profile_staged_record.cost_centre_description%TYPE DEFAULT NULL,
	in_work_address_1				IN	csr.user_profile_staged_record.work_address_1%TYPE DEFAULT NULL,
	in_work_address_2				IN	csr.user_profile_staged_record.work_address_2%TYPE DEFAULT NULL,
	in_work_address_3				IN	csr.user_profile_staged_record.work_address_3%TYPE DEFAULT NULL,
	in_work_address_4				IN	csr.user_profile_staged_record.work_address_4%TYPE DEFAULT NULL,
	in_home_address_1				IN	csr.user_profile_staged_record.home_address_1%TYPE DEFAULT NULL,
	in_home_address_2				IN	csr.user_profile_staged_record.home_address_2%TYPE DEFAULT NULL,
	in_home_address_3				IN	csr.user_profile_staged_record.home_address_3%TYPE DEFAULT NULL,
	in_home_address_4				IN	csr.user_profile_staged_record.home_address_4%TYPE DEFAULT NULL,
	in_location_region_ref			IN	csr.user_profile_staged_record.location_region_ref%TYPE DEFAULT NULL,
	in_use_loc_region_as_start_pt	IN	csr.auto_imp_user_imp_settings.use_loc_region_as_start_pt%TYPE DEFAULT NULL,
	in_internal_username			IN	csr.user_profile_staged_record.internal_username%TYPE DEFAULT NULL,
	in_manager_username				IN	csr.user_profile_staged_record.manager_username%TYPE DEFAULT NULL,
	in_activate_on					IN	csr.user_profile_staged_record.activate_on%TYPE DEFAULT NULL,
	in_deactivate_on				IN	csr.user_profile_staged_record.deactivate_on%TYPE DEFAULT NULL,
	in_instance_step_id				IN	csr.user_profile_staged_record.instance_step_id%TYPE DEFAULT NULL,
	out_result						OUT	VARCHAR2,
	out_csr_user_sid				OUT	csr.csr_user.csr_user_sid%TYPE
)
AS
	v_profile_exists			NUMBER;
	v_existing_csr_user_sid		NUMBER;
	v_error_message				VARCHAR2(1024);
	v_username_exists			NUMBER;
	v_user_with_username		NUMBER;
	v_anonymised_user			NUMBER;
	v_existing_username			csr.user_profile_staged_record.username%TYPE;
	v_row						CSR.T_USER_PROFILE_STAGED_ROW;
BEGIN
	--out_result := 'ERROR';
	
	BEGIN
		SELECT T_USER_PROFILE_STAGED_ROW(
			in_primary_key,										NVL(in_employee_ref, employee_ref),								NVL(in_payroll_ref, payroll_ref),
			NVL(in_first_name, first_name), 					NVL(in_last_name, last_name),									NVL(in_middle_name, middle_name),
			NVL(in_friendly_name, friendly_name),				NVL(in_email_address, email_address),							NVL(in_username, username),
			NVL(in_work_phone_number, work_phone_number),		NVL(in_work_phone_extension, work_phone_extension),				NVL(in_home_phone_number, home_phone_number),
			NVL(in_mobile_phone_number, mobile_phone_number),	NVL(in_manager_employee_ref, manager_employee_ref),				NVL(in_manager_payroll_ref, manager_payroll_ref),
			NVL(in_manager_primary_key, manager_primary_key),	NVL(in_employment_start_date, employment_start_date),			NVL(in_employment_leave_date, employment_leave_date),
			NVL(in_profile_active, profile_active),				NVL(in_date_of_birth, date_of_birth),							NVL(in_gender, gender),
			NVL(in_job_title, job_title),						NVL(in_contract, contract),										NVL(in_employment_type, employment_type),
			NVL(in_pay_grade, pay_grade),						NVL(in_business_area_ref, business_area_ref),					NVL(in_business_area_code, business_area_code),
			NVL(in_business_area_name, business_area_name),		NVL(in_business_area_description, business_area_description),	NVL(in_division_ref, division_ref),
			NVL(in_division_code, division_code),				NVL(in_division_name, division_name),							NVL(in_division_description, division_description),
			NVL(in_department, department),						NVL(in_number_hours, number_hours),								NVL(in_country, country),
			NVL(in_location, location),							NVL(in_building, building),										NVL(in_cost_centre_ref, cost_centre_ref),
			NVL(in_cost_centre_code, cost_centre_code),			NVL(in_cost_centre_name, cost_centre_name),						NVL(in_cost_centre_description, cost_centre_description),
			NVL(in_work_address_1, work_address_1),				NVL(in_work_address_2, work_address_2),							NVL(in_work_address_3, work_address_3),
			NVL(in_work_address_4, work_address_4),				NVL(in_home_address_1, home_address_1),							NVL(in_home_address_2, home_address_2),
			NVL(in_home_address_3, home_address_3),				NVL(in_home_address_4, home_address_4),							NVL(in_location_region_ref, location_region_ref),
			NVL(in_internal_username, internal_username),		NVL(in_manager_username, manager_username),						NVL(in_activate_on, activate_on),
			NVL(in_deactivate_on, deactivate_on),				in_instance_step_id,											SYSDATE,
			SYS_CONTEXT('SECURITY', 'SID'),						NVL2(in_instance_step_id, 'Import', 'Manual'),					v_error_message
		)
		  INTO v_row
		  FROM user_profile_staged_record
		 WHERE UPPER(primary_key) = UPPER(in_primary_key);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			SELECT T_USER_PROFILE_STAGED_ROW(
				in_primary_key, 			in_employee_ref, 			in_payroll_ref, 				in_first_name, 					in_last_name, 
				in_middle_name, 			in_friendly_name, 			in_email_address, 				in_username, 					in_work_phone_number, 
				in_work_phone_extension, 	in_home_phone_number, 		in_mobile_phone_number, 		in_manager_employee_ref,		in_manager_payroll_ref, 
				in_manager_primary_key, 	in_employment_start_date, 	in_employment_leave_date, 		in_profile_active, 				in_date_of_birth, 
				in_gender, 					in_job_title, 				in_contract, 					in_employment_type, 			in_pay_grade, 
				in_business_area_ref, 		in_business_area_code, 		in_business_area_name, 			in_business_area_description, 	in_division_ref,
				in_division_code, 			in_division_name, 			in_division_description, 		in_department, 					in_number_hours, 
				in_country, 				in_location, 				in_building, 					in_cost_centre_ref, 			in_cost_centre_code, 
				in_cost_centre_name, 		in_cost_centre_description, in_work_address_1, 				in_work_address_2, 				in_work_address_3,
				in_work_address_4, 			in_home_address_1, 			in_home_address_2, 				in_home_address_3, 				in_home_address_4, 
				in_location_region_ref, 	in_internal_username, 		in_manager_username, 			in_activate_on, 				in_deactivate_on, 
				in_instance_step_id, 		SYSDATE, 					SYS_CONTEXT('SECURITY', 'SID'), NVL2(in_instance_step_id, 'Import', 'Manual'), v_error_message
			)
			  INTO v_row
			  FROM DUAL;
	END;
	
	SELECT COUNT(*)
	  INTO v_profile_exists
	  FROM user_profile
	 WHERE UPPER(primary_key) = UPPER(v_row.primary_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT COUNT(*)
	  INTO v_username_exists
	  FROM csr_user
	 WHERE LOWER(user_name) = LOWER(v_row.username)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT MAX(csr_user_sid)
	  INTO v_existing_csr_user_sid
	  FROM csr_user
	 WHERE LOWER(user_ref) = LOWER(v_row.primary_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_profile_exists = 0 THEN
		-- Validate
		IF v_row.first_name IS NULL THEN
			v_error_message := v_error_message||'No first name. ';
		END IF;

		IF v_row.email_address IS NULL THEN
			v_error_message := v_error_message||'No email address. ';
		END IF;
		
		IF v_row.username IS NULL THEN
			-- It's a new profile, but no username specified
			v_error_message := v_error_message||'No username. ';
		END IF;
		
		IF v_username_exists > 0 THEN
			-- It's a new profile, but the usernam e is already in use
			v_error_message := v_error_message||'Username already exists.';
		END IF;
	ELSE
		-- It's an existing profile. If the username has changed we need to ensure there isn't a clash with a different
		-- user
			SELECT cu.user_name, up.csr_user_sid
			  INTO v_existing_username, v_user_with_username
			  FROM user_profile up
			  JOIN csr_user cu ON up.csr_user_sid = cu.csr_user_sid
			 WHERE UPPER(up.primary_key) = UPPER(in_primary_key)
			   AND up.app_sid = SYS_CONTEXT('SECURITY', 'APP');
			
		-- Check for Anonymised User
			SELECT COUNT(*)
			  INTO v_anonymised_user
			  FROM user_profile up
			  JOIN csr_user cu ON up.csr_user_sid = cu.csr_user_sid
			 WHERE cu.anonymised = 1
			   AND UPPER(up.primary_key) = UPPER(in_primary_key)
			   AND up.app_sid = SYS_CONTEXT('SECURITY', 'APP');


			IF v_anonymised_user > 0 THEN
				v_error_message := v_error_message||'Cannot edit anonymised user.';
			END IF;

			IF LOWER(v_existing_username) != LOWER(v_row.username) AND v_username_exists > 0 THEN
				v_error_message := v_error_message||'Username already exists.';
			END IF;

	END IF;
	
	IF v_error_message IS NULL THEN
		IF v_profile_exists > 0 THEN
			UpdateProfile(v_row, out_csr_user_sid);
			out_result := 'UPDATE';
		ELSIF v_existing_csr_user_sid IS NOT NULL THEN
			-- Handle the case where a csr_user record exists for this user, but a profile does not
			CreateProfile(v_row, v_existing_csr_user_sid, v_row.location_region_ref);
			UpdateProfile(v_row, out_csr_user_sid);
			out_result := 'UPDATE';
		ELSE
			CreateUserAndProfile(v_row, in_use_loc_region_as_start_pt, out_csr_user_sid);
			out_result := 'NEW';
		END IF;	
	ELSE
		v_row.error_message := v_error_message;
		WriteStagedUserProfileRow(v_row);
		out_csr_user_sid := 0;
		out_result := 'STAGED';
	END IF;

END;


PROCEDURE WriteStagedUserProfileRow(
	in_row					IN	CSR.T_USER_PROFILE_STAGED_ROW
)
AS
BEGIN

	BEGIN
		INSERT INTO user_profile_staged_record
			(primary_key, employee_ref, payroll_ref, first_name, last_name, middle_name, friendly_name, email_address, username,
			 work_phone_number, work_phone_extension, home_phone_number, mobile_phone_number, manager_employee_ref, manager_payroll_ref, manager_primary_key, employment_start_date, 
			 employment_leave_date, profile_active, date_of_birth, gender, job_title, contract, employment_type, pay_grade, 
			 business_area_ref, business_area_code, business_area_name, business_area_description, division_ref, division_code, division_name, division_description, 
			 department, number_hours, country, location, building, cost_centre_ref, cost_centre_code, cost_centre_name, 
			 cost_centre_description, work_address_1, work_address_2, work_address_3, work_address_4, home_address_1, home_address_2, home_address_3, 
			 home_address_4, location_region_ref, internal_username, manager_username, activate_on, deactivate_on, instance_step_id, 
			 last_updated_dtm, last_updated_user_sid, last_update_method, error_message)
		VALUES
			(in_row.primary_key, in_row.employee_ref, in_row.payroll_ref, in_row.first_name, in_row.last_name, in_row.middle_name, in_row.friendly_name, in_row.email_address, in_row.username,
			 in_row.work_phone_number, in_row.work_phone_extension, in_row.home_phone_number, in_row.mobile_phone_number, in_row.manager_employee_ref, in_row.manager_payroll_ref, in_row.manager_primary_key, 
			 in_row.employment_start_date, in_row.employment_leave_date, in_row.profile_active, in_row.date_of_birth, in_row.gender, in_row.job_title, in_row.contract, in_row.employment_type, in_row.pay_grade, 
			 in_row.business_area_ref, in_row.business_area_code, in_row.business_area_name, in_row.business_area_description, in_row.division_ref, in_row.division_code, in_row.division_name, 
			 in_row.division_description, in_row.department, in_row.number_hours, in_row.country, in_row.location, in_row.building, in_row.cost_centre_ref, in_row.cost_centre_code, in_row.cost_centre_name, 
			 in_row.cost_centre_description, in_row.work_address_1, in_row.work_address_2, in_row.work_address_3, in_row.work_address_4, in_row.home_address_1, in_row.home_address_2, in_row.home_address_3, 
			 in_row.home_address_4, in_row.location_region_ref, in_row.internal_username, in_row.manager_username, in_row.activate_on, in_row.deactivate_on, in_row.instance_step_id, 
			 SYSDATE, SYS_CONTEXT('SECURITY', 'SID'), NVL2(in_row.instance_step_id, 'Import', 'Manual'), in_row.error_message);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_profile_staged_record
			   SET employee_ref = NVL(in_row.employee_ref, employee_ref),
				   payroll_ref = NVL(in_row.payroll_ref, payroll_ref),
				   first_name = NVL(in_row.first_name, first_name),
				   last_name = NVL(in_row.last_name, last_name),
				   middle_name = NVL(in_row.middle_name, middle_name),
				   friendly_name = NVL(in_row.friendly_name, friendly_name),
				   email_address = NVL(in_row.email_address, email_address),
				   username = NVL(in_row.username, username),
				   work_phone_number = NVL(in_row.work_phone_number, work_phone_number),
				   work_phone_extension = NVL(in_row.work_phone_extension, work_phone_extension),
				   home_phone_number = NVL(in_row.home_phone_number, home_phone_number),
				   mobile_phone_number = NVL(in_row.mobile_phone_number, mobile_phone_number),
				   manager_employee_ref = NVL(in_row.manager_employee_ref, manager_employee_ref),
				   manager_payroll_ref = NVL(in_row.manager_payroll_ref, manager_payroll_ref),
				   manager_primary_key = NVL(in_row.manager_primary_key, manager_primary_key),
				   employment_start_date = NVL(in_row.employment_start_date, employment_start_date),
				   employment_leave_date = NVL(in_row.employment_leave_date, employment_leave_date),
				   profile_active = NVL(in_row.profile_active, profile_active),
				   date_of_birth = NVL(in_row.date_of_birth, date_of_birth),
				   gender = NVL(in_row.gender, gender),
				   job_title = NVL(in_row.job_title, job_title),
				   contract = NVL(in_row.contract, contract),
				   employment_type = NVL(in_row.employment_type, employment_type),
				   pay_grade = NVL(in_row.pay_grade, pay_grade),
				   business_area_ref = NVL(in_row.business_area_ref, business_area_ref),
				   business_area_code = NVL(in_row.business_area_code, business_area_code),
				   business_area_name = NVL(in_row.business_area_name, business_area_name),
				   business_area_description = NVL(in_row.business_area_description, business_area_description),
				   division_ref = NVL(in_row.division_ref, division_ref),
				   division_code = NVL(in_row.division_code, division_code),
				   division_name = NVL(in_row.division_name, division_name),
				   division_description = NVL(in_row.division_description, division_description),
				   department = NVL(in_row.department, department),
				   number_hours = NVL(in_row.number_hours, number_hours),
				   country = NVL(in_row.country, country),
				   location = NVL(in_row.location, location),
				   building = NVL(in_row.building, building),
				   cost_centre_ref = NVL(in_row.cost_centre_ref, cost_centre_ref),
				   cost_centre_code = NVL(in_row.cost_centre_code, cost_centre_code),
				   cost_centre_name = NVL(in_row.cost_centre_name, cost_centre_name),
				   cost_centre_description = NVL(in_row.cost_centre_description, cost_centre_description),
				   work_address_1 = NVL(in_row.work_address_1, work_address_1),
				   work_address_2 = NVL(in_row.work_address_2, work_address_2),
				   work_address_3 = NVL(in_row.work_address_3, work_address_3),
				   work_address_4 = NVL(in_row.work_address_4, work_address_4),
				   home_address_1 = NVL(in_row.home_address_1, home_address_1),
				   home_address_2 = NVL(in_row.home_address_2, home_address_2),
				   home_address_3 = NVL(in_row.home_address_3, home_address_3),
				   home_address_4 = NVL(in_row.home_address_4, home_address_4),
				   location_region_ref = NVL(in_row.location_region_ref, location_region_ref),
				   internal_username = NVL(in_row.internal_username, internal_username),
				   manager_username = NVL(in_row.manager_username, manager_username),
				   activate_on = NVL(in_row.activate_on, activate_on),
				   deactivate_on = NVL(in_row.deactivate_on, deactivate_on),
				   instance_step_id = in_row.instance_step_id,
				   last_updated_dtm = SYSDATE,
				   last_updated_user_sid = SYS_CONTEXT('SECURITY', 'SID'),
				   last_update_method = NVL2(in_row.instance_step_id, 'Import', 'Manual'),
				   error_message = in_row.error_message
			 WHERE UPPER(primary_key) = UPPER(in_row.primary_key)
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
	
	UPDATE automated_import_instance_step
	   SET custom_url = '/csr/site/automatedExportImport/failedUserRows.acds',
	       custom_url_title = 'View staged rows'
	 WHERE auto_import_instance_step_id = in_row.instance_step_id;
	
END;

FUNCTION GetLocationRegionSid(
	v_location_region_ref		IN	csr.user_profile_staged_record.location_region_ref%TYPE
) RETURN NUMBER
AS
BEGIN
	RETURN imp_pkg.autoMapRegion(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), v_location_region_ref);
END;

PROCEDURE UpdateProfile(
	in_row					IN	CSR.T_USER_PROFILE_STAGED_ROW,
	out_csr_user_sid		OUT	csr.user_profile.csr_user_sid%TYPE
)
AS
	v_csr_user_sid						NUMBER(10);
	v_send_alerts						csr_user.send_alerts%TYPE;
BEGIN
	SELECT csr_user_sid
	  INTO v_csr_user_sid
	  FROM user_profile
	 WHERE UPPER(primary_key) = UPPER(in_row.primary_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	out_csr_user_sid := v_csr_user_sid;

	IF in_row.profile_active = 0 THEN
		v_send_alerts := 0;
	END IF;

	csr.csr_user_pkg.amendUserWhereInputNotNull(
		in_act						=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_user_sid					=>	v_csr_user_sid,
		in_user_name				=>	in_row.username,
		in_full_name				=>	in_row.first_name || ' ' || in_row.last_name,
		in_friendly_name			=>	NVL(in_row.friendly_name, in_row.first_name),
		in_email					=>	in_row.email_address,
		in_job_title				=>	in_row.job_title, 
		in_phone_number				=>	NULL,
		in_active					=>	in_row.profile_active,
		in_info_xml					=>	NULL,
		in_send_alerts				=>	v_send_alerts,
		in_enable_aria				=>	NULL,
		in_line_manager_sid			=>	NULL);

	BEGIN
		UPDATE user_profile
		   SET employee_ref = NVL(in_row.employee_ref, employee_ref),
			   payroll_ref = NVL(in_row.payroll_ref, payroll_ref),
			   first_name = NVL(in_row.first_name, first_name),
			   last_name = NVL(in_row.last_name, last_name),
			   middle_name = NVL(in_row.middle_name, middle_name),
			   friendly_name = NVL(in_row.friendly_name, friendly_name),
			   email_address = NVL(in_row.email_address, email_address),
			   work_phone_number = NVL(in_row.work_phone_number, work_phone_number),
			   work_phone_extension = NVL(in_row.work_phone_extension, work_phone_extension),
			   home_phone_number = NVL(in_row.home_phone_number, home_phone_number),
			   mobile_phone_number = NVL(in_row.mobile_phone_number, mobile_phone_number),
			   manager_employee_ref = NVL(in_row.manager_employee_ref, manager_employee_ref),
			   manager_payroll_ref = NVL(in_row.manager_payroll_ref, manager_payroll_ref),
			   manager_primary_key = NVL(in_row.manager_primary_key, manager_primary_key),
			   employment_start_date = NVL(in_row.employment_start_date, employment_start_date),
			   employment_leave_date = NVL(in_row.employment_leave_date, employment_leave_date),
			   date_of_birth = NVL(in_row.date_of_birth, date_of_birth),
			   gender = NVL(in_row.gender, gender),
			   job_title = NVL(in_row.job_title, job_title),
			   contract = NVL(in_row.contract, contract),
			   employment_type = NVL(in_row.employment_type, employment_type),
			   pay_grade = NVL(in_row.pay_grade, pay_grade),
			   business_area_ref = NVL(in_row.business_area_ref, business_area_ref),
			   business_area_code = NVL(in_row.business_area_code, business_area_code),
			   business_area_name = NVL(in_row.business_area_name, business_area_name),
			   business_area_description = NVL(in_row.business_area_description, business_area_description),
			   division_ref = NVL(in_row.division_ref, division_ref),
			   division_code = NVL(in_row.division_code, division_code),
			   division_name = NVL(in_row.division_name, division_name),
			   division_description = NVL(in_row.division_description, division_description),
			   department = NVL(in_row.department, department),
			   number_hours = NVL(in_row.number_hours, number_hours),
			   country = NVL(in_row.country, country),
			   location = NVL(in_row.location, location),
			   building = NVL(in_row.building, building),
			   cost_centre_ref = NVL(in_row.cost_centre_ref, cost_centre_ref),
			   cost_centre_code = NVL(in_row.cost_centre_code, cost_centre_code),
			   cost_centre_name = NVL(in_row.cost_centre_name, cost_centre_name),
			   cost_centre_description = NVL(in_row.cost_centre_description, cost_centre_description),
			   work_address_1 = NVL(in_row.work_address_1, work_address_1),
			   work_address_2 = NVL(in_row.work_address_2, work_address_2),
			   work_address_3 = NVL(in_row.work_address_3, work_address_3),
			   work_address_4 = NVL(in_row.work_address_4, work_address_4),
			   home_address_1 = NVL(in_row.home_address_1, home_address_1),
			   home_address_2 = NVL(in_row.home_address_2, home_address_2),
			   home_address_3 = NVL(in_row.home_address_3, home_address_3),
			   home_address_4 = NVL(in_row.home_address_4, home_address_4),
			   location_region_sid = NVL(in_row.location_region_ref,location_region_sid),
			   internal_username = NVL(in_row.internal_username, internal_username),
			   manager_username = NVL(in_row.manager_username, manager_username),
			   activate_on = NVL(in_row.activate_on, activate_on),
			   deactivate_on = NVL(in_row.deactivate_on, deactivate_on),
			   updated_instance_step_id = in_row.instance_step_id,
			   last_updated_dtm = SYSDATE,
			   last_updated_user_sid = SYS_CONTEXT('SECURITY', 'SID'),
			   last_update_method = NVL2(in_row.instance_step_id, 'Import', 'Manual')
		 WHERE csr_user_sid = v_csr_user_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN OTHERS THEN 
			WriteStagedUserProfileRow(in_row);
	END;
	DELETE FROM user_profile_staged_record
	 WHERE UPPER(primary_key) = UPPER(in_row.primary_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE CreateUserAndProfile(
	in_row							IN	CSR.T_USER_PROFILE_STAGED_ROW,
	in_use_loc_region_as_start_pt	IN	csr.auto_imp_user_imp_settings.use_loc_region_as_start_pt%TYPE,
	out_csr_user_sid				OUT	csr.user_profile.csr_user_sid%TYPE
)
AS
	v_csr_user_sid						NUMBER(10);
	v_start_points						security_pkg.T_SID_IDS;
	v_class_sid							NUMBER(10);
	v_step_number						NUMBER(10);
BEGIN
	
	csr.csr_user_pkg.CreateUser(
		in_act					=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid				=>	SYS_CONTEXT('SECURITY', 'APP'),
		in_user_name			=>	in_row.username,
		in_password				=>	NULL,
		in_full_name			=>	in_row.first_name || ' ' || in_row.last_name,
		in_friendly_name		=>	NVL(in_row.friendly_name, in_row.first_name),
		in_email				=>	in_row.email_address,
		in_job_title			=>	in_row.job_title,
		in_send_alerts			=>	1,
		in_phone_number			=>	NULL,
		in_info_xml				=>	NULL,
		in_user_ref				=>	in_row.primary_key,
		out_user_sid			=>	v_csr_user_sid
	);
	
	out_csr_user_sid := v_csr_user_sid;

	SELECT MIN(automated_import_class_sid), MIN(step_number)
	  INTO v_class_sid, v_step_number
	  FROM automated_import_instance_step
	 WHERE auto_import_instance_step_id = in_row.instance_step_id;	
	
	IF in_row.location_region_ref IS NOT NULL THEN
		SELECT in_row.location_region_ref
		  BULK COLLECT INTO v_start_points
		  FROM DUAL;
		
		IF in_use_loc_region_as_start_pt = 1 THEN
			csr.csr_user_pkg.SetRegionStartPoints(
				in_user_sid			=>	v_csr_user_sid,
				in_region_sids		=>	v_start_points
			);
		END IF;
		
		FOR r IN (
		SELECT role_sid 
		  FROM csr.user_profile_default_role
		 WHERE automated_import_class_sid IS NULL
			OR (automated_import_class_sid = v_class_sid AND step_number = v_step_number)
		)
		LOOP
			csr.role_pkg.SetRoleMembersForUser(
				in_act_id		=>	SYS_CONTEXT('SECURITY', 'ACT'),
				in_role_sid		=>	r.role_sid,
				in_user_sid		=>	v_csr_user_sid,
				in_region_sids	=>	v_start_points
			);
		END LOOP;
	END IF;

	FOR r IN (
		SELECT group_sid 
		  FROM csr.user_profile_default_group
		 WHERE automated_import_class_sid IS NULL
			OR (automated_import_class_sid = v_class_sid AND step_number = v_step_number)
	)
	LOOP
		security.group_pkg.AddMember(
			in_act_id		=>	SYS_CONTEXT('SECURITY', 'ACT'),
			in_member_sid	=>	v_csr_user_sid,
			in_group_sid	=> 	r.group_sid
		);
	END LOOP;
	
	-- Add an audit entry
	csr.csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr.csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, SYS_CONTEXT('SECURITY', 'APP'), v_csr_user_sid, 'User created via automated import');
	IF in_row.profile_active = 0 THEN
		csr_user_pkg.deactivateUser(
			in_act			 				=>	SYS_CONTEXT('SECURITY', 'ACT'),
			in_user_sid		 				=>	v_csr_user_sid,
			in_disable_alerts				=>	1,
			in_raise_user_inactive_alert	=>	0,
			in_remove_from_roles			=>	0
		);
	END IF;
	
	CreateProfile(in_row, v_csr_user_sid, in_row.location_region_ref);

	DELETE FROM user_profile_staged_record
	 WHERE UPPER(primary_key) = UPPER(in_row.primary_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
END;

PROCEDURE CreateProfile(
	in_row							IN	CSR.T_USER_PROFILE_STAGED_ROW,
	in_csr_user_sid					IN	csr.user_profile.csr_user_sid%TYPE,
	in_region_sid					IN	csr.user_profile.location_region_sid%TYPE
)
AS
BEGIN
	INSERT INTO user_profile
		(primary_key, csr_user_sid, employee_ref, payroll_ref, first_name, last_name, middle_name, friendly_name, email_address, 
		 work_phone_number, work_phone_extension, home_phone_number, mobile_phone_number, manager_employee_ref, manager_payroll_ref, manager_primary_key, employment_start_date, 
		 employment_leave_date, date_of_birth, gender, job_title, contract, employment_type, pay_grade, 
		 business_area_ref, business_area_code, business_area_name, business_area_description, division_ref, division_code, division_name, division_description, 
		 department, number_hours, country, location, building, cost_centre_ref, cost_centre_code, cost_centre_name, 
		 cost_centre_description, work_address_1, work_address_2, work_address_3, work_address_4, home_address_1, home_address_2, home_address_3, 
		 home_address_4, location_region_sid, internal_username, manager_username, activate_on, deactivate_on, creation_instance_step_id, 
		 created_dtm, created_user_sid, creation_method, last_updated_dtm, last_updated_user_sid, last_update_method)
	VALUES
		(in_row.primary_key, in_csr_user_sid, in_row.employee_ref, in_row.payroll_ref, in_row.first_name, in_row.last_name, in_row.middle_name, in_row.friendly_name, in_row.email_address, 
		 in_row.work_phone_number, in_row.work_phone_extension, in_row.home_phone_number, in_row.mobile_phone_number, in_row.manager_employee_ref, in_row.manager_payroll_ref, in_row.manager_primary_key, 
		 in_row.employment_start_date, in_row.employment_leave_date, in_row.date_of_birth, in_row.gender, in_row.job_title, in_row.contract, in_row.employment_type, in_row.pay_grade, 
		 in_row.business_area_ref, in_row.business_area_code, in_row.business_area_name, in_row.business_area_description, in_row.division_ref, in_row.division_code, in_row.division_name, in_row.division_description, 
		 in_row.department, in_row.number_hours, in_row.country, in_row.location, in_row.building, in_row.cost_centre_ref, in_row.cost_centre_code, in_row.cost_centre_name, 
		 in_row.cost_centre_description, in_row.work_address_1, in_row.work_address_2, in_row.work_address_3, in_row.work_address_4, in_row.home_address_1, in_row.home_address_2, in_row.home_address_3, 
		 in_row.home_address_4, in_region_sid, in_row.internal_username, in_row.manager_username, in_row.activate_on, in_row.deactivate_on, in_row.instance_step_id, 
		 SYSDATE, SYS_CONTEXT('SECURITY', 'SID'), NVL2(in_row.instance_step_id, 'Import', 'Manual'), SYSDATE, SYS_CONTEXT('SECURITY', 'SID'), in_row.last_update_method);
END;

PROCEDURE CreateProfilesForUsers
AS
	v_row					CSR.T_USER_PROFILE_STAGED_ROW;
	v_csr_user_sid			csr.csr_user.csr_user_sid%TYPE;
	v_first_name			VARCHAR2(256);
	v_last_name				VARCHAR2(256);
BEGIN
	FOR r IN (
	  SELECT u.user_ref, u.csr_user_sid, u.email, u.full_name, u.friendly_name
		FROM csr_user u
		LEFT JOIN user_profile p ON u.csr_user_sid = p.csr_user_sid AND u.app_sid = p.app_sid
	   WHERE u.user_ref IS NOT NULL
		 AND p.csr_user_sid IS NULL
		 AND u.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 AND u.hidden = 0
		 AND NOT EXISTS(SELECT 1 FROM trash t WHERE t.trash_sid = u.csr_user_sid)
		 AND NOT EXISTS(SELECT 1 FROM superadmin sa WHERE sa.csr_user_sid = u.csr_user_sid)
		 AND u.anonymised = 0
		)
	LOOP
	
		SELECT r.csr_user_sid, SUBSTR(r.full_name,1,INSTR(r.full_name,' ')-1), SUBSTR(r.full_name,INSTR(r.full_name,' ')+1)
		  INTO v_csr_user_sid, v_first_name, v_last_name
		  FROM DUAL;
	
		SELECT T_USER_PROFILE_STAGED_ROW(
				r.user_ref, NULL,				NULL,							NVL(v_first_name, v_last_name),		NVL2(v_first_name, v_last_name, ''),
				NULL,		r.friendly_name,	r.email,						NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		NULL,				NULL,							NULL,								NULL,
				NULL,		SYSDATE,			SYS_CONTEXT('SECURITY', 'SID'),	'Util',								NULL
			)
			  INTO v_row
			  FROM DUAL;
			
		CreateProfile(v_row, v_csr_user_sid, NULL);
	END LOOP;
END;

PROCEDURE GetStagedUserRows(
	in_start_row			IN  NUMBER,
	in_page_size			IN  NUMBER,
	in_search_string		IN  VARCHAR2,
	in_order_by			 	IN  VARCHAR2,
	in_order_dir			IN  VARCHAR2,
	out_cur				 	OUT	SYS_REFCURSOR
)
AS

	v_search_query				  	VARCHAR2(102);

BEGIN

	v_search_query := '%' || LOWER(in_search_string) || '%';

	OPEN out_cur FOR

		SELECT rn, total_rows, primary_key, first_name, last_name, email_address, username, error_message, 
			   last_updated, u.instance_step_id, aic.label import_class_name, last_update_method
		  FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY last_name, first_name) rn, COUNT(*) OVER () total_rows, primary_key, first_name, last_name, email_address, username, error_message, 
					   last_updated_dtm last_updated, instance_step_id, last_update_method
				  FROM csr.user_profile_staged_record
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND v_search_query IS NULL OR
				 LOWER(first_name) LIKE v_search_query OR
				 LOWER(email_address) LIKE v_search_query OR
				 LOWER(last_name) LIKE v_search_query OR
				 LOWER(username) LIKE v_search_query  OR
				 LOWER(first_name||' '||last_name) LIKE v_search_query
				 ORDER BY 
				  CASE in_order_dir WHEN 'ASC' THEN
						CASE LOWER(in_order_by)
							WHEN 'firstname' THEN first_name
							WHEN 'lastname' THEN last_name
							WHEN 'email' THEN email_address
							WHEN 'username' THEN username
							ELSE first_name
						END
				   END	ASC,
				  CASE in_order_dir WHEN 'DESC' THEN
						CASE LOWER(in_order_by)
							WHEN 'firstname' THEN first_name
							WHEN 'lastname' THEN last_name
							WHEN 'email' THEN email_address
							WHEN 'username' THEN username
							ELSE first_name
						END
				   END DESC
			   ) u
		  LEFT JOIN csr.automated_import_instance_step aiis ON aiis.auto_import_instance_step_id = u.instance_step_id
		  LEFT JOIN csr.automated_import_class aic ON aiis.automated_import_class_sid = aic.automated_import_class_sid
		 WHERE rn > in_start_row 
		   AND rn <= in_start_row + in_page_size
			 ;
END;

PROCEDURE GetStagedRows(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT primary_key, first_name, last_name, email_address, username, error_message, last_updated_dtm last_updated, rec.instance_step_id, cls.label import_class_name, last_update_method
		  FROM csr.user_profile_staged_record rec
	 LEFT JOIN csr.automated_import_instance_step step 	ON step.auto_import_instance_step_id = rec.instance_step_id
	 LEFT JOIN csr.automated_import_class cls 			ON step.automated_import_class_sid = cls.automated_import_class_sid;

END;

PROCEDURE DeleteStagedRow(
	in_primary_key			IN	csr.user_profile_staged_record.primary_key%TYPE
)
AS
BEGIN

	DELETE FROM csr.user_profile_staged_record rec
	 WHERE UPPER(primary_key) = UPPER(in_primary_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE DeleteAllStagedRows
AS
BEGIN
	DELETE FROM csr.user_profile_staged_record rec
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetProfile(
	in_user_sid			IN csr_user.csr_user_sid%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 
			up.primary_key,
			up.csr_user_sid,
			up.employee_ref,
			up.payroll_ref,
			up.first_name,
			up.last_name,
			up.middle_name,
			up.friendly_name,
			up.email_address,
			up.work_phone_number,
			up.work_phone_extension,
			up.home_phone_number,
			up.mobile_phone_number,
			up.manager_employee_ref,
			up.manager_payroll_ref,
			up.manager_primary_key,
			up.employment_start_date,
			up.employment_leave_date,
			up.date_of_birth,
			up.gender,
			up.job_title,
			up.contract,
			up.employment_type,
			up.pay_grade,
			up.business_area_ref,
			up.business_area_code,
			up.business_area_name,
			up.business_area_description,
			up.division_ref,
			up.division_code,
			up.division_name,
			up.division_description,
			up.department,
			up.number_hours,
			up.country,
			up.location,
			up.building,
			up.cost_centre_ref,
			up.cost_centre_code,
			up.cost_centre_name,
			up.cost_centre_description,
			up.work_address_1,
			up.work_address_2,
			up.work_address_3,
			up.work_address_4,
			up.home_address_1,
			up.home_address_2,
			up.home_address_3,
			up.home_address_4,
			r.description location_region,
			up.location_region_sid,
			up.internal_username,
			up.manager_username,
			up.activate_on,
			up.deactivate_on,
			up.creation_instance_step_id,
			up.created_dtm,
			up.created_user_sid,
			up.creation_method,
			up.updated_instance_step_id,
			up.last_updated_dtm,
			luu.full_name last_updated_user,
			up.last_updated_user_sid,
			up.last_update_method
		  FROM csr.user_profile up
		  LEFT JOIN csr_user luu ON luu.csr_user_sid = up.last_updated_user_sid
		  LEFT JOIN v$region r ON r.region_sid = up.location_region_sid
		 WHERE up.csr_user_sid = in_user_sid
		   AND up.app_sid = security_pkg.GetApp;
END;

PROCEDURE UserHasProfile(					
	in_user_sid 		IN 	security_pkg.T_SID_ID,
	out_result			OUT	BINARY_INTEGER
)
AS
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	
	SELECT COUNT(*) 
	  INTO out_result
	  FROM user_profile
	 WHERE csr_user_sid = in_user_sid
	   AND app_sid = v_app_sid
	   AND ROWNUM = 1;
END;

PROCEDURE UserImportClassExists(
	out_result			OUT	BINARY_INTEGER
)
AS
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	
	SELECT COUNT(*) 
	  INTO out_result
	  FROM csr.automated_import_class aic
	  JOIN csr.automated_import_class_step aics on aic.automated_import_class_sid = aics.automated_import_class_sid
	  JOIN csr.auto_imp_importer_plugin aiip ON aiip.plugin_id = aics.importer_plugin_id
	 WHERE aiip.importer_assembly = 'Credit360.ExportImport.Automated.Import.Importers.UserImporter.UserImporter'	
	   AND aic.app_sid = v_app_sid
	   AND ROWNUM = 1;
END;

PROCEDURE IsUserImportClass(
	in_class_sid 		IN 	csr.automated_import_class.automated_import_class_sid%TYPE,
	out_result			OUT	BINARY_INTEGER
)
AS
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	
	SELECT COUNT(*) 
	  INTO out_result
	  FROM csr.automated_import_class aic
	  JOIN csr.automated_import_class_step aics ON aic.automated_import_class_sid = aics.automated_import_class_sid
	  JOIN csr.auto_imp_importer_plugin aiip ON aiip.plugin_id = aics.importer_plugin_id
	 WHERE aiip.importer_assembly = 'Credit360.ExportImport.Automated.Import.Importers.UserImporter.UserImporter'
	   AND aic.app_sid = v_app_sid
	   AND aic.automated_import_class_sid = in_class_sid
	   AND ROWNUM = 1;
END;

PROCEDURE CreateLineManagerLinks
AS
BEGIN
	FOR r IN (
			SELECT p1.csr_user_sid, p2.csr_user_sid as line_manager
			  FROM user_profile p1
			  JOIN user_profile p2 ON p1.manager_primary_key = p2.primary_key AND p1.app_sid = p2.app_sid
			  JOIN csr_user u ON p1.csr_user_sid = u.csr_user_sid AND p1.app_sid = u.app_sid
			 WHERE p1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND (u.line_manager_sid IS NULL OR u.line_manager_sid <> p2.csr_user_sid) --keep rows with no manager set yet and if manager has changed
	)
	LOOP
		--this only needs to update because we would've created a row in csr_user table already, the line_manager might or might not be set
		UPDATE csr_user 
		   SET line_manager_sid = r.line_manager
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid = r.csr_user_sid
		   AND csr_user.anonymised = 0;
	END LOOP;
END;

PROCEDURE CreateLineManagerLinksForUser(
	in_csr_user_sid			IN	csr.user_profile.csr_user_sid%TYPE
)
AS
BEGIN
	FOR r IN (
			SELECT p1.csr_user_sid, p2.csr_user_sid as line_manager
			  FROM user_profile p1
			  JOIN user_profile p2 ON p1.manager_primary_key = p2.primary_key AND p1.app_sid = p2.app_sid
			  JOIN csr_user u ON p1.csr_user_sid = u.csr_user_sid AND p1.app_sid = u.app_sid
			 WHERE p1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND p1.csr_user_sid = in_csr_user_sid
			   AND (u.line_manager_sid IS NULL OR u.line_manager_sid <> p2.csr_user_sid)
	)
	LOOP
		UPDATE csr_user 
		   SET line_manager_sid = r.line_manager
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid = r.csr_user_sid
		   AND csr_user.anonymised = 0;
	END LOOP;
END;

PROCEDURE GetUserProfile(
	in_csr_user_sid		IN	csr.user_profile.csr_user_sid%TYPE,
	out_user_profile	OUT	csr.T_USER_PROFILE
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_csr_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user profile for the user with sid '||in_csr_user_sid);
	END IF;

	UNSEC_GetUserProfile(
		in_csr_user_sid 	=> in_csr_user_sid,
		out_user_profile	=> out_user_profile
	);

END;

PROCEDURE UNSEC_GetUserProfile(
	in_csr_user_sid		IN	csr.user_profile.csr_user_sid%TYPE,
	out_user_profile	OUT	csr.T_USER_PROFILE
)
AS
BEGIN

	SELECT T_USER_PROFILE(
		primary_key,
		csr_user_sid,
		employee_ref,
		payroll_ref,
		first_name,
		last_name,
		middle_name,
		friendly_name,
		email_address,
		work_phone_number,
		work_phone_extension,
		home_phone_number,
		mobile_phone_number,
		manager_employee_ref,
		manager_payroll_ref,
		manager_primary_key,
		employment_start_date,
		employment_leave_date,
		date_of_birth,
		gender,
		job_title,
		contract,
		employment_type,
		pay_grade,
		business_area_ref,
		business_area_code,
		business_area_name,
		business_area_description,
		division_ref,
		division_code,
		division_name,
		division_description,
		department,
		number_hours,
		country,
		location,
		building,
		cost_centre_ref,
		cost_centre_code,
		cost_centre_name,
		cost_centre_description,
		work_address_1,
		work_address_2,
		work_address_3,
		work_address_4,
		home_address_1,
		home_address_2,
		home_address_3,
		home_address_4,
		location_region_sid,
		internal_username,
		manager_username,
		activate_on,
		deactivate_on,
		creation_instance_step_id,
		created_dtm,
		created_user_sid,
		creation_method,
		updated_instance_step_id,
		last_updated_dtm,
		last_updated_user_sid,
		last_update_method
	)
	  INTO out_user_profile
	  FROM csr.user_profile
	 WHERE csr_user_sid = in_csr_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

END;
/