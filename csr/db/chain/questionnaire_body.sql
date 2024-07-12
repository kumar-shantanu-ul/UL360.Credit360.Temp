CREATE OR REPLACE PACKAGE BODY CHAIN.questionnaire_pkg
IS

/***************************************************************************************
	PRIVATE
***************************************************************************************/
PROCEDURE AddStatusLogEntry (
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE,
	in_status					IN	chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN	qnr_status_log_entry.user_notes%TYPE
)
AS
	v_index							NUMBER(10);
	v_company_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT NVL(MAX(status_log_entry_index), 0) + 1
	  INTO v_index
	  FROM qnr_status_log_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = in_questionnaire_id;

	INSERT INTO qnr_status_log_entry
	(questionnaire_id, status_log_entry_index, questionnaire_status_id, user_notes)
	VALUES
	(in_questionnaire_id, v_index, in_status, in_user_notes);
	
	SELECT company_sid
	  INTO v_company_sid
	  FROM questionnaire
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = in_questionnaire_id;
	
	chain_link_pkg.QuestionnaireStatusChange(v_company_sid, in_questionnaire_id, in_status);
	
END;

PROCEDURE AddShareLogEntry (
	in_qnr_share_id				IN	questionnaire_share.questionnaire_share_id%TYPE,
	in_status					IN	chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN	qnr_share_log_entry.user_notes%TYPE
)
AS
	v_index							NUMBER(10);
	v_questionnaire_id				questionnaire.questionnaire_id%TYPE;
	v_share_with_company_sid		security_pkg.T_SID_ID;
	v_qnr_owner_company_sid			security_pkg.T_SID_ID;
	v_expire_after_months			questionnaire_type.expire_after_months%TYPE;
BEGIN

	--RAISE_APPLICATION_ERROR(-20001, 'AddShareLogEntry' || in_status || dbms_utility.format_error_backtrace);
	
	SELECT qs.questionnaire_id, qs.qnr_owner_company_sid, qs.share_with_company_sid, qt.expire_after_months
	  INTO v_questionnaire_id, v_qnr_owner_company_sid, v_share_with_company_sid, v_expire_after_months
	  FROM questionnaire_share qs
	  JOIN questionnaire q ON qs.app_sid = q.app_sid AND qs.questionnaire_id = q.questionnaire_id
	  JOIN questionnaire_type qt ON q.app_sid = qt.app_sid AND q.questionnaire_type_id = qt.questionnaire_type_id
	 WHERE qs.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND qs.questionnaire_share_id = in_qnr_share_id;
	
	INSERT INTO qnr_share_log_entry
	(questionnaire_share_id, share_log_entry_index, share_status_id, user_notes, company_sid)
	SELECT in_qnr_share_id, NVL(MAX(share_log_entry_index), 0) + 1, in_status, in_user_notes,
		   NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), v_share_with_company_sid)
	  FROM qnr_share_log_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_share_id = in_qnr_share_id;
	
	-- Set expiry on approve
	IF in_status = chain_pkg.SHARED_DATA_ACCEPTED AND v_expire_after_months IS NOT NULL THEN
		UPDATE questionnaire_share
		   SET expiry_dtm = ADD_MONTHS(SYSDATE, v_expire_after_months), expiry_sent_dtm = NULL
		 WHERE questionnaire_share_id = in_qnr_share_id;
	END IF;
	
	chain_link_pkg.QuestionnaireShareStatusChange(v_questionnaire_id, v_share_with_company_sid, v_qnr_owner_company_sid, in_status);
END;

/***************************************************************************************
	PUBLIC
***************************************************************************************/

-- ok
PROCEDURE GetQuestionnaireFilterClass (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT questionnaire_filter_class
		  FROM customer_options
		 WHERE app_sid = security_pkg.GetApp;
END;

-- ok
PROCEDURE GetQuestionnaireGroups (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, group_name, description
		  FROM questionnaire_group
		 WHERE app_sid = security_pkg.GetApp;
END;

FUNCTION GetActiveQuestionnaireTypes 
RETURN security_pkg.T_SID_IDS
AS
	v_qnr_type_ids		security_pkg.T_SID_IDS;
BEGIN
	
	SELECT qt.questionnaire_type_id
	  BULK COLLECT INTO v_qnr_type_ids
	  FROM questionnaire_type qt
	 WHERE qt.app_sid = security_pkg.GetApp
	   AND qt.active = chain_pkg.ACTIVE
	 ORDER BY qt.position;
	 
	 RETURN v_qnr_type_ids;
END;

-- ok
PROCEDURE GetQuestionnaireTypes (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT qt.*, qs.audience
		  FROM questionnaire_type qt
		  LEFT JOIN csr.quick_survey qs
		  ON qs.survey_sid = qt.questionnaire_type_id
		 WHERE qt.app_sid = security_pkg.GetApp
		   AND qt.active = chain_pkg.ACTIVE
		 ORDER BY qt.position, LOWER(qt.name);
END;

-- ok
PROCEDURE GetQuestionnaireType (
	in_qt_class					IN   questionnaire_type.CLASS%TYPE,
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, questionnaire_type_id, view_url, edit_url, owner_can_review, class, name, db_class, group_name, position,
		       active, requires_review, reminder_offset_days, enable_reminder_alert, enable_overdue_alert, security_scheme_id,
		       can_be_overdue, default_overdue_days, procurer_can_review, expire_after_months, auto_resend_on_expiry, is_resendable,
		       enable_status_log, enable_transition_alert
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.GetApp
		   AND LOWER(class) = LOWER(TRIM(in_qt_class));
END;

PROCEDURE GetQuestionnaireTypeFromName (
	in_name						IN  questionnaire_type.name%TYPE,
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, questionnaire_type_id, view_url, edit_url, owner_can_review, class, name, db_class, group_name, position,
		       active, requires_review, reminder_offset_days, enable_reminder_alert, enable_overdue_alert, security_scheme_id,
		       can_be_overdue, default_overdue_days, procurer_can_review, expire_after_months, auto_resend_on_expiry, is_resendable,
		       enable_status_log, enable_transition_alert
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.GetApp
		   AND LOWER(name) = LOWER(TRIM(in_name));
END;

-- ok
FUNCTION GetQuestionnaireTypeId (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
	v_ret			NUMBER;
BEGIN
	SELECT questionnaire_type_id
	  INTO v_ret
	  FROM questionnaire_type
	 WHERE app_sid = security_pkg.GetApp
	   AND LOWER(CLASS) = LOWER(in_qt_class);

	RETURN v_ret;
END;

FUNCTION GetQuestionnaireTypeIdFromName (
	in_name					IN  questionnaire_type.name%TYPE
) RETURN NUMBER
AS
	v_ret			NUMBER;
BEGIN
	SELECT questionnaire_type_id
	  INTO v_ret
	  FROM questionnaire_type
	 WHERE app_sid = security_pkg.GetApp
	   AND LOWER(name) = LOWER(in_name);

	RETURN v_ret;
END;

FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
BEGIN
	RETURN GetQuestionnaireId(in_company_sid, in_qt_class, NULL);
END;

-- ok
FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN	 component.component_id%TYPE
) RETURN NUMBER
AS
	v_q_id						questionnaire.questionnaire_id%TYPE;
BEGIN
	BEGIN
		SELECT questionnaire_id
		  INTO v_q_id
		  FROM questionnaire
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class)
		   AND company_sid = in_company_sid
		   AND (component_id = in_component_id OR component_id IS NULL AND in_component_id IS NULL);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_NOT_FOUND, 'No questionnaire of type '||in_qt_class||' is setup for company with sid '||in_company_sid||' and component with id '||in_component_id);
	END;
	
	RETURN v_q_id;
END;

FUNCTION GetQuestionnaireTypeClass(
	in_survey_sid					IN  security_pkg.T_SID_ID
) RETURN questionnaire_type.class%TYPE
AS
	v_qt_class questionnaire_type.class%TYPE;
BEGIN
	SELECT class
	  INTO v_qt_class
	  FROM chain.questionnaire_type
	 WHERE app_sid = security_pkg.GetApp
	   AND questionnaire_type_id = in_survey_sid;
	
	RETURN v_qt_class;
END;

FUNCTION QnrTypeRequiresReview (
	in_questionnaire_type_id	questionnaire_type.questionnaire_type_id%TYPE
) RETURN NUMBER
AS
	v_requires_review			questionnaire_type.requires_review%TYPE;
BEGIN
	SELECT requires_review
	  INTO v_requires_review
	  FROM questionnaire_type
	 WHERE questionnaire_type_id = in_questionnaire_type_id;
	
	RETURN v_requires_review;
END;

PROCEDURE GetQuestionnaireByQnrId (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	out_cur						OUT security.security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, questionnaire_id, company_sid, component_id, component_description, questionnaire_type_id, created_dtm,
		   view_url, edit_url, owner_can_review, class, name, description, db_class, group_name, position, security_scheme_id, 
		   status_log_entry_index, questionnaire_status_id, questionnaire_status_name, status_update_dtm,
		   enable_status_log, enable_transition_alert, 
		   CASE WHEN questionnaire_status_id IN (chain_pkg.ENTERING_DATA, chain_pkg.REVIEWING_DATA) THEN edit_url ELSE view_url END url
		  FROM v$questionnaire q
		 WHERE app_sid = security.security_pkg.GetApp
		   AND questionnaire_id = in_questionnaire_id;
END;

PROCEDURE GetQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetQuestionnaire(in_company_sid, in_qt_class, NULL, out_cur);
END;

PROCEDURE GetQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id				IN component.component_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_company_sid, in_qt_class, in_component_id);
BEGIN
	-- IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
	IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;
	
	GetQuestionnaireByQnrId(v_questionnaire_id, out_cur);
END;

PROCEDURE GetQuestionnaires (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	out_questionnaires_cur		OUT security_pkg.T_OUTPUT_CUR,	
	out_invitations_cur			OUT security_pkg.T_OUTPUT_CUR	
)
AS
	v_questionnaire_ids			T_NUMERIC_TABLE := T_NUMERIC_TABLE();
BEGIN
	IF NVL(in_owner_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		
		SELECT T_NUMERIC_ROW(questionnaire_id, null)
		  BULK COLLECT INTO v_questionnaire_ids
		  FROM questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		
	ELSE
		
		SELECT T_NUMERIC_ROW(questionnaire_id, null)
		  BULK COLLECT INTO v_questionnaire_ids
		  FROM v$questionnaire_share
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND qnr_owner_company_sid = in_owner_company_sid
		   AND share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		
	END IF;
	
	OPEN out_questionnaires_cur FOR
		SELECT app_sid, questionnaire_id, company_sid, component_id, component_description, questionnaire_type_id, created_dtm,
		   view_url, edit_url, owner_can_review, class, name, description, db_class, group_name, position, security_scheme_id, 
		   status_log_entry_index, questionnaire_status_id, questionnaire_status_name, status_update_dtm,
		   CASE WHEN questionnaire_status_id IN (chain_pkg.ENTERING_DATA, chain_pkg.REVIEWING_DATA) THEN edit_url ELSE view_url END url
		  FROM v$questionnaire
		 WHERE app_sid = security_pkg.GetApp 
		   AND questionnaire_id IN (SELECT item FROM TABLE(v_questionnaire_ids));
	
	OPEN out_invitations_cur FOR
		SELECT i.from_company_sid, fc.name from_company_name, i.from_user_sid, fu.full_name from_user_name, 
		       i.to_company_sid, tc.name to_company_name, i.to_user_sid, tu.full_name to_user_name, 
			   i.sent_dtm, i.expiration_dtm, i.invitation_status_id, qi.questionnaire_id
		  FROM questionnaire_invitation qi, invitation i, v$company fc, csr.csr_user fu, v$company tc, csr.csr_user tu
		 WHERE qi.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND qi.app_sid = i.app_sid
		   AND qi.app_sid = fc.app_sid
		   AND qi.app_sid = fu.app_sid
		   AND qi.app_sid = tc.app_sid
		   AND qi.app_sid = tu.app_sid
		   AND qi.questionnaire_id IN (SELECT item FROM TABLE(v_questionnaire_ids))
		   AND qi.invitation_id = i.invitation_id
		   AND i.from_company_sid = fc.company_sid
		   AND i.to_company_sid = tc.company_sid
		   AND i.from_user_sid = fu.csr_user_sid
		   AND i.to_user_sid = tu.csr_user_sid
		   AND (i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') OR i.to_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		 ORDER BY qi.added_dtm;
	
END;

FUNCTION InitializeQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
BEGIN
	RETURN InitializeQuestionnaire(in_company_sid, in_qt_class, NULL);
END;

FUNCTION InitializeQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
) RETURN NUMBER
AS
	v_q_id						questionnaire.questionnaire_id%TYPE;
BEGIN
	IF QuestionnaireExists(in_company_sid, in_qt_class, in_component_id) THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_ALREADY_EXISTS, 'A questionnaire of class '||in_qt_class||' already exists for company with sid '||in_company_sid||' and component with id '||in_component_id);
	END IF;
	
	INSERT INTO questionnaire
	(questionnaire_id, company_sid, questionnaire_type_id, created_dtm, component_id)
	VALUES
	(questionnaire_id_seq.nextval, in_company_sid, GetQuestionnaireTypeId(in_qt_class), SYSDATE, in_component_id)
	RETURNING questionnaire_id INTO v_q_id;
	
	AddStatusLogEntry(v_q_id, chain_pkg.ENTERING_DATA, NULL);
	
	RETURN v_q_id;	
END;

PROCEDURE SendQuestionnaire (
	in_questionnaire_type_class		IN	questionnaire_type.class%TYPE,
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_requested_due_dtm			IN	questionnaire_share.due_by_dtm%TYPE
)
AS
BEGIN
	SendQuestionnaire(in_questionnaire_type_class, in_to_company_sid, in_from_company_sid, in_requested_due_dtm, NULL);
END;

PROCEDURE SendQuestionnaire (
	in_questionnaire_type_class		IN	questionnaire_type.class%TYPE,
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_requested_due_dtm			IN	questionnaire_share.due_by_dtm%TYPE,
	in_component_id					IN component.component_id%TYPE
)
AS
	v_questionnaire_id		questionnaire.questionnaire_id%TYPE;
	v_share_started			BOOLEAN := FALSE;
BEGIN
	BEGIN
		v_questionnaire_id := InitializeQuestionnaire(in_to_company_sid, in_questionnaire_type_class, in_component_id);
	EXCEPTION
		WHEN chain_pkg.QNR_ALREADY_EXISTS THEN
			v_questionnaire_id := GetQuestionnaireId(in_to_company_sid, in_questionnaire_type_class, in_component_id);
	END;
	
	BEGIN
		StartShareQuestionnaire(in_to_company_sid, v_questionnaire_id, in_from_company_sid, in_requested_due_dtm);	
		v_share_started := TRUE;
	EXCEPTION
		WHEN chain_pkg.QNR_ALREADY_SHARED THEN
			v_share_started := FALSE;
	END;

	IF v_share_started THEN
			
		message_pkg.TriggerMessage (
			in_primary_lookup           => CASE WHEN in_component_id IS NULL THEN chain_pkg.COMPLETE_QUESTIONNAIRE ELSE chain_pkg.COMP_COMPLETE_QUESTIONNAIRE END,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid           => in_to_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => in_from_company_sid,
			in_re_questionnaire_type_id => GetQuestionnaireTypeId(in_questionnaire_type_class),
			in_due_dtm					=> in_requested_due_dtm,
			in_re_component_id		=> in_component_id
		);
		
		chain_link_pkg.QuestionnaireAdded(in_from_company_sid, in_to_company_sid, NULL, v_questionnaire_id);
	END IF;
END;

PROCEDURE StartShareQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID,
	in_due_by_dtm				IN  questionnaire_share.DUE_BY_DTM%TYPE
)
AS
	v_qnr_share_id				questionnaire_share.questionnaire_share_id%TYPE;
	v_count						NUMBER(10);
BEGIN
	
	IF NOT company_pkg.IsSupplier(in_share_with_company_sid, in_company_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - company with sid '||in_company_sid||' is not a supplier to company with sid '||in_share_with_company_sid);
	END IF;	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM questionnaire
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = in_questionnaire_id
	   AND company_sid = in_company_sid;
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - company with sid '||in_company_sid||' does not own the questionnaire with id '||in_questionnaire_id);
	END IF;	
	
	BEGIN
		INSERT INTO questionnaire_share
		(questionnaire_share_id, questionnaire_id, qnr_owner_company_sid, share_with_company_sid, due_by_dtm)
		VALUES
		(questionnaire_share_id_seq.nextval, in_questionnaire_id, in_company_sid, in_share_with_company_sid, in_due_by_dtm)
		RETURNING questionnaire_share_id INTO v_qnr_share_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_ALREADY_SHARED, 'The questionnaire with id '||in_questionnaire_id||' is already shared from company with sid '||in_company_sid||' to company with sid '||in_share_with_company_sid);
	END;
	
	AddShareLogEntry(v_qnr_share_id, chain_pkg.NOT_SHARED, NULL);
END;

FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN
AS
BEGIN
	RETURN QuestionnaireExists(in_company_sid, in_qt_class, NULL);
END;

FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE;
BEGIN
	BEGIN
		v_questionnaire_id := GetQuestionnaireId(in_company_sid, in_qt_class, in_component_id);
	EXCEPTION
		WHEN chain_pkg.QNR_NOT_FOUND THEN
			RETURN FALSE;
	END;
	
	RETURN TRUE;
END;

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_exists					OUT NUMBER
)
AS
BEGIN
	QuestionnaireExists(in_company_sid, in_qt_class, NULL, out_exists);
END;

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE,
	out_exists					OUT NUMBER
)
AS
BEGIN
	out_exists := 0;
	
	IF QuestionnaireExists(in_company_sid, in_qt_class, in_component_id) THEN
		out_exists := 1;
	END IF;
END;

FUNCTION QuestionnaireTypeIsActive (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN
AS
	v_active NUMBER(1, 0);
BEGIN
	SELECT active
	  INTO v_active
	  FROM questionnaire_type
	 WHERE class = in_qt_class;
	  
	RETURN v_active = 1;
END;

PROCEDURE GetQuestionnaireShareWith (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_component_id				IN component.component_id%TYPE,	
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
	IF NOT questionnaire_security_pkg.CheckPermission(in_questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT qs.share_with_company_sid, qs.share_status_id share_status, swc.name share_with_company_name
		  FROM v$questionnaire_share qs
		  JOIN company swc
		    ON qs.share_with_company_sid = swc.company_sid
		   AND qs.app_sid = swc.app_sid
		 WHERE qs.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND qs.questionnaire_id = in_questionnaire_id
		   AND qs.qnr_owner_company_sid = in_company_sid
		   AND ((qs.component_id = in_component_id) OR qs.component_id IS NULL AND in_component_id IS NULL)
		 ORDER BY qs.questionnaire_share_id;
END;

FUNCTION GetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_QUESTIONNAIRE_STATUS
AS
BEGIN
	RETURN GetQuestionnaireStatus(in_company_sid, in_qt_class, NULL);
END;

FUNCTION GetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
) RETURN chain_pkg.T_QUESTIONNAIRE_STATUS
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_company_sid, in_qt_class, in_component_id);
	v_q_status_id				chain_pkg.T_QUESTIONNAIRE_STATUS;
BEGIN
	-- IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
	IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;
	
	SELECT questionnaire_status_id
	  INTO v_q_status_id
	  FROM v$questionnaire
	 WHERE app_sid = security_pkg.GetApp
	   AND questionnaire_id = v_questionnaire_id;

	RETURN v_q_status_id;
END;

PROCEDURE GetQuestionnaireShareStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetQuestionnaireShareStatus(in_company_sid, in_qt_class, NULL, out_cur);
END;

PROCEDURE GetQuestionnaireShareStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE,	
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_company_sid, in_qt_class, in_component_id);
BEGIN
	-- IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
	IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT share_with_company_sid, share_status_id
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
	       AND questionnaire_id = GetQuestionnaireId(in_company_sid, in_qt_class, in_component_id);
END;

FUNCTION GetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_SHARE_STATUS
AS
BEGIN
	RETURN GetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, NULL);
END;

FUNCTION GetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
) RETURN chain_pkg.T_SHARE_STATUS
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id);
	v_s_status_id				chain_pkg.T_SHARE_STATUS;
BEGIN
	-- IF NOT capability_pkg.CheckCapability(in_qnr_owner_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
	IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_qnr_owner_company_sid);
	END IF;

	v_s_status_id := UNSEC_GetQnnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_component_id);
	RETURN v_s_status_id;
END;

FUNCTION UNSEC_GetQnnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
) RETURN chain_pkg.T_SHARE_STATUS
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id);
	v_s_status_id				chain_pkg.T_SHARE_STATUS;
BEGIN
	BEGIN
		SELECT share_status_id
		  INTO v_s_status_id
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id)
		   AND share_with_company_sid = in_share_with_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a questionanire share status between OWNER: '||in_qnr_owner_company_sid||' SHARE WITH:'||in_share_with_company_sid||' of CLASS:"'||in_qt_class||'" COMPONENT:'||in_component_id);
	END;
	
	RETURN v_s_status_id;
END;

PROCEDURE SetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_status_id				IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
)
AS
BEGIN
	SetQuestionnaireStatus(in_company_sid, in_qt_class, in_q_status_id, in_user_notes, NULL);
END;

PROCEDURE SetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_status_id				IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE,
	in_component_id			IN component.component_id%TYPE	
)
AS
	v_current_status			chain_pkg.T_QUESTIONNAIRE_STATUS DEFAULT GetQuestionnaireStatus(in_company_sid, in_qt_class, in_component_id);
	v_owner_can_review			questionnaire_type.owner_can_review%TYPE;
	v_count						NUMBER(10);
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_company_sid, in_qt_class, in_component_id);
BEGIN
	-- validate the incoming state
	IF in_q_status_id NOT IN (
		chain_pkg.ENTERING_DATA, 
		chain_pkg.REVIEWING_DATA, 
		chain_pkg.READY_TO_SHARE
	) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unexpected questionnaire state "'||in_q_status_id||'"');
	END IF;
	
	-- we're not changing status - get out
	IF v_current_status = in_q_status_id THEN
		RETURN;
	END IF;
	
	CASE
	WHEN v_current_status = chain_pkg.ENTERING_DATA THEN
		CASE
		WHEN in_q_status_id = chain_pkg.REVIEWING_DATA THEN
			-- I suppose anyone can make this status change
			NULL;
		WHEN in_q_status_id = chain_pkg.READY_TO_SHARE THEN
			-- force the call to reviewing data for logging purposes
			SetQuestionnaireStatus(in_company_sid, in_qt_class, chain_pkg.REVIEWING_DATA, 'Automatic progression', in_component_id);
			v_current_status := chain_pkg.REVIEWING_DATA;
		END CASE;
	
	WHEN v_current_status = chain_pkg.REVIEWING_DATA THEN
		CASE
		WHEN in_q_status_id = chain_pkg.ENTERING_DATA THEN
			-- it's going back down, that's fine
			NULL;
		WHEN in_q_status_id = chain_pkg.READY_TO_SHARE THEN
			-- IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.SUBMIT_QUESTIONNAIRE)  THEN
			IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_SUBMIT) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sharing questionnaire for company with sid '||in_company_sid);
			END IF;
		END CASE;
	
	WHEN v_current_status = chain_pkg.READY_TO_SHARE THEN
		
		-- we're trying to downgrade the status, so let's see if the questionnaire has been returned/resent or if the owner can review
		
		SELECT count(*)
		  INTO v_count
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND qnr_owner_company_sid = in_company_sid
		   AND ((component_id = in_component_id) OR component_id IS NULL AND in_component_id IS NULL)
		   AND share_status_id IN (chain_pkg.SHARED_DATA_RETURNED, chain_pkg.SHARED_DATA_RESENT);
		
		IF v_count = 0 THEN
			SELECT owner_can_review
			  INTO v_owner_can_review
			  FROM questionnaire_type
			 WHERE app_sid = security_pkg.GetApp
			   AND questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class);
			--TODO: not entirely correct. We need to check who tries to change the status (purchaser, supplier) and use the relevant qt flag
			IF v_owner_can_review = chain_pkg.INACTIVE THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied re-editting questionnaire for company with sid '||in_company_sid);
			END IF;
		END IF;
	END CASE;
	
	AddStatusLogEntry(GetQuestionnaireId(in_company_sid, in_qt_class, in_component_id), in_q_status_id, in_user_notes);
END;

PROCEDURE SetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_q_share_id, in_user_notes, NULL);
END;

PROCEDURE ValidateIncomingState(
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS
)
AS
BEGIN
	-- validate the incoming state
	IF in_q_share_id NOT IN (
		chain_pkg.NOT_SHARED, 
		chain_pkg.SHARING_DATA, 
		chain_pkg.SHARED_DATA_RETURNED,
		chain_pkg.SHARED_DATA_ACCEPTED,
		chain_pkg.SHARED_DATA_REJECTED,
		chain_pkg.SHARED_DATA_RESENT
	) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unexpected questionnaire share state "'||in_q_share_id||'"');
	END IF;
END;

FUNCTION GetQnrShareId(
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN questionnaire.questionnaire_id%TYPE
) RETURN questionnaire_share.questionnaire_share_id%TYPE
AS
	v_qnr_share_id 		questionnaire_share.questionnaire_share_id%TYPE;
BEGIN
	SELECT questionnaire_share_id
	  INTO v_qnr_share_id
	  FROM questionnaire_share
	 WHERE app_sid = security_pkg.GetApp
	   AND qnr_owner_company_sid = in_qnr_owner_company_sid
	   AND share_with_company_sid = in_share_with_company_sid
	   AND questionnaire_id = in_questionnaire_id;
	   
	RETURN v_qnr_share_id;
END;

PROCEDURE SetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE,
	in_component_id				IN component.component_id%TYPE
)
AS
	v_qnr_share_id 				questionnaire_share.questionnaire_share_id%TYPE;
	v_is_owner					BOOLEAN DEFAULT in_qnr_owner_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY');
	v_is_purchaser				BOOLEAN DEFAULT company_pkg.IsPurchaser(SYS_CONTEXT('SECURITY','CHAIN_COMPANY'), in_qnr_owner_company_sid);
	v_count						NUMBER(10);
	v_current_status			chain_pkg.T_SHARE_STATUS DEFAULT GetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_component_id);
	
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id);
	v_qnr_type_id				questionnaire_type.questionnaire_type_id%TYPE := questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class);
BEGIN
	IF NOT v_is_owner AND NOT v_is_purchaser THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of a questionnaire where you are neither the owner or a Purchaser');
	END IF;
	
	ValidateIncomingState(in_q_share_id);

	-- nothing's changed - get out
	IF v_current_status = in_q_share_id THEN
		RETURN;
	END IF;
	
	--TODO: this needs a bit of tidying-up to make it more readable. We can re-write it by validating the incoming action by checking permissions + acceptable current states
	
	-- we can only set certain states depending on who we are
	-- if we are the owner, we can only modify the questionnaire share from a not shared or sharing data retured state
	IF security_pkg.IsAdmin(SYS_CONTEXT('SECURITY','ACT')) THEN
		NULL; -- no need for these security checks if we're the built-in admin
	ELSIF v_is_owner AND v_current_status NOT IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED, chain_pkg.SHARED_DATA_RESENT) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of your questionnaire when it is not in the NOT SHARED, SHARED DATA RETURNED, SHARED DATA RESENT states');
	-- if we are the Purchaser, we can only modify from the other states.
	ELSIF v_is_purchaser AND v_current_status NOT IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED) THEN
		-- allow purchaser setting the questionnaire status when current status is chain_pkg.NOT_SHARED, RETURNED and he has submit permission
		--OR allow them rejecting the questionnaire if they have the reject permission
		IF NOT ((in_q_share_id = chain_pkg.SHARING_DATA AND v_current_status IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED, chain_pkg.SHARED_DATA_RESENT) AND questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_SUBMIT))
			OR (in_q_share_id = chain_pkg.SHARED_DATA_REJECTED AND questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_REJECT))) THEN 
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of a supplier''s questionnaire.' || in_qnr_owner_company_sid || '/' || in_share_with_company_sid || '/' || in_qt_class || '/' || in_q_share_id || '/' || v_current_status);
		END IF;
	END IF;			
		
		
	IF in_q_share_id = chain_pkg.SHARED_DATA_REJECTED THEN
		IF v_current_status = chain_pkg.SHARED_DATA_ACCEPTED THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied rejecting approved questionnaire with id:'||v_questionnaire_id||' owned by company with sid:'||in_qnr_owner_company_sid||' and shared with company with sid:'||in_share_with_company_sid);
		ELSE
			IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_REJECT) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied rejecting questionnaire with id:'||v_questionnaire_id||' owned by company with sid:'||in_qnr_owner_company_sid||' and shared with company with sid:'||in_share_with_company_sid);
			END IF;

			UPDATE questionnaire
			   SET rejected = 1
			 WHERE questionnaire_id = v_questionnaire_id;
		 			
		END IF;
	ELSE		
		CASE 	
		-- if the current status is not shared or shared data retured, we can only go to a sharing data state
		WHEN v_current_status IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED, chain_pkg.SHARED_DATA_RESENT) THEN
			CASE
			WHEN in_q_share_id = chain_pkg.SHARING_DATA THEN
				-- IF NOT capability_pkg.CheckCapability(chain_pkg.SUBMIT_QUESTIONNAIRE)  THEN
				IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_SUBMIT) THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sharing questionnaire for your company ('||in_qnr_owner_company_sid||')');
				END IF;		
			ELSE
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied progressing questionnaires from NOT SHARED or SHARED DATA RETURNED to any state other than SHARING DATA');
			END CASE;

		-- if the current status is in any other sharing state, we can move to returned, accepted or rejected states
		WHEN v_current_status IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED) THEN
			CASE
			WHEN in_q_share_id IN (
				chain_pkg.SHARING_DATA, 
				chain_pkg.SHARED_DATA_RETURNED, 
				chain_pkg.SHARED_DATA_ACCEPTED, 
				chain_pkg.SHARED_DATA_RESENT
			) THEN			
				IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_APPROVE) THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied approving questionnaires for your suppliers');
				END IF;
			ELSE
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied progressing questionnaires from SHARING_DATA, SHARED_DATA_ACCEPTED or SHARED_DATA_REJECTED to states other than SHARING_DATA, SHARED_DATA_RETURNED, SHARED_DATA_ACCEPTED, SHARED_DATA_RESENT or SHARED_DATA_REJECTED');
			END CASE;
		END CASE;
	END IF;
	
	-- if we get here, we're good to go!
	v_qnr_share_id := GetQnrShareId(in_qnr_owner_company_sid, in_share_with_company_sid, v_questionnaire_id);
	
	AddShareLogEntry(v_qnr_share_id, in_q_share_id, in_user_notes);
	
	/*if it's being shared, check for auto-approve
		note: there are cases the auto-approve is handled in the link_pkg triggered by AddShareLogEntry, even when requires_review=1 (eg: mns)*/
	v_current_status := GetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_component_id);
	IF QnrTypeRequiresReview(v_qnr_type_id) = 0 AND in_q_share_id = chain_pkg.SHARING_DATA AND v_current_status != chain_pkg.SHARED_DATA_ACCEPTED THEN
		AddShareLogEntry(v_qnr_share_id, chain.chain_pkg.SHARED_DATA_ACCEPTED, 'Auto-approved');
	END IF;

END;

PROCEDURE UNSEC_SetQnrShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
)
AS
BEGIN
	UNSEC_SetQnrShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_q_share_id, in_user_notes, NULL);
END;

PROCEDURE UNSEC_SetQnrShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE,
	in_component_id			IN component.component_id%TYPE
)
AS
	v_qnr_share_id 				questionnaire_share.questionnaire_share_id%TYPE;
	v_current_status			chain_pkg.T_SHARE_STATUS; -- DEFAULT GetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_component_id);
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id);
	v_qnr_type_id				questionnaire_type.questionnaire_type_id%TYPE := questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class);
BEGIN
	
	ValidateIncomingState(in_q_share_id);

	-- can't use v$questionnaire_share because it filters out shares that don't involve
	-- the logged on company sid. Since we're in an unsec_ block we can assume a link
	-- package is calling and doesn't require this restriction.
	BEGIN
		SELECT qsl.share_status_id
		  INTO v_current_status
		  FROM questionnaire_share qs
		  JOIN qnr_share_log_entry qsl ON qs.questionnaire_share_id = qsl.questionnaire_share_id AND qs.app_sid = qsl.app_sid
		 WHERE qs.app_sid = security_pkg.GetApp
		   AND qs.questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id)
		   AND qs.share_with_company_sid = in_share_with_company_sid
		   AND (qsl.app_sid, qsl.questionnaire_share_id, qsl.share_log_entry_index) IN (   
	   			SELECT app_sid, questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 GROUP BY app_sid, questionnaire_share_id
			);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a questionanire share status between OWNER: '||in_qnr_owner_company_sid||' SHARE WITH:'||in_share_with_company_sid||' of CLASS:"'||in_qt_class||'" COMPONENT:'||in_component_id);
	END;

	-- nothing's changed - get out
	IF v_current_status = in_q_share_id THEN
		RETURN;
	END IF;

	-- if we get here, we're good to go!
	v_qnr_share_id := GetQnrShareId(in_qnr_owner_company_sid, in_share_with_company_sid, v_questionnaire_id);

	AddShareLogEntry(v_qnr_share_id, in_q_share_id, in_user_notes);
END;

PROCEDURE UNSEC_ReactivateQuestionnaire (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
)
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id);
	v_share_status				chain_pkg.T_SHARE_STATUS DEFAULT UNSEC_GetQnnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_component_id);
	v_reactivated_share_status_id	chain_pkg.T_SHARE_STATUS;
BEGIN
	IF v_share_status <> chain_pkg.SHARED_DATA_REJECTED THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot reactivate a not rejected questionnaire. Qnr_owner_company_sid:'
		||in_qnr_owner_company_sid||', in_share_with_company_sid:'||in_share_with_company_sid||', in_qt_class:'||in_qt_class|| ', component_id:'||in_component_id); 
	END IF;
	
	--find last state before qnr was rejected
	SELECT x.share_status_id
	  INTO v_reactivated_share_status_id
	  FROM questionnaire_share qs
	  JOIN (
		SELECT questionnaire_share_id, share_status_id, ROW_NUMBER() OVER (PARTITION BY questionnaire_share_id ORDER BY share_log_entry_index DESC) rn
		  FROM chain.qnr_share_log_entry
	  )x ON x.questionnaire_share_id = qs.questionnaire_share_id
	 WHERE qs.questionnaire_id = v_questionnaire_id
	   AND qs.share_with_company_sid = in_share_with_company_sid
	   AND qs.qnr_owner_company_sid = in_qnr_owner_company_sid
	   AND x.rn = 2; --second to last state
	
	UPDATE chain.questionnaire
	   SET rejected = 0
	 WHERE questionnaire_id = v_questionnaire_id;
	 
	UNSEC_SetQnrShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, v_reactivated_share_status_id, 'Questionnaire re-activated from rejected state', in_component_id);
END;

FUNCTION CanEditQuestionnaire(
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE
)
RETURN BOOLEAN
AS
	v_q_status_id	chain_pkg.T_QUESTIONNAIRE_STATUS;
BEGIN

	SELECT x.questionnaire_status_id
	  INTO v_q_status_id
	  FROM (
		SELECT questionnaire_status_id, ROW_NUMBER() OVER (ORDER BY status_log_entry_index DESC) rn
		  FROM qnr_status_log_entry
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_id = in_questionnaire_id
	   )x
	 WHERE x.rn = 1; 
	
	RETURN NVL(v_q_status_id = chain_pkg.ENTERING_DATA AND questionnaire_security_pkg.CheckPermission(in_questionnaire_id, chain_pkg.QUESTIONNAIRE_EDIT), FALSE);
END;

FUNCTION GetPermEditableQrTypes
RETURN security_pkg.T_SID_IDS
AS
	v_questionnaire_type_ids	security_pkg.T_SID_IDS;
BEGIN
	SELECT questionnaire_type_id
	  BULK COLLECT INTO v_questionnaire_type_ids
	  FROM questionnaire_type qt
	 WHERE qt.security_scheme_id IS NOT NULL
	   AND EXISTS(
		SELECT 1
		  FROM v$qnr_action_security_mask qasm
		 WHERE qasm.app_sid = security_pkg.GetApp
		   AND qasm.questionnaire_type_id = qt.questionnaire_type_id
		   AND qasm.user_check = 1
	); 
	
	RETURN v_questionnaire_type_ids;
END;

PROCEDURE ValidateSortOptions(
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2
)
AS
BEGIN
	--to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN (
		-- add support as needed
		'name', 
		'questionnaire_status_name', 
		'status_update_dtm'
	) THEN 
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by "'||in_sort_by||'".');
	END IF;
END;

PROCEDURE GetQManagementData (
	in_company_sids		security_pkg.T_SID_IDS, /* holds sids of questionnaire owner companies */
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_sort				VARCHAR2(100) DEFAULT CASE WHEN in_sort_by ='name' THEN 'name '|| in_sort_dir||', component_description '||in_sort_dir ELSE in_sort_by||' '||in_sort_dir END;
	v_qnr_type_table	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(GetActiveQuestionnaireTypes);
	v_company_sid_table	security.T_SID_TABLE := security.T_SID_TABLE();
	v_editable_qnr_sid_table	security.T_SID_TABLE := security.T_SID_TABLE();
	v_q_status_id		chain_pkg.T_QUESTIONNAIRE_STATUS;
	v_share_status_desc_table   T_VARCHAR_TABLE DEFAULT chain_link_pkg.GetAlterShareStatusDescr;
	v_total_rows				NUMBER;
	v_has_audit_qnr_cap	NUMBER := 0;
	v_search_for_all_companies  NUMBER(1) := 0;
BEGIN
	-- to prevent any injection
	ValidateSortOptions(in_sort_by, in_sort_dir);

	DELETE FROM tt_questionnaire_organizer;
	
	IF in_company_sids.COUNT = 1 AND in_company_sids(1) = -1 THEN
		OPEN out_cur FOR
			SELECT *
			  FROM dual
			 WHERE 0 = 1;
		RETURN;
	END IF;
	
	IF in_company_sids IS NULL OR in_company_sids.COUNT = 0 OR in_company_sids(1) IS NULL THEN
		v_search_for_all_companies := 1;
		
		--If the array is empty, search for all questionnaires that the context company has been shared with
		INSERT INTO tt_questionnaire_organizer 
		(questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm, due_by_dtm, name, component_description, company_sid,
			questionnaire_type_id)
		SELECT questionnaire_id, share_status_id, NVL(ssd.item, share_status_name), qs.status_entry_dtm, due_by_dtm, qt.name, cmp.description, qs.qnr_owner_company_sid,
			qt.questionnaire_type_id
		  FROM v$questionnaire_share qs
		  JOIN TABLE(v_qnr_type_table) t ON qs.questionnaire_type_id = t.column_value
		  JOIN questionnaire_type qt ON t.column_value = qt.questionnaire_type_id
		  LEFT JOIN TABLE(v_share_status_desc_table) ssd ON qs.share_status_id = ssd.pos
		  LEFT JOIN component cmp ON qs.component_id = cmp.component_id
		 WHERE qs.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND qs.questionnaire_rejected = 0;
		   
	ELSIF in_company_sids(1) = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		
		SELECT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  BULK COLLECT INTO v_company_sid_table
		  FROM dual;
		
		-- questionnaires that belong to my company
		INSERT INTO tt_questionnaire_organizer 
		(questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm, name, component_description, company_sid, questionnaire_type_id)
		SELECT q.questionnaire_id, q.questionnaire_status_id, q.questionnaire_status_name, q.status_update_dtm, q.name, cmp.description, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
			q.questionnaire_type_id
		  FROM v$questionnaire q
		  JOIN TABLE(v_qnr_type_table) t ON q.questionnaire_type_id = t.column_value
		  LEFT JOIN component cmp ON q.component_id = cmp.component_id
		 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND q.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND q.rejected = 0;
		   
	ELSE
		v_company_sid_table := security_pkg.SidArrayToTable(in_company_sids);
		--search for supplier questionnaires that the context company has been shared with
		INSERT INTO tt_questionnaire_organizer 
		(questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm, due_by_dtm, name, component_description, company_sid,
			questionnaire_type_id)
		SELECT questionnaire_id, share_status_id, NVL(ssd.item, share_status_name), status_entry_dtm, due_by_dtm, qt.name, cmp.description, qs.qnr_owner_company_sid,
			qt.questionnaire_type_id
		  FROM v$questionnaire_share qs
		  JOIN TABLE(v_qnr_type_table) t ON qs.questionnaire_type_id = t.column_value
		  JOIN questionnaire_type qt ON t.column_value = qt.questionnaire_type_id
		  JOIN TABLE(v_company_sid_table) tt ON qs.qnr_owner_company_sid = tt.column_value 
		  LEFT JOIN TABLE(v_share_status_desc_table) ssd ON qs.share_status_id = ssd.pos
		  LEFT JOIN component cmp ON qs.component_id = cmp.component_id
		 WHERE qs.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND qs.questionnaire_rejected = 0;
		
		-- Check if we can audit their responses (only if there's only one supplier)
		IF in_company_sids.COUNT = 1 AND type_capability_pkg.CheckCapability(in_company_sids(1), chain_pkg.AUDIT_QUESTIONNAIRE_RESPONSES) THEN
			v_has_audit_qnr_cap := 1;
		END IF;
		
	END IF;
		
	FOR r IN (
		SELECT DISTINCT questionnaire_id 
		  FROM tt_questionnaire_organizer
	) 
	LOOP
		-- todo: This is an expensive call
		IF NOT questionnaire_security_pkg.CheckPermission(r.questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
			DELETE FROM tt_questionnaire_organizer WHERE questionnaire_id = r.questionnaire_id;		
		END IF;
	END LOOP;
	
	-- now we'll fudge any data that is sitting in a mixed shared state
	UPDATE tt_questionnaire_organizer
	   SET questionnaire_status_id = 1000, -- pseudo id
		   questionnaire_status_name = 'Mixed shared states', 
		   status_update_dtm = NULL
	 WHERE questionnaire_id IN (
				SELECT questionnaire_id 
				  FROM (SELECT questionnaire_id, COUNT(share_status_id) unique_status_count 
						  FROM (SELECT DISTINCT questionnaire_id, share_status_id FROM v$questionnaire_share) 
						 GROUP BY questionnaire_id
				) WHERE unique_status_count > 1
		   );
		
	-- now lets fix up statuses that are in unique and valid shared state
	UPDATE tt_questionnaire_organizer qo
	   SET (questionnaire_status_id, questionnaire_status_name, status_update_dtm) = (
			SELECT share_status_id, NVL(ssd.item, share_status_name), MAX(status_entry_dtm)
			  FROM v$questionnaire_share qs
			  LEFT JOIN TABLE(v_share_status_desc_table) ssd ON qs.share_status_id = ssd.pos 
			 WHERE qs.questionnaire_id = qo.questionnaire_id
			   AND qo.questionnaire_status_id = chain_pkg.READY_TO_SHARE
			 GROUP BY share_status_id, share_status_name, ssd.item
			)
	 WHERE qo.questionnaire_status_id = chain_pkg.READY_TO_SHARE;
	
	-- now fix up the due by dtms
	UPDATE tt_questionnaire_organizer qo
	   SET due_by_dtm = (
			SELECT MAX(due_by_dtm)
			  FROM v$questionnaire_share qs
			 WHERE qs.questionnaire_id = qo.questionnaire_id
			   AND qo.questionnaire_status_id = qs.share_status_id
			   AND qo.questionnaire_status_id <> 1000 -- pseudo id
			)
	 WHERE qo.questionnaire_status_id <> 1000;
	 
	 /* append unitialized questionnaires */
	INSERT INTO tt_questionnaire_organizer
	(questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm, due_by_dtm, name, 
	component_description, company_sid, questionnaire_type_id)
	SELECT NULL, x.qnr_share_status_id, x.questionnaire_status_name, x.sent_dtm, x.expiration_dtm, x.name, NULL, x.to_company_sid, 
		x.questionnaire_type_id
	  FROM (
		SELECT i.to_company_sid, qt.questionnaire_type_id, qt.name, chain_pkg.NOT_STARTED qnr_share_status_id, 
			DECODE(i.invitation_status_id, chain_pkg.EXPIRED, 'Invitation expired', 'Invitation not accepted') questionnaire_status_name, 
			i.sent_dtm, i.expiration_dtm, qt.view_url, 
			ROW_NUMBER() OVER (PARTITION BY i.to_company_sid, iqt.questionnaire_type_id ORDER BY i.invitation_id DESC) rn --in case we have more than one active invitation (first resend, then resend cancelled)
		  FROM invitation i 
		  JOIN invitation_qnr_type iqt ON i.invitation_id = iqt.invitation_id
		  JOIN TABLE(v_qnr_type_table) t ON iqt.questionnaire_type_id = t.column_value
		  JOIN questionnaire_type qt ON t.column_value = qt.questionnaire_type_id
		 WHERE i.app_sid = security_pkg.GetApp
		   AND i.sent_dtm IS NOT NULL
		   AND i.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION
		   AND i.invitation_status_id <> chain.chain_pkg.CANCELLED
		   AND (v_search_for_all_companies = 1 OR i.to_company_sid IN (SELECT tt.column_value FROM TABLE(v_company_sid_table) tt))
		   AND NOT EXISTS(
				SELECT 1 
				  FROM questionnaire q 
				 WHERE q.app_sid = security_pkg.GetApp
				   AND q.company_sid = i.to_company_sid
				   AND q.questionnaire_type_id = iqt.questionnaire_type_id
				   AND q.rejected = 0
				)	
		)x
	  WHERE x.rn = 1;
		
	-- now we'll run the sort on the data, setting a position value for each questionnaire_id
	EXECUTE IMMEDIATE
		'UPDATE tt_questionnaire_organizer qo '||
		'   SET qo.position = ( '||
		'		SELECT rn '||
		'		  FROM ( '||
		'				SELECT tqo.questionnaire_id, tqo.company_sid, tqo.questionnaire_type_id, row_number() OVER (ORDER BY ' || v_sort || ') rn  '||
		'				  FROM tt_questionnaire_organizer tqo'||
		'			   ) q  '||
		'		 WHERE q.questionnaire_id = qo.questionnaire_id 
					OR (q.questionnaire_id IS NULL AND q.company_sid = qo.company_sid AND q.questionnaire_type_id = qo.questionnaire_type_id) '||
		'	  )';
	
	SELECT count(*)
	  INTO v_total_rows
	  FROM tt_questionnaire_organizer;
	  
	DELETE FROM tt_questionnaire_organizer
	  WHERE position <= in_start OR position > (in_start + in_page_size);
	  
	FOR r IN (
		SELECT DISTINCT questionnaire_id 
		  FROM tt_questionnaire_organizer
		 WHERE questionnaire_id IS NOT NULL
	) 
	LOOP
		IF CanEditQuestionnaire(r.questionnaire_id) THEN
			v_editable_qnr_sid_table.extend;
			v_editable_qnr_sid_table(v_editable_qnr_sid_table.count) := r.questionnaire_id;
		END IF;
	END LOOP;
		
	-- we can now open a clean cursor and use the position column to order and control paging
	OPEN out_cur FOR 
		SELECT r.*, CASE WHEN 
				r.questionnaire_status_id IN (chain_pkg.ENTERING_DATA, chain_pkg.REVIEWING_DATA) 
				THEN edit_url ELSE view_url END url
		  FROM (
				SELECT qo.questionnaire_id, qo.company_sid, qo.name, qt.edit_url, qt.view_url, qo.due_by_dtm, qo.questionnaire_type_id, q.component_id, cmp.description component_description,
						qo.questionnaire_status_id, qo.questionnaire_status_name, qo.status_update_dtm, qo.position page_position, 
						c.name company_name, v_total_rows AS total_rows, NVL2(tt.column_value, 1, 0) is_editable,
						CASE WHEN v_has_audit_qnr_cap = 1 AND qs.auditing_audit_type_id IS NOT NULL THEN 1 ELSE 0 END can_audit_questionnaire,
						ssr.survey_response_id, ia.audit_sid response_audit_sid, ssr2.last_updated_by_full_name, qs.audience
				  FROM tt_questionnaire_organizer qo 				 
				  JOIN company c ON qo.company_sid = c.company_sid
				  LEFT JOIN questionnaire q ON q.questionnaire_id = qo.questionnaire_id
				  LEFT JOIN questionnaire_type qt ON qt.questionnaire_type_id = q.questionnaire_type_id
				  LEFT JOIN component cmp ON cmp.component_id = q.component_id
				  LEFT JOIN TABLE(v_editable_qnr_sid_table) tt ON q.questionnaire_id = tt.column_value
				  LEFT JOIN csr.quick_survey qs ON q.questionnaire_type_id = qs.survey_sid
				  LEFT JOIN csr.supplier_survey_response ssr ON q.company_sid = ssr.supplier_sid AND q.questionnaire_type_id = ssr.survey_sid AND ssr.component_id IS NULL
				  LEFT JOIN (
					SELECT ia.comparison_response_id, MIN(ia.internal_audit_sid) audit_sid
					  FROM csr.internal_audit ia
					 GROUP BY ia.comparison_response_id
					) ia ON ssr.survey_response_id = ia.comparison_response_id
				  LEFT JOIN (
				 	SELECT ssr.app_sid, ssr.supplier_sid, ssr.component_id, lcu.full_name last_updated_by_full_name
				 	  FROM csr.supplier_survey_response ssr
				 	  JOIN (
				 		SELECT app_sid, survey_response_id, set_by_user_sid, ROW_NUMBER() OVER(PARTITION BY app_sid, survey_response_id ORDER BY set_dtm DESC) rn
				 		  FROM csr.qs_answer_log
				 	  ) qal ON ssr.app_sid = qal.app_sid AND ssr.survey_response_id = qal.survey_response_id AND qal.rn = 1
				 	  JOIN v$chain_user lcu ON ssr.app_sid = lcu.app_sid AND qal.set_by_user_sid = lcu.user_sid
				 ) ssr2 ON q.app_sid = ssr2.app_sid AND q.company_sid = ssr2.supplier_sid AND q.component_id = ssr2.component_id
				 ORDER BY qo.position
			   ) r;
END;


/* Returns Product questionnaires + unstarted product invitation entries 
There is a data overlap with GetQManagementData as both return started product questionnaires
The difference is the TT we use here is based on the component, not the questionnaire
*/
PROCEDURE GetProductManagementData (
	in_company_sids		security_pkg.T_SID_IDS, /* holds sids of questionnaire owner companies */
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_sort				VARCHAR2(100) DEFAULT CASE WHEN in_sort_by ='name' THEN 'name '|| in_sort_dir||', component_description '||in_sort_dir ELSE in_sort_by||' '||in_sort_dir END;
	v_qnr_type_table			security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(GetActiveQuestionnaireTypes);
	v_company_sid_table			security.T_SID_TABLE;
	v_editable_qnr_sid_table	security.T_SID_TABLE := security.T_SID_TABLE();
	v_editable_perm_qnr_type_table	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(GetPermEditableQrTypes);
	v_can_search_all_unstarted	NUMBER(1) DEFAULT CASE WHEN helper_pkg.ShowAllComponents = 1 OR company_user_pkg.IsCompanyAdmin = 1 OR chain_link_pkg.CanViewUnstartedProductQnr = 1 THEN 1 ELSE 0 END;
	v_search_for_all_companies  NUMBER(1) := 0;
	v_qnr_type_perm_editable  	NUMBER(1);
	v_share_status_desc_table   T_VARCHAR_TABLE DEFAULT chain_link_pkg.GetAlterShareStatusDescr;
	v_total_rows				NUMBER;
BEGIN
	ValidateSortOptions(in_sort_by, in_sort_dir);

	DELETE FROM TT_PRODUCT_QNR_DATA_ORG;

	IF in_company_sids IS NULL OR in_company_sids.COUNT = 0 OR in_company_sids(1) IS NULL THEN
		v_search_for_all_companies := 1;
	END IF;
	
	v_company_sid_table := security_pkg.SidArrayToTable(in_company_sids);
	
	--search for supplier questionnaires that the context company has been shared with
	INSERT INTO TT_PRODUCT_QNR_DATA_ORG 
	(component_id, questionnaire_id, company_sid, questionnaire_type_id, name, component_description, questionnaire_status_id, questionnaire_status_name, 
		status_update_dtm, due_by_dtm, url, created_by_sid)
	SELECT cmp.component_id, qs.questionnaire_id, c.company_sid, qs.questionnaire_type_id, qt.name, cmp.description, qs.share_status_id, 
		NVL(ssd.item, qs.share_status_name), qs.entry_dtm, qs.due_by_dtm, qt.view_url, created_by_sid
	  FROM v$questionnaire_share qs
	  JOIN TABLE(v_qnr_type_table) t ON qs.questionnaire_type_id = t.column_value
	  LEFT JOIN TABLE(v_company_sid_table) tt ON qs.qnr_owner_company_sid = tt.column_value
	  JOIN company c ON qs.qnr_owner_company_sid = c.company_sid
	  JOIN questionnaire_type qt ON t.column_value = qt.questionnaire_type_id
	  JOIN component cmp ON qs.component_id = cmp.component_id	  
	  LEFT JOIN TABLE(v_share_status_desc_table) ssd ON qs.share_status_id = ssd.pos
	 WHERE qs.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (tt.column_value IS NOT NULL OR v_search_for_all_companies = 1);
	
	FOR r IN (
		SELECT DISTINCT questionnaire_id, questionnaire_type_id, company_sid
		  FROM TT_PRODUCT_QNR_DATA_ORG
	) 
	LOOP
		IF NOT questionnaire_security_pkg.CheckPermission(r.questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
			DELETE FROM TT_PRODUCT_QNR_DATA_ORG WHERE questionnaire_id = r.questionnaire_id;
		END IF;
	END LOOP;
	 
	/* append unitialized component questionnaires */
	INSERT INTO TT_PRODUCT_QNR_DATA_ORG
	(component_id, company_sid, questionnaire_type_id, name, component_description, questionnaire_status_id, questionnaire_status_name, 
		status_update_dtm, due_by_dtm, url, created_by_sid)
	SELECT x.component_id, x.to_company_sid, x.questionnaire_type_id, x.name, x.description, x.qnr_share_status_id, x.questionnaire_status_name, 
		x.sent_dtm, x.expiration_dtm, x.view_url, x.created_by_sid	
	  FROM (
		SELECT cmp.component_id, i.to_company_sid, qt.questionnaire_type_id, qt.name, cmp.description, chain_pkg.NOT_STARTED qnr_share_status_id, 
			DECODE(i.invitation_status_id, chain_pkg.EXPIRED, 'Invitation expired', 'Pending invitation') questionnaire_status_name, 
			i.sent_dtm, i.expiration_dtm, qt.view_url, created_by_sid,
			ROW_NUMBER() OVER (PARTITION BY cmp.component_id ORDER BY i.sent_dtm DESC) rn --in case we have more than one active invitation for a component (resend -> resend cancelled)
		  FROM invitation i 
		  LEFT JOIN TABLE(v_company_sid_table) tt ON i.to_company_sid = tt.column_value 
		  JOIN invitation_qnr_type_component iqtc ON i.invitation_id = iqtc.invitation_id
		  JOIN TABLE(v_qnr_type_table) t ON iqtc.questionnaire_type_id = t.column_value
		  JOIN questionnaire_type qt ON t.column_value = qt.questionnaire_type_id
		  JOIN component cmp ON iqtc.component_id = cmp.component_id
		 WHERE i.app_sid = security_pkg.GetApp
		   AND i.sent_dtm IS NOT NULL
		   AND i.invitation_status_id <> chain.chain_pkg.CANCELLED
		   AND (v_can_search_all_unstarted = 1 OR (cmp.created_by_sid = SYS_CONTEXT('SECURITY', 'SID')))
		   AND (tt.column_value IS NOT NULL OR v_search_for_all_companies = 1)
		   AND NOT EXISTS(
				SELECT 1 
				  FROM questionnaire q 
				 WHERE q.app_sid = security_pkg.GetApp
				   AND q.component_id = cmp.component_id
				)	
		)x
	  WHERE x.rn = 1;
	
	-- now we'll run the sort on the data, setting a position value for each questionnaire_id
	EXECUTE IMMEDIATE
		'UPDATE TT_PRODUCT_QNR_DATA_ORG tpq '||
		'   SET tpq.position = ( '||
		'		SELECT rn '||
		'		  FROM ( '||
		'				SELECT tpq.component_id, row_number() OVER (ORDER BY tpq.' || v_sort || ') rn  '||
		'				  FROM TT_PRODUCT_QNR_DATA_ORG tpq ' ||
		'			   ) c  '||
		'		 WHERE c.component_id = tpq.component_id ' ||
		'	  )';
	
	SELECT count(*)
	  INTO v_total_rows
	  FROM TT_PRODUCT_QNR_DATA_ORG;
	  
	DELETE FROM TT_PRODUCT_QNR_DATA_ORG
	  WHERE position <= in_start OR position > (in_start + in_page_size);
	  
	FOR r IN (
		SELECT DISTINCT questionnaire_id, questionnaire_type_id, company_sid
		  FROM tt_product_qnr_data_org
		 WHERE questionnaire_id IS NOT NULL
	) 
	LOOP
		IF CanEditQuestionnaire(r.questionnaire_id) THEN
			v_editable_qnr_sid_table.extend;
			v_editable_qnr_sid_table(v_editable_qnr_sid_table.count) := r.questionnaire_id;
		END IF;
			
		--check if we can change questionnaire permissions
		SELECT DECODE(COUNT(*), 0, 0, 1)
		  INTO v_qnr_type_perm_editable
		  FROM TABLE(v_editable_perm_qnr_type_table) t
		 WHERE r.questionnaire_type_id = t.column_value;
		
		IF v_qnr_type_perm_editable = 1 THEN			
			--IF type_capability_pkg.CheckCapability(r.company_sid, chain_pkg.MANAGE_QUESTIONNAIRE_SECURITY) THEN
			IF questionnaire_security_pkg.CanGrantPermissions(r.questionnaire_id, r.company_sid) = 1 THEN
				UPDATE TT_PRODUCT_QNR_DATA_ORG
				   SET can_manage_supplier_perms = 1
				 WHERE questionnaire_id = r.questionnaire_id;
			END IF;
			
			--IF type_capability_pkg.CheckCapability(chain_pkg.MANAGE_QUESTIONNAIRE_SECURITY) THEN
			IF questionnaire_security_pkg.CanGrantPermissions(r.questionnaire_id, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) = 1 THEN
				UPDATE TT_PRODUCT_QNR_DATA_ORG
				   SET can_manage_procurer_perms = 1
				 WHERE questionnaire_id = r.questionnaire_id;
			END IF;
		END IF;
	END LOOP;
	 
	-- we can now open a clean cursor and use the position column to order and control paging
	OPEN out_cur FOR 
		SELECT r.*
		  FROM (
				SELECT tpq.company_sid, tpq.name, tpq.url, tpq.due_by_dtm, tpq.questionnaire_type_id, tpq.component_id, tpq.component_description,
						tpq.questionnaire_status_id, tpq.questionnaire_status_name, tpq.status_update_dtm, tpq.position page_position, 
						c.name company_name, v_total_rows AS total_rows, questionnaire_id,
						NVL2(tt.column_value, 1, 0) is_editable, cu.full_name created_by_full_name, 
						tpq.can_manage_procurer_perms, tpq.can_manage_supplier_perms, ssr.last_updated_by_full_name
				  FROM TT_PRODUCT_QNR_DATA_ORG tpq 
				  JOIN company c ON tpq.company_sid = c.company_sid
				  JOIN v$chain_user cu ON c.app_sid = cu.app_sid AND cu.user_sid = tpq.created_by_sid
				  LEFT JOIN TABLE(v_editable_qnr_sid_table) tt ON tpq.questionnaire_id = tt.column_value
				  LEFT JOIN (
					SELECT ssr.app_sid, ssr.supplier_sid, ssr.component_id, lcu.full_name last_updated_by_full_name
					  FROM csr.supplier_survey_response ssr
					  JOIN (
						SELECT app_sid, survey_response_id, set_by_user_sid, ROW_NUMBER() OVER(PARTITION BY app_sid, survey_response_id ORDER BY set_dtm DESC) rn
						  FROM csr.qs_answer_log
					  ) qal ON ssr.app_sid = qal.app_sid AND ssr.survey_response_id = qal.survey_response_id AND qal.rn = 1
					  JOIN v$chain_user lcu ON ssr.app_sid = lcu.app_sid AND qal.set_by_user_sid = lcu.user_sid
				) ssr ON c.app_sid = ssr.app_sid AND c.company_sid = ssr.supplier_sid AND tpq.component_id = ssr.component_id
				 ORDER BY tpq.position
			   ) r;
END;


PROCEDURE GetMyQuestionnaires (
	in_status			IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_cur FOR
		SELECT q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.component_id, q.component_description, q.created_dtm, q.view_url, q.edit_url, q.owner_can_review, 
				q.class, q.name, q.db_class, q.group_name, q.position, q.status_log_entry_index, q.questionnaire_status_id, q.status_update_dtm, qs.due_by_dtm
		  FROM v$questionnaire q
		  JOIN v$questionnaire_share qs
			ON q.app_sid = qs.app_sid
		   AND q.questionnaire_id = qs.questionnaire_id
		   AND q.questionnaire_type_id = qs.questionnaire_type_id
		 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND q.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND q.questionnaire_status_id = NVL(in_status, q.questionnaire_status_id)
		 ORDER BY LOWER(q.name);
END;


PROCEDURE CreateQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_view_url					IN	questionnaire_type.view_url%TYPE,
	in_edit_url					IN	questionnaire_type.edit_url%TYPE,
	in_owner_can_review			IN	questionnaire_type.owner_can_review%TYPE,
	in_name						IN	questionnaire_type.name%TYPE,
	in_class					IN	questionnaire_type.CLASS%TYPE,
	in_db_class					IN	questionnaire_type.db_class%TYPE,
	in_group_name				IN	questionnaire_type.group_name%TYPE,
	in_position					IN	questionnaire_type.position%TYPE,
	in_requires_review			In	questionnaire_type.requires_review%TYPE DEFAULT 1
)
AS
BEGIN
	-- TODO: This is going to be too restrictive for Survey Manager
	-- IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		-- IF NOT capability_pkg.CheckCapability(chain_pkg.CREATE_QUESTIONNAIRE_TYPE) THEN
			-- RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateQuestionnaireType can only be run as BuiltIn/Administrator or with capability CREATE_QUESTIONNAIRE_TYPE');
		-- END IF;
	-- END IF;

	BEGIN
		INSERT INTO questionnaire_type (
			questionnaire_type_id, 
			view_url, 
			edit_url, 
			owner_can_review, 
			name, 
			CLASS, 
			db_class,
			group_name,
			position,
			requires_review
		) VALUES ( 
			in_questionnaire_type_id,
			in_view_url,
			in_edit_url,
			in_owner_can_review,
			in_name,
			in_class,
			in_db_class,	
			in_group_name,
			in_position,
			in_requires_review
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE questionnaire_type
			   SET	view_url=in_view_url,
					edit_url= in_edit_url,
					owner_can_review= in_owner_can_review,
					name=in_name,
					CLASS=in_class,
					db_class=in_db_class,
					group_name=in_group_name,
					position=in_position,
					requires_review = in_requires_review,
					active=chain_pkg.ACTIVE
			WHERE app_sid=security_pkg.getApp
			  AND questionnaire_type_id=in_questionnaire_type_id;
	END;
END;

PROCEDURE HideQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
)
AS
BEGIN
	-- TODO: This is going to be too restrictive for Survey Manager
	-- IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		-- IF NOT capability_pkg.CheckCapability(chain_pkg.CREATE_QUESTIONNAIRE_TYPE) THEN
			-- RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'HideQuestionnaireType can only be run as BuiltIn/Administrator or with capability CREATE_QUESTIONNAIRE_TYPE');
		-- END IF;
	-- END IF;
	
	UPDATE questionnaire_type
	   SET active=0
	 WHERE app_sid=security_pkg.getApp
	   AND questionnaire_type_id=in_questionnaire_type_id;
END;

PROCEDURE RenameQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_name						IN	questionnaire_type.name%TYPE	
)
AS
BEGIN
	-- TODO: This is going to be too restrictive for Survey Manager
	-- IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		-- IF NOT capability_pkg.CheckCapability(chain_pkg.CREATE_QUESTIONNAIRE_TYPE) THEN
			-- RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RenameQuestionnaireType can only be run as BuiltIn/Administrator or with capability CREATE_QUESTIONNAIRE_TYPE');
		-- END IF;
	-- END IF;
	
	UPDATE questionnaire_type
		   SET name = in_name
	 WHERE questionnaire_type_id = in_questionnaire_type_id
		  AND app_sid = security_pkg.getApp;	
END;

/* Returns 1 if Visible, 0 if Hidden, NULL if doesn't exist */
FUNCTION IsQuestionnaireTypeVisible (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
) RETURN NUMBER
AS
	v_active				questionnaire_type.active%TYPE;
BEGIN
	BEGIN
		SELECT active
		  INTO v_active
		  FROM questionnaire_type
		 WHERE app_sid=security_pkg.getApp
		   AND questionnaire_type_id=in_questionnaire_type_id;
	EXCEPTION
		WHEN no_data_found THEN
			v_active := NULL;
	END;
	
	RETURN v_active;
END;


PROCEDURE DeleteQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateQuestionnaireType can only be run as BuiltIn/Administrator');
	END IF;

	DELETE FROM qnr_status_log_entry
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	
	DELETE FROM qnr_share_log_entry
	 WHERE questionnaire_share_id IN (
		SELECT questionnaire_share_id
		  FROM questionnaire_share qs	
			JOIN questionnaire q ON qs.questionnaire_id = q.questionnaire_id
		 WHERE q.questionnaire_type_id = in_questionnaire_type_id
		   AND q.app_sid = security_pkg.GetApp
	);
	
	DELETE FROM questionnaire_share 
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	 
	-- now we can clear questionaires
	DELETE FROM questionnaire_metric
	 WHERE questionnaire_id IN(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	
	-- DELETE FROM event
	 -- WHERE related_action_id IN (
		-- SELECT action_id
		  -- FROM action a 
			-- JOIN questionnaire q ON a.related_questionnaire_id = q.questionnaire_id
		  -- WHERE q.questionnaire_type_id = in_questionnaire_type_id
		    -- AND q.app_sid = security_pkg.getApp
	 -- );
	
	-- DELETE FROM action
     -- WHERE related_questionnaire_id IN (
		-- SELECT questionnaire_id
		  -- FROM questionnaire 
		 -- WHERE questionnaire_type_id = in_questionnaire_type_id
		   -- AND app_sid = security_pkg.GetApp
     -- );
	
	DELETE FROM message_recipient
	 WHERE message_id IN (
			SELECT message_id
			  FROM message
			 WHERE re_questionnaire_type_id = in_questionnaire_type_id
			   AND app_sid = security_pkg.getApp
	        )
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM message_refresh_log
	 WHERE message_id IN (
			SELECT message_id
			  FROM message
			 WHERE re_questionnaire_type_id = in_questionnaire_type_id
			   AND app_sid = security_pkg.getApp
	        )
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM user_message_log
	 WHERE message_id IN (
			SELECT message_id
			  FROM message
			 WHERE re_questionnaire_type_id = in_questionnaire_type_id
			   AND app_sid = security_pkg.getApp
	        )
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM message
	 WHERE re_questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM invitation_qnr_type
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM questionnaire_invitation
	  WHERE app_sid = security_pkg.GetApp
		AND questionnaire_id IN (
			SELECT questionnaire_id
			  FROM questionnaire
			 WHERE app_sid = security_pkg.GetApp
			   AND questionnaire_type_id = in_questionnaire_type_id
		);
	
	DELETE FROM qnr_action_security_mask
	  WHERE app_sid = security_pkg.GetApp
		AND questionnaire_type_id = in_questionnaire_type_id;
		
	DELETE FROM questionnaire_user_action
	  WHERE app_sid = security_pkg.GetApp
		AND questionnaire_id IN (
			SELECT questionnaire_id
			  FROM questionnaire
			 WHERE app_sid = security_pkg.GetApp
			   AND questionnaire_type_id = in_questionnaire_type_id
		);	
		
	DELETE FROM questionnaire_user
	  WHERE app_sid = security_pkg.GetApp
		AND questionnaire_id IN (
			SELECT questionnaire_id
			  FROM questionnaire
			 WHERE app_sid = security_pkg.GetApp
			   AND questionnaire_type_id = in_questionnaire_type_id
		);	
	
	DELETE FROM questionnaire
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM flow_questionnaire_type
	  WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.GetApp;
	   
	DELETE FROM questionnaire_type
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.GetApp;
	
END;

PROCEDURE RetractQuestionnaire (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_company_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	RetractQuestionnaire(in_questionnaire_type_id, in_company_sid, NULL);
END;

PROCEDURE RetractQuestionnaire (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_component_id				IN component.component_id%TYPE
)
AS
	v_message_ids				T_NUMERIC_TABLE := T_NUMERIC_TABLE();
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RetractQuestionnaire can only be run as BuiltIn/Administrator');
	END IF;

	DELETE FROM qnr_status_log_entry
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid
		   AND ((component_id = in_component_id) OR component_id IS NULL AND in_component_id IS NULL)
	);
	
	DELETE FROM qnr_share_log_entry
	 WHERE questionnaire_share_id IN (
		SELECT questionnaire_share_id
		  FROM questionnaire_share qs	
			JOIN questionnaire q ON qs.questionnaire_id = q.questionnaire_id
		 WHERE q.questionnaire_type_id = in_questionnaire_type_id
		   AND q.app_sid = security_pkg.GetApp
		   AND q.company_sid = in_company_sid
		   AND ((q.component_id = in_component_id) OR q.component_id IS NULL AND in_component_id IS NULL)
	);
	
	DELETE FROM questionnaire_share 
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid
		   AND ((component_id = in_component_id) OR component_id IS NULL AND in_component_id IS NULL)
	);
	 
	-- now we can clear questionaires
	DELETE FROM questionnaire_metric
	 WHERE questionnaire_id IN(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid
		   AND ((component_id = in_component_id) OR component_id IS NULL AND in_component_id IS NULL)
	);
	
	-- DELETE FROM event
	 -- WHERE related_action_id IN (
		-- SELECT action_id
		  -- FROM action a 
			-- JOIN questionnaire q ON a.related_questionnaire_id = q.questionnaire_id
		  -- WHERE q.questionnaire_type_id = in_questionnaire_type_id
		    -- AND q.app_sid = security_pkg.getApp
		    -- AND q.company_sid = in_company_sid
			-- AND ((q.component_id = in_component_id) OR q.component_id IS NULL AND in_component_id IS NULL)
	 -- );
	
	-- DELETE FROM action
     -- WHERE related_questionnaire_id IN (
		-- SELECT questionnaire_id
		  -- FROM questionnaire 
		 -- WHERE questionnaire_type_id = in_questionnaire_type_id
		   -- AND app_sid = security_pkg.GetApp
		   -- AND company_sid = in_company_sid
		   -- AND ((component_id = in_component_id) OR component_id IS NULL AND in_component_id IS NULL)
     -- );
	
	SELECT T_NUMERIC_ROW(message_id, null)
	  BULK COLLECT INTO v_message_ids
	  FROM message
	 WHERE app_sid = security_pkg.getApp
	   AND re_questionnaire_type_id = in_questionnaire_type_id
	   AND NVL(re_component_id, -1) = NVL(in_component_id, -1)
	   AND (re_company_sid = in_company_sid
	    OR message_id IN (
			SELECT mr.message_id
			  FROM message_recipient mr
			  JOIN recipient r ON mr.recipient_id = r.recipient_id AND mr.app_sid = r.app_sid
			 WHERE r.to_company_sid = in_company_sid
	    ));
	
	DELETE FROM message_recipient
	 WHERE message_id IN (
			SELECT item FROM TABLE(v_message_ids)
	        )
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM message_refresh_log
	 WHERE message_id IN (
			SELECT item FROM TABLE(v_message_ids)
	        )
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM user_message_log
	 WHERE message_id IN (
			SELECT item FROM TABLE(v_message_ids)
	        )
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM message
	 WHERE message_id IN (
			SELECT item FROM TABLE(v_message_ids)
	        )
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM questionnaire_user_action
	 WHERE questionnaire_id = (
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid
		   AND NVL(component_id, -1) = NVL(in_component_id, -1)
	 );
	 
	DELETE FROM questionnaire_user
	 WHERE questionnaire_id = (
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid
		   AND NVL(component_id, -1) = NVL(in_component_id, -1)
	 );
	 
	DELETE FROM questionnaire_invitation
	 WHERE questionnaire_id = (
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid
		   AND NVL(component_id, -1) = NVL(in_component_id, -1)
	 );
	
	DELETE FROM invitation_qnr_type_component
	  WHERE app_sid = security_pkg.GetApp
		AND questionnaire_type_id = in_questionnaire_type_id
		AND component_id = in_component_id;
	 
	DELETE FROM questionnaire
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid
	   AND ((component_id = in_component_id) OR component_id IS NULL AND in_component_id IS NULL);

END;

PROCEDURE GetQuestionnaireAbilities (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetQuestionnaireAbilities(in_company_sid, in_qt_class, NULL, out_cur);
END;

PROCEDURE GetQuestionnaireAbilities (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id				IN	component.component_id%TYPE,	
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_company_sid, in_qt_class, in_component_id);
	v_is_owner					NUMBER(1) DEFAULT CASE WHEN in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN 1 ELSE 0 END;
	v_can_write					NUMBER(1) DEFAULT CASE WHEN questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_EDIT) THEN 1 ELSE 0 END;
	v_can_approve				NUMBER(1) DEFAULT CASE WHEN questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_APPROVE) THEN 1 ELSE 0 END;
	v_can_submit				NUMBER(1) DEFAULT CASE WHEN questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_SUBMIT) THEN 1 ELSE 0 END;
	v_can_reject				NUMBER(1) DEFAULT CASE WHEN questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_REJECT) THEN 1 ELSE 0 END;
	v_ready_to_share			NUMBER(1);
	v_is_shared					NUMBER(1) DEFAULT 0;
	v_status					chain_pkg.T_QUESTIONNAIRE_STATUS;
	v_share_status				chain_pkg.T_SHARE_STATUS;
	v_owner_can_review			questionnaire_type.owner_can_review%TYPE;
	v_procurer_can_review		number;
	v_rejected					questionnaire.rejected%TYPE;
BEGIN
	-- IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
	IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;
	
	IF NOT QuestionnaireExists(in_company_sid, in_qt_class, in_component_id) THEN
		OPEN out_cur FOR
			SELECT 
				0 questionnaire_exists, 
				0 is_ready_to_share,
				0 is_shared, 
				0 can_share, 
				0 is_read_only, 
				0 can_make_editable, 
				0 is_owner, 
				0 is_approved,
				0 is_rejected,
				0 can_reject
			  FROM DUAL;
		
		RETURN;
	END IF;
	
	v_status := GetQuestionnaireStatus(in_company_sid, in_qt_class, in_component_id);
	v_ready_to_share := CASE WHEN v_status = chain_pkg.READY_TO_SHARE THEN 1 ELSE 0 END; 
	
	IF v_is_owner = 0 THEN
		v_share_status := GetQuestionnaireShareStatus(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_qt_class, in_component_id);
		v_is_shared := CASE WHEN v_share_status IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED, chain_pkg.SHARED_DATA_RESENT) THEN 1 ELSE 0 END;
	ELSE
		SELECT owner_can_review
		  INTO v_owner_can_review
		  FROM questionnaire_type
		 WHERE questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class);
	END IF;
	
	SELECT procurer_can_review
	  INTO v_procurer_can_review
	  FROM questionnaire_type
	 WHERE questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class);
	
	SELECT rejected 
	  INTO v_rejected
	  FROM questionnaire
	 WHERE questionnaire_id = v_questionnaire_id;
	 
	OPEN out_cur FOR
		SELECT
			1 questionnaire_exists,
			v_ready_to_share is_ready_to_share,
			v_is_shared is_shared,
			v_can_submit can_share,
			v_can_approve can_approve,
			v_is_owner is_owner,
			CASE 
				WHEN v_share_status IN (chain_pkg.SHARED_DATA_RESENT, chain_pkg.SHARED_DATA_RETURNED) THEN 1
				WHEN v_can_write = 0 THEN 1
				WHEN v_ready_to_share = 0 THEN 0
				ELSE 1 
			END is_read_only,
			CASE 
				WHEN v_share_status IN (chain_pkg.SHARED_DATA_RESENT, chain_pkg.SHARED_DATA_RETURNED) THEN 0
				WHEN v_is_owner = 1 AND v_owner_can_review = 1 THEN 1
				WHEN v_is_owner = 0 AND v_can_write = 1 AND v_share_status = chain_pkg.SHARING_DATA AND v_procurer_can_review=1 THEN 1
				ELSE 0
			END can_make_editable,
			CASE 
				WHEN v_share_status = chain_pkg.SHARED_DATA_ACCEPTED THEN 1 
				ELSE 0 
			END is_approved,
			v_rejected is_rejected,
			v_can_reject can_reject
		  FROM DUAL;
END;

FUNCTION GetOverdueQuestionnaireTypes
RETURN security.T_SID_TABLE
AS 
	v_qnr_type_ids security.T_SID_TABLE;
BEGIN

	SELECT questionnaire_type_id
	  BULK COLLECT INTO v_qnr_type_ids
	  FROM chain.questionnaire_type
	 WHERE app_sid = security_pkg.GetApp
	   AND can_be_overdue = 1;
	   
	RETURN v_qnr_type_ids;
END;

PROCEDURE CheckForOverdueQuestionnaires
AS
	v_expirable_qnr_type_ids 	security.T_SID_TABLE DEFAULT GetOverdueQuestionnaireTypes;
BEGIN
	
	FOR r IN (
		SELECT qs.*
		  FROM v$questionnaire_share qs
		  JOIN TABLE(v_expirable_qnr_type_ids) t ON t.column_value = qs.questionnaire_type_id
		 WHERE qs.app_sid = security_pkg.GetApp
		   AND qs.due_by_dtm < SYSDATE
		   AND qs.overdue_events_sent = 0
		   AND qs.share_status_id IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RESENT)
	) LOOP
	
	
		-- send the message to the Purchaser
		message_pkg.TriggerMessage (
			in_primary_lookup           => CASE WHEN r.component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_OVERDUE ELSE chain_pkg.COMP_QUESTIONNAIRE_OVERDUE END,
			in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
			in_to_company_sid           => r.share_with_company_sid,
			in_to_user_sid		        => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.qnr_owner_company_sid,
			in_re_questionnaire_type_id => r.questionnaire_type_id,
			in_re_component_id			=> r.component_id
		);

		-- send the message to the supplier
		message_pkg.TriggerMessage (
			in_primary_lookup           => CASE WHEN r.component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_OVERDUE ELSE chain_pkg.COMP_QUESTIONNAIRE_OVERDUE END,
			in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
			in_to_company_sid           => r.qnr_owner_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.share_with_company_sid,
			in_re_questionnaire_type_id => r.questionnaire_type_id,
			in_re_component_id			=> r.component_id
		);

		
		UPDATE questionnaire_share
		   SET overdue_events_sent = 1
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_share_id = r.questionnaire_share_id;
		   
		chain_link_pkg.QuestionnaireOverdue(r.questionnaire_id);
	END LOOP;
END;

PROCEDURE ShareQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,	
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ShareQuestionnaire(in_qt_class, in_qnr_owner_company_sid, in_share_with_company_sid, NULL);
END;

PROCEDURE ShareQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,	
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID,
	in_component_id				IN	component.component_id%TYPE,
	in_transition_comments		IN  qnr_status_log_entry.user_notes%TYPE DEFAULT NULL
)
AS
	v_qnr_type_id				questionnaire_type.questionnaire_type_id%TYPE := questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class);
	v_current_share				chain_pkg.T_SHARE_STATUS := GetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_component_id);
BEGIN
	-- TODO: remove this loop - stuck in quickly for rfa
	--FOR r IN (
	--	SELECT share_with_company_sid 
	--	  FROM questionnaire_share
	--	 WHERE app_sid = security_pkg.GetApp
	--	   AND qnr_owner_company_sid = in_qnr_owner_company_sid
	--	   AND questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class)
	--) LOOP
		SetQuestionnaireStatus(in_qnr_owner_company_sid, in_qt_class, chain_pkg.READY_TO_SHARE, null, in_component_id);
		
		IF v_current_share != chain_pkg.SHARED_DATA_ACCEPTED THEN
			-- No need to change share status if data already accepted
			SetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, chain_pkg.SHARING_DATA, in_transition_comments, in_component_id);
		END IF;
		
		message_pkg.CompleteMessageIfExists(
			in_primary_lookup			=> CASE WHEN in_component_id IS NULL THEN chain_pkg.COMPLETE_QUESTIONNAIRE ELSE chain_pkg.COMP_COMPLETE_QUESTIONNAIRE END,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid			=> in_qnr_owner_company_sid,
			in_re_company_sid			=> in_share_with_company_sid,
			in_re_questionnaire_type_id	=> v_qnr_type_id,
			in_re_component_id			=> in_component_id			
		);
		
		message_pkg.CompleteMessageIfExists(
			in_primary_lookup			=> CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_RETURNED ELSE chain_pkg.COMP_QUESTIONNAIRE_RETURNED END,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid			=> in_qnr_owner_company_sid,
			in_re_company_sid			=> in_share_with_company_sid,
			in_re_questionnaire_type_id	=> v_qnr_type_id,
			in_re_component_id			=> in_component_id			
		);
		
		message_pkg.CompleteMessageIfExists(
			in_primary_lookup			=> CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_RESENT ELSE chain_pkg.COMP_QUESTIONNAIRE_RESENT END,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid			=> in_qnr_owner_company_sid,
			in_re_company_sid			=> in_share_with_company_sid,
			in_re_questionnaire_type_id	=> v_qnr_type_id,
			in_re_component_id			=> in_component_id			
		);
		
		message_pkg.TriggerMessage (
			in_primary_lookup           => CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_SUBMITTED ELSE chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED END,
			in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
			in_to_company_sid           => in_qnr_owner_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => in_share_with_company_sid,
			in_re_user_sid           	=> SYS_CONTEXT('SECURITY', 'SID'),
			in_re_questionnaire_type_id => v_qnr_type_id,
			in_re_component_id			=> in_component_id			
		);
		
		v_current_share := GetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, in_component_id);
		
		message_pkg.TriggerMessage (
			in_primary_lookup			=>	CASE WHEN v_current_share != chain_pkg.SHARED_DATA_ACCEPTED AND QnrTypeRequiresReview(v_qnr_type_id) = 1 THEN
												CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_SUBMITTED ELSE chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED END
											ELSE 
												CASE WHEN in_component_id IS NULL THEN chain_pkg.QNR_SUBMITTED_NO_REVIEW  ELSE chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW END
											END,
			in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
			in_to_company_sid           => in_share_with_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => in_qnr_owner_company_sid,
			in_re_questionnaire_type_id => v_qnr_type_id,
			in_re_component_id			=> in_component_id			
		);

	--END LOOP;
END;

PROCEDURE GetShareStatusLogEntries(
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_component_id				IN	component.component_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_questionnaire_id	questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id);
	v_share_status_desc_table   T_VARCHAR_TABLE DEFAULT chain_link_pkg.GetAlterShareStatusDescr;
BEGIN
	OPEN out_cur FOR
		SELECT qsle.questionnaire_share_id, qsle.share_log_entry_index, qsle.entry_dtm, qsle.user_sid, cu.full_name user_full_name,
			qsle.user_notes, NVL(ssd.item, ss.description) share_status_description
		  FROM qnr_share_log_entry qsle
		  JOIN questionnaire_share qs ON qs.questionnaire_share_id = qsle.questionnaire_share_id
		  JOIN share_status ss ON qsle.share_status_id = ss.share_status_id
		  LEFT JOIN TABLE(v_share_status_desc_table) ssd ON ss.share_status_id = ssd.pos
		  JOIN csr.csr_user cu ON cu.csr_user_sid = qsle.user_sid
		 WHERE qs.questionnaire_id = v_questionnaire_id
		 ORDER BY qsle.share_log_entry_index desc;
END;

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ApproveQuestionnaire(in_qt_class, in_qnr_owner_company_sid, NULL);
END;

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	,
	in_component_id				IN	 component.component_id%TYPE,
	in_transition_comments		IN  qnr_status_log_entry.user_notes%TYPE DEFAULT NULL
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class, chain_pkg.SHARED_DATA_ACCEPTED, in_transition_comments, in_component_id);
	
	message_pkg.CompleteMessageIfExists(
		in_primary_lookup			=> CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_SUBMITTED ELSE chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED END,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> company_pkg.GetCompany,
		in_re_company_sid			=> in_qnr_owner_company_sid,
		in_re_questionnaire_type_id	=> questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id	
	);	
	
	-- trigger questionnaire approved message to the supplier
	message_pkg.TriggerMessage (
		in_primary_lookup           => CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_APPROVED ELSE chain_pkg.COMP_QUESTIONNAIRE_APPROVED END,
		in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
		in_to_company_sid           => in_qnr_owner_company_sid,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => company_pkg.GetCompany,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id			
	);

	-- trigger questionnaire approved message to the purchaser
	message_pkg.TriggerMessage (
		in_primary_lookup           => CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_APPROVED ELSE chain_pkg.COMP_QUESTIONNAIRE_APPROVED END,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id					
	);
	
	-- trigger action plan started message to the purchaser (hidden by default)
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.ACTION_PLAN_STARTED,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid
	);
END;

PROCEDURE RejectQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID		
)
AS
BEGIN
	RejectQuestionnaire(in_qt_class, in_qnr_owner_company_sid, NULL);
END;

PROCEDURE RejectQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_component_id				IN	component.component_id%TYPE,
	in_transition_comments		IN  qnr_status_log_entry.user_notes%TYPE DEFAULT NULL
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class, chain_pkg.SHARED_DATA_REJECTED, in_transition_comments, in_component_id);
	
	message_pkg.CompleteMessageIfExists(
		in_primary_lookup			=> CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_SUBMITTED ELSE chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED END,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> company_pkg.GetCompany,
		in_re_company_sid			=> in_qnr_owner_company_sid,
		in_re_questionnaire_type_id	=> questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id					
	);	
	
	-- trigger questionnaire rejected message to the supplier
	message_pkg.TriggerMessage (
		in_primary_lookup           => CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_REJECTED ELSE chain_pkg.COMP_QUESTIONNAIRE_REJECTED END,
		in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
		in_to_company_sid           => in_qnr_owner_company_sid,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => company_pkg.GetCompany,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id					
	);

	-- trigger questionnaire rejected message to the purchaser
	message_pkg.TriggerMessage (
		in_primary_lookup           => CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_REJECTED ELSE chain_pkg.COMP_QUESTIONNAIRE_REJECTED END,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid,
		in_re_user_sid              => security_pkg.GetSid,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id					
	);
	
END;

PROCEDURE ReturnQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ReturnQuestionnaire(in_qt_class, in_qnr_owner_company_sid, NULL);
END;

PROCEDURE ReturnQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	,
	in_component_id				IN	component.component_id%TYPE,
	in_transition_comments		IN  qnr_status_log_entry.user_notes%TYPE DEFAULT NULL
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class, chain_pkg.SHARED_DATA_RETURNED, in_transition_comments, in_component_id);
	SetQuestionnaireStatus(in_qnr_owner_company_sid, in_qt_class, chain_pkg.ENTERING_DATA, null, in_component_id);
	
	message_pkg.CompleteMessageIfExists(
		in_primary_lookup			=> CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_SUBMITTED ELSE chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED END,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> company_pkg.GetCompany,
		in_re_company_sid			=> in_qnr_owner_company_sid,
		in_re_questionnaire_type_id	=> questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id					
	);	
	
	-- trigger questionnaire returned message to the supplier
	message_pkg.TriggerMessage (
		in_primary_lookup           => CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_RETURNED ELSE chain_pkg.COMP_QUESTIONNAIRE_RETURNED END,
		in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
		in_to_company_sid           => in_qnr_owner_company_sid,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => company_pkg.GetCompany,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id					
	);

	-- trigger questionnaire returned message to the purchaser
	message_pkg.TriggerMessage (
		in_primary_lookup           => CASE WHEN in_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_RETURNED ELSE chain_pkg.COMP_QUESTIONNAIRE_RETURNED END,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid,
		in_re_user_sid              => security_pkg.GetSid,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class),
		in_re_component_id			=> in_component_id					
	);
	
END;

PROCEDURE ReSendQuestionnaire (
	in_questionnaire_share_id	IN	questionnaire_share.questionnaire_share_id%TYPE,
	in_due_by_dtm				IN	questionnaire_share.due_by_dtm%TYPE
)
AS
	v_qnr_owner_company_sid		security_pkg.T_SID_ID;
	v_share_with_company_sid	security_pkg.T_SID_ID;
	v_qt_class					questionnaire_type.class%TYPE;
	v_qt_id						questionnaire_type.questionnaire_type_id%TYPE;
	v_component_id				component.component_id%TYPE;
	v_share_status_id			share_status.share_status_id%TYPE;
BEGIN
	
	SELECT qs.qnr_owner_company_sid, qs.share_with_company_sid, qs.qt_class, qs.component_id,
		   qs.share_status_id, qs.questionnaire_type_id
	  INTO v_qnr_owner_company_sid, v_share_with_company_sid, v_qt_class,
		   v_component_id, v_share_status_id, v_qt_id
	  FROM v$questionnaire_share qs
	 WHERE qs.questionnaire_share_id = in_questionnaire_share_id;
	
	IF v_share_status_id = chain_pkg.NOT_SHARED THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot resend questionnaire that hasn''t been shared');
	END IF;
	
	SetQuestionnaireShareStatus(v_qnr_owner_company_sid, v_share_with_company_sid, v_qt_class, chain_pkg.SHARED_DATA_RESENT, null, v_component_id);
	SetQuestionnaireStatus(v_qnr_owner_company_sid, v_qt_class, chain_pkg.ENTERING_DATA, null, v_component_id);
	
	-- update the due date
	UPDATE questionnaire_share
	   SET due_by_dtm = in_due_by_dtm
	 WHERE questionnaire_share_id = in_questionnaire_share_id;
	
	-- Trigger messsage for supplier to fill out survey (if there isn't a message requiring action already)
	-- Delete any messages for purchaser to approve data (it's in the wrong state now)
	-- Trigger message for purchaser to say data has been resent
	
	message_pkg.DeleteMessageIfIncomplete(
		in_primary_lookup			=> CASE WHEN v_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_SUBMITTED ELSE chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED END,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> v_share_with_company_sid,
		in_re_company_sid			=> v_qnr_owner_company_sid,
		in_re_questionnaire_type_id	=> v_qt_id,
		in_re_component_id			=> v_component_id
	);
	
	-- trigger questionnaire resent message to the supplier
	message_pkg.TriggerMessage (
		in_primary_lookup           => CASE WHEN v_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_RESENT ELSE chain_pkg.COMP_QUESTIONNAIRE_RESENT END,
		in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
		in_to_company_sid           => v_qnr_owner_company_sid,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => v_share_with_company_sid,
		in_re_questionnaire_type_id => v_qt_id,
		in_re_component_id			=> v_component_id
	);

	-- trigger questionnaire resent message to the purchaser
	IF v_share_status_id != chain_pkg.SHARED_DATA_RESENT THEN
		message_pkg.TriggerMessage (
			in_primary_lookup           => CASE WHEN v_component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_RESENT ELSE chain_pkg.COMP_QUESTIONNAIRE_RESENT END,
			in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
			in_to_company_sid           => v_share_with_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => v_qnr_owner_company_sid,
			in_re_user_sid              => security_pkg.GetSid,
			in_re_questionnaire_type_id => v_qt_id,
			in_re_component_id			=> v_component_id
		);
	END IF;
	
END;

PROCEDURE GetQnnaireEnabledAlertsAppSids(
	out_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid
		  FROM customer_options
		 WHERE enable_qnnaire_reminder_alerts = 1; --used also for overdue alerts
END;

PROCEDURE AddShareAlertLog_(
	in_app_sid					IN  security_pkg.T_SID_ID,
	in_questionnaire_share_id	IN	questionnaire_share.questionnaire_share_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID,--recipient user sid
	in_std_alert_type_id		IN  qnnaire_share_alert_log.std_alert_type_id%TYPE
)
AS
BEGIN	   
	 --qnnaire_share_alert_log keeps entries for every alert sent
	INSERT INTO qnnaire_share_alert_log (app_sid, questionnaire_share_id, alert_sent_dtm, std_alert_type_id, user_sid)
		VALUES (in_app_sid, in_questionnaire_share_id, SYSDATE, in_std_alert_type_id, in_user_sid);

END;

/* Gets all active, registered company users*/
FUNCTION GetAllCompanyUsers_(
	in_app_sid	IN  security_pkg.T_SID_ID
) RETURN T_NUMERIC_TABLE /* T_NUMERIC_ROW <item, pos>  */
AS 
	v_result 	T_NUMERIC_TABLE; 
BEGIN

	SELECT T_NUMERIC_ROW(company_sid, user_sid)
	  BULK COLLECT INTO v_result
	  FROM ( --inline a more lightweight version of CHAIN.v$company_user (exclude join with csr.csr_user)
		SELECT cug.company_sid, cu.user_sid
		  FROM v$company_user_group cug 
		  JOIN security.group_members gm ON (cug.user_group_sid = gm.group_sid_id)
		  JOIN chain_user cu ON (gm.member_sid_id = cu.user_sid)
		  JOIN security.user_table ut ON (cu.user_sid = ut.sid_id)
		 WHERE cu.registration_status_id = 1
		   AND ut.account_enabled = 1
		   AND cu.deleted = 0
		);
	
	/* SELECT T_NUMERIC_ROW(company_sid, user_sid)
	  BULK COLLECT INTO v_result
	  FROM v$company_user
	 WHERE app_sid = in_app_sid
	   AND registration_status_id = 1
	   AND account_enabled = 1; */
	   
	RETURN v_result;
END;

/* Gets not shared questionnaires when reminder or ovedue alerts (based on passing arg) is enabled */
FUNCTION CollectQnrShares_(
	in_app_sid					IN  security_pkg.T_SID_ID,
	in_used_for_reminder		IN NUMBER,
	in_used_for_overdue			IN NUMBER
) RETURN T_QNNAIRER_SHARE_TABLE /* T_QNNAIRER_SHARE_ROW */
AS
	v_result  T_QNNAIRER_SHARE_TABLE; 
BEGIN
	--todo: add support for component_id
	SELECT T_QNNAIRER_SHARE_ROW(
		qs.questionnaire_share_id, 
		qs.questionnaire_type_id, 
		qs.due_by_dtm, 
		qs.qnr_owner_company_sid, 
		qt.edit_url,
		qt.reminder_offset_days,
		qt.name,
		qs.entry_dtm, 
		NULL, --SHARE_STATUS_NAME,
		qs.component_id, --component_id,
		qs.component_description
	)
	  BULK COLLECT INTO v_result
	  FROM ( --inline a more lightweight version of CHAIN.v$questionnaire_share
		SELECT q.app_sid, 
			   q.questionnaire_type_id, 
		       qs.due_by_dtm, 
			   qs.qnr_owner_company_sid,  
			   qs.questionnaire_share_id, 
			   qs.reminder_sent_dtm, 
			   qs.overdue_sent_dtm, 
			   qsle.share_status_id,
			   qsle.entry_dtm,
			   cmp.component_id,
			   cmp.description component_description
		  FROM questionnaire q
		  JOIN questionnaire_share qs ON (q.app_sid = qs.app_sid AND q.questionnaire_id = qs.questionnaire_id)
		  JOIN qnr_share_log_entry qsle ON (qs.app_sid = qsle.app_sid AND qs.questionnaire_share_id = qsle.questionnaire_share_id)
	      JOIN company c ON (q.app_sid = c.app_sid AND q.company_sid = c.company_sid)
		  LEFT JOIN component cmp ON q.app_sid = cmp.app_sid AND q.component_id = cmp.component_id
		 WHERE q.app_sid = in_app_sid
		   AND c.deleted = 0
		   AND c.pending = 0
		   AND (qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   			 GROUP BY questionnaire_share_id
			)
	  ) qs
	  JOIN questionnaire_type qt ON (qs.app_sid = qt.app_sid AND qs.questionnaire_type_id = qt.questionnaire_type_id)
	 WHERE qs.app_sid = in_app_sid	 
	   AND qs.share_status_id = chain_pkg.NOT_SHARED --not shared (not submitted)
	   AND (
			(in_used_for_reminder = 1 AND qt.enable_reminder_alert = 1 AND qs.reminder_sent_dtm IS NULL) --reminders enabled and no reminder sent before
		OR 
			(in_used_for_overdue = 1 AND qt.enable_overdue_alert = 1 AND qs.overdue_sent_dtm IS NULL) --overdue enabled and overdue sent before
		);
		
	RETURN v_result;
END;

PROCEDURE GetRemindersOfQnnaireShares(
	in_app_sid	IN  security_pkg.T_SID_ID,
	out_cur		OUT	SYS_REFCURSOR
)
AS
	v_company_users 	T_NUMERIC_TABLE := GetAllCompanyUsers_(in_app_sid); /* gets all account-enabled and registered users for this app*/
	v_qnnaire_shares	T_QNNAIRER_SHARE_TABLE := CollectQnrShares_(in_app_sid => in_app_sid, in_used_for_reminder => 1, in_used_for_overdue => 0); 
BEGIN
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ qs.name questionnaire_name, 
			   qs.edit_url questionnaire_link, 
			   qs.questionnaire_share_id, 
			   qs.due_by_dtm, 
			   qs.component_id, 
			   qs.component_description,
			   vcu.POS to_user_sid, 
			   c.company_sid to_company_sid,
			   c.name to_company_name
		  FROM TABLE(v_qnnaire_shares) qs /* not shared qnr shares (no reminder sent before)*/
		  JOIN TABLE(v_company_users) vcu ON (qs.qnr_owner_company_sid = vcu.ITEM) /* enabled and registered users <item, pos>:<companySid, userSid>*/
		  JOIN company c ON (qs.qnr_owner_company_sid = c.company_sid)
		  JOIN csr.temp_alert_batch_run tabr ON (vcu.POS = tabr.csr_user_sid AND in_app_sid = tabr.app_sid)
		 WHERE qs.due_by_dtm - qs.reminder_offset_days <= tabr.this_fire_time --qnnaire needs a reminder
		   AND qs.due_by_dtm > tabr.this_fire_time; --but is no overdue (in the user's local time zone)

	/* commented out due to performance issues*/			   
	--	SELECT /*+ALL_ROWS*/ qt.name questionnaire_name, 
	--		   qt.edit_url questionnaire_link, 
	--		   qs.questionnaire_share_id, 
	--		   qs.due_by_dtm, 
	--		   cu.user_sid to_user_sid, 
	--		   c.company_sid to_company_sid,
	--		   c.name to_company_name
	--	  FROM questionnaire_type qt
	--	  JOIN v$questionnaire_share qs ON (qt.questionnaire_type_id = qs.questionnaire_type_id AND qt.app_sid = qs.app_sid)
	--	  JOIN v$company_user cu ON (qs.qnr_owner_company_sid = cu.company_sid AND qs.app_sid = cu.app_sid)
	--	  JOIN v$chain_user vcu ON (cu.user_sid = vcu.user_sid) --to be removed
	--	  JOIN company c ON (qs.qnr_owner_company_sid = c.company_sid)
	--	  JOIN csr.temp_alert_batch_run tabr ON (cu.user_sid = tabr.csr_user_sid AND in_app_sid = tabr.app_sid)
	--	 WHERE qt.app_sid = in_app_sid
	--	   AND qs.reminder_sent_dtm IS NULL --no reminder sent before
	--	   AND qs.share_status_id = chain_pkg.NOT_SHARED --not shared (not submitted)
	--	   AND qt.enable_reminder_alert = 1 --when enabled
	--	   AND cu.registration_status_id = 1 --only registered users
	--	   AND vcu.account_enabled = 1 --enabled users
	--	   AND qs.due_by_dtm - qt.reminder_offset_days <= tabr.this_fire_time --qnnaire needs a reminder
	--	   AND qs.due_by_dtm > tabr.this_fire_time; --but is no overdue (in the user's local time zone)
END;

PROCEDURE RecordReminderSent(
	in_app_sid					IN  security_pkg.T_SID_ID,
	in_questionnaire_share_id	IN	questionnaire_share.questionnaire_share_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_std_alert_type_id		IN  qnnaire_share_alert_log.std_alert_type_id%TYPE
)
AS
BEGIN
	/* We send a qnnaire share alert to every registered user of the qnnaire_owner_company.
		Questionnaire_share is user-agnostic though, so by convention it keeps the last user's alert date of a batch as a reminder date */
	UPDATE questionnaire_share
	   SET reminder_sent_dtm = SYSDATE
	 WHERE app_sid = in_app_sid
	   AND questionnaire_share_id = in_questionnaire_share_id;
	
	AddShareAlertLog_(in_app_sid, in_questionnaire_share_id, in_user_sid, in_std_alert_type_id);
END;

--todo: merge this with GetReminders to a unique method
PROCEDURE GetOverduesOfQnnaireShares(
	in_app_sid	IN  security_pkg.T_SID_ID,
	out_cur		OUT	SYS_REFCURSOR
)
AS
	v_company_users 	T_NUMERIC_TABLE := GetAllCompanyUsers_(in_app_sid); /* gets all enabled and registered users for this app*/
	v_qnnaire_shares	T_QNNAIRER_SHARE_TABLE := CollectQnrShares_(in_app_sid => in_app_sid, in_used_for_reminder => 0, in_used_for_overdue => 1); 
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ qs.name questionnaire_name, 
			   qs.edit_url questionnaire_link, 
			   qs.questionnaire_share_id, 
			   qs.due_by_dtm, 
			   qs.component_id, 
			   qs.component_description,
			   vcu.POS to_user_sid, 
			   c.company_sid to_company_sid,
			   c.name to_company_name
		  FROM TABLE(v_qnnaire_shares) qs /* not shared qnr shares (no overdue sent before)*/
		  JOIN TABLE(v_company_users) vcu ON (qs.qnr_owner_company_sid = vcu.ITEM) /* enabled and registered users*/
		  JOIN company c ON (qs.qnr_owner_company_sid = c.company_sid)
		  JOIN csr.temp_alert_batch_run tabr ON (vcu.POS = tabr.csr_user_sid AND in_app_sid = tabr.app_sid)
		 WHERE qs.due_by_dtm < tabr.this_fire_time; --is overdue (in the user's local time zone)
	
	/* commented out due to performance issues*/	
	--	SELECT /*+ALL_ROWS*/ qt.name questionnaire_name, 
	--		   qt.edit_url questionnaire_link, 
	--		   qs.questionnaire_share_id, 
	--		   qs.due_by_dtm, 
	--		   cu.user_sid to_user_sid, 
	--		   c.company_sid to_company_sid,
	--		   c.name to_company_name
	--	  FROM questionnaire_type qt
	--	  JOIN v$questionnaire_share qs ON (qt.questionnaire_type_id = qs.questionnaire_type_id AND qt.app_sid = qs.app_sid)
	--	  JOIN v$company_user cu ON (qs.qnr_owner_company_sid = cu.company_sid AND qs.app_sid = cu.app_sid)
	--	  JOIN v$chain_user vcu ON (cu.user_sid = vcu.user_sid)
	--	  JOIN company c ON (qs.qnr_owner_company_sid = c.company_sid)
	--	  JOIN csr.temp_alert_batch_run tabr ON (cu.user_sid = tabr.csr_user_sid AND in_app_sid = tabr.app_sid)
	--	 WHERE qt.app_sid = in_app_sid
	--	   AND qs.overdue_sent_dtm IS NULL --no overdue sent before
	--	   AND qs.share_status_id = chain_pkg.NOT_SHARED --not shared (not submitted)
	--	   AND qt.enable_overdue_alert = 1 --when enabled
	--	   AND cu.registration_status_id = 1 --only registered users
	--	   AND vcu.account_enabled = 1 --enabled users
	--	   AND qs.due_by_dtm < tabr.this_fire_time; --is overdue (in the user's local time zone)
END;

PROCEDURE RecordOverdueSent(
	in_app_sid					IN  security_pkg.T_SID_ID,
	in_questionnaire_share_id	IN	questionnaire_share.questionnaire_share_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_std_alert_type_id		IN  qnnaire_share_alert_log.std_alert_type_id%TYPE
)
AS
BEGIN
	/* We send a qnnaire share alert to every registered user of the qnnaire_owner_company.
		Questionnaire_share is user-agnostic though so by convention it keeps the last user's alert date of a batch as a reminder date */
	UPDATE questionnaire_share
	   SET overdue_sent_dtm = SYSDATE
	 WHERE app_sid = in_app_sid
	   AND questionnaire_share_id = in_questionnaire_share_id;
	   
	AddShareAlertLog_(in_app_sid, in_questionnaire_share_id, in_user_sid, in_std_alert_type_id);

END;

PROCEDURE GetQSQuestionnaireSubmissions(
	in_survey_sid					IN  security_pkg.T_SID_ID,
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_component_id					IN 	NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_qt_class				questionnaire_type.class%TYPE DEFAULT GetQuestionnaireTypeClass(in_survey_sid);
	v_questionnaire_id		questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_company_sid, v_qt_class, in_component_id);
BEGIN
	   
	IF NOT questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
			SELECT qss.submission_id, qss.submitted_dtm, qss.submitted_by_user_sid, cu.full_name submitted_by_user_name,
				   qsr.survey_response_id, qss.score_threshold_id, qss.overall_score, qss.overall_max_score,
				   st.description score_threshold_description, NVL(s.format_mask, '#,##0.0%') format_mask
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey qs ON qsr.survey_sid = qs.survey_sid
			  JOIN csr.supplier_survey_response ssr
				ON qsr.survey_sid = ssr.survey_sid
			   AND qsr.survey_response_id = ssr.survey_response_id
			  JOIN csr.quick_survey_submission qss
				ON qsr.survey_response_id = qss.survey_response_id
			  JOIN csr.csr_user cu
				ON cu.csr_user_sid = qss.submitted_by_user_sid
			  LEFT JOIN csr.score_type s
			    ON qs.score_type_id = s.score_type_id
			  LEFT JOIN csr.score_threshold st
				ON qss.score_threshold_id = st.score_threshold_id
			 WHERE qss.submission_id != 0 --0 is the draft submission so don't get those
			   AND qsr.survey_sid = in_survey_sid
			   AND ssr.supplier_sid = in_company_sid
			   AND (ssr.component_id = in_component_id OR ssr.component_id IS NULL AND in_component_id IS NULL)
		  ORDER BY qss.submitted_dtm DESC;
END;

FUNCTION IsProductQuestionnaireType(
	in_questionnaire_type_id	IN questionnaire_type.questionnaire_type_id%TYPE
)RETURN NUMBER
AS
	v_audience 				csr.quick_survey.audience%TYPE;
BEGIN

	SELECT audience 
	  INTO v_audience
	  FROM csr.quick_survey 
	 WHERE survey_sid = in_questionnaire_type_id;
	
	IF v_audience = 'chain.product' THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;

END;

-- Triggered by dbms_scheduler
PROCEDURE ExpireQuestionnaires
AS
BEGIN
	user_pkg.LogonAdmin(timeout => 1200);
	FOR r IN (
		SELECT qs.app_sid, qs.questionnaire_share_id, qs.qnr_owner_company_sid, qs.share_with_company_sid,
			   qt.auto_resend_on_expiry, qs.questionnaire_id, q.component_id,
			   qt.questionnaire_type_id qnr_type_id, NVL(qt.default_overdue_days,30) due_days
		  FROM questionnaire_share qs
		  JOIN questionnaire q ON qs.questionnaire_id = q.questionnaire_id AND qs.app_sid = q.app_sid
		  JOIN questionnaire_type qt ON q.questionnaire_type_id = qt.questionnaire_type_id AND q.app_sid = qt.app_sid
		 WHERE expiry_dtm < SYSDATE
		   AND expiry_sent_dtm IS NULL
	) LOOP
		security_pkg.SetApp(r.app_sid);
		
		-- Ensure built-in admin is a chain_user
		helper_pkg.AddUserToChain(SYS_CONTEXT('SECURITY','SID'));
		
		BEGIN
			-- tell purchaser questionnaire has expired
			message_pkg.TriggerMessage (
				in_primary_lookup           => CASE WHEN r.component_id IS NULL THEN chain_pkg.QUESTIONNAIRE_EXPIRED ELSE chain_pkg.COMP_QUESTIONNAIRE_EXPIRED END,
				in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
				in_to_company_sid           => r.share_with_company_sid,
				in_to_user_sid              => chain_pkg.FOLLOWERS,
				in_re_company_sid           => r.qnr_owner_company_sid,
				in_re_questionnaire_type_id => r.qnr_type_id,
				in_re_component_id			=> r.component_id
			);
			
			IF r.auto_resend_on_expiry = 1 THEN
				-- We need a due date, if there's no default on the questionnaire_type then pick 30 days
				ReSendQuestionnaire(r.questionnaire_share_id, sysdate + r.due_days);
				
				FOR u IN (
					SELECT user_sid
					  FROM v$company_user
					 WHERE registration_status_id = 1
					   AND account_enabled = 1
					   AND company_sid = r.qnr_owner_company_sid
				) LOOP
					-- Send alert to all registered users of that company (same rules as overude alerts,
					-- but in future may want to restrict to roles or invitation_to_user_sid)
					BEGIN
						INSERT INTO questionnaire_expiry_alert (questionnaire_share_id, user_sid)
						VALUES (r.questionnaire_share_id, u.user_sid);
					EXCEPTION
						WHEN DUP_VAL_ON_INDEX THEN
							NULL; -- no need to send twice
					END;
				END LOOP;
			END IF;
			
			chain_link_pkg.QuestionnaireExpired(r.questionnaire_id, r.share_with_company_sid, r.qnr_owner_company_sid);
			
			UPDATE questionnaire_share
			   SET expiry_sent_dtm = SYSDATE
			 WHERE questionnaire_share_id = r.questionnaire_share_id;
			
			COMMIT;
		EXCEPTION
			WHEN OTHERS THEN
				-- rollback first
				ROLLBACK;

				-- aspen2.error_pkg runs on an autonomous transaction
				aspen2.error_pkg.LogError('Error running chain.questionnaire_pkg.ExpireQuestionnaires for app_sid: '||r.app_sid||
					', questionnaire_share_id: '||r.questionnaire_share_id||' ERR: '||SQLERRM||chr(10)||
					dbms_utility.format_error_backtrace);
		END;
	END LOOP;
	security_pkg.SetApp(NULL);
	security.user_pkg.LogOff(security_pkg.GetAct);
END;

-- Called by scheduled task
PROCEDURE GetExpiryAlerts (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT qea.app_sid, qea.user_sid, qea.questionnaire_share_id, qs.share_with_company_sid,
			   fc.name share_with_company_name, qs.qnr_owner_company_sid, tc.name qnr_owner_company_name,
			   co.support_email, qs.questionnaire_name
		  FROM questionnaire_expiry_alert qea
		  JOIN v$questionnaire_share qs ON qea.app_sid = qs.app_sid AND qea.questionnaire_share_id = qs.questionnaire_share_id
		  JOIN company fc ON qs.app_sid = fc.app_sid AND qs.share_with_company_sid = fc.company_sid
		  JOIN company tc ON qs.app_sid = tc.app_sid AND qs.qnr_owner_company_sid = tc.company_sid
		  JOIN customer_options co ON qs.app_sid = co.app_sid
		 ORDER BY qea.app_sid, qea.user_sid, qea.questionnaire_share_id;
END;

-- Called by scheduled task
PROCEDURE MarkExpiryAlertSent (
	in_questionnaire_share_id	IN	questionnaire_expiry_alert.questionnaire_share_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM questionnaire_expiry_alert
	 WHERE questionnaire_share_id = in_questionnaire_share_id
	   AND user_sid = in_user_sid;
	COMMIT;
END;

FUNCTION IsTransitionAlertsEnabled(
	in_questionnaire_type_id	IN questionnaire_type.questionnaire_type_id%TYPE
)RETURN NUMBER
AS
	v_is_enabled	NUMBER;
BEGIN
	SELECT enable_transition_alert
	  INTO v_is_enabled
	  FROM questionnaire_type
	 WHERE app_sid = security_pkg.getApp
	   AND questionnaire_type_id = in_questionnaire_type_id;
	
	RETURN v_is_enabled;
END;

PROCEDURE GetReturnedQnrRecipients(
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_component_id				IN	component.component_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_user_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_questionnaire_id		questionnaire.questionnaire_id%TYPE DEFAULT GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class, in_component_id);
	v_current_status 		chain_pkg.T_SHARE_STATUS DEFAULT GetQuestionnaireShareStatus(in_qnr_owner_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_qt_class, in_component_id);
BEGIN
	IF v_current_status <> chain_pkg.SHARED_DATA_RETURNED THEN
		RAISE_APPLICATION_ERROR(-20001, 'Questionnaire with class:'||in_qt_class||' and owner company:'||in_qnr_owner_company_sid||' and component_id:'||in_component_id||' is not in a returned share status');
	END IF;
		
	-- the following never worked for a scheme that employed a standard capability check as capabilities checks are always carried out 
	-- against the context company as the primary company.
	-- Supporting a behaviour where we can ask for capabilities a company different than the context holds
	-- requires a change in the very core of supply chain permissions and it's not worth doing
	-- Identify as recipient the user that made the last submission instead is a reasonable work-around
	--	FOR r IN ( 
	--		SELECT user_sid
	--			FROM v$company_user
	--			WHERE company_sid = in_qnr_owner_company_sid
	--	)
	--	LOOP
	--		IF questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain_pkg.QUESTIONNAIRE_EDIT, r.user_sid, in_qnr_owner_company_sid) THEN
	--			v_user_sids_t.extend;
	--			v_user_sids_t(v_user_sids_t.COUNT) := r.user_sid;
	--		END IF;
	--	END LOOP;

	SELECT user_sid
	  BULK COLLECT INTO v_user_sids_t
	  FROM (
		SELECT qsle.user_sid
		  FROM questionnaire q
		  JOIN questionnaire_share qs ON q.app_sid = qs.app_sid AND q.questionnaire_id = qs.questionnaire_id
		  JOIN qnr_share_log_entry qsle ON qs.app_sid = qsle.app_sid AND qs.questionnaire_share_id = qsle.questionnaire_share_id
		 WHERE q.questionnaire_id = v_questionnaire_id
		   AND qsle.company_sid = in_qnr_owner_company_sid 
		 ORDER BY qsle.share_log_entry_index DESC
		) x
	 WHERE rownum = 1;
	 
	OPEN out_cur FOR 
		SELECT column_value user_sid
		  FROM TABLE(v_user_sids_t);
END;

END questionnaire_pkg;
/
