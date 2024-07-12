define version=2171
@update_header

begin
	for r in (select 1 from all_constraints where constraint_name='FK_QS_FILTER_COND_GEN_SURVEY' and owner='CSRIMP') loop
		execute immediate 'alter table csrimp.qs_filter_condition_general drop constraint FK_QS_FILTER_COND_GEN_SURVEY';
	end loop;
end;
/	
@update_tail