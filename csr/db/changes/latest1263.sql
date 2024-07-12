-- Please update version.sql too -- this keeps clean builds in sync
define version=1263
@update_header

ALTER TABLE csr.qs_expr_non_compl_action DROP CONSTRAINT CHK_QS_EXPR_NC_ACT_DUE_DTM;
ALTER TABLE csr.qs_expr_non_compl_action ADD CONSTRAINT CHK_QS_EXPR_NC_ACT_DUE_DTM CHECK 
	((DUE_DTM_RELATIVE IS NULL AND DUE_DTM_RELATIVE_UNIT IS NULL) OR (DUE_DTM_RELATIVE IS NOT NULL AND DUE_DTM_RELATIVE_UNIT IS NOT NULL));

@update_tail
	