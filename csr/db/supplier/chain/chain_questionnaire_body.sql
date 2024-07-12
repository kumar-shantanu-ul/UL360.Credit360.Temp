CREATE OR REPLACE PACKAGE BODY SUPPLIER.chain_questionnaire_pkg
IS


PROCEDURE GetQuestionnaires (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	IF NOT security_pkg.IsAccessAllowedSID(
		security_pkg.GetAct(), 
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct(), security_pkg.GetApp(), 'Supplier/Companies'), 
		security_pkg.PERMISSION_READ
	) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading companies container');
	END IF;
	
	OPEN out_cur FOR
		SELECT chain_questionnaire_id, app_sid, active, friendly_name, description, edit_url, result_url, all_results_url, quick_survey_sid, view_url
		  FROM chain_questionnaire
		 WHERE app_sid = security_pkg.GetApp
		   AND NVL(active, 1) = 1
		 ORDER BY friendly_name;
END;

PROCEDURE GetStatusSummary(
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	-- TODO: this query should probably group it by company or something?
	OPEN out_cur FOR
		SELECT qrs.description response_description, count(cqr.chain_questionnaire_id) cnt
		  FROM supplier.company_questionnaire_response cqr, supplier.questionnaire_response_status qrs
		 WHERE qrs.response_status_id = cqr.response_status_id(+)
		   AND NVL(app_sid,in_app_sid) = in_app_sid
		 GROUP BY qrs.description
		 ORDER BY qrs.description;
END;

PROCEDURE GetQuestionnaire (
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	IF NOT security_pkg.IsAccessAllowedSID(
		security_pkg.GetAct(), 
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct(), security_pkg.GetApp(), 'Supplier/Companies'), 
		security_pkg.PERMISSION_READ
	) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading companies container');
	END IF;

	OPEN out_cur FOR
		SELECT chain_questionnaire_id, app_sid, active, friendly_name, description, edit_url, result_url, all_results_url, quick_survey_sid, view_url
		  FROM chain_questionnaire
		 WHERE app_sid = security_pkg.GetApp
		   AND chain_questionnaire_id = in_questionnaire_id;
END;


PROCEDURE GetQuestionnaireOutbox ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_procurer_user_sid  	IN  company_user.csr_user_sid%TYPE,
	in_procurer_company_sid	IN  company_user.company_sid%TYPE,
	in_request_status_id	IN  T_REQUEST_STATUS,	
	in_order_by				IN  T_ORDER_BY,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_from_sql				varchar2(500);
	v_where_sql				varchar2(2000);
	v_order_by_sql			varchar2(100);
	v_search_term			varchar2(2000) DEFAULT LOWER(in_search_term);
	v_procurer_company_sid 	security_pkg.T_SID_ID;
BEGIN
	
	v_procurer_company_sid := NVL(in_procurer_company_sid, company_pkg.GetCompany);
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), v_procurer_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading company with sid '||v_procurer_company_sid);
	END IF;
	
	v_search_term := LOWER(in_search_term);
	
	CASE
		WHEN in_order_by = OB_COMPANY THEN
			v_order_by_sql := ' ORDER BY supplier_company_name, questionnaire_name ';
		WHEN in_order_by = OB_QUESTIONNAIRE THEN
			v_order_by_sql := ' ORDER BY questionnaire_name, supplier_company_name ';
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'T_ORDER_BY type '||in_order_by||' is not known');
	END CASE;
			
	v_from_sql :=  '  FROM v$company_questionnaire ';
	v_where_sql := ' WHERE app_sid = :app_sid '||
					 ' AND procurer_company_sid = :company_sid '||
					 ' AND (procurer_user_sid = :user_sid '||
	        			  ' OR :user_sid IS NULL) '||
	        		 ' AND (request_status_id = :request_status '||
	        			  ' OR :request_status IS NULL) '||
	        		 ' AND (LOWER(supplier_company_name) LIKE ''%''||:search_term||''%'' '||
        				  ' OR LOWER(questionnaire_name) LIKE ''%''||:search_term||''%'') ';
      
	OPEN out_count_cur FOR
		'SELECT COUNT(*) total_result_count '||
		 v_from_sql ||
		 v_where_sql
	USING security_pkg.GetApp, v_procurer_company_sid,
		  in_procurer_user_sid, in_procurer_user_sid,
		  in_request_status_id, in_request_status_id,
		  v_search_term, v_search_term;
	
	OPEN out_result_cur FOR
		' SELECT * FROM ('||
			' SELECT a.*, rownum r '||
			  ' FROM ('||
					'SELECT * '||
					 v_from_sql ||
					 v_where_sql ||
					 v_order_by_sql ||
			        ') a'||
			 ' WHERE rownum < (:page * :page_size) + 1'|| 
		') WHERE r >= ((:page - 1) * :page_size) + 1'
	USING security_pkg.GetApp, v_procurer_company_sid,
		  in_procurer_user_sid, in_procurer_user_sid,
		  in_request_status_id, in_request_status_id,
		  v_search_term, v_search_term,
		  in_page, in_page_size,
		  in_page, in_page_size;
END;

PROCEDURE GetQuestionnaireInbox ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_supplier_user_sid  	IN  company_user.csr_user_sid%TYPE,
	in_supplier_company_sid	IN  company_user.company_sid%TYPE,
	in_request_status_id	IN  T_REQUEST_STATUS,	
	in_order_by				IN  T_ORDER_BY,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_from_sql				varchar2(500);
	v_where_sql				varchar2(2000);
	v_order_by_sql			varchar2(100);
	v_search_term			varchar2(2000) DEFAULT LOWER(in_search_term);
	v_supplier_company_sid 	security_pkg.T_SID_ID;
BEGIN
	
	v_supplier_company_sid := NVL(in_supplier_company_sid, company_pkg.GetCompany);
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), v_supplier_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading company with sid '||v_supplier_company_sid);
	END IF;
	
	CASE
		WHEN in_order_by = OB_COMPANY THEN
			v_order_by_sql := ' ORDER BY procurer_company_name, questionnaire_name ';
		WHEN in_order_by = OB_QUESTIONNAIRE THEN
			v_order_by_sql := ' ORDER BY questionnaire_name, procurer_company_name ';
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'T_ORDER_BY type '||in_order_by||' is not known');
	END CASE;
			
	v_from_sql :=  '  FROM v$company_questionnaire ';
	v_where_sql := ' WHERE app_sid = :app_sid '||
					 ' AND supplier_company_sid = :company_sid '||
					 ' AND (supplier_user_sid = :user_sid '||
	        			  ' OR :user_sid IS NULL) '||
	        		 ' AND request_status_id > 0 '||
	        		 ' AND (request_status_id = :request_status '||
	        			  ' OR :request_status IS NULL) '||
	        		 ' AND (LOWER(procurer_company_name) LIKE ''%''||:search_term||''%'' '||
        				  ' OR LOWER(questionnaire_name) LIKE ''%''||:search_term||''%'') ';
      
	OPEN out_count_cur FOR
		'SELECT COUNT(*) total_result_count '||
		 v_from_sql ||
		 v_where_sql
	USING security_pkg.GetApp, v_supplier_company_sid,
		  in_supplier_user_sid, in_supplier_user_sid,
		  in_request_status_id, in_request_status_id,
		  v_search_term, v_search_term;
	
	OPEN out_result_cur FOR
		' SELECT * FROM ('||
			' SELECT a.*, rownum r '||
			  ' FROM ('||
					'SELECT * '||
					 v_from_sql ||
					 v_where_sql ||
					 v_order_by_sql ||
			        ') a'||
			 ' WHERE rownum < (:page * :page_size) + 1'|| 
		') WHERE r >= ((:page - 1) * :page_size) + 1'
	USING security_pkg.GetApp, v_supplier_company_sid,
		  in_supplier_user_sid, in_supplier_user_sid,
		  in_request_status_id, in_request_status_id,
		  v_search_term, v_search_term,
		  in_page, in_page_size,
		  in_page, in_page_size;
END;

PROCEDURE GetQuickSurveyResults (
	in_survey_sid			IN  security_pkg.T_SID_ID,
	in_flag					IN  varchar2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_start_sql				varchar2(1000);
	v_end_sql				varchar2(1000);
	v_inner_sql				varchar2(1000);
	v_supplier_sid			security_pkg.T_SID_ID;
	v_procurer_sid			security_pkg.T_SID_ID;
	v_is_supplier			BOOLEAN DEFAULT FALSE;
	v_is_procurer			BOOLEAN DEFAULT FALSE;
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on survey sid '||in_survey_sid);
	END IF;
	
	IF in_flag IS NULL THEN
		v_procurer_sid := SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY');
		v_is_procurer := true;
	END IF;
	
	IF LOWER(in_flag) LIKE 'supplier_sid_%' THEN
		v_supplier_sid := TO_NUMBER(SUBSTR(in_flag, LENGTH('supplier_sid_')+1));
		v_procurer_sid := SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY');
		v_is_procurer := true;
	END IF;
	
	IF LOWER(in_flag) LIKE 'procurer_sid_%' THEN
		v_supplier_sid := SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY');
		v_procurer_sid := TO_NUMBER(SUBSTR(in_flag, LENGTH('procurer_sid_')+1));
		v_is_supplier := TRUE;
	END IF;


	IF NOT company_user_pkg.UserIsAuthorized(security_pkg.GetSid, SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The user with sid '||security_pkg.GetSid||' is not an authorized user of the company with sid '||SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY'));
	END IF;
		
	v_start_sql :=  'SELECT question_id, count(answer) answer_count, answer '||
					'  FROM csr.quick_survey_answer sra, csr.quick_survey_response sr '||
					' WHERE sra.survey_response_id = sr.survey_response_id '||
					'   AND sr.survey_sid = :survey_sid '||
					'   AND sr.company_sid IN ( ';

	v_end_sql :=	' ) '||
					' GROUP BY question_id, answer '||
					' ORDER BY question_id, answer ';


	IF v_is_procurer THEN
		v_inner_sql :=  'SELECT supplier_company_sid '||
						'  FROM v$company_questionnaire '||
						' WHERE quick_survey_sid = :survey_sid '||
						'   AND request_status_id = :request_status '||
						'   AND procurer_company_sid = :procurer_sid';
	END IF;
	
	IF v_is_supplier THEN
			v_inner_sql :=  'SELECT supplier_company_sid '||
							'  FROM v$company_questionnaire '||
							' WHERE quick_survey_sid = :survey_sid '||
							'   AND request_status_id = :request_status '||
							'   AND supplier_company_sid = :supplier_sid';
	END IF;

	

	
	IF v_supplier_sid IS NULL THEN
		OPEN out_cur FOR
			v_start_sql ||
			v_inner_sql ||
			v_end_sql
		USING in_survey_sid, in_survey_sid, RS_SHARED, SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY');
	ELSE
		OPEN out_cur FOR
			v_start_sql ||
			v_inner_sql ||
			' AND supplier_company_sid = :supplier_sid' ||
			v_end_sql
		USING in_survey_sid, in_survey_sid, RS_SHARED, SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY'), v_supplier_sid;
	END IF;	
END;

PROCEDURE SubmitQuestionnaire (
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE
)
AS
	v_user_sid				security_pkg.T_SID_ID default security_pkg.GetSid;
	v_company_sid			security_pkg.T_SID_ID default company_pkg.GetCompany;
BEGIN
	IF NOT company_user_pkg.UserIsAuthorized(security_pkg.GetSid, v_company_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The user with sid '||security_pkg.GetSid||' is not an authorized user of the company with sid '||v_company_sid);
	END IF;
		
	-- TODO: if an approval process ever gets put in, we'll need to change the 
	-- QRS to QRS_SUBMITTED_FOR_APPROVAL, and add appropriate messaging
	UPDATE company_questionnaire_response
	   SET response_status_id = QRS_APPPROVED_FOR_RELEASE
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = v_company_sid
	   AND chain_questionnaire_id = in_questionnaire_id;
END;

PROCEDURE ReleaseQuestionnaire (
	in_questionnaire_id		IN  chain_questionnaire.chain_questionnaire_id%TYPE,
	in_procurer_sid			IN  security_pkg.T_SID_ID
)
AS
	v_app_sid 				security_pkg.T_SID_ID default security_pkg.GetApp;
	v_user_sid				security_pkg.T_SID_ID default security_pkg.GetSid;
	v_company_sid			security_pkg.T_SID_ID default company_pkg.GetCompany;
	v_response_status		T_RESPONSE_STATUS;
	v_exists				number(10);
BEGIN
	IF NOT company_user_pkg.UserIsAuthorized(security_pkg.GetSid, v_company_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The user with sid '||security_pkg.GetSid||' is not an authorized user of the company with sid '||v_company_sid);
	END IF;

	-- check that the questionnaire is approved for release
	SELECT response_status_id
	  INTO v_response_status
	  FROM company_questionnaire_response
	 WHERE app_sid = v_app_sid
	   AND company_sid = v_company_sid
	   AND chain_questionnaire_id = in_questionnaire_id;
	   
	IF v_response_status <> QRS_APPPROVED_FOR_RELEASE THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The questionnaire '||in_questionnaire_id||' is not approved for release from company '||v_company_sid);
	END IF;

	-- check that the procurer is actually requesting the questionnaire from this company
	SELECT COUNT(*)
	  INTO v_exists
	  FROM questionnaire_request
	 WHERE app_sid = v_app_sid
	   AND procurer_company_sid = in_procurer_sid
	   AND supplier_company_sid = v_company_sid
	   AND chain_questionnaire_id = in_questionnaire_id;
	   
	IF v_exists <> 1 THEN
		-- hmmm should we throw a fit here? A graceful exit seem appropriate enough I suppose...
		RETURN;
	END IF;
	
	UPDATE questionnaire_request
	   SET request_status_id = RS_SHARED, released_dtm = SYSDATE, released_by_user_sid = v_user_sid
	 WHERE app_sid = v_app_sid
	   AND procurer_company_sid = in_procurer_sid
	   AND supplier_company_sid = v_company_sid
	   AND chain_questionnaire_id = in_questionnaire_id;
	
	-- Create the message to notify the procurer of the acceptance
	message_pkg.CreateMessage(
		message_pkg.MT_QUESTIONNAIRE_RECEIVED,
		in_procurer_sid, null, null, null,
		in_questionnaire_id,
		v_company_sid,
		message_pkg.MIDT_SUPPLIER
	);				

	-- Create the message to notify the supplier of the acceptance
	message_pkg.CreateMessage(
		message_pkg.MT_QUESTIONNAIRE_RELEASED,
		null,null, null,
		v_user_sid,
		in_questionnaire_id,
		in_procurer_sid,
		message_pkg.MIDT_PROCURER			
	);	  
	
END;

PROCEDURE SendingReminder (
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_questionnaire_id		IN  invite_questionnaire.chain_questionnaire_id%TYPE,
	out_cur_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetSid;
	v_company_sid			security_pkg.T_SID_ID DEFAULT company_pkg.GetCompany;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), company_pkg.GetCompany, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing company with sid '||company_pkg.GetCompany);
	END IF;
	
	IF NOT company_user_pkg.UserIsAuthorized(v_user_sid, v_company_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'The user with sid '||v_user_sid||' is not an authorized user of the company with sid '||v_company_sid);
	END IF;
	
	-- update the qr data
	UPDATE questionnaire_request
	   SET last_reminder_dtm = sysdate, reminder_count = reminder_count + 1
	 WHERE app_sid = security_pkg.GetApp
   	   AND procurer_company_sid = v_company_sid
   	   AND supplier_company_sid = in_supplier_sid
   	   AND chain_questionnaire_id = in_questionnaire_id;
   	
   -- get the user details of the logged on user
	company_user_pkg.GetUser(out_cur_user_cur);
	
	-- create the message
	message_pkg.CreateMessage(
		message_pkg.MT_SUPPLIER_REMINDER,
		null, null, null,
		v_user_sid,
		in_questionnaire_id,
		in_supplier_sid,
		message_pkg.MIDT_SUPPLIER			
	);

	-- get the details of the contact, invite and chain_questionnaire
	OPEN out_supplier_cur FOR
		SELECT cq.*, csru.full_name, csru.email, cu.user_profile_visibility_id 
		  FROM v$company_questionnaire cq, csr.csr_user csru, company_user cu
		 WHERE cq.app_sid = security_pkg.GetApp
		   AND cq.app_sid = csru.app_sid
		   AND cq.app_sid = cu.app_sid    
		   AND cq.procurer_company_sid = v_company_sid
		   AND cq.supplier_company_sid = in_supplier_sid
		   AND cq.chain_questionnaire_id = in_questionnaire_id
		   AND cq.supplier_user_sid = csru.csr_user_sid
		   AND cq.supplier_user_sid = cu.csr_user_sid
   		   AND cq.supplier_company_sid = cu.company_sid;
END;



END chain_questionnaire_pkg;
/



