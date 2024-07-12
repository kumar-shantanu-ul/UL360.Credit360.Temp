create or replace package supplier.supplier_questionnaire_pkg
IS

PROCEDURE GetAnswers(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAnswers(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_csr_policy			IN supplier_answers.csr_policy%TYPE,
	in_env_policy			IN supplier_answers.env_policy%TYPE,
	in_eth_policy			IN supplier_answers.eth_policy%TYPE,
	in_bio_policy			IN supplier_answers.bio_policy%TYPE,
	in_written_procs		IN supplier_answers.written_procs%TYPE,
	in_notes				IN supplier_answers.notes%TYPE
);


PROCEDURE GetAnswersWood(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAnswersWood(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_legal_procs			IN supplier_answers_wood.legal_procs%TYPE,
	in_legal_proc_note		IN supplier_answers_wood.legal_proc_note%TYPE,
	in_declare_no_app		IN supplier_answers_wood.declare_no_app%TYPE,
	in_declare_no_cities	IN supplier_answers_wood.declare_no_cities%TYPE
);

PROCEDURE GetCompanyStatus(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	out_status				OUT all_company.company_status_id%TYPE
);

PROCEDURE SetCompanyStatus(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_status				IN all_company.company_status_id%TYPE
);

END supplier_questionnaire_pkg;
/

