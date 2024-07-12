create or replace package body supplier.supplier_questionnaire_pkg
IS

PROCEDURE GetAnswers(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading company with SID ' || in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT company_sid, csr_policy, env_policy, 
			eth_policy, bio_policy, written_procs, notes
		  FROM supplier_answers
		 WHERE company_sid = in_company_sid;
END;

PROCEDURE SetAnswers(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_csr_policy			IN supplier_answers.csr_policy%TYPE,
	in_env_policy			IN supplier_answers.env_policy%TYPE,
	in_eth_policy			IN supplier_answers.eth_policy%TYPE,
	in_bio_policy			IN supplier_answers.bio_policy%TYPE,
	in_written_procs		IN supplier_answers.written_procs%TYPE,
	in_notes				IN supplier_answers.notes%TYPE
)
AS
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing company with SID ' || in_company_sid);
	END IF;
	
	-- Just get the csr root sid from the 
	-- company as the company sid is unique
	SELECT app_sid
	  INTO v_app_sid
	  FROM all_company
	 WHERE company_sid = in_company_sid;

	BEGIN
		INSERT INTO supplier_answers
			(company_sid, csr_policy, env_policy, eth_policy, bio_policy, written_procs, notes)
			VALUES (in_company_sid, in_csr_policy, in_env_policy, in_eth_policy, in_bio_policy, in_written_procs, in_notes);
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE supplier_answers
		   SET csr_policy = in_csr_policy,
		   	   env_policy = in_env_policy,
		   	   eth_policy = in_eth_policy,
		   	   bio_policy = in_bio_policy,
		   	   written_procs = in_written_procs,
		   	   notes = in_notes
		 WHERE company_sid = in_company_sid;
	END;
END;


PROCEDURE GetAnswersWood(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading company with SID ' || in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT company_sid, legal_procs, legal_proc_note, declare_no_app, declare_no_cities
		  FROM supplier_answers_wood
		 WHERE company_sid = in_company_sid;
END;

PROCEDURE SetAnswersWood(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_legal_procs			IN supplier_answers_wood.legal_procs%TYPE,
	in_legal_proc_note		IN supplier_answers_wood.legal_proc_note%TYPE,
	in_declare_no_app		IN supplier_answers_wood.declare_no_app%TYPE,
	in_declare_no_cities	IN supplier_answers_wood.declare_no_cities%TYPE
)
AS
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing company with SID ' || in_company_sid);
	END IF;

	-- Just get the csr root sid from the 
	-- company as the company sid is unique
	SELECT app_sid
	  INTO v_app_sid
	  FROM all_company
	 WHERE company_sid = in_company_sid;

	BEGIN
		INSERT INTO supplier_answers_wood
			(company_sid, legal_procs, legal_proc_note, declare_no_app, declare_no_cities)
			VALUES (in_company_sid, in_legal_procs, in_legal_proc_note, in_declare_no_app, in_declare_no_cities);
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE supplier_answers_wood
		   SET legal_procs = in_legal_procs,
		   	   legal_proc_note = in_legal_proc_note,
		   	   declare_no_app = in_declare_no_app,
		   	   declare_no_cities = in_declare_no_cities
		 WHERE company_sid = in_company_sid;
	END;
END;


PROCEDURE GetCompanyStatus(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	out_status				OUT all_company.company_status_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading company with SID ' || in_company_sid);
	END IF;

	SELECT company_status_id
	  INTO out_status
	  FROM all_company
	 WHERE company_sid = in_company_sid;
END;

PROCEDURE SetCompanyStatus(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_status				IN all_company.company_status_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing company with SID ' || in_company_sid);
	END IF;

	UPDATE all_company
	   SET company_status_id = in_status
	 WHERE company_sid = in_company_sid;
END;

END supplier_questionnaire_pkg;
/

