CREATE OR REPLACE PACKAGE BODY SUPPLIER.audit_pkg
IS

PROCEDURE AuditValueChange(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_field_name		IN	VARCHAR2,
	in_old_value		IN	VARCHAR2,
	in_new_value		IN	VARCHAR2,
	in_sub_object_id	IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	csr.csr_data_pkg.AuditValueChange(in_act_id, in_audit_type_id, in_app_sid, in_object_sid, in_field_name, in_old_value, in_new_value, in_sub_object_id);
END;

PROCEDURE AuditTagChange(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_audit_type_id			IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid				IN	security_pkg.T_SID_ID,
	in_tag_group_description	IN	tag_group.description%TYPE,
	in_old_tag_ids				IN  tag_pkg.T_TAG_IDS,
	in_new_tag_id				IN  tag.tag_id%TYPE,
	in_clear_old_tag_ids		IN	NUMBER,
	in_sub_object_id			IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_new_tag_ids				tag_pkg.T_TAG_IDS; -- a tag IDS array with a single element
BEGIN
	v_new_tag_ids(1) := in_new_tag_id;
	
	AuditTagChange(in_act_id, in_audit_type_id, in_app_sid, in_object_sid, in_tag_group_description,
		in_old_tag_ids,	v_new_tag_ids, in_clear_old_tag_ids, in_sub_object_id);
	
END;

PROCEDURE AuditTagChange(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_audit_type_id			IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid				IN	security_pkg.T_SID_ID,
	in_tag_group_description	IN	tag_group.description%TYPE,
	in_old_tag_ids				IN  tag_pkg.T_TAG_IDS,
	in_new_tag_ids				IN  tag_pkg.T_TAG_IDS,
	in_clear_old_tag_ids		IN	NUMBER,
	in_sub_object_id			IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_old_values				T_VARCHAR2_VALUES;
	v_new_values				T_VARCHAR2_VALUES;
BEGIN


	IF in_old_tag_ids IS NOT NULL AND in_old_tag_ids.count > 0 THEN
		FOR i IN in_old_tag_ids.FIRST..in_old_tag_ids.LAST LOOP
			SELECT NVL(explanation,tag) INTO v_old_values(i) FROM tag WHERE tag_id = in_old_tag_ids(i);
		END LOOP;
	END IF;
	
	IF in_new_tag_ids IS NOT NULL AND in_new_tag_ids.count > 0 THEN
		FOR j IN in_new_tag_ids.FIRST..in_new_tag_ids.LAST LOOP
			SELECT NVL(explanation,tag) INTO v_new_values(j) FROM tag WHERE tag_id = in_new_tag_ids(j);
		END LOOP;
	END IF;

	AuditVarcharListChange(in_act_id, in_audit_type_id, in_app_sid, in_object_sid, 
		'Adding {0} value', 'Removing {0} value', in_tag_group_description, NULL, NULL, v_old_values, v_new_values, in_clear_old_tag_ids, in_sub_object_id);
		
END;

PROCEDURE AuditVarcharListChange(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_audit_type_id			IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid				IN	security_pkg.T_SID_ID,
	in_add_description			IN	csr.audit_log.description%TYPE,
	in_remove_description		IN	csr.audit_log.description%TYPE,
	in_param_1          		IN  csr.audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          		IN  csr.audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          		IN  csr.audit_log.param_3%TYPE DEFAULT NULL,
	in_old_values				IN  T_VARCHAR2_VALUES,
	in_new_values				IN  T_VARCHAR2_VALUES,
	in_clear_values				IN	NUMBER,
	in_sub_object_id			IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_matched					NUMBER;
BEGIN

	-- if there is something in the old list we may need to log it's removal
	-- never need to log removal if we're not clearing old tags 
	IF in_old_values IS NOT NULL AND in_old_values.count > 0 AND in_clear_values = 1 THEN
		-- loop through old tag ids and compare against new tag ids
		FOR i IN in_old_values.FIRST..in_old_values.LAST LOOP
			
			v_matched := 0;
			
			IF in_new_values IS NOT NULL AND in_new_values.count > 0 THEN
				FOR j IN in_new_values.FIRST..in_new_values.LAST LOOP
					IF in_old_values(i) = in_new_values(j) THEN 
						v_matched := 1;
					END IF;
				END LOOP;
			END IF;
			
			-- log if we are clearing old values and the old tag value doen;t exist in the new tag list
			IF v_matched = 0 THEN
				WriteAuditLogEntry(in_act_id, in_audit_type_id, in_app_sid, in_app_sid, 
					in_remove_description || ': ' || in_old_values(i), in_param_1, in_param_2, in_param_3, in_sub_object_id);
			END IF;

		END LOOP;
	END IF;
	
	
	-- if there is something in the new list we may need to log it's addition
	IF in_new_values IS NOT NULL AND in_new_values.count > 0 THEN
		-- loop through new values and compare against old values
		FOR j IN in_new_values.FIRST..in_new_values.LAST LOOP
			
			v_matched := 0;
			
			IF in_old_values IS NOT NULL AND in_old_values.count > 0 THEN
				FOR i IN in_old_values.FIRST..in_old_values.LAST LOOP
					IF in_old_values(i) = in_new_values(j) THEN 
						v_matched := 1;
					END IF;
				END LOOP;
			END IF;
			
			IF v_matched = 0 THEN
				WriteAuditLogEntry(in_act_id, in_audit_type_id, in_app_sid, in_app_sid, 
					in_add_description || ': ' || in_new_values(j), in_param_1, in_param_2, in_param_3, in_sub_object_id);
			END IF;
	
		END LOOP;
	END IF;

END;

PROCEDURE WriteAuditLogEntry(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	csr.audit_log.description%TYPE,
	in_param_1          IN  csr.audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  csr.audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  csr.audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	csr.csr_data_pkg.WriteAuditLogEntry(in_act_id, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);	
END;

PROCEDURE GetAuditLogForUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	csr.csr_data_pkg.GetAuditLogForUser(in_act_id, in_app_sid, in_user_sid, NULL, out_cur);
END;

PROCEDURE GetAuditLogForCompany(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_company_sid		IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	csr.csr_data_pkg.GetAuditLogForObject(in_act_id, in_app_sid, in_company_sid, NULL, out_cur);
END;

PROCEDURE GetAuditLogForProdQuests(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_product_id		IN	csr.audit_log.sub_object_id%TYPE,
	in_start			IN NUMBER,
	in_page_size		IN NUMBER,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
    -- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT audit_date, audit_type_id, label, object_sid, full_name, user_name, csr_user_sid, description, name, param_1, param_2, param_3, audit_date order_seq
		  FROM (
		  	SELECT ROWNUM rn, x.*
		  	  FROM (
				SELECT al.audit_date, aut.audit_type_id, aut.LABEL, al.object_sid, cu.full_name, cu.user_name, cu.csr_user_sid, description, so.NAME, param_1, param_2, param_3
			      FROM csr.audit_log al, csr.audit_type aut, SECURITY.securable_object so, csr.csr_user cu
				 WHERE so.sid_id = al.object_sid
			       AND cu.csr_user_sid = al.user_sid
			       AND al.audit_type_id = aut.audit_type_Id
			       AND al.app_sid = in_app_sid
	               AND object_sid = in_app_sid
	           	   AND sub_object_id = NVL(in_product_id, sub_object_id)
                   AND al.audit_type_id IN (SELECT audit_type_id FROM csr.audit_type WHERE audit_type_group_id = csr.csr_data_pkg.ATG_SUPPLIER_QUESTIONNAIRE)
			 	ORDER BY audit_date DESC
			  )x
			  WHERE rownum <= NVL(in_page_size + in_start, rownum)
		    )
		    WHERE rn > NVL(in_start, rn)
		 ORDER BY order_seq DESC;
END;

PROCEDURE GetAuditLogForProdQuestsCount(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_product_id		IN	csr.audit_log.sub_object_id%TYPE,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cnt				OUT	NUMBER
)
AS
BEGIN
    -- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- TODO: check privs for doing this
		SELECT COUNT(*) INTO out_cnt
	      FROM csr.audit_log al, csr.audit_type aut, SECURITY.securable_object so, csr.csr_user cu
		 WHERE so.sid_id = al.object_sid
	       AND cu.csr_user_sid = al.user_sid
	       AND al.audit_type_id = aut.audit_type_Id
	       AND al.app_sid = in_app_sid
           AND object_sid = in_app_sid
       	   AND sub_object_id = NVL(in_product_id, sub_object_id)
           AND al.audit_type_id IN (SELECT audit_type_id FROM csr.audit_type WHERE audit_type_group_id = csr.csr_data_pkg.ATG_SUPPLIER_QUESTIONNAIRE);
END;

END audit_pkg;
/
