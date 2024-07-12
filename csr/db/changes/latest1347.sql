-- Please update version.sql too -- this keeps clean builds in sync
define version=1347
@update_header

begin
	for r in (select owner from all_constraints where owner in ('CSR','CSRIMP') and constraint_name='CHK_QS_EXPR_ACTION_TYPE' and table_name='QUICK_SURVEY_EXPR_ACTION') loop
		execute immediate 'alter table '||r.owner||'.quick_survey_expr_action drop constraint chk_qs_expr_action_type';
	end loop;
end;
/

@update_tail
