CREATE OR REPLACE PACKAGE BODY CSR.Csr_Data_Pkg AS

PROCEDURE LockPeriod(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	customer.lock_start_dtm%TYPE,
	in_end_dtm						IN	customer.lock_end_dtm%TYPE
)
AS
BEGIN
	-- permissions
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;

	UPDATE customer 
	   SET lock_start_dtm = in_start_dtm,
		lock_end_dtm = in_end_dtm
     WHERE app_sid = in_app_sid;
END;

PROCEDURE RemovePeriodLock(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE customer
	   SET lock_start_dtm = date '1980-01-01', lock_end_dtm = date '1980-01-01'
	 WHERE app_sid = in_app_sid;
END;

FUNCTION IsPeriodLocked(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	customer.lock_start_dtm%TYPE,
	in_end_dtm						IN	customer.lock_end_dtm%TYPE
) RETURN NUMBER
AS
	CURSOR c IS
		SELECT lock_start_dtm, lock_end_dtm 
		  FROM customer
		 WHERE app_sid = in_app_sid
		   AND lock_start_dtm < in_end_dtm
		   AND lock_end_dtm > in_start_dtm;
	r	c%ROWTYPE;
BEGIN
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RETURN 0;
	ELSE
		RETURN 1;
	END IF;
END;

PROCEDURE GetLockPeriod(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT lock_start_dtm, lock_end_dtm
		  FROM customer c
		 WHERE c.app_sid = security_pkg.GetApp();
END;

FUNCTION AddToAuditDescription(
	in_field_name					IN	VARCHAR2,
	in_old_value					IN	VARCHAR2,
	in_new_value					IN	VARCHAR2
) RETURN VARCHAR2
AS
BEGIN
	IF in_old_value!=in_new_value OR
		(in_old_value IS NULL AND in_new_value IS NOT NULL) OR
		(in_new_value IS NULL AND in_old_value IS NOT NULL) THEN
		IF LENGTH(in_new_value)>40 THEN
			RETURN in_field_name||' changed to '''||SUBSTR(in_new_value,1,40)||'...''; ';
		ELSE
			RETURN in_field_name||' changed to '''||NVL(in_new_value,'null')||'''; ';
		END IF;
	ELSE
		RETURN '';
	END IF;
END;

PROCEDURE AuditClobChange(
	in_act							IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_field_name					IN	VARCHAR2,
	in_old_value					IN	CLOB,
	in_new_value					IN	CLOB,
	in_sub_object_id    			IN  audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_from	CLOB;
	v_to	CLOB;
BEGIN
	IF DBMS_LOB.COMPARE(in_old_value, in_new_value) != 0 OR
		(in_old_value IS NULL AND in_new_value IS NOT NULL) OR
		(in_new_value IS NULL AND in_old_value IS NOT NULL) THEN
		
		IF in_old_value IS NULL THEN
			v_from := 'Empty';
		ELSE
			-- hmm, that's chars not number of bytes, but the audit log code truncates properly anyway. Main thing is to avoid passing a 60k clob
			-- note that the param order on DBMS_LOB.SUBSTR is different to normal SUBSTR
			v_from := DBMS_LOB.SUBSTR(in_old_value, LEAST(LENGTH(in_old_value), 2048), 1);
		END IF;
		IF in_new_value IS NULL THEN
			v_to := 'Empty';
		ELSE
			-- hmm, that's chars not number of bytes, but the audit log code truncates properly anyway. Main thing is to avoid passing a 60k clob
			-- note that the param order on DBMS_LOB.SUBSTR is different to normal SUBSTR
			v_to := DBMS_LOB.SUBSTR(in_new_value, LEAST(LENGTH(in_new_value), 2048), 1);
		END IF;
		
		csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, in_audit_type_id, in_app_sid, in_object_sid, in_sub_object_id,
			 '{0} changed from "{1}" to "{2}"', in_field_name, v_from, v_to);
	END IF;
END;

PROCEDURE AuditValueChange(
	in_act							IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_field_name					IN	VARCHAR2,
	in_old_value					IN	VARCHAR2,
	in_new_value					IN	VARCHAR2,
	in_sub_object_id    			IN  audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	IF in_old_value!=in_new_value OR
		(in_old_value IS NULL AND in_new_value IS NOT NULL) OR
		(in_new_value IS NULL AND in_old_value IS NOT NULL) THEN
		csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, in_audit_type_id, in_app_sid, in_object_sid, in_sub_object_id,
			 '{0} changed from "{1}" to "{2}"', in_field_name, NVL(in_old_value,'Empty'), NVL(in_new_value,'Empty'));
	END IF;
END;

PROCEDURE AuditValueDescChange(
	in_act							IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_field_name					IN	VARCHAR2,
	in_old_value					IN	VARCHAR2,
	in_new_value					IN	VARCHAR2,
	in_old_desc						IN	VARCHAR2,
	in_new_desc						IN	VARCHAR2,
	in_sub_object_id    			IN  audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	IF in_old_value!=in_new_value OR
		(in_old_value IS NULL AND in_new_value IS NOT NULL) OR
		(in_new_value IS NULL AND in_old_value IS NOT NULL) THEN
		csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, in_audit_type_id, in_app_sid, in_object_sid, in_sub_object_id,
			 '{0} changed from "{1}" to "{2}"', in_field_name, NVL(in_old_desc,'Empty'), NVL(in_new_desc,'Empty'));
	END IF;
END;

PROCEDURE AuditInfoXmlChanges(
	in_act							IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_info_xml_fields				IN	XMLType,
	in_old_info_xml					IN	XMLType,
	in_new_info_xml					IN	XMLType,
	in_sub_object_id    			IN  audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_max_string_size				NUMBER := 1000;
BEGIN
	
	-- there is slightly customized version of this procedure in donations/donation_body.sql
	FOR rx IN (
		 SELECT 
		    CASE 
		      WHEN n.node_key IS NULL THEN '{0} deleted'
		      WHEN o.node_key IS NULL THEN '{0} set to "{2}"'
		      ELSE '{0} changed from "{1}" to "{2}"'
		    END action, NVL(f.node_label, NVL(o.node_key, n.node_key)) node_label, 
		    REGEXP_REPLACE(NVL(o.node_value,'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') old_node_value, 
		    REGEXP_REPLACE(NVL(n.node_value,'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') new_node_value
		  FROM (
		      SELECT 
		        EXTRACT(VALUE(x), 'field/@name').getStringVal() node_key,
		        EXTRACT(VALUE(x), 'field/@label').getStringVal() node_label
		      FROM TABLE(XMLSEQUENCE(EXTRACT(in_info_xml_fields, '*/field' )))x
		   )f, (
			 SELECT
				TO_CHAR(SUBSTR(x.name,1,v_max_string_size)) node_key,
				TO_CHAR(SUBSTR(x.value,1,v_max_string_size)) node_value
		      FROM XMLTABLE ('fields/field'
							  PASSING in_old_info_xml
							  COLUMNS value clob PATH 'text()',
									  name clob PATH '@name') x
		  )o FULL JOIN (
		     SELECT
				TO_CHAR(SUBSTR(x.name,1,v_max_string_size)) node_key,
				TO_CHAR(SUBSTR(x.value,1,v_max_string_size)) node_value
		      FROM XMLTABLE ('fields/field'
							  PASSING in_new_info_xml
							  COLUMNS value clob PATH 'text()',
									  name clob PATH '@name') x
		  )n ON o.node_key = n.node_key
		  WHERE f.node_key = NVL(o.node_key, n.node_key)
		    AND (n.node_key IS NULL
				OR o.node_key IS NULL
				OR NVL(o.node_value, '-') != NVL(n.node_value, '-')
			)
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, in_audit_type_id, in_app_sid, in_object_sid, in_sub_object_id,
			 rx.action, rx.node_label, rx.old_node_value, rx.new_node_value);
	END LOOP;
END;

-- takes appsid (useful for actions + donations)
PROCEDURE WriteAppAuditLogEntry(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid		    			IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
    WriteAuditLogEntryForSid(v_user_sid, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);
END;

PROCEDURE WriteAuditLogEntry_AT(
	in_act_id						IN	security_pkg.T_ACT_ID	DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION; 
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
    WriteAuditLogEntryForSid(v_user_sid, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);
    COMMIT;
END;

PROCEDURE WriteAuditLogEntry(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	WriteAuditLogEntryForSid(v_user_sid, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);	
END;

PROCEDURE WriteAuditLogEntryAndSubObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_sub_object_id				IN  audit_log.sub_object_id%TYPE DEFAULT NULL,
	in_description					IN	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	INSERT INTO audit_log
		(AUDIT_DATE, AUDIT_TYPE_ID, app_sid, OBJECT_SID, USER_SID, DESCRIPTION, SUB_OBJECT_ID, PARAM_1, PARAM_2, PARAM_3)
	VALUES
		(SYSDATE, in_audit_type_id, in_app_sid, in_object_sid, v_user_sid, TruncateString(in_description,1023), in_sub_object_id, TruncateString(in_param_1,2048), TruncateString(in_param_2,2048), TruncateString(in_param_3,2048) );
END;


-- doesn't seem to like overloading when we chagne the first param - maybe due to the defaults? dunno
PROCEDURE WriteAuditLogEntryForSid(
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO audit_log
		(AUDIT_DATE, AUDIT_TYPE_ID, app_sid, OBJECT_SID, USER_SID, DESCRIPTION, PARAM_1, PARAM_2, PARAM_3, SUB_OBJECT_ID)
	VALUES
		(SYSDATE, in_audit_type_id, in_app_sid, in_object_sid, in_sid_id, TruncateString(in_description,1023), TruncateString(in_param_1,2048), TruncateString(in_param_2,2048), TruncateString(in_param_3,2048), in_sub_object_id);
END;

PROCEDURE GetAuditLogForUser(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
    -- check permission.... insist on WRITE - slightly more hard-core than READ
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ al.audit_date, al.audit_type_id, aut.label, al.object_sid, cu.full_name, cu.user_name, 
			al.csr_user_sid, al.description, al.name, al.param_1, al.param_2, al.param_3, al.remote_addr, 
			al.original_user_sid, cu2.user_name original_user_name, cu2.full_name original_full_name, audit_date order_seq
		  FROM csr_user cu, audit_type aut, csr_user cu2, (
			SELECT al.audit_date, al.audit_type_id, al.object_sid, al.user_sid csr_user_sid, 
			       al.description, so.name, param_1, param_2, param_3, al.remote_addr, al.original_user_sid -- this is what this user has done
			  FROM (
				SELECT row_id
				  FROM (SELECT ROWID row_id
					      FROM audit_log al
					     WHERE (al.user_sid = in_user_sid OR al.original_user_sid = in_user_sid)
					       AND al.app_sid = in_app_sid
					       AND audit_type_id != csr_data_pkg.AUDIT_TYPE_BATCH_LOGON
					  ORDER BY audit_date DESC, ROWNUM DESC)
				 WHERE ROWNUM <= 100
			  ) i
			  JOIN csr.audit_log al ON al.ROWID = i.row_id
			  JOIN SECURITY.securable_object so ON so.sid_id = al.object_sid
			UNION 
			SELECT * -- this is what has been done to this user
			  FROM (SELECT al.audit_date, al.audit_type_id, al.object_sid, al.user_sid csr_user_sid, 
						   al.description, so.name, param_1, param_2, param_3, al.remote_addr, al.original_user_sid
					  FROM audit_log al, SECURITY.securable_object so
					 WHERE al.object_sid = in_user_sid
					   AND so.sid_id = al.object_sid
					   AND al.app_sid = in_app_sid
					   AND audit_type_id != csr_data_pkg.AUDIT_TYPE_BATCH_LOGON
				  ORDER BY audit_date DESC, ROWNUM DESC)
			 WHERE rownum <= 100
		) al
		WHERE aut.audit_type_id = al.audit_type_id 
		  AND cu.csr_user_sid = al.csr_user_sid
		  AND cu2.csr_user_sid(+) = al.original_user_sid
	 ORDER BY audit_date DESC, ROWNUM DESC;
END;

PROCEDURE GetAuditLogForUser(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2, -- redundant but needed for quick list output
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_start_date					IN	DATE,
	in_end_date						IN	DATE,
	out_total						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_is_anonymised				csr_user.anonymised%TYPE;
BEGIN
    -- check permission.... insist on WRITE - slightly more hard-core than READ
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT anonymised
	  INTO v_is_anonymised
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid;

	IF v_is_anonymised = 1 THEN
		out_total := 1;
		
		OPEN out_cur FOR
			SELECT al.audit_date, aut.label, cu2.user_name original_user_name, cu2.full_name original_full_name, cu.user_name,
				cu.full_name, al.param_1 first_parameter, al.param_2 second_parameter, al.param_3 third_parameter,
				al.description, al.remote_addr
			FROM audit_log al
			JOIN csr_user cu ON cu.csr_user_sid = al.user_sid
			LEFT JOIN csr_user cu2 ON cu2.csr_user_sid = al.original_user_sid
			JOIN audit_type aut ON aut.audit_type_id = al.audit_type_id
			WHERE al.app_sid = in_app_sid AND al.object_sid = in_user_sid
				AND al.audit_type_id = csr_data_pkg.AUDIT_TYPE_ANONYMISED
				AND al.audit_date >= in_start_date AND al.audit_date <= in_end_date;
		RETURN;
	END IF;


	INSERT INTO temp_audit_log_ids(row_id, audit_dtm)
    (SELECT /*+ INDEX (audit_log IDX_AUDIT_LOG_OBJECT_SID) */ rowid, audit_date
	   FROM csr.audit_log
	  WHERE app_sid = in_app_sid AND object_sid = in_user_sid 
		AND audit_date >= in_start_date AND audit_date <= in_end_date
		AND audit_type_id != csr_data_pkg.AUDIT_TYPE_BATCH_LOGON
	  UNION
	 SELECT rowid, audit_date
	   FROM csr.audit_log 
	  WHERE app_sid = in_app_sid AND (user_sid = in_user_sid OR original_user_sid = in_user_sid)
		AND audit_date >= in_start_date AND audit_date <= in_end_date
		AND audit_type_id != csr_data_pkg.AUDIT_TYPE_BATCH_LOGON);
	
	 SELECT COUNT(row_id)
	   INTO out_total
	   FROM temp_audit_log_ids;
	  	
	OPEN out_cur FOR
		SELECT al.audit_date, aut.label, cu2.user_name original_user_name, cu2.full_name original_full_name, cu.user_name, 
			cu.full_name, al.param_1 first_parameter, al.param_2 second_parameter, al.param_3 third_parameter, 
			al.description, al.remote_addr
		  FROM (SELECT /*+CARDINALITY(100)*/ row_id, rn
                  FROM (SELECT row_id, rownum rn
                          FROM (SELECT row_id
                                  FROM temp_audit_log_ids
                              ORDER BY audit_dtm DESC, row_id DESC)
                         WHERE rownum < in_start_row + in_page_size)
                 WHERE rn >= in_start_row) alr
          JOIN audit_log al ON al.rowid = alr.row_id 
		  JOIN csr_user cu ON cu.csr_user_sid = al.user_sid
	 LEFT JOIN csr_user cu2 ON cu2.csr_user_sid = al.original_user_sid
		  JOIN audit_type aut ON aut.audit_type_id = al.audit_type_id
	  ORDER BY alr.rn;
END;

PROCEDURE GetAuditLogForObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetAuditLogForObject(in_act_id, in_app_sid, in_object_sid, NULL, in_order_by, out_cur);
END;

PROCEDURE GetAuditLogForObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE,
	in_order_by						IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
    -- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT audit_date, audit_type_id, LABEL, object_sid, original_full_name, original_user_name, 
			   full_name, user_name, csr_user_sid, description, NAME, param_1, param_2, param_3, audit_date order_seq
		  FROM (
		  	SELECT ROWNUM rn, x.*
		  	  FROM (
				SELECT al.audit_date, aut.audit_type_id, aut.LABEL, al.object_sid, cu2.full_name original_full_name, 
					   cu2.user_name original_user_name, cu.full_name, cu.user_name, 
					   cu.csr_user_sid, description, so.NAME, param_1, param_2, param_3, al.remote_addr
			      FROM audit_log al, audit_type aut, SECURITY.securable_object so, csr_user cu, csr_user cu2
				 WHERE so.sid_id = al.object_sid
				   AND cu.csr_user_sid = al.user_sid
				   AND cu2.csr_user_sid(+) = al.original_user_sid
				   AND al.audit_type_id = aut.audit_type_Id
				   AND al.app_sid = in_app_sid
				   AND object_sid = in_object_sid
				   AND (sub_object_id is NULL OR sub_object_id = in_sub_object_id)
			 	ORDER BY audit_date DESC, ROWNUM DESC
			  )x
		    )
		 ORDER BY order_seq DESC;
END;

PROCEDURE GetAuditLogForObjectType(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_audit_type_id    			IN  audit_log.audit_type_id%TYPE,
	in_order_by						IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetAuditLogForObjectType(in_act_id, in_app_sid, in_object_sid, NULL, in_audit_type_id, in_order_by, out_cur);
END;

PROCEDURE GetAuditLogForObjectType(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE,
	in_audit_type_id    			IN  audit_log.audit_type_id%TYPE,
	in_order_by						IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
    -- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT audit_date, audit_type_id, LABEL, object_sid, 
			NVL(full_name,'unknown') full_name, -- UserCreatorDaemon isn't in csr_user
			NVL(user_name,'unknown') user_name, -- UserCreatorDaemon isn't in csr_user
			user_sid csr_user_sid, -- UserCreatorDaemon isn't in csr_user
			description, NAME, param_1, param_2, param_3, audit_date order_seq
		  FROM (
		  	SELECT ROWNUM rn, x.*
		  	  FROM (
				SELECT al.user_sid, al.audit_date, aut.audit_type_id, aut.LABEL, al.object_sid, cu.full_name, 
					   cu.user_name, cu.csr_user_sid, description, so.NAME, param_1, param_2, param_3,
					   al.remote_addr
			      FROM audit_log al, audit_type aut, SECURITY.securable_object so, csr_user cu
				 WHERE so.sid_id = al.object_sid
			       AND cu.csr_user_sid(+) = al.user_sid
			       AND al.audit_type_id = aut.audit_type_Id
			       AND al.app_sid = in_app_sid
	               AND object_sid = in_object_sid
	           	   AND ((sub_object_id IS NULL AND in_sub_object_id IS NULL) OR sub_object_id = NVL(in_sub_object_id, sub_object_id))
                   AND al.audit_type_id = in_audit_type_id
			 	ORDER BY audit_date, ROWNUM
			  )x
		    )
		 ORDER BY order_seq DESC;
END;

PROCEDURE GenerateAuditReport(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can generate audit log reports') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can generate audit log reports" capability');
	END IF;

	OPEN out_cur FOR
		SELECT al.audit_date action_date, aut.label action_type,
			   --cu2.full_name original_full_name, cu2.user_name original_user_name, 
			   CASE WHEN al.original_user_sid IS NULL THEN csru.full_name ELSE cu2.full_name || ' as ' || csru.full_name END username,
			   so.name action_target, 
			   REPLACE(REPLACE(REPLACE(al.description, '{0}', al.param_1), '{1}', al.param_2), '{2}', al.param_3) action_desc
		 FROM audit_log al
		 JOIN audit_type aut ON al.audit_type_id = aut.audit_type_id
		 JOIN csr_user csru ON al.user_sid = csru.csr_user_sid
	LEFT JOIN csr_user cu2 ON cu2.csr_user_sid = al.original_user_sid
		 JOIN security.securable_object so ON al.object_sid = so.sid_id
		WHERE al.audit_date >= in_start_dtm
		  AND al.audit_date < in_end_dtm
		  AND al.app_sid = security_pkg.GetApp
		 
		  ORDER BY audit_date DESC, ROWNUM DESC;
END;


PROCEDURE CheckRegisteredUser
IS
	v_act_id	security_pkg.T_ACT_ID;
BEGIN
	v_act_id := security_pkg.GetACT();
	IF user_pkg.IsUserInGroup(
		v_act_id, 
		securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp(), 'Groups/RegisteredUsers')) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied due to lack of membership in Groups/RegisteredUsers '||
			'for the application with sid '||security_pkg.GetApp()||
			' using the act '||v_act_id);
	END IF;
END;

PROCEDURE GetConfiguration(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckRegisteredUser;

	OPEN out_cur FOR
		SELECT c.name, c.host, c.system_mail_address, c.aggregation_engine_version, c.contact_email, c.editing_url,
			   c.message, c.raise_reminders, c.account_policy_sid, c.app_sid, c.status, c.raise_split_deleg_alerts,
			   c.ind_info_xml_fields, c.region_info_xml_fields, c.user_info_xml_fields, c.current_reporting_period_sid,
			   c.lock_start_dtm, c.lock_end_dtm, c.region_root_sid, c.ind_root_sid, c.reporting_ind_root_sid,
			   c.cascade_reject, c.approver_response_window, c.self_reg_group_sid, c.self_reg_needs_approval,
			   c.self_reg_approver_sid, cu.full_name self_reg_approver_full_name, c.allow_partial_submit,
			   c.helper_assembly, c.tracker_mail_address, c.alert_mail_address, c.approval_step_sheet_url, 
			   c.use_tracker, c.audit_calc_changes, c.fully_hide_sheets, c.use_user_sheets, c.allow_val_edit, c.calc_sum_zero_fill,
			   c.equality_epsilon, c.create_sheets_at_period_end, c.alert_mail_name, c.alert_batch_run_time, c.incl_inactive_regions,
			   c.lock_prevents_editing, c.tear_off_deleg_header, c.deleg_dropdown_threshold, c.show_data_approve_confirm,
			   c.auto_anonymisation_enabled, c.inactive_days_before_anonymisation
		  FROM customer c, csr_user cu
		 WHERE c.app_sid = security_pkg.GetApp()
		   AND c.app_sid = cu.app_sid(+) and c.self_reg_approver_sid = cu.csr_user_sid(+);
END;

PROCEDURE SetConfiguration(
	in_alert_mail_address					IN	customer.alert_mail_address%TYPE,
	in_alert_mail_name						IN	customer.alert_mail_name%TYPE,
	in_alert_batch_run_time					IN	customer.alert_batch_run_time%TYPE,
	in_raise_reminders						IN	customer.raise_reminders%TYPE,
	in_raise_split_deleg_alerts				IN	customer.raise_split_deleg_alerts%TYPE,
	in_cascade_reject       				IN	customer.cascade_reject%TYPE,
	in_approver_response_window				IN	customer.approver_response_Window%TYPE,
	in_self_reg_group_sid					IN	customer.self_reg_group_sid%TYPE,
	in_self_reg_needs_approval				IN	customer.self_reg_needs_approval%TYPE,
	in_self_reg_approver_sid				IN	customer.self_reg_approver_sid%TYPE,
    in_lock_end_dtm             			IN  customer.lock_end_dtm%TYPE,
    in_allow_partial_submit					IN	customer.allow_partial_submit%TYPE,
    in_create_sheets_period_end				IN	customer.create_sheets_at_period_end%TYPE,
	in_incl_inactive_regions				IN	customer.incl_inactive_regions%TYPE,
	in_lock_prevents_editing				IN	customer.lock_prevents_editing%TYPE,
	in_tear_off_deleg_header        		IN  customer.tear_off_deleg_header%TYPE,
	in_deleg_dropdown_threshold     		IN  customer.deleg_dropdown_threshold%TYPE,
	in_show_data_approve_confirm			IN	customer.show_data_approve_confirm%TYPE DEFAULT 0,
	in_auto_anonymisation_enabled			IN	customer.auto_anonymisation_enabled%TYPE,
	in_inactive_days_before_anonymisation	IN	customer.inactive_days_before_anonymisation%TYPE
)
AS
	v_old_alert_batch_run_time		customer.alert_batch_run_time%TYPE;
	v_self_reg_group_sid			customer.self_reg_group_sid%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), security_pkg.GetApp(), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied writing configuration for the CSR application with sid '||security_pkg.GetApp());
	END IF;
	
	SELECT alert_batch_run_time
	  INTO v_old_alert_batch_run_time
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF in_self_reg_group_sid = -1 THEN
		v_self_reg_group_sid := NULL;
	ELSE
		v_self_reg_group_sid := in_self_reg_group_sid;
	END IF;
	UPDATE customer
	   SET alert_mail_address = in_alert_mail_address,
	   	   alert_mail_name = in_alert_mail_name,
	   	   alert_batch_run_time = in_alert_batch_run_time,
	   	   raise_reminders = in_raise_reminders,
	       raise_split_deleg_alerts = in_raise_split_deleg_alerts,
	       cascade_reject = in_cascade_reject,
           approver_response_window = in_approver_response_window,
           self_reg_group_sid = v_self_reg_group_sid,
           self_reg_needs_approval = in_self_reg_needs_approval,
           self_reg_approver_sid = in_self_reg_approver_sid,
           lock_end_dtm = in_lock_end_dtm,
           allow_partial_submit = in_allow_partial_submit,
           create_sheets_at_period_end = in_create_sheets_period_end,
		   incl_inactive_regions = in_incl_inactive_regions,
		   lock_prevents_editing = in_lock_prevents_editing,
		   tear_off_deleg_header = in_tear_off_deleg_header,
		   deleg_dropdown_threshold = in_deleg_dropdown_threshold,
		   show_data_approve_confirm = in_show_data_approve_confirm
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	IF in_auto_anonymisation_enabled IS NOT NULL AND in_inactive_days_before_anonymisation IS NOT NULL THEN
		UPDATE customer
		SET auto_anonymisation_enabled = in_auto_anonymisation_enabled,
			inactive_days_before_anonymisation = in_inactive_days_before_anonymisation
		WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;

	 IF v_self_reg_group_sid > 0 THEN
		SetSelfRegistrationPermissions(1);
	 ELSE
		SetSelfRegistrationPermissions(0);
	 END IF;
	 
	-- fix up batch run times if the batch time has changed
	IF v_old_alert_batch_run_time != in_alert_batch_run_time THEN
		UPDATE alert_batch_run abr
		   SET next_fire_time = (SELECT next_fire_time_gmt
		   						   FROM v$alert_batch_run_time abrt
		   						  WHERE abr.app_sid = abrt.app_sid
		   						    AND abr.csr_user_sid = abrt.csr_user_sid)
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE SetSelfRegistrationPermissions(
	in_setting						IN	NUMBER
)
AS
	v_app_sid				security.security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_ind_root_sid			security.security_pkg.T_SID_ID;
	v_region_root_sid		security.security_pkg.T_SID_ID;
	v_usercreatordaemon_sid	security.security_pkg.T_SID_ID;
	
	v_ind_acl_id			security.security_pkg.T_SID_ID;
	v_region_acl_id			security.security_pkg.T_SID_ID;
	v_current_ind_perms		security.acl.permission_set%TYPE;
	v_current_region_perms	security.acl.permission_set%TYPE;
	v_current_ind_access	BOOLEAN;
	v_current_region_access	BOOLEAN;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	v_act_id := security_pkg.getact;
	
	-- Add/remove UserCreatorDaemon write access from the Indicator and Region roots.
	v_ind_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Indicators');
	v_region_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Regions');
	BEGIN
		v_usercreatordaemon_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users/usercreatordaemon');
	EXCEPTION
	     WHEN security_pkg.OBJECT_NOT_FOUND THEN RETURN;
	END;

	v_ind_acl_id := security.acl_pkg.GetDACLIDForSID(v_ind_root_sid);
	v_region_acl_id := security.acl_pkg.GetDACLIDForSID(v_region_root_sid);
	
	v_current_ind_perms := 0;
	v_current_region_perms := 0;
	v_current_ind_access := FALSE;
	v_current_region_access := FALSE;
	
	BEGIN
		SELECT MAX(permission_set)
		  INTO v_current_ind_perms
		  FROM security.ACL
		 WHERE acl_id = v_ind_acl_id 
		   AND sid_id = v_usercreatordaemon_sid
		   AND ace_flags = security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE;
	EXCEPTION
	     WHEN NO_DATA_FOUND THEN NULL;
	END;

	BEGIN
		SELECT MAX(permission_set)
		  INTO v_current_region_perms
		  FROM security.ACL
		 WHERE acl_id = v_region_acl_id 
		   AND sid_id = v_usercreatordaemon_sid
		   AND ace_flags = security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE;
	EXCEPTION
	     WHEN NO_DATA_FOUND THEN NULL;
	END;

	IF v_current_ind_perms = security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE THEN
		v_current_ind_access := TRUE;
	END IF;
	   
	IF v_current_region_perms = security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE THEN
		v_current_region_access := TRUE;
	END IF;

	IF in_setting = 0 THEN
		IF v_current_ind_access = TRUE THEN
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ind_root_sid), v_usercreatordaemon_sid);
		END IF;
		IF v_current_region_access = TRUE THEN
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_region_root_sid), v_usercreatordaemon_sid);
		END IF;
	ELSE
		IF v_current_ind_access = FALSE THEN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ind_root_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, 
				v_usercreatordaemon_sid, security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE);
		END IF;
		IF v_current_region_access = FALSE THEN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_region_root_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, 
				v_usercreatordaemon_sid, security.security_pkg.PERMISSION_STANDARD_READ+security.security_pkg.PERMISSION_WRITE);
		END IF;
	END IF;
END;

PROCEDURE EnableCapability(
	in_capability  					IN	security_pkg.T_SO_NAME,
	in_swallow_dup_exception    	IN  NUMBER DEFAULT 1
)
AS
    v_allow_by_default      capability.allow_by_default%TYPE;
	v_capability_sid		security_pkg.T_SID_ID;
	v_capabilities_sid		security_pkg.T_SID_ID;
BEGIN
    -- this also serves to check that the capability is valid
    BEGIN
        SELECT allow_by_default
          INTO v_allow_by_default
          FROM capability
         WHERE LOWER(name) = LOWER(in_capability);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
	END;

    -- just create a sec obj of the right type in the right place
    BEGIN
		v_capabilities_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				SYS_CONTEXT('SECURITY','APP'), 
				security_pkg.SO_CONTAINER,
				'Capabilities',
				v_capabilities_sid
			);
	END;
	
	BEGIN
		securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
			v_capabilities_sid, 
			class_pkg.GetClassId('CSRCapability'),
			in_capability,
			v_capability_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			IF in_swallow_dup_exception = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
			END IF;
	END;
END;

PROCEDURE DeleteCapability (
	in_name							VARCHAR2
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_capability_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_capability_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, '/Capabilities/' || in_name);
		securableobject_pkg.DeleteSO(v_act_id, v_capability_sid);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
	END;
END;

-- ACTless version (i.e. pulls from context)
FUNCTION CheckCapability(
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN
AS
BEGIN
    RETURN CheckCapability(SYS_CONTEXT('SECURITY','ACT'), in_capability);
END;

FUNCTION SQL_CheckCapability(
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER
AS
BEGIN
	IF CheckCapability(SYS_CONTEXT('SECURITY','ACT'), in_capability) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION SQL_CheckCapability(
    in_act_Id                   	IN  security_pkg.T_ACT_ID,
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER
AS
BEGIN
	IF CheckCapability(in_act_id, in_capability) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION CheckCapabilityOfUser(
	in_user_sid						IN  security_Pkg.T_SID_ID,
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN
AS
	v_act	security_pkg.T_ACT_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_user_sid, security_pkg.PERMISSION_STANDARD_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	v_act := user_pkg.GenerateACT(); 
	Act_Pkg.Issue(in_user_sid, v_act, 1, SYS_CONTEXT('SECURITY','APP'));
	
    RETURN CheckCapability(v_act, in_capability);
END;

FUNCTION SQL_CheckCapabilityOfUser(
	in_user_sid						IN  security_Pkg.T_SID_ID,
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER
AS
	v_act	security_pkg.T_ACT_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_user_sid, security_pkg.PERMISSION_STANDARD_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	v_act := user_pkg.GenerateACT(); 
	Act_Pkg.Issue(in_user_sid, v_act, 1, SYS_CONTEXT('SECURITY','APP'));
	
	IF CheckCapability(v_act, in_capability) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

-- version with ACT since this is sometimes called by older SPs that are passed ACTs, so it 
-- is more consistent to also call this with the same ACT (just in case they were different
-- for some reason).
FUNCTION CheckCapability(
	in_act_id      					IN 	security_pkg.T_ACT_ID,
	in_capability  					IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN
AS
    v_allow_by_default      capability.allow_by_default%TYPE;
	v_capability_sid        security_pkg.T_SID_ID;
BEGIN
    -- this also serves to check that the capability is valid
    BEGIN
        SELECT allow_by_default
          INTO v_allow_by_default
          FROM capability
         WHERE LOWER(name) = LOWER(in_capability);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
	END;
	
	BEGIN
		-- get sid of capability to check permission
		v_capability_sid := securableobject_pkg.GetSIDFromPath(in_act_id, SYS_CONTEXT('SECURITY','APP'), '/Capabilities/' || in_capability);
		-- check permissions....
		RETURN Security_Pkg.IsAccessAllowedSID(in_act_id, v_capability_sid, security_pkg.PERMISSION_WRITE);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
            IF v_allow_by_default = 1 THEN
                RETURN TRUE; -- let them do it if it's not configured
            ELSE
                RETURN FALSE;
            END IF;
	END;
END; 

PROCEDURE GetCapabilities(
	in_act_id      					IN 	security_pkg.T_ACT_ID,
	out_cur							OUT SYS_REFCURSOR
) AS
	v_capabilities_sid		security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(in_act_id, SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
BEGIN
	OPEN out_cur FOR
		SELECT c.name capability_name,
			   CASE
					WHEN pso.sid_id IS NOT NULL THEN 1
					WHEN so.sid_id IS NULL THEN c.allow_by_default
					ELSE 0
				END has_capability
		  FROM capability c
		  LEFT JOIN TABLE (securableobject_pkg.GetChildrenAsTable(in_act_id, v_capabilities_sid)) so ON c.name = so.name
		  LEFT JOIN TABLE (securableobject_pkg.GetChildrenWithPermAsTable(in_act_id, v_capabilities_sid, security_pkg.PERMISSION_WRITE)) pso ON so.sid_id = pso.sid_id
		;
END;


PROCEDURE GetAppGroups(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_act_id		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	OPEN out_cur FOR	
		SELECT sid_id, name 
		  FROM TABLE(securableobject_pkg.GetDescendantsAsTable(v_act_id, 
		  			 	securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups')))
		 WHERE class_id in (security_pkg.SO_GROUP, class_pkg.GetClassId('CSRUserGroup'));
END;

PROCEDURE LockApp(
	in_lock_type					IN	app_lock.lock_type%TYPE,
	in_app_sid						IN	app_lock.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
AS
BEGIN
	UPDATE app_lock
	   SET dummy = 1
	 WHERE lock_type = in_lock_type
	   AND app_sid = in_app_sid;
	 
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown lock type: '||in_lock_type||' for app_sid:'||in_app_sid);
	END IF;
END;

FUNCTION TryLockApp(
	in_app_sid						IN	app_lock.app_sid%TYPE,
	in_lock_type					IN	app_lock.lock_type%TYPE
)
RETURN BOOLEAN
AS
	v_dummy							app_lock.dummy%TYPE;
	e_resource_busy 				EXCEPTION;
  	PRAGMA EXCEPTION_INIT(e_resource_busy, -54);
	e_wait_timed_out				EXCEPTION;
  	PRAGMA EXCEPTION_INIT(e_wait_timed_out, -30006);
BEGIN
	BEGIN
		SELECT dummy
		  INTO v_dummy 
		  FROM app_lock 
		 WHERE app_sid = in_app_sid 
		   AND lock_type = in_lock_type
		   	   FOR UPDATE WAIT 1;
		RETURN TRUE;
	EXCEPTION
		WHEN e_resource_busy OR e_wait_timed_out THEN
			RETURN FALSE;
	END;
END;

FUNCTION HasUnmergedScenario(
	in_app_sid						IN	customer.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')	
)
RETURN BOOLEAN
AS
	v_auto_unmerged_scenarios		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_auto_unmerged_scenarios
	  FROM DUAL
	 WHERE EXISTS (SELECT 1
	 				 FROM scenario
	 				WHERE auto_update_run_sid IS NOT NULL
	 				  AND app_sid = in_app_sid);
	RETURN v_auto_unmerged_scenarios != 0;
END;

PROCEDURE GetValueChangeReport(
	in_region_sid			IN	security.security_pkg.T_SID_ID,
	in_user_sid				IN	security.security_pkg.T_SID_ID,
	in_period_start_dtm		IN	DATE,
	in_period_end_dtm		IN	DATE,
	in_merged_start_dtm		IN	DATE,
	in_merged_end_dtm		IN	DATE,
	in_data_source_name		IN	VARCHAR2,
	in_indicator_sid		IN	security.securITY_PKG.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_region_start_points		security.T_SID_TABLE;
BEGIN
	IF in_region_sid IS NULL THEN
		SELECT region_sid
		  BULK COLLECT INTO v_region_start_points
		  FROM region_start_point
		 WHERE app_sid = security.security_pkg.GetApp AND user_sid = security.security_pkg.GetSid;
	ELSE
		SELECT in_region_sid
		  BULK COLLECT INTO v_region_start_points
		  FROM DUAL;
	END IF;

	OPEN out_cur FOR
		WITH merged_val AS (
			SELECT app_sid, region_sid, ind_sid, period_start_dtm, period_end_dtm, source_type_id, source_id,
				   changed_by_sid, changed_dtm, val_number, entry_val_number, entry_measure_conversion_id
			  FROM val
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC)
			   AND (in_user_sid IS NULL OR changed_by_sid = in_user_sid)
			   AND (in_period_end_dtm IS NULL OR period_start_dtm < in_period_end_dtm)
			   AND (in_period_start_dtm IS NULL OR period_end_dtm > in_period_start_dtm)
			   AND (in_merged_start_dtm IS NULL OR changed_dtm >= in_merged_start_dtm)
			   AND (in_merged_end_dtm IS NULL OR changed_dtm < in_merged_end_dtm + 1)
			   AND region_sid IN (
				SELECT NVL(link_to_region_sid, region_sid)
				  FROM region
				 START WITH region_sid IN (SELECT column_value FROM TABLE(v_region_start_points))
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid)
				   AND ind_sid IN (
					SELECT ind_sid
					  FROM ind
					 START WITH ind_sid = in_indicator_sid
				   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid)
		), last_val_change AS (
			SELECT app_sid, region_sid, ind_sid, period_start_dtm, period_end_dtm, source_type_id, source_id,
				   changed_by_sid, changed_dtm, val_number, entry_val_number, entry_measure_conversion_id
			  FROM (    
				SELECT vc.app_sid, vc.region_sid, vc.ind_sid, vc.period_start_dtm, vc.period_end_dtm, vc.source_type_id, vc.source_id,
					   vc.changed_by_sid, vc.changed_dtm, vc.val_number, vc.entry_val_number, vc.entry_measure_conversion_id,
					   ROW_NUMBER() OVER (PARTITION BY vc.region_sid, vc.ind_sid, vc.period_start_dtm, vc.period_end_dtm ORDER BY vc.changed_dtm DESC) rn
				  FROM val_change vc
				  JOIN merged_val mv ON vc.app_sid = mv.app_sid AND vc.region_sid = mv.region_sid AND vc.ind_sid = mv.ind_sid
				   AND vc.period_start_dtm = mv.period_start_dtm AND vc.period_end_dtm = mv.period_end_dtm
			)
			 WHERE rn = 2
		)
		SELECT r.description AS region, i.description AS "indicator",
			   CASE
					WHEN MONTHS_BETWEEN(mv.period_end_dtm, mv.period_start_dtm) = 12 THEN TO_CHAR(mv.period_start_dtm, 'YYYY')
					WHEN MONTHS_BETWEEN(mv.period_end_dtm, mv.period_start_dtm) = 6 THEN
						CASE
							WHEN TO_CHAR(mv.period_start_dtm,'MM') IN ('01','02','03','04','05','06') THEN 'H1 - '|| TO_CHAR(mv.period_start_dtm,'YYYY')
							WHEN TO_CHAR(mv.period_start_dtm,'MM') IN ('07','08','09','10','11','12') THEN 'H2 - '|| TO_CHAR(mv.period_start_dtm,'YYYY')
							ELSE NULL
						END
					WHEN MONTHS_BETWEEN(mv.period_end_dtm, mv.period_start_dtm) = 3 THEN TO_CHAR(mv.period_start_dtm,'"Q"Q-YYYY')
					WHEN MONTHS_BETWEEN(mv.period_end_dtm, mv.period_start_dtm) = 1 THEN TO_CHAR(mv.period_start_dtm, 'MON-YYYY')
					ELSE TO_CHAR(mv.period_start_dtm,'DD-MON-YYYY')
			   END data_period,
			   u.full_name AS merged_by,
			   mv.val_number AS stored_value, m.description stored_unit, mv.entry_val_number entered_value, NVL(mc.description, m.description) entered_unit,
			   st.description AS source_type,
			   mv.changed_dtm AS date_merged,
			   lu.full_name AS last_merged_by,
			   lvc.val_number AS last_stored_value, m.description last_stored_unit, lvc.entry_val_number last_entered_value, NVL(lmc.description, m.description) last_entered_unit,
			   lst.description AS last_source_type,
			   lvc.changed_dtm AS last_date_merged,
			   CASE 
					WHEN mv.source_type_id = 1 THEN d.name 
					WHEN mv.source_type_id = 2 THEN imps.name
					ELSE NULL
			   END AS "DATA_SOURCE_NAME",
			   mv.source_type_id,
			   mv.source_id
		  FROM merged_val mv
		  LEFT JOIN last_val_change lvc ON mv.app_sid = lvc.app_sid AND mv.region_sid = lvc.region_sid AND mv.ind_sid = lvc.ind_sid
		   AND mv.period_start_dtm = lvc.period_start_dtm AND mv.period_end_dtm = lvc.period_end_dtm
		  JOIN csr_user u ON mv.changed_by_sid = u.csr_user_sid
		  LEFT JOIN csr_user lu ON lvc.changed_by_sid = lu.csr_user_sid
		  JOIN v$region r ON mv.region_sid = r.region_sid
		  JOIN v$ind i ON mv.ind_sid = i.ind_sid
		  JOIN source_type st ON mv.source_type_id = st.source_type_id
		  LEFT JOIN source_type lst ON lvc.source_type_id = lst.source_type_id
		  JOIN measure m ON i.measure_sid = m.measure_sid
		  LEFT JOIN measure_conversion mc ON mv.entry_measure_conversion_id = mc.measure_conversion_id
		  LEFT JOIN measure_conversion lmc ON lvc.entry_measure_conversion_id = lmc.measure_conversion_id
		  LEFT JOIN sheet_value sv ON mv.source_id = sv.sheet_value_id
		  LEFT JOIN sheet s ON sv.sheet_id = s.sheet_id
		  LEFT JOIN delegation d ON s.delegation_sid = d.delegation_sid
		  LEFT JOIN imp_val iv ON mv.source_id = iv.imp_val_id
		  LEFT JOIN imp_session imps ON iv.imp_session_sid = imps.imp_session_sid
		 WHERE (in_data_source_name IS NULL OR LOWER(d.name) = LOWER(in_data_source_name) OR LOWER(imps.name) = LOWER(in_data_source_name))
		   AND (m.custom_field IS NULL OR m.custom_field NOT IN ('&', '|'))
		 ORDER BY mv.ind_sid, mv.region_sid, mv.period_start_dtm;
END;

PROCEDURE GetAuditLogForObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE,
	in_audit_type_group_id			IN	audit_type.audit_type_group_id%TYPE,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_start_date					IN	DATE,
	in_end_date						IN	DATE,
	out_total						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security.security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security.security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INSERT INTO temp_audit_log_ids(row_id, audit_dtm)
	SELECT /*+ INDEX (audit_log IDX_AUDIT_LOG_OBJECT_SID) */ ROWID, audit_date
	  FROM audit_log
	 WHERE app_sid = in_app_sid AND object_sid = in_object_sid
	   AND (in_sub_object_id IS NULL OR sub_object_id = in_sub_object_id)	 
	   AND (in_audit_type_group_id IS NULL OR audit_type_id IN (
			SELECT audit_type_id FROM audit_type WHERE audit_type_group_id = in_audit_type_group_id))
	   AND audit_date >= in_start_date AND audit_date < in_end_date; -- for inclusive end date 1 day is added to end date in c#

	SELECT COUNT(row_id)
	  INTO out_total
	  FROM temp_audit_log_ids;

	OPEN out_cur FOR
		SELECT al.audit_date, aut.label, cu2.full_name original_full_name, cu2.user_name original_user_name, cu.user_name, 
			   cu.full_name, al.param_1 first_parameter, al.param_2 second_parameter, al.param_3 third_parameter, 
			   al.description, al.remote_addr
		  FROM (
			SELECT /*+CARDINALITY(100)*/ row_id, rn
			  FROM (
				SELECT row_id, ROWNUM rn
				  FROM (
					SELECT row_id
					  FROM temp_audit_log_ids
					 ORDER BY audit_dtm DESC, row_id DESC
				)
				 WHERE ROWNUM < in_start_row + in_page_size
			)
			 WHERE rn >= in_start_row
		) alr
		  JOIN audit_log al ON al.rowid = alr.row_id 
		  JOIN csr_user cu ON cu.csr_user_sid = al.user_sid
	 LEFT JOIN csr_user cu2 ON cu2.csr_user_sid = al.original_user_sid
		  JOIN audit_type aut ON aut.audit_type_id = al.audit_type_id;
END;

FUNCTION JITNextVal (
	in_seq_name 	IN	varchar2
)
RETURN NUMBER
AS
	v_seq_val		NUMBER(38,0);
BEGIN
	EXECUTE IMMEDIATE 'select '|| in_seq_name|| '.nextval from dual' INTO v_seq_val;
	RETURN v_seq_val;
END;

PROCEDURE GetAutoAnonymisedEnabled(
	out_auto_anonymised_enabled				OUT NUMBER
)
AS
BEGIN
	SELECT auto_anonymisation_enabled
	  INTO out_auto_anonymised_enabled
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAutoAnonymisedInactiveDays(
	out_auto_anonymised_inactive_days		OUT NUMBER
)
AS
BEGIN
	SELECT inactive_days_before_anonymisation
	  INTO out_auto_anonymised_inactive_days
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

END;
/
