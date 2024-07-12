CREATE OR REPLACE PACKAGE BODY SUPPLIER.questionnaire_pkg
IS

PROCEDURE GetQuestionnaireInfo(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_questionnaire_id		IN 	questionnaire.questionnaire_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Security check??
	OPEN out_cur FOR
		SELECT questionnaire_id, class_name, friendly_name, description
		  FROM questionnaire
		 WHERE questionnaire_id = in_questionnaire_id;
END;

PROCEDURE GetQuestionnaireInfo(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_class_name			IN 	questionnaire.class_name%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Security check??
	OPEN out_cur FOR
		SELECT questionnaire_id, class_name, friendly_name, description
		  FROM questionnaire
		 WHERE LOWER(class_name) = LOWER(in_class_name);
END;

PROCEDURE GetProductGroupQuestionnaires(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_group_id					IN	questionnaire_group.group_id%TYPE,
	in_questionnaire_status_id 	IN  product_questionnaire.questionnaire_status_id%TYPE,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT q.questionnaire_id, q.class_name, q.friendly_name, q.description, p.questionnaire_status_id, s.status
		  FROM questionnaire q, product_questionnaire p, questionnaire_status s, questionnaire_group qg, questionnaire_group_membership qgm
		 WHERE q.questionnaire_id = p.questionnaire_id
		   AND qgm.group_id = qg.group_id
		   AND q.questionnaire_id = qgm.questionnaire_id
		   AND p.product_id = in_product_id
		   AND p.questionnaire_status_id = NVL(in_questionnaire_status_id, p.questionnaire_status_id)
		   AND q.active = 1
		   AND qg.group_id = in_group_id
		   AND p.questionnaire_status_id(+) = s.questionnaire_status_id
		 	ORDER BY qgm.pos asc, q.friendly_name;
END;

FUNCTION GetQuestionnaireIdByClass(
	in_class_name				IN  questionnaire.class_name%TYPE
) RETURN NUMBER
AS
	v_questionnaire_id 			NUMBER;
BEGIN
	SELECT questionnaire_id INTO v_questionnaire_id FROM questionnaire
		WHERE class_name = in_class_name;
		
	RETURN  v_questionnaire_id;
END;

PROCEDURE SetQuestionnaireStatus(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_questionnaire_id			IN	product_questionnaire.questionnaire_id%TYPE,
	in_questionnaire_status_id 	IN  product_questionnaire.questionnaire_status_id%TYPE
)
AS
	v_new_status_name				questionnaire_status.status%TYPE;
	v_old_status_name				questionnaire_status.status%TYPE;
	v_questionnaire_name		questionnaire.friendly_name%TYPE;
	v_app_sid 				security_pkg.T_SID_ID;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT status INTO v_old_status_name FROM product_questionnaire pq, questionnaire_status qs
		WHERE pq.questionnaire_status_id = qs.questionnaire_status_id
		AND pq.product_id = in_product_id
		AND pq.questionnaire_id = in_questionnaire_id;
		
	UPDATE all_product_questionnaire 
		SET questionnaire_status_id = in_questionnaire_status_id, 
		    last_saved_by_sid = SYS_CONTEXT('SECURITY','SID'),
			last_saved_dtm = SYSDATE
		WHERE product_id = in_product_id
		AND questionnaire_id = in_questionnaire_id;
		
	-- just for audit info
	SELECT status INTO v_new_status_name FROM questionnaire_status WHERE questionnaire_status_id = in_questionnaire_status_id;
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
	SELECT friendly_name INTO v_questionnaire_name FROM questionnaire WHERE questionnaire_id = in_questionnaire_id;
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_STATE_CHANGED, v_app_sid, v_app_sid, 
		v_questionnaire_name||' - Questionnaire state', v_old_status_name, v_new_status_name, in_product_id);

END;

PROCEDURE SetQuestionnaireStatus(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_class_name				IN	questionnaire.class_name%TYPE,
	in_questionnaire_status_id 	IN  product_questionnaire.questionnaire_status_id%TYPE
)
AS
BEGIN
	
	questionnaire_pkg.SetQuestionnaireStatus(in_act_id, in_product_id, questionnaire_pkg.GetQuestionnaireIdByClass(in_class_name),in_questionnaire_status_id);

END;

PROCEDURE SetQuestStatusesForProdGroup(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_group_id					IN product_questionnaire_group.group_id%TYPE,
	in_questionnaire_status_id 	IN  product_questionnaire.questionnaire_status_id%TYPE
)
AS
	v_status_name				questionnaire_status.status%TYPE;
	v_app_sid 					security_pkg.T_SID_ID;
	v_group_name				questionnaire_group.name%TYPE;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE all_product_questionnaire
		SET questionnaire_status_id = in_questionnaire_status_id
		WHERE product_id = in_product_id
		AND questionnaire_id IN (SELECT questionnaire_id FROM questionnaire_group_membership WHERE group_id = in_group_id);
		
	-- just for audit info
	SELECT status INTO v_status_name FROM questionnaire_status WHERE questionnaire_status_id = in_questionnaire_status_id;
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
	SELECT name INTO v_group_name FROM questionnaire_group WHERE group_id = in_group_id;
		
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_STATE_CHANGED, v_app_sid, v_app_sid, 
		'Questionnaires in group '||v_group_name||' states set to {0}', v_status_name, NULL, NULL, in_product_id);

END;

-- this copies the last revision 
-- ASSUMPTIONS - it currently assumes that the prdoct being copied to (id=in_new_product_id) is a new product
PROCEDURE CopyQsToNewProd(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_old_product_id		IN product.product_id%TYPE,
	in_new_product_id		IN product.product_id%TYPE,
	in_package_name			IN 	questionnaire.class_name%TYPE
)
AS
	v_max_from_revision			product_revision.revision_id%TYPE;
	v_max_to_revision			product_revision.revision_id%TYPE;
	v_q_description				questionnaire.friendly_name%TYPE;
	v_old_product_description	product.description%TYPE;
	v_app_sid					product.app_sid%TYPE;
BEGIN
	
	v_max_from_revision := product_pkg.GetMaxProdRevisionId(in_old_product_id);
	v_max_to_revision := product_pkg.GetMaxProdRevisionId(in_new_product_id);
	
	SELECT friendly_name INTO v_q_description FROM questionnaire WHERE package_name = in_package_name;
	SELECT description, app_sid INTO v_old_product_description, v_app_sid FROM product WHERE product_id = in_old_product_id;
	
    EXECUTE IMMEDIATE 'begin '||in_package_name||'.CopyAnswers(:1,:2,:3,:4,:5);end;'
		USING in_act_id, in_old_product_id, v_max_from_revision, in_new_product_id, v_max_to_revision;
		
	-- set group status to data being entered and questionnaire status to open
	-- as the data has been copied and needs a review for this product.
	UPDATE all_product_questionnaire 
	   SET questionnaire_status_id = QUESTIONNAIRE_OPEN
	 WHERE product_id = in_new_product_id
	   AND questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE package_name = in_package_name);
	   
	UPDATE product_questionnaire_group 
	   SET group_status_id = product_pkg.DATA_BEING_ENTERED, declaration_made_by_sid = null, status_changed_dtm = sysdate
	 WHERE product_id = in_new_product_id
	   AND group_id = (
	       SELECT qg.group_id 
             FROM questionnaire_group_membership qgm, questionnaire_group qg 
            WHERE qg.group_id = qgm.group_id 
              AND questionnaire_id = (SELECT questionnaire_id FROM questionnaire WHERE package_name = in_package_name)
              AND app_sid = (SELECT app_sid FROM product WHERE product_id = in_new_product_id)
           );
  
-- Commented out by RK as it's a dependency on greentick - don't see why - ASK JAMES         
--	audit_pkg.WriteAuditLogEntry(in_act_id, score_log_pkg.AUDIT_TYPE_GT_Q_COPIED, v_app_sid, v_app_sid, 
--		'Questionnaire "{0}" copied from product "{1}"', v_q_description, v_old_product_description, NULL, in_new_product_id);
	
END;

PROCEDURE CopyQsToNewProd(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_old_product_id		IN product.product_id%TYPE,
	in_new_product_id		IN product.product_id%TYPE,
	in_questionnaire_id		IN 	questionnaire.questionnaire_id%TYPE
)
AS
	v_package_name			questionnaire.class_name%TYPE;
BEGIN
	
	SELECT package_name INTO v_package_name FROM questionnaire WHERE questionnaire_id = in_questionnaire_id;
	
	CopyQsToNewProd(in_act_id, in_old_product_id, in_new_product_id, v_package_name);
	
END;

PROCEDURE MapQuestionnaire(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_product_id			IN	all_product.product_id%TYPE
)
AS
	v_app_sid 				security_pkg.T_SID_ID;
	v_questionnaire_names		VARCHAR2(4000);
BEGIN
	-- Based on the product's category tags set the questionnaires it will be linked to
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
		
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
	

	-- for audit 
	SELECT csr.utils_pkg.JoinString
			(cursor(
		        SELECT DISTINCT(q.FRIENDLY_NAME) FROM questionnaire_tag qt, tag t, product_tag pt, questionnaire q
		            WHERE t.tag_id = qt.tag_id
		              AND t.tag_id = pt.tag_id
		              AND q.questionnaire_id = qt.questionnaire_id
		              AND product_id = in_product_id        
		              AND qt.questionnaire_id NOT IN (SELECT questionnaire_id FROM product_questionnaire WHERE product_id = in_product_id)
					  AND mapped = 1 -- only the ones that have positive mapping
	      	)) INTO v_questionnaire_names FROM dual;

	-- add questionnaires that are now needed  and not already present
	
		UPDATE all_product_questionnaire
			SET used = 1, questionnaire_status_id = QUESTIONNAIRE_OPEN -- as effectively new
			WHERE questionnaire_id IN (
				 SELECT DISTINCT questionnaire_id 
				   FROM questionnaire_tag qt, tag t, product_tag pt
				  WHERE t.tag_id = qt.tag_id
			        AND t.tag_id = pt.tag_id
			        AND product_id = in_product_id        
			        --AND qt.questionnaire_id NOT IN (SELECT questionnaire_id FROM product_questionnaire WHERE product_id = in_product_id)
					AND mapped = 1 -- only the ones that have positive mapping
				) 
				AND product_id = in_product_id
				AND used = 0;
    
	IF (SQL%ROWCOUNT) > 0 THEN 
		audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_QUEST_LINKED, v_app_sid, v_app_sid, 
			'Linked questionnaire(s): {0}', v_questionnaire_names, NULL, NULL, in_product_id);	
	END IF;
	



		-- for audit 
	SELECT csr.utils_pkg.JoinString
			(cursor(
			    SELECT DISTINCT (q.friendly_name) from all_product_questionnaire pql, questionnaire q
			        WHERE pql.questionnaire_id = q.questionnaire_id
			        AND q.questionnaire_id NOT IN 
			        (
			            SELECT questionnaire_id 
						FROM (
							SELECT questionnaire_id, COUNT(questionnaire_id), SUM(mapped) 
							  FROM questionnaire_tag qt, tag t, product_tag pt
							 WHERE t.tag_id = qt.tag_id
							   AND t.tag_id = pt.tag_id
							   AND product_id = in_product_id 
							 GROUP BY questionnaire_id
							HAVING COUNT(questionnaire_id) = SUM(mapped)
						)						  
			        )
			        AND product_id = in_product_id
					AND used = 1
	      	)
	     ) INTO v_questionnaire_names FROM dual;
	
	-- set used = 0 for questionnaires that are no longer needed 
	UPDATE all_product_questionnaire
		SET used = 0 
		WHERE questionnaire_id NOT IN 
		(
			SELECT questionnaire_id 
			FROM (
				SELECT questionnaire_id, COUNT(questionnaire_id), SUM(mapped) 
				  FROM questionnaire_tag qt, tag t, product_tag pt
				 WHERE t.tag_id = qt.tag_id
				   AND t.tag_id = pt.tag_id
				   AND product_id = in_product_id 
				 GROUP BY questionnaire_id
				HAVING COUNT(questionnaire_id) = SUM(mapped)
			)
		)
		AND product_id = in_product_id
		AND used = 1;
		
	IF (SQL%ROWCOUNT) > 0 THEN 
		audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_QUEST_UNLINKED, v_app_sid, v_app_sid, 
			'Unlinked questionnaire(s): {0}', v_questionnaire_names, NULL, NULL, in_product_id);
	END IF;
	
	
	-- open any groups that have open questionnaires
	UPDATE product_questionnaire_group
	SET group_status_id = product_pkg.DATA_BEING_ENTERED
	WHERE group_id IN
	(
		SELECT qgm.group_id 
		FROM product_questionnaire_group pqg, questionnaire_group_membership qgm, all_product_questionnaire pql
		WHERE   qgm.group_id = pqg.group_id
		    AND pql.QUESTIONNAIRE_ID = qgm.QUESTIONNAIRE_ID
		    AND pql.PRODUCT_ID = pqg.PRODUCT_ID
		    AND pqg.product_id = in_product_id
		    AND questionnaire_status_id = QUESTIONNAIRE_OPEN
			AND used = 1 -- only consider used questionnaires
	)
	AND product_id = in_product_id;
	
END;


PROCEDURE SetQuestionnaireDueDate(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_product_id			IN	all_product.product_id%TYPE,
	in_questionnaire_id		IN	questionnaire.questionnaire_id%TYPE,
	in_due_date				IN  all_product_questionnaire.due_date%TYPE
)
AS
	v_app_sid 				security_pkg.T_SID_ID;
BEGIN
	-- Based on the product's category tags set the questionnaires it will be linked to
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
		
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
		
	-- if the questionnaire is not in the link table then add it
	INSERT INTO all_product_questionnaire (product_id, questionnaire_id, questionnaire_status_id, used)
		SELECT in_product_id, q.questionnaire_id, questionnaire_open, 0  
		FROM questionnaire_group qg, questionnaire_group_membership qgm, questionnaire q 
		WHERE qg.group_id = qgm.group_id 
		AND qgm.questionnaire_id = q.questionnaire_id
		AND qg.app_sid = v_app_sid
		AND q.questionnaire_id = in_questionnaire_id
		AND q.questionnaire_id NOT IN (SELECT questionnaire_id FROM all_product_questionnaire WHERE product_id = in_product_id);
		
	-- will now exist - so update the date
	UPDATE all_product_questionnaire SET due_date = in_due_date 
	WHERE product_id = in_product_id 
	AND questionnaire_id = in_questionnaire_id;

END;

END questionnaire_pkg;
/
