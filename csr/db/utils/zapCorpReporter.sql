PROMPT please enter: host

-- test data
DECLARE
	v_act_id				security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID;
BEGIN
	-- log on
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	
	v_app_sid := securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.SID_ROOT, '//aspen/applications/&&1');
	security_pkg.SetACT(v_act_id, v_app_sid);
    --
	FOR r IN (SELECT 1
			FROM all_tables
		   WHERE owner = 'OWL' and table_name = 'INTERNAL_AUDIT') LOOP
	EXECUTE IMMEDIATE 
		'DELETE FROM owl.CLIENT_MODULE '||
		 'WHERE credit_module_id='||
			'(SELECT credit_module_id'|| 
			   'FROM owl.credit_module'|| 
			  'WHERE lookup_Key = ''CORP_REPORTER'')'|| 
		   'AND client_sid = v_app_sid';
	END LOOP;
	
	securableobject_pkg.deleteso(SYS_CONTEXT('SECURITY','ACT'), 
		securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/data/csr_text_admin_list2'));
END;
/
