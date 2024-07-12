-- Please update version.sql too -- this keeps clean builds in sync
define version=1561
@update_header

ALTER TABLE csr.tpl_report_tag_eval_cond DROP CONSTRAINT CK_RPT_TG_EVL_COND_COMP_NN ;
ALTER TABLE csr.tpl_report_tag_eval_cond ADD CONSTRAINT CK_RPT_TG_EVL_COND_COMP_NN 
CHECK ((RIGHT_VALUE IS NOT NULL AND RIGHT_IND_SID IS NULL) OR (RIGHT_VALUE IS NULL AND RIGHT_IND_SID IS NOT NULL) OR (RIGHT_VALUE IS NULL AND RIGHT_IND_SID IS NULL AND operator IN ('N','NN'))) enable;

ALTER TABLE csr.tpl_report_tag_eval_cond DROP CONSTRAINT CK_RPT_TG_EVL_OP;
ALTER TABLE csr.tpl_report_tag_eval_cond ADD CONSTRAINT CK_RPT_TG_EVL_OP 
CHECK (operator IN ('>','<','<=','>=','=','!=','N','NN')) enable;

@update_tail
