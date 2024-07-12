CREATE OR REPLACE PACKAGE BODY chain.chain_link_pkg
IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

PROCEDURE ExecuteAllProcedures (
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
);

PROCEDURE ExecuteFirstProcedure (
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
);

PROCEDURE ExecutePkgProcedure (
	in_package						IN	VARCHAR2,
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
);

PROCEDURE ExecutePkgProcedure (
	in_package						IN	VARCHAR2,
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
);

FUNCTION ExecuteFirstProcReturnCursor (
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN;

PROCEDURE ExecuteFirstProcReturnCursor (
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_success						OUT	BOOLEAN
);

PROCEDURE ExecutePkgProcReturnCursor (
	in_package						IN	VARCHAR2,
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_cur 						OUT	security_pkg.T_OUTPUT_CUR,
	out_success						OUT	BOOLEAN
);

FUNCTION ExecuteFirstFuncReturnNumber (
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN NUMBER;

FUNCTION ExecuteFirstFuncReturnDate (
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN DATE;

FUNCTION ExecutePkgFuncReturnNumber (
	in_package						IN	VARCHAR2,
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN NUMBER;

FUNCTION ExecutePkgFuncReturnDate (
	in_package						IN	VARCHAR2,
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN DATE;

FUNCTION ExecuteFirstFuncReturnNumTable (
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN T_NUMERIC_TABLE;

FUNCTION ExecFirstFuncReturnVarcharTbl (
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN T_VARCHAR_TABLE;

FUNCTION ExecFirstFuncReturnVarcharTbl (
	in_package						IN	VARCHAR2,
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
) RETURN T_VARCHAR_TABLE;

FUNCTION ExecutePkgFuncReturnNumTable (
	in_package						IN	VARCHAR2,
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
) RETURN T_NUMERIC_TABLE;


/******************************************************************
	PRIVATE WORKER METHODS
******************************************************************/
-- Getting helper_pkg by just definition ID is faster, but we should
-- remove message helper packages entirely
FUNCTION GetMessageDefHelperPkg (
	in_message_definition_id		IN	message.message_id%TYPE
) RETURN message_definition.helper_pkg%TYPE DETERMINISTIC
AS
	v_helper_pkg					message_definition.helper_pkg%TYPE;
BEGIN
	SELECT MIN(md.helper_pkg)
	  INTO v_helper_pkg
	  FROM message_definition md
	 WHERE md.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND md.message_definition_id = in_message_definition_id;

	RETURN v_helper_pkg;
END;

FUNCTION GetMessageHelperPkg (
	in_message_id					IN	message.message_id%TYPE
) RETURN message_definition.helper_pkg%TYPE
AS
	v_helper_pkg					message_definition.helper_pkg%TYPE;
BEGIN
	SELECT MIN(md.helper_pkg)
	  INTO v_helper_pkg
	  FROM message m, message_definition md
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.app_sid = md.app_sid
	   AND m.message_definition_id = md.message_definition_id;

	RETURN v_helper_pkg;
END;

FUNCTION Params (
	in_param_1						IN	VARCHAR2,
	in_param_2						IN	VARCHAR2 DEFAULT NULL,
	in_param_3						IN	VARCHAR2 DEFAULT NULL,
	in_param_4						IN	VARCHAR2 DEFAULT NULL,
	in_param_5						IN	VARCHAR2 DEFAULT NULL,
	in_param_6						IN	VARCHAR2 DEFAULT NULL
) RETURN VARCHAR2
AS
	v_out							VARCHAR2(1000);
	v_stack							T_STRING_LIST DEFAULT T_STRING_LIST(in_param_1, in_param_2, in_param_3, in_param_4, in_param_5, in_param_6);
	v_sep							VARCHAR2(2) DEFAULT '';
	v_record						BOOLEAN DEFAULT FALSE;
BEGIN

	FOR i IN REVERSE v_stack.FIRST .. v_stack.LAST
	LOOP
		IF v_stack(i) IS NOT NULL THEN
			v_record := TRUE;
		END IF;

		IF v_record THEN
			v_out := NVL(v_stack(i), 'NULL') || v_sep || v_out;
			v_sep := ', ';
		END IF;
	END LOOP;

	IF NOT v_record THEN
		RAISE_APPLICATION_ERROR(-20001, 'no parameters found');
	END IF;

	RETURN v_out;
END;

FUNCTION GetQuestionnaireLinkPkg (
	in_questionnaire_id				IN	questionnaire.questionnaire_id%TYPE
)
RETURN questionnaire_type.db_class%TYPE
AS
	v_helper_pkg					questionnaire_type.db_class%TYPE;
BEGIN
	BEGIN
		SELECT db_class
		  INTO v_helper_pkg
		  FROM v$questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_id = in_questionnaire_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	RETURN v_helper_pkg;
END;

FUNCTION GetQuestionnaireTypeLinkPkg (
	in_questionnaire_type_id		IN	questionnaire_type.questionnaire_type_id%TYPE
)
RETURN questionnaire_type.db_class%TYPE
AS
	v_helper_pkg					questionnaire_type.db_class%TYPE;
BEGIN
	BEGIN
		SELECT db_class
		  INTO v_helper_pkg
		  FROM questionnaire_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_type_id = in_questionnaire_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	RETURN v_helper_pkg;
END;


/*************************************************************************
	EXECUTE PROCEDURE
*************************************************************************/

-- Executes a procedure call against all implementation link_pkgs
PROCEDURE ExecuteAllProcedures (
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
)
AS
	v_success						BOOLEAN;
BEGIN
	FOR r IN (
		SELECT link_pkg
		  FROM implementation
		 WHERE link_pkg IS NOT NULL
		 ORDER BY execute_order
	) LOOP
		ExecutePkgProcedure(r.link_pkg, in_proc, in_variables, v_success);
	END LOOP;
END;

-- Executes a procedure call against all implementation link_pkgs, returns success flag from first call that succeeds
-- NOTE: THIS PROC WILL STOP AFTER FINDING A VALID LINK IMPLEMENTATION
PROCEDURE ExecuteFirstProcedure (
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
)
AS
BEGIN
	FOR r IN (
		SELECT link_pkg
		  FROM implementation
		 WHERE link_pkg IS NOT NULL
		 ORDER BY execute_order
	) LOOP
		ExecutePkgProcedure(r.link_pkg, in_proc, in_variables, out_success);
		IF out_success THEN
			RETURN;
		END IF;
	END LOOP;
END;

-- Executes a procedure call against a specific link_pkg
PROCEDURE ExecutePkgProcedure (
	in_package						IN	VARCHAR2,
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
)
AS
BEGIN
	IF in_package IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE (
			'BEGIN ' || in_package || '.' || in_proc || '(' || in_variables || ');END;');
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

-- Executes a procedure call against a specific link_pkg, with success output
PROCEDURE ExecutePkgProcedure (
	in_package						IN	VARCHAR2,
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
)
AS
BEGIN
	out_success := FALSE;
	IF in_package IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE (
			'BEGIN ' || in_package || '.' || in_proc || '(' || in_variables || ');END;');
			out_success := TRUE;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				--RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'NukeChain can only be run as BuiltIn/Administrator');
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

/*************************************************************************
	EXECUTE PROCEDURE RETURN CURSOR
*************************************************************************/

-- Executes a procedure call against all implementation link_pkgs, returning
-- the cursor from the first successful call that succeeds.
-- On failure, the cursor is left uninitialized and the FALSE is returned.
FUNCTION ExecuteFirstProcReturnCursor (
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_success						BOOLEAN;
BEGIN
	ExecuteFirstProcReturnCursor(in_proc, in_variables, out_cur, v_success);
	RETURN v_success;
END;

-- Executes a procedure call against all implementation link_pkgs, returning
-- the cursor from the first successful call that succeeds.
-- On failure, the cursor is left uninitialized and out_success is set to FALSE.
PROCEDURE ExecuteFirstProcReturnCursor (
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_success						OUT	BOOLEAN
)
AS
BEGIN
	out_success := FALSE;
	FOR r IN (
		SELECT link_pkg
		  FROM implementation
		 WHERE link_pkg IS NOT NULL
		 ORDER BY execute_order
	) LOOP
		ExecutePkgProcReturnCursor(r.link_pkg, in_proc, in_variables, out_cur, out_success);
		IF out_success THEN
			RETURN;
		END IF;
	END LOOP;
END;

-- Executes a procedure call using the defined link_pkg, returning the cursor if the call succeeds.
-- On failure, the cursor is left uninitialized and out_success is set to FALSE.
PROCEDURE ExecutePkgProcReturnCursor (
	in_package						IN	VARCHAR2,
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_cur 						OUT	security_pkg.T_OUTPUT_CUR,
	out_success						OUT	BOOLEAN
)
AS
	v_out_vars						VARCHAR2(100) DEFAULT ':out_cur';
	c_cursor						security_pkg.T_OUTPUT_CUR;
BEGIN
	out_success := FALSE;
	IF in_package IS NOT NULL THEN

		IF in_variables IS NOT NULL THEN
			v_out_vars := ', '||v_out_vars;
		END IF;

		BEGIN

			EXECUTE IMMEDIATE (
				'BEGIN ' || in_package || '.' || in_proc || '(' || in_variables || v_out_vars || ');END;'
			) USING c_cursor;

			out_cur := c_cursor;
			out_success := TRUE;

		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

/*************************************************************************
	EXECUTE SEARCH RETURN CURSOR
*************************************************************************/

-- Executes a procedure call that accepts a search string bind variable using the
-- defined link_pkg, returning the cursor if the call succeeds.
-- On failure, the cursor is left uninitialized and out_success is set to FALSE.
PROCEDURE ExecutePkgSearchReturnCursor (
	in_package						IN	VARCHAR2,
	in_proc							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	in_search_string				IN	VARCHAR2,
	out_cur 						OUT	security_pkg.T_OUTPUT_CUR,
	out_success						OUT	BOOLEAN
)
AS
	v_out_vars						VARCHAR2(100) DEFAULT ':search_string, :out_cur';
	c_cursor						security_pkg.T_OUTPUT_CUR;
BEGIN
	out_success := FALSE;

	IF in_package IS NOT NULL THEN

		IF in_variables IS NOT NULL THEN
			v_out_vars := ', '||v_out_vars;
		END IF;

		BEGIN
			EXECUTE IMMEDIATE (
				'BEGIN ' || in_package || '.' || in_proc || '(' || in_variables || v_out_vars || ');END;'
			) USING in_search_string, c_cursor;

			out_cur := c_cursor;
			out_success := TRUE;

		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

/*************************************************************************
	EXECUTE FUNCTION RETURN NUMBER
*************************************************************************/

-- Executes a function call against all implementation link_pkgs, returning
-- the value from the first successful call that doesn't return null.
-- Null is returned if no value can be determined.
FUNCTION ExecuteFirstFuncReturnNumber (
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN NUMBER
AS
	v_value							NUMBER(10);
BEGIN
	FOR r IN (
		SELECT link_pkg
		  FROM implementation
		 WHERE link_pkg IS NOT NULL
		 ORDER BY execute_order
	) LOOP
		v_value := ExecutePkgFuncReturnNumber(r.link_pkg, in_func, in_variables);
		IF v_value IS NOT NULL THEN
			RETURN v_value;
		END IF;
	END LOOP;

	RETURN NULL;
END;

FUNCTION ExecuteFirstFuncReturnDate (
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN DATE
AS
	v_value							DATE;
BEGIN
	FOR r IN (
		SELECT link_pkg
		  FROM implementation
		 WHERE link_pkg IS NOT NULL
		 ORDER BY execute_order
	) LOOP
		v_value := ExecutePkgFuncReturnDate(r.link_pkg, in_func, in_variables);
		IF v_value IS NOT NULL THEN
			RETURN v_value;
		END IF;
	END LOOP;

	RETURN NULL;
END;

-- Executes a function call against a specific link_pkg and returns a number or null.
FUNCTION ExecutePkgFuncReturnNumber (
	in_package						IN	VARCHAR2,
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN NUMBER
AS
	v_result						NUMBER(10) DEFAULT NULL;
BEGIN
	IF in_package IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE
				'BEGIN :result := ' || in_package || '.' || in_func || '(' || in_variables || ');END;'
			USING OUT v_result;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;

	RETURN v_result;
END;

-- Executes a function call against a specific link_pkg and returns a number or null.
FUNCTION ExecutePkgFuncReturnDate (
	in_package						IN	VARCHAR2,
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN DATE
AS
	v_result						DATE DEFAULT NULL;
BEGIN
	IF in_package IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE
				'BEGIN :result := ' || in_package || '.' || in_func || '(' || in_variables || ');END;'
			USING OUT v_result;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;

	RETURN v_result;
END;

/*************************************************************************
	EXECUTE FUNCTION RETURN VARCHAR TABLE
*************************************************************************/
FUNCTION ExecFirstFuncReturnVarcharTbl (
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN T_VARCHAR_TABLE
AS
	v_result						T_VARCHAR_TABLE := T_VARCHAR_TABLE();
	v_success						BOOLEAN;
BEGIN

	FOR r IN (
		SELECT link_pkg
		  FROM implementation
		 WHERE link_pkg IS NOT NULL
		 ORDER BY execute_order
	) LOOP
		v_result := ExecFirstFuncReturnVarcharTbl(r.link_pkg, in_func, in_variables, v_success);
		IF v_success THEN
			RETURN v_result;
		END IF;
	END LOOP;

	RETURN NULL;
END;

FUNCTION ExecFirstFuncReturnVarcharTbl (
	in_package						IN	VARCHAR2,
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
) RETURN T_VARCHAR_TABLE
AS
	v_result						T_VARCHAR_TABLE :=  T_VARCHAR_TABLE();
BEGIN
	out_success := FALSE;

	IF in_package IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE
				'BEGIN :result := ' || in_package || '.' || in_func || '(' || in_variables || ');END;'
			USING OUT v_result;
			out_success := TRUE;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;

	RETURN v_result;
END;
/*************************************************************************
	EXECUTE FUNCTION RETURN NUMBER TABLE
*************************************************************************/

-- Executes a function call against all implementation link_pkgs, returning
-- the value from the first successful call. Success is determined by function existance.
-- Null is returned if no value can be determined.
FUNCTION ExecuteFirstFuncReturnNumTable (
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2
) RETURN T_NUMERIC_TABLE
AS
	v_result						T_NUMERIC_TABLE := T_NUMERIC_TABLE();
	v_success						BOOLEAN;
BEGIN

	FOR r IN (
		SELECT link_pkg
		  FROM implementation
		 WHERE link_pkg IS NOT NULL
		 ORDER BY execute_order
	) LOOP
		v_result := ExecutePkgFuncReturnNumTable(r.link_pkg, in_func, in_variables, v_success);
		IF v_success THEN
			RETURN v_result;
		END IF;
	END LOOP;

	RETURN NULL;
END;

FUNCTION ExecutePkgFuncReturnNumTable (
	in_package						IN	VARCHAR2,
	in_func							IN	VARCHAR2,
	in_variables					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
) RETURN T_NUMERIC_TABLE
AS
	v_result						T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	out_success := FALSE;

	IF in_package IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE
				'BEGIN :result := ' || in_package || '.' || in_func || '(' || in_variables || ');END;'
			USING OUT v_result;
			out_success := TRUE;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;

	RETURN v_result;
END;

/******************************************************************
	PUBLIC IMPLEMENTATION CALLS
******************************************************************/

/******************************************************************
	ExecuteProcedure calls
******************************************************************/

PROCEDURE AddCompanyUser (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('AddCompanyUser', Params(in_company_sid, in_user_sid));
END;

PROCEDURE RemoveUserFromCompany (
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('RemoveUserFromCompany', Params(in_user_sid, in_company_sid));
END;

PROCEDURE AddCompany (
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('AddCompany', in_company_sid);
END;

PROCEDURE DeleteCompany (
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('DeleteCompany', in_company_sid);
END;

PROCEDURE VirtualDeleteCompany (
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('VirtualDeleteCompany', in_company_sid);
END;

PROCEDURE UpdateCompany (
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('UpdateCompany', in_company_sid);
END;

PROCEDURE SetTags (
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('SetTags', in_company_sid);
END;

PROCEDURE DeleteUpload (
	in_upload_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('DeleteUpload', in_upload_sid);
END;

PROCEDURE InviteCreated (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_to_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('InviteCreated', Params(in_invitation_id, in_from_company_sid, in_to_company_sid, in_to_user_sid));
END;

PROCEDURE EstablishRelationship(
	in_purchaser_sid				IN	security_pkg.T_SID_ID,
	in_supplier_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('EstablishRelationship', Params(in_purchaser_sid, in_supplier_sid));
END;

PROCEDURE DeleteRelationship (
	in_purchaser_sid				IN	security_pkg.T_SID_ID,
	in_supplier_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('DeleteRelationship', Params(in_purchaser_sid, in_supplier_sid));
END;

PROCEDURE UpdateRelationship(
	in_purchaser_sid				IN	security_pkg.T_SID_ID,
	in_supplier_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('UpdateRelationship', Params(in_purchaser_sid, in_supplier_sid));
END;

PROCEDURE QuestionnaireAdded (
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_to_user_sid					IN	security_pkg.T_SID_ID,
	in_questionnaire_id				IN	questionnaire.questionnaire_id%TYPE
)
AS
BEGIN
	ExecutePkgProcedure(GetQuestionnaireLinkPkg(in_questionnaire_id),
		'QuestionnaireAdded', Params(in_from_company_sid, in_to_company_sid, CASE WHEN in_to_user_sid IS NULL THEN 'NULL' ELSE CAST(in_to_user_sid as VARCHAR2) END, in_questionnaire_id));
END;

PROCEDURE QuestionnaireStatusChange (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_questionnaire_id				IN	questionnaire.questionnaire_id%TYPE,
	in_status_id					IN	chain_pkg.T_QUESTIONNAIRE_STATUS
)
AS
BEGIN
	ExecutePkgProcedure(GetQuestionnaireLinkPkg(in_questionnaire_id),
		'QuestionnaireStatusChange', Params(in_company_sid, in_questionnaire_id, in_status_id));
END;

PROCEDURE QuestionnaireShareStatusChange (
	in_questionnaire_id				IN	questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid		IN	security_pkg.T_SID_ID,
	in_qnr_owner_company_sid		IN	security_pkg.T_SID_ID,
	in_status						IN	chain_pkg.T_SHARE_STATUS
)
AS
BEGIN
	ExecutePkgProcedure(GetQuestionnaireLinkPkg(in_questionnaire_id),
		'QuestionnaireShareStatusChange', Params(in_questionnaire_id, in_share_with_company_sid, in_qnr_owner_company_sid, in_status));
END;

PROCEDURE QuestionnaireExpired (
	in_questionnaire_id				IN	questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid		IN	security_pkg.T_SID_ID,
	in_qnr_owner_company_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecutePkgProcedure(GetQuestionnaireLinkPkg(in_questionnaire_id),
		'QuestionnaireExpired', Params(in_questionnaire_id, in_share_with_company_sid, in_qnr_owner_company_sid));
END;

PROCEDURE QuestionnaireOverdue (
	in_questionnaire_id				IN	questionnaire.questionnaire_id%TYPE
)
AS
BEGIN
	ExecutePkgProcedure(GetQuestionnaireLinkPkg(in_questionnaire_id), 'QuestionnaireOverdue', PARAMS(in_questionnaire_id));
END;

PROCEDURE ActivateCompany(
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('ActivateCompany', in_company_sid);
END;

PROCEDURE DeactivateCompany(
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('DeactivateCompany', in_company_sid);
END;

PROCEDURE ReactivateCompany(
	in_company_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('ReactivateCompany', in_company_sid);
END;


PROCEDURE ActivateUser (
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('ActivateUser', in_user_sid);
END;

PROCEDURE DeactivateUser (
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('DeactivateUser', in_user_sid);
END;


PROCEDURE ApproveUser (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('ApproveUser', Params(in_company_sid, in_user_sid));
END;

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('ActivateRelationship', Params(in_purchaser_company_sid, in_supplier_company_sid));
END;

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('TerminateRelationship', Params(in_purchaser_company_sid, in_supplier_company_sid));
END;

PROCEDURE FindSupplierRelFlowItemId (
	in_purchaser_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid			IN	security_pkg.T_SID_ID,
	in_flow_sid						IN	security_pkg.T_SID_ID,
	out_flow_item_id				OUT	supplier_relationship.flow_item_id%TYPE
)
AS
BEGIN
	out_flow_item_id := ExecuteFirstFuncReturnNumber('FindSupplierRelFlowItemId', Params(in_purchaser_company_sid, in_supplier_company_sid, in_flow_sid));
END;

PROCEDURE AfterRelFlowItemActivate (
	in_new_item_created				IN	NUMBER,
	in_purchaser_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid			IN	security_pkg.T_SID_ID,
	in_flow_sid						IN	security_pkg.T_SID_ID,
	in_flow_item_id					IN	supplier_relationship.flow_item_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('AfterRelFlowItemActivate', Params(in_new_item_created, in_purchaser_company_sid, in_supplier_company_sid, in_flow_sid, in_flow_item_id));
END;

PROCEDURE AcceptReqQnnaireInvitation (
	in_purchaser_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('AcceptReqQnnaireInvitation', Params(in_purchaser_company_sid, in_supplier_company_sid));
END;


PROCEDURE AddProduct (
	in_product_id					IN	product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('AddProduct', in_product_id);
END;

PROCEDURE KillProduct (
	in_product_id					IN	product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('KillProduct', in_product_id);
END;

PROCEDURE CopyComponent (
	in_component_id					IN	component.component_id%TYPE,
	in_new_component_id				IN	component.component_id%TYPE,
	in_from_company_sid 			IN	security.security_pkg.T_SID_ID,
	in_to_company_sid				IN	security.security_pkg.T_SID_ID,
	in_container_component_id		IN	component.component_id%TYPE DEFAULT NULL,
	in_new_container_component_id	IN	component.component_id%TYPE DEFAULT NULL
)
AS
BEGIN
	ExecuteAllProcedures('CopyComponent', Params(in_component_id, in_new_component_id, in_from_company_sid, in_to_company_sid, in_container_component_id, in_new_container_component_id));
END;

PROCEDURE CreateNewProductRevision (
	in_product_id					IN	product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('CreateNewProductRevision', in_product_id);
END;

PROCEDURE FilterComponentTypeContainment
AS
BEGIN
	ExecuteAllProcedures('FilterComponentTypeContainment', null);
END;

PROCEDURE InvitationAccepted (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_to_company_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('InvitationAccepted', Params(in_invitation_id, in_from_company_sid, in_to_company_sid));
END;

PROCEDURE InvitationRejected (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_reason						IN	chain_pkg.T_INVITATION_STATUS
)
AS
BEGIN
	ExecuteAllProcedures('InvitationRejected', Params(in_invitation_id, in_from_company_sid, in_to_company_sid, in_reason));
END;

PROCEDURE InvitationExpired (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_to_company_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('InvitationExpired', Params(in_invitation_id, in_from_company_sid, in_to_company_sid));
END;

PROCEDURE FilterTaskCards (
	in_card_group_id				IN	card_group.card_group_id%TYPE,
	in_supplier_company_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('FilterTaskCards', Params(in_card_group_id, in_supplier_company_sid));
END;

PROCEDURE TaskStatusChanged (
	in_task_change_id				IN	task.change_group_id%TYPE,
	in_task_id						IN	task.task_id%TYPE,
	in_status_id					IN	chain_pkg.T_TASK_STATUS
)
AS
	v_db_class						task_type.db_class%TYPE;
BEGIN
	SELECT tt.db_class
	  INTO v_db_class
	  FROM task_type tt, task t
	 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tt.app_sid = t.app_sid
	   AND tt.task_type_id = t.task_type_id
	   AND t.task_id = in_task_id;

	IF v_db_class IS NOT NULL THEN
		ExecutePkgProcedure(v_db_class, 'TaskStatusChanged', Params(in_task_change_id, in_task_id, in_status_id));
	END IF;
END;

PROCEDURE TaskEntryChanged (
	in_task_change_id				IN	task.change_group_id%TYPE,
	in_task_entry_id				IN	task_entry.task_entry_id%TYPE
)
AS
	v_db_class						task_type.db_class%TYPE;
BEGIN
	SELECT tt.db_class
	  INTO v_db_class
	  FROM task_type tt, task t, task_entry te
	 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tt.app_sid = t.app_sid
	   AND tt.app_sid = te.app_sid
	   AND tt.task_type_id = t.task_type_id
	   AND t.task_id = te.task_id
	   AND te.task_entry_id = in_task_entry_id;

	IF v_db_class IS NOT NULL THEN
		ExecutePkgProcedure(v_db_class, 'TaskEntryChanged', Params(in_task_change_id, in_task_entry_id));
	END IF;
END;


PROCEDURE MessageRefreshed (
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_message_id					IN	message.message_id%TYPE,
	in_message_definition_id		IN	message.message_definition_id%TYPE
)
AS
BEGIN
	ExecutePkgProcedure(GetMessageDefHelperPkg(in_message_definition_id), 'MessageRefreshed', Params(in_to_company_sid, in_message_id));
END;

PROCEDURE MessageCreated (
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_message_id					IN	message.message_id%TYPE,
	in_message_definition_id		IN	message.message_definition_id%TYPE
)
AS
BEGIN
	ExecutePkgProcedure(GetMessageDefHelperPkg(in_message_definition_id), 'MessageCreated', Params(in_to_company_sid, in_message_id));
END;


PROCEDURE MessageCompleted (
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_message_id					IN	message.message_id%TYPE
)
AS
BEGIN
	ExecutePkgProcedure(GetMessageHelperPkg(in_message_id), 'MessageCompleted', Params(in_to_company_sid, in_message_id));
END;

PROCEDURE FilterTasksAgainstMetricType
AS
BEGIN
	ExecuteAllProcedures('FilterTasksAgainstMetricType', null);
END;

PROCEDURE ClearDuplicatesForTaskSummary
AS
BEGIN
	ExecuteAllProcedures('ClearDuplicatesForTaskSummary', null);
END;

PROCEDURE NukeChain
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'NukeChain can only be run as BuiltIn/Administrator');
	END IF;

	ExecuteAllProcedures('NukeChain', null);
END;

PROCEDURE StartWorkflowForRegion (
	in_region_sid					IN	security.security_pkg.T_SID_ID,
	in_flow_sid						IN	security.security_pkg.T_SID_ID,
	in_oracle_schema				IN	cms.tab.oracle_schema%TYPE,
	in_oracle_table					IN	cms.tab.oracle_table%TYPE,
	in_flow_item_id					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('StartWorkflowForRegion', Params(in_region_sid, in_flow_sid, '''' || in_oracle_schema || '''', '''' || in_oracle_table || '''', in_flow_item_id));
END;

PROCEDURE AuditRequested(
	in_auditor_company_sid			IN	security.security_pkg.T_SID_ID,
	in_auditee_company_sid			IN	security.security_pkg.T_SID_ID,
	in_requested_by_company_sid		IN	security.security_pkg.T_SID_ID,
	in_audit_request_id				IN	audit_request.audit_request_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('AuditRequested', Params(in_auditor_company_sid, in_auditee_company_sid, in_requested_by_company_sid, in_audit_request_id));
END;

PROCEDURE AuditRequestAuditSet(
	in_audit_request_id				IN	audit_request.audit_request_id%TYPE,
	in_auditor_company_sid			IN	security.security_pkg.T_SID_ID,
	in_auditee_company_sid			IN	security.security_pkg.T_SID_ID,
	in_audit_sid					IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('AuditRequestAuditSet', Params(in_audit_request_id, in_auditor_company_sid, in_auditee_company_sid, in_audit_sid));
END;

PROCEDURE SaveSupplierAudit(
	in_audit_sid					IN	security.security_pkg.T_SID_ID,
	in_supplier_company_sid			IN	security.security_pkg.T_SID_ID,
	in_auditor_company_sid			IN	security.security_pkg.T_SID_ID,
	in_created_by_company_sid		IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteAllProcedures('SaveSupplierAudit', Params(in_audit_sid, in_supplier_company_sid, in_auditor_company_sid, in_created_by_company_sid));
END;

PROCEDURE OnQnnairePermissionsChange(
	in_questionnaire_id				IN	chain.questionnaire.questionnaire_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('OnQnnairePermissionsChange', Params(in_questionnaire_id));
END;

PROCEDURE SupplierScoreUpdated(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_score_type_id				IN	csr.supplier_score_log.score_type_id%TYPE,
	in_score						IN	csr.supplier_score_log.score%TYPE,
	in_score_threshold_id			IN	csr.supplier_score_log.score_threshold_id%TYPE,
	in_supplier_score_id			IN	csr.supplier_score_log.score_threshold_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('SupplierScoreUpdated', Params(in_company_sid, in_score_type_id, in_score, in_score_threshold_id, in_supplier_score_id));
END;

/******************************************************************
	ExecuteProcedureReturnCursor calls
******************************************************************/

PROCEDURE GetWizardTitles (
	in_card_group_id				IN	card_group.card_group_id%TYPE,
	out_titles						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT ExecuteFirstProcReturnCursor('GetWizardTitles', in_card_group_id, out_titles) THEN
		OPEN out_titles FOR
			SELECT NULL AS WIZARD_TITLE, NULL AS WIZARD_SUB_TITLE FROM dual;
	END IF;
END;

PROCEDURE GetUnitsSuppSellsProdIn (
	in_component_id					IN	purchased_component.component_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT ExecuteFirstProcReturnCursor('GetUnitsSuppSellsProdIn', in_component_id, out_cur) THEN
		OPEN out_cur FOR
			SELECT NULL AS amount_unit_id, NULL AS description, NULL AS unit_type FROM dual;
	END IF;
END;

PROCEDURE FilterExportExtras (
	in_filtered_sids				IN	T_FILTERED_OBJECT_TABLE,
	out_cur_extras2					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT ExecuteFirstProcReturnCursor('FilterExportExtras', helper_pkg.AddFilterSidLinkLookup(in_filtered_sids), out_cur_extras2) THEN
		OPEN out_cur_extras2 FOR
			SELECT NULL company_sid, NULL column_name, NULL column_value
			  FROM dual
			 WHERE 1=0;
	END IF;
END;

PROCEDURE GetOnBehalfOfCompanies (
	in_company_sids					IN	security.T_SID_TABLE,
	out_obo_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT ExecuteFirstProcReturnCursor('GetOnBehalfOfCompanies', helper_pkg.AddSidLinkLookup(in_company_sids), out_obo_cur) THEN
		OPEN out_obo_cur FOR
			SELECT NULL company_sid, NULL obo_company_sid
			  FROM dual
			 WHERE 1=0;
	END IF;
END;

PROCEDURE GenerateCompanyUploadsData(
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_root_folder					IN	VARCHAR2,
	out_success						OUT	BOOLEAN
)
AS
BEGIN
	ExecuteFirstProcedure('GenerateCompanyUploadsData', Params(in_to_company_sid, '''' || in_root_folder || ''''), out_success);
END;

FUNCTION GetDefaultRevisionStartDate
RETURN DATE
AS
	v_revision_start_date	DATE;
BEGIN
	v_revision_start_date := ExecuteFirstFuncReturnDate('GetDefaultRevisionStartDate', NULL);
	RETURN NVL(v_revision_start_date, SYSDATE);
END;

/******************************************************************
	ExecuteSearchReturnCursor calls
******************************************************************/

PROCEDURE SearchQuestionnairesByType (
	in_questionnaire_type_id		IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_page							IN	number,
	in_page_size					IN	number,
	in_phrase						IN	VARCHAR2,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_shared_qnnaires				T_QNNAIRER_SHARE_TABLE;
	v_success						BOOLEAN;
BEGIN

	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	--todo: paging is not supported when a link package call exists(marksandspencer, chaindemo, otto_chain)
	--make link_pkg calls to return T_QNNAIRER_SHARE_TABLE (that could be tricky beacuase they call csr.supplier_pkg.SearchQuestionnairesByType)
	ExecutePkgSearchReturnCursor(GetQuestionnaireTypeLinkPkg(in_questionnaire_type_id), 'SearchQuestionnairesByType', in_questionnaire_type_id, in_phrase, out_result_cur, v_success);

	IF NOT v_success THEN
		/* Collect questionnaires shared with logged chain company */
		SELECT T_QNNAIRER_SHARE_ROW(
				qs.questionnaire_share_id,
				qt.questionnaire_type_id,
				qs.due_by_dtm,
				qs.qnr_owner_company_sid,
				qt.view_url, --piggy bag edit url
				qt.reminder_offset_days, --dont really need it
				qt.name,
				qsle.entry_dtm,
				ss.description,
				q.component_id,
				c.component_code
				)
		  BULK COLLECT INTO v_shared_qnnaires
		  FROM questionnaire_type qt
		  JOIN questionnaire q ON qt.questionnaire_type_id = q.questionnaire_type_id
		  JOIN questionnaire_share qs ON q.questionnaire_id = qs.questionnaire_id AND qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  JOIN company c ON qs.qnr_owner_company_sid = c.company_sid
		  JOIN qnr_share_log_entry qsle ON qs.questionnaire_share_id = qsle.questionnaire_share_id
		  JOIN share_status ss ON qsle.share_status_id = ss.share_status_id
		  LEFT JOIN chain.component c ON q.component_id = c.component_id
		 WHERE qt.questionnaire_type_id = in_questionnaire_type_id
		   AND LOWER(c.name) LIKE '%'||RTRIM(LTRIM(LOWER(in_phrase)))||'%'
		   AND c.deleted = 0
		   AND c.pending = 0
		   AND (qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (
				SELECT questionnaire_share_id, MAX(share_log_entry_index)
				  FROM qnr_share_log_entry
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 GROUP BY questionnaire_share_id
			);

		/* page the results */
		OPEN out_result_cur FOR
			SELECT *
			  FROM (
				SELECT c.company_sid, c.name company_name, t.name questionnaire_name, t.entry_dtm submitted_dtm,
					   t.edit_url view_url, t.share_status_name questionnaire_status_name, t.component_id, t.component_description, ROWNUM r
				  FROM TABLE(v_shared_qnnaires) t
				  JOIN company c ON t.qnr_owner_company_sid = c.company_sid
			  )
			 WHERE r >= (in_page - 1) * in_page_size + 1
		       AND r < in_page * in_page_size + 1;

		/* count the total search results found */
		OPEN out_count_cur FOR
			SELECT COUNT(*) total_count,
				   CASE WHEN in_page_size = 0 THEN 1
						ELSE CEIL(COUNT(*) / in_page_size) END total_pages
			  FROM TABLE(v_shared_qnnaires);
	ELSE
		--todo: temp solution until we support page in link_pkg too
		OPEN out_count_cur FOR
			SELECT NULL total_count, 1 total_pages
			  FROM DUAL;
	END IF;

END;


/******************************************************************
	ExecuteFuncReturnNumTable calls
******************************************************************/

FUNCTION FindProdWithUnitMismatch
RETURN T_NUMERIC_TABLE
AS
BEGIN
	RETURN ExecuteFirstFuncReturnNumTable('FindProdWithUnitMismatch', null);
END;

/* what unit of sale has a supplier entered for a product 0 has to be in link package as this could be stored in different ways - depending on the questionnaire/application */
/* or there may be no unit of sale */

/******************************************************************
	ExecuteFuncReturnNumber calls
******************************************************************/

FUNCTION GetExpectedSupplierUnitId
RETURN NUMBER
AS
BEGIN
	RETURN ExecuteFirstFuncReturnNumber('GetExpectedSupplierUnitId', null);
END;

FUNCTION GetTaskSchemeId (
	in_owner_company_sid			IN	security_pkg.T_SID_ID,
	in_supplier_company_sid			IN	security_pkg.T_SID_ID
) RETURN task_scheme.task_scheme_id%TYPE
AS
BEGIN
	RETURN ExecuteFirstFuncReturnNumber('GetTaskSchemeId', Params(in_owner_company_sid, in_supplier_company_sid));
END;

FUNCTION IsTopCompany
RETURN NUMBER
AS
BEGIN
	RETURN ExecuteFirstFuncReturnNumber('IsTopCompany', null);
END;

FUNCTION IsSidTopCompany (
	in_company_sid					IN	security_pkg.T_SID_ID
)
RETURN NUMBER
AS
BEGIN
	RETURN ExecuteFirstFuncReturnNumber('IsSidTopCompany', in_company_sid);
END;

PROCEDURE FilterCompaniesForTaskSummary (
	in_companies					IN	security.T_SID_TABLE,
	out_companies					OUT	security.T_SID_TABLE
)
AS
	v_id							tt_sid_link_lookup.id%TYPE;
BEGIN

	v_id := ExecuteFirstFuncReturnNumber('FilterCompaniesForTaskSummary', helper_pkg.AddSidLinkLookup(in_companies));

	SELECT sid
	  BULK COLLECT INTO out_companies
	  FROM tt_sid_link_lookup c
	 WHERE id = v_id;
END;

PROCEDURE OnPurchaseSaved(
	in_purchase_id					IN	purchase.purchase_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('OnPurchaseSaved', Params(in_purchase_id));
END;

PROCEDURE OnProductMapped(
	in_component_id					IN	component.component_id%TYPE,
	in_product_id					IN	product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('OnProductMapped', Params(in_component_id, in_product_id));
END;

FUNCTION GetAlterShareStatusDescr
RETURN chain.T_VARCHAR_TABLE
AS
BEGIN
	RETURN ExecFirstFuncReturnVarcharTbl('GetShareStatusDescriptions', NULL);
END;

FUNCTION CanViewUnstartedProductQnr
RETURN NUMBER
AS
BEGIN
	RETURN ExecuteFirstFuncReturnNumber('CanViewUnstartedProductQnr', NULL);
END;

PROCEDURE BusinessRelationshipCreated(
	in_bus_rel_id					IN	business_relationship.business_relationship_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('BusinessRelationshipCreated', Params(in_bus_rel_id));
END;

PROCEDURE BusinessRelationshipUpdated(
	in_bus_rel_id					IN	business_relationship.business_relationship_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('BusinessRelationshipUpdated', Params(in_bus_rel_id));
END;

PROCEDURE CompanyProductCreated(
	in_product_id				IN  company_product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('CompanyProductCreated', Params(in_product_id));
END;

PROCEDURE CompanyProductUpdated(
	in_product_id				IN  company_product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('CompanyProductUpdated', Params(in_product_id));
END;

PROCEDURE DeletingCompanyProduct(
	in_product_id				IN  company_product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('DeletingCompanyProduct', Params(in_product_id));
END;

PROCEDURE CompanyProductDeleted(
	in_product_id				IN  company_product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('CompanyProductDeleted', Params(in_product_id));
END;

PROCEDURE CompanyProductDeactivated(
	in_product_id				IN  company_product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('CompanyProductDeactivated', Params(in_product_id));
END;

PROCEDURE CompanyProductReactivated(
	in_product_id				IN  company_product.product_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('CompanyProductReactivated', Params(in_product_id));
END;

PROCEDURE ProductCertReqAdded
(
	in_product_id				IN  company_product_required_cert.product_id%TYPE,
	in_certification_type_id	IN	company_product_required_cert.certification_type_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductCertReqAdded', Params(in_product_id, in_certification_type_id));
END;

PROCEDURE ProductCertReqRemoved
(
	in_product_id				IN  company_product_required_cert.product_id%TYPE,
	in_certification_type_id	IN	company_product_required_cert.certification_type_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductCertReqRemoved', Params(in_product_id, in_certification_type_id));
END;

PROCEDURE ProductCertAdded
(
	in_product_id				IN  company_product_certification.product_id%TYPE,
	in_certification_id			IN	company_product_certification.certification_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductCertAdded', Params(in_product_id, in_certification_id));
END;

PROCEDURE ProductCertRemoved
(
	in_product_id				IN  company_product_certification.product_id%TYPE,
	in_certification_id			IN	company_product_certification.certification_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductCertRemoved', Params(in_product_id, in_certification_id));
END;

PROCEDURE ProductSupplierAdded
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductSupplierAdded', Params(in_product_supplier_id));
END;

PROCEDURE ProductSupplierUpdated
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductSupplierUpdated', Params(in_product_supplier_id));
END;

PROCEDURE ProductSupplierDeactivated
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductSupplierDeactivated', Params(in_product_supplier_id));
END;

PROCEDURE ProductSupplierReactivated
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductSupplierReactivated', Params(in_product_supplier_id));
END;

PROCEDURE RemovingProductSupplier
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('RemovingProductSupplier', Params(in_product_supplier_id));
END;

PROCEDURE ProductSupplierRemoved
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProductSupplierRemoved', Params(in_product_supplier_id));
END;

PROCEDURE ProdSuppCertAdded
(
	in_product_supplier_id		IN  product_supplier_certification.product_supplier_id%TYPE,
	in_certification_id			IN	product_supplier_certification.certification_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProdSuppCertAdded', Params(in_product_supplier_id, in_certification_id));
END;

PROCEDURE ProdSuppCertRemoved
(
	in_product_supplier_id		IN  product_supplier_certification.product_supplier_id%TYPE,
	in_certification_id			IN	product_supplier_certification.certification_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('ProdSuppCertRemoved', Params(in_product_supplier_id, in_certification_id));
END;

PROCEDURE RiskLevelUpdated(
	in_risk_level_id		IN	risk_level.risk_level_id%TYPE
)
AS
BEGIN
	ExecuteAllProcedures('RiskLevelUpdated', Params(in_risk_level_id));
END;

PROCEDURE CountryRiskLevelUpdated(
	in_risk_level_id		IN	risk_level.risk_level_id%TYPE DEFAULT NULL,
	in_country				IN	country_risk_level.country%TYPE DEFAULT NULL,
	in_dtm					IN	chain.country_risk_level.start_dtm%TYPE DEFAULT NULL
)
AS
BEGIN
	ExecuteAllProcedures('CountryRiskLevelUpdated', 
		Params(
			CASE WHEN in_risk_level_id IS NULL THEN 'NULL' ELSE CAST(in_risk_level_id as VARCHAR2) END, 
			CASE WHEN in_country IS NULL THEN 'NULL' ELSE '''' || in_country || '''' END,
			CASE WHEN in_dtm IS NULL THEN 'NULL' ELSE 'TO_DATE(''' || TO_CHAR(in_dtm, 'DD-MM-YYYY') || ''', ''DD-MM-YYYY'')' END
		));
END;

END chain_link_pkg;
/
