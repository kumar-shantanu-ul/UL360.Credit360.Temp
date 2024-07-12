CREATE OR REPLACE PACKAGE CHAIN.company_score_pkg
IS

PROCEDURE GetCompanyTypeScoreCalcs (
	in_company_type_id				IN	chain.company_type_score_calc.company_type_id%TYPE DEFAULT NULL,
	in_score_type_id				IN	chain.company_type_score_calc.score_type_id%TYPE DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_types_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompanyTypeScoreCalc (
	in_company_type_id				IN	chain.company_type_score_calc.company_type_id%TYPE,
	in_score_type_id				IN	chain.company_type_score_calc.score_type_id%TYPE,
	in_calc_type					IN	chain.company_type_score_calc.calc_type%TYPE,
	in_operator_type				IN	chain.company_type_score_calc.operator_type%TYPE,
	in_supplier_score_type_id		IN	chain.company_type_score_calc.supplier_score_type_id%TYPE,
	in_active_suppliers_only		IN	chain.company_type_score_calc.active_suppliers_only%TYPE,
	in_sup_cmp_type_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteCompanyTypeScoreCalcs (
	in_company_type_id				IN	chain.company_type_score_calc.company_type_id%TYPE,
	in_keep_score_type_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE RecalculateCompanyScores (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_score_type_id				IN	csr.supplier_score_log.score_type_id%TYPE DEFAULT NULL,
	in_set_dtm						IN	csr.supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm				IN  csr.supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL
);

PROCEDURE UNSEC_RecalculateCompanyScores (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_score_type_id				IN	csr.supplier_score_log.score_type_id%TYPE DEFAULT NULL,
	in_set_dtm						IN	csr.supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm				IN  csr.supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL
);

PROCEDURE UNSEC_PropagateCompanyScores (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_score_type_id				IN	csr.supplier_score_log.score_type_id%TYPE DEFAULT NULL,
	in_set_dtm						IN	csr.supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm				IN  csr.supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL
);

END company_score_pkg;
/
