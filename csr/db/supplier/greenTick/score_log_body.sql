create or replace package body supplier.score_log_pkg
IS

PROCEDURE LogNumValChange (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_description		IN  gt_score_log.description%TYPE,
	in_val_name			IN  gt_score_log.param_1%TYPE,
	in_val_old			IN  NUMBER,
	in_val_new			IN  NUMBER
)
AS
	v_val_old_char		VARCHAR2(256);
	v_val_new_char		VARCHAR2(256);
BEGIN
	IF in_val_old IS NULL OR in_val_old = -1 THEN
		v_val_old_char := 'Not Set';
	ELSE
		v_val_old_char := TO_CHAR(in_val_old);
	END IF;

	IF in_val_new IS NULL OR in_val_new = -1 THEN
		v_val_new_char := 'Not Set';
	ELSE
		v_val_new_char := TO_CHAR(in_val_new);
	END IF;

	LogValChange(in_act_id, in_product_id, in_score_id, in_description, in_val_name, v_val_old_char, v_val_new_char);
END;

PROCEDURE LogYesNoValChange (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_description		IN  gt_score_log.description%TYPE,
	in_val_name			IN  gt_score_log.param_1%TYPE,
	in_val_old			IN  NUMBER,
	in_val_new			IN  NUMBER
)
AS
	v_val_old_char		VARCHAR2(256);
	v_val_new_char		VARCHAR2(256);
BEGIN
	IF in_val_old IS NULL OR in_val_old = -1 THEN
		v_val_old_char := 'Not Set';
	ELSE
		IF in_val_old = 1 THEN
			v_val_old_char := 'Yes';
		ELSE
			v_val_old_char := 'No';
		END IF;
	END IF;

	IF in_val_new IS NULL OR in_val_new = -1 THEN
		v_val_new_char := 'Not Set';
	ELSE
		IF in_val_new = 1 THEN
			v_val_new_char := 'Yes';
		ELSE
			v_val_new_char := 'No';
		END IF;
	END IF;

	LogValChange(in_act_id, in_product_id, in_score_id, in_description, in_val_name, v_val_old_char, v_val_new_char);
END;

PROCEDURE LogSimpleTypeValChange (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_description		IN  gt_score_log.description%TYPE,
	in_val_name			IN  gt_score_log.param_1%TYPE,
	in_val_old			IN  NUMBER,
	in_val_new			IN  NUMBER,
	in_table_name		IN  VARCHAR2,
	in_desc_col_name	IN  VARCHAR2,
	in_id_col_name		IN  VARCHAR2
)
AS
	v_old_desc			VARCHAR2(256);
	v_new_desc			VARCHAR2(256);
BEGIN
	IF in_val_old IS NULL OR in_val_old =- 1 THEN
		v_old_desc := 'Not Set';
	ELSE
		EXECUTE IMMEDIATE
			'SELECT '||in_desc_col_name||' FROM '||in_table_name||' WHERE '||in_id_col_name||' = :id'
				INTO v_old_desc USING in_val_old;
	END IF;

	IF in_val_new IS NULL OR in_val_new = -1 THEN
		v_new_desc := 'Not Set';
	ELSE
		EXECUTE IMMEDIATE
			'SELECT '||in_desc_col_name||' FROM '||in_table_name||' WHERE '||in_id_col_name||' = :id'
				INTO v_new_desc USING in_val_new;
	END IF;

	LogValChange(in_act_id, in_product_id, in_score_id, in_description, in_val_name, v_old_desc, v_new_desc);
END;

PROCEDURE LogValChange (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_description		IN  gt_score_log.description%TYPE,
	in_val_name			IN  gt_score_log.param_1%TYPE,
	in_val_old			IN  gt_score_log.param_2%TYPE,
	in_val_new			IN  gt_score_log.param_3%TYPE
)
AS
	v_val_old_char		gt_score_log.param_2%TYPE;
	v_val_new_char		gt_score_log.param_3%TYPE;
	v_description		gt_score_log.description%TYPE;
BEGIN
	IF in_description IS NULL THEN
		v_description := 'Value "{0}" changed from "{1}" to "{2}"';
	END IF;

	IF in_val_old IS NULL OR in_val_old = '' THEN
		v_val_old_char := 'Not Set';
	ELSE
		v_val_old_char := TO_CHAR(in_val_old);
	END IF;

	IF in_val_new IS NULL OR in_val_new = '' THEN
		v_val_new_char := 'Not Set';
	ELSE
		v_val_new_char := TO_CHAR(in_val_new);
	END IF;

	-- only insert stuff we want to write out
	IF v_val_old_char != v_val_new_char THEN
		INSERT INTO gt_score_log (product_id, gt_score_type_id, description, param_1, param_2, param_3)
			VALUES (in_product_id, in_score_id, v_description, in_val_name, v_val_old_char, v_val_new_char) ;
	END IF;
END;

PROCEDURE WriteToAuditFromScoreLog (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_old_score		IN  gt_scores.score_chemicals%TYPE, -- all the same so chose one
	in_new_score		IN  gt_scores.score_chemicals%TYPE -- all the same so chose one
)
AS
	v_score_change_message		VARCHAR2(256);
	v_score_old_char			VARCHAR2(64);
	v_score_new_char			VARCHAR2(64);
	v_score_desc				gt_score_type.description%TYPE;
	v_message					VARCHAR2(1023);
	v_app_sid					security_pkg.T_SID_ID;
	v_audit_type				csr.audit_log.audit_type_id%TYPE;
BEGIN
	IF in_old_score IS NULL OR in_old_score = -1 THEN
		v_score_old_char := 'Not Set';
	ELSE
		v_score_old_char := TO_CHAR(in_old_score);
	END IF;

	IF in_new_score IS NULL OR in_new_score = -1 THEN
		v_score_new_char := 'Not Set';
	ELSE
		v_score_new_char := TO_CHAR(in_new_score);
	END IF;

	SELECT description
	  INTO v_score_desc
	  FROM gt_score_type
	 WHERE gt_score_type_id = in_score_id;

	SELECT app_sid
	  INTO v_app_sid
	  FROM product
	 WHERE product_id = in_product_id;

	v_audit_type := AUDIT_TYPE_GT_SCORE_SAVED;
	v_score_change_message := '"'||v_score_desc||'" values changed: ';
	-- has the score changed - if so prepend with a note about this - otherwise just log value
	IF v_score_old_char != v_score_new_char THEN
		v_score_change_message := '"'||v_score_desc||'" score changed from "'||v_score_old_char||'" to "'||v_score_new_char||'". Reason: ';
		v_audit_type := AUDIT_TYPE_GT_SCORE_CHANGED;
	END IF;

	FOR r IN
	(
		SELECT product_id, gt_score_type_id, description, param_1, param_2, param_3
		  FROM gt_score_log
		 WHERE product_id = in_product_id
		   AND gt_score_type_id = in_score_id
	)
	LOOP
		IF(LENGTHB(v_score_change_message||r.description) > 1023) THEN
			v_message := SUBSTRB(v_score_change_message||r.description, 1, 1019) || '...';
		ELSE
			v_message := v_score_change_message || r.description;
		END IF;

		csr.csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act_id, v_audit_type, v_app_sid,
			 v_app_sid, in_product_id, v_message, r.param_1, r.param_2, r.param_3);
	END LOOP;

	-- clear the log once written
	ClearLogForProductScore(in_act_id, in_product_id, in_score_id);
END;

PROCEDURE ClearLogForProductScore (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE
)
AS
BEGIN
	DELETE FROM gt_score_log
	 WHERE product_id = in_product_id
	   AND gt_score_type_id = in_score_id;
END;

PROCEDURE WriteToAuditTargetScoreLog (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_product_type_id	IN	gt_product_type.gt_product_type_id%TYPE,
	in_product_range_id	IN	gt_product_answers.gt_product_range_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_old_min_score	IN  gt_target_scores.min_score_chemicals%TYPE,
	in_new_min_score	IN  gt_target_scores.max_score_chemicals%TYPE,
	in_old_max_score	IN  gt_target_scores.min_score_chemicals%TYPE,
	in_new_max_score	IN  gt_target_scores.max_score_chemicals%TYPE
)
AS
	v_score_change_message		VARCHAR2(256);
	v_score_old_min_char		VARCHAR2(64);
	v_score_new_min_char		VARCHAR2(64);
	v_score_old_max_char		VARCHAR2(64);
	v_score_new_max_char		VARCHAR2(64);
	v_score_desc				gt_score_type.description%TYPE;

	v_message					VARCHAR2(1023);
	v_changes					NUMBER(1) := 0;

	v_user_sid					security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	IF in_old_min_score IS NULL OR in_old_min_score = -1 THEN
		v_score_old_min_char := 'Not Set';
	ELSE
		v_score_old_min_char := TO_CHAR(in_old_min_score);
	END IF;

	IF in_old_max_score IS NULL OR in_old_max_score =- 1 THEN
		v_score_old_max_char := 'Not Set';
	ELSE
		v_score_old_max_char := TO_CHAR(in_old_max_score);
	END IF;

	IF in_new_min_score IS NULL OR in_new_min_score = -1 THEN
		v_score_new_min_char := 'Not Set';
	ELSE
		v_score_new_min_char := TO_CHAR(in_new_min_score);
	END IF;

	IF in_new_max_score IS NULL OR in_new_max_score = -1 THEN
		v_score_new_max_char := 'Not Set';
	ELSE
		v_score_new_max_char := TO_CHAR(in_new_max_score);
	END IF;

	SELECT description
	  INTO v_score_desc
	  FROM gt_score_type
	 WHERE gt_score_type_id = in_score_id;

	v_score_change_message := '"'||v_score_desc||'" targets changed: ';

	-- has the score changed - if so prepend with a note about this - otherwise just log value
	IF v_score_old_min_char != v_score_new_min_char THEN
		v_score_change_message := v_score_change_message || 'Min ('|| v_score_old_min_char || ' to ' || v_score_new_min_char || ')';
		v_changes := 1;
	END IF;

	IF v_score_old_max_char != v_score_new_max_char THEN
		v_score_change_message := v_score_change_message || 'Max ('|| v_score_old_max_char || ' to ' || v_score_new_max_char || ')';
		v_changes := 1;
	END IF;

	IF v_changes = 1 THEN
		INSERT INTO gt_target_scores_log (app_sid, user_sid, gt_product_type_id, gt_product_range_id, description, audit_date)
			VALUES (in_app_sid, v_user_sid, in_product_type_id, in_product_range_id, v_score_change_message, sysdate);
	END IF;
END;

PROCEDURE GetScoreAuditLogForProduct (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_product_id		IN	product.product_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT al.audit_date, aut.LABEL, cu.full_name, REPLACE(REPLACE(REPLACE(description, '{0}', param_1), '{1}', param_2),'{2}', param_3) message
		      FROM csr.audit_log al, csr.audit_type aut, csr.csr_user cu
			 WHERE cu.csr_user_sid = al.user_sid
		       AND al.audit_type_id = aut.audit_type_Id
		       AND al.app_sid = in_app_sid
	           AND object_sid = in_app_sid
	       	   AND sub_object_id = in_product_id
	           AND al.audit_type_id IN (AUDIT_TYPE_GT_SCORE_CHANGED, AUDIT_TYPE_GT_SCORE_SAVED)
           )
	 	ORDER BY audit_date, LOWER(message);
END;

PROCEDURE GetScoreAuditLogForTarget (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_product_type_id	IN	gt_product_type.gt_product_type_id%TYPE,
	in_product_range_id	IN	gt_product_answers.gt_product_range_id%TYPE,
	in_start			IN NUMBER,
	in_page_size		IN NUMBER,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT description, full_name, audit_date, total_count
		  FROM (
		  	SELECT ROWNUM rn, x.*
		  	  FROM (
		        SELECT audit_date, full_name, description, COUNT(*) OVER () total_count FROM (
		            SELECT al.audit_date, cu.full_name, description
		              FROM gt_target_scores_log al, csr.csr_user cu
		             WHERE cu.csr_user_sid = al.user_sid
		               AND al.app_sid = in_app_sid
		               AND al.gt_product_type_id = in_product_type_id
		               AND NVL(al.gt_product_range_id, -1) = NVL(in_product_range_id, -1)
		           )
		         ORDER BY audit_date
			  )x
			  WHERE rownum <= NVL(in_page_size + in_start, rownum)
		    )
		    WHERE rn > NVL(in_start, rn)
		 ORDER BY audit_date DESC;
END;

END score_log_pkg;
/

