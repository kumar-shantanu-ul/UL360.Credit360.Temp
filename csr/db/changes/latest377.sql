-- Please update version.sql too -- this keeps clean builds in sync
define version=377
@update_header

begin
	for r in (select table_name from user_tables where table_name in ('TPL_REPORT_TAG_EVAL_IND', 'STD_FACTOR_SET_CUSTOMER')) loop
		execute immediate 'drop table '||r.table_name;
	end loop;
end;
/

alter table customer add CONSTRAINT CK_CUST_FULLY_HIDE_SHEETS CHECK (FULLY_HIDE_SHEETS IN (0,1));

DECLARE
	v_act 			security_pkg.T_ACT_ID;
	v_class_id		security_pkg.T_CLASS_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	BEGIN	
		class_pkg.CreateClass(v_act, NULL, 'CSRAudit', 'csr.audit_pkg', NULL, v_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/

@..\create_views

@..\csr_data_pkg
@..\pending_pkg
@..\issue_pkg
@..\quick_survey_pkg
@..\audit_pkg

@..\csr_data_body
@..\pending_body
@..\issue_body
@..\quick_survey_body
@..\audit_body
grant execute on audit_pkg to web_user, security;

@update_tail
