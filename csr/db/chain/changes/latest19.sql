define version=19
@update_header

declare
	v_chain security_pkg.T_SID_ID;
	v_built_in security_pkg.T_SID_ID;
	v_respondent security_pkg.T_SID_ID;
begin
user_pkg.logonadmin;
for r in (
	select app_sid from customer_options
)
loop
	v_chain := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, r.app_sid, 'Chain');

	begin
		v_built_in := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_chain, 'BuiltIn');
	exception
		when security_pkg.OBJECT_NOT_FOUND then
			securableobject_pkg.CreateSO(security_pkg.GetACT, v_chain, class_pkg.GetClassID('Container'), 'BuiltIn', v_built_in);
	end;

	begin
		v_respondent := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_built_in, 'Invitation Respondent');
	exception
		when security_pkg.OBJECT_NOT_FOUND then

			user_pkg.CreateUser(
				in_act_id						=> security_pkg.GetACT,
				in_parent_sid				=> v_built_in,
				in_login_name				=> 'Invitation Respondent',
				in_class_id					=> class_pkg.GetClassID('User'),
				in_account_expiry_enabled	=> 0,
				out_user_sid				=> v_respondent
			);

	end;
end loop;
end;
/

@..\company_body.sql

@update_tail
