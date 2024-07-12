create or replace package supplier.score_log_pkg
IS

ID_SCORE_NON_SCORING		CONSTANT	NUMBER(10) := 0	;	
ID_SCORE_NAT_DERIVED		CONSTANT	NUMBER(10) := 1	;
ID_SCORE_CHEMICALS	        CONSTANT	NUMBER(10) := 2	;
ID_SCORE_SOURCE_BIOD	    CONSTANT	NUMBER(10) := 3	;
ID_SCORE_ACCRED_BIOD	    CONSTANT	NUMBER(10) := 4	;
ID_SCORE_FAIR_TRADE	       	CONSTANT	NUMBER(10) := 5	;
ID_SCORE_RENEW_PACK	        CONSTANT	NUMBER(10) := 6	;
ID_SCORE_WHATS_IN_PROD	    CONSTANT	NUMBER(10) := 7	;
ID_SCORE_WATER_IN_PROD	    CONSTANT	NUMBER(10) := 8	;
ID_SCORE_ENERGY_IN_PROD     CONSTANT	NUMBER(10) := 9	;
ID_SCORE_PACK_IMPACT	    CONSTANT	NUMBER(10) := 10;  
ID_SCORE_PACK_OPT	        CONSTANT	NUMBER(10) := 11;  
ID_SCORE_RECYCLED_PACK	    CONSTANT	NUMBER(10) := 12;  
ID_SCORE_SUPP_MANAGEMENT    CONSTANT	NUMBER(10) := 13;  
ID_SCORE_TRANS_RAW_MAT	    CONSTANT	NUMBER(10) := 14;  
ID_SCORE_TRANS_TO_BOOTS     CONSTANT	NUMBER(10) := 15;  
ID_SCORE_TRANS_PACKAGING    CONSTANT	NUMBER(10) := 16;  
ID_SCORE_TRANS_OPT	        CONSTANT	NUMBER(10) := 17;  
ID_SCORE_WATER_USE	        CONSTANT	NUMBER(10) := 18;  
ID_SCORE_ENERGY_USE	        CONSTANT	NUMBER(10) := 19;  
ID_SCORE_ANCILLARY_REQ	    CONSTANT	NUMBER(10) := 20;  
ID_SCORE_PROD_WASTE	        CONSTANT	NUMBER(10) := 21;  
ID_SCORE_RECYCLABLE_PACK    CONSTANT	NUMBER(10) := 22; 
ID_SCORE_RECOV_PACK	        CONSTANT	NUMBER(10) := 23;
ID_SCORE_ENERGY_DIST        CONSTANT	NUMBER(10) := 24;

AUDIT_TYPE_GT_SCORE_SAVED	CONSTANT	NUMBER(10) := 75; -- move to CSR data pkg later - as on csr release hold atm
AUDIT_TYPE_GT_SCORE_CHANGED	CONSTANT	NUMBER(10) := 76; -- move to CSR data pkg later - as on csr release hold atm
AUDIT_TYPE_GT_Q_COPIED		CONSTANT	NUMBER(10) := 77; -- move to CSR data pkg later - as on csr release hold atm

PROCEDURE LogNumValChange (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_description		IN  gt_score_log.description%TYPE,
	in_val_name			IN  gt_score_log.param_1%TYPE,
	in_val_old			IN  NUMBER, -- covers pct and 10,2
	in_val_new			IN  NUMBER -- covers pct and 10,2	
);

PROCEDURE LogYesNoValChange (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_description		IN  gt_score_log.description%TYPE,
	in_val_name			IN  gt_score_log.param_1%TYPE,
	in_val_old			IN  NUMBER, 
	in_val_new			IN  NUMBER 
);

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
);

PROCEDURE LogValChange (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_description		IN  gt_score_log.description%TYPE,
	in_val_name			IN  gt_score_log.param_1%TYPE,
	in_val_old			IN  gt_score_log.param_2%TYPE,
	in_val_new			IN  gt_score_log.param_3%TYPE
);

PROCEDURE WriteToAuditFromScoreLog (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE,
	in_old_score		IN  gt_scores.score_chemicals%TYPE, -- all the same so chose one
	in_new_score		IN  gt_scores.score_chemicals%TYPE -- all the same so chose one
);

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
);

PROCEDURE ClearLogForProductScore (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	product.product_id%TYPE,
	in_score_id			IN  gt_score_log.gt_score_type_id%TYPE
);

PROCEDURE GetScoreAuditLogForProduct (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_product_id		IN	product.product_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR 
);

PROCEDURE GetScoreAuditLogForTarget (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_product_type_id	IN	gt_product_type.gt_product_type_id%TYPE,
	in_product_range_id	IN	gt_product_answers.gt_product_range_id%TYPE,
	in_start			IN NUMBER,
	in_page_size		IN NUMBER,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END score_log_pkg;
/
