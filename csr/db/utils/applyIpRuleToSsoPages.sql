PROMPT *********************************************************
PROMPT * Use addIpRuleEntry.sql to create new IP rule entries. *
PROMPT * Use this script to apply an IP rule to the SSO pages. *
PROMPT *********************************************************

declare
	v_web_root_sid_id	security.security_pkg.T_SID_ID;
	v_parent_sid_id		security.security_pkg.T_SID_ID;
	v_page_sid_id		security.security_pkg.T_SID_ID;
	v_ip_rule_id		security.ip_rule.ip_rule_id%TYPE;
	v_parent_path		varchar2(100) := '/csr/public';
begin
	security.user_pkg.logonadmin('&&host');

	begin
		select ip_rule_id
		into v_ip_rule_id
		from security.ip_rule
		where ip_rule_id = TO_NUMBER('&&ip_rule_id');
	exception
		when NO_DATA_FOUND then
			RAISE_APPLICATION_ERROR(-20001, 'IP rule does not exist.');
	end;

	select web_root_sid_id into v_web_root_sid_id from security.website where website_name = '&&host';
	v_parent_sid_id := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_web_root_sid_id, v_parent_path);
	
	-- Create web resources if they don't exist, and set IP rule
	begin
		v_page_sid_id := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_parent_sid_id, 'authenticate.aspx');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.web_pkg.CreateResource(security.security_pkg.getACT, v_web_root_sid_id, v_parent_sid_id, 'authenticate.aspx', v_page_sid_id);
	end;
	
	update security.web_resource set ip_rule_id = v_ip_rule_id where sid_id = v_page_sid_id;
	
	begin
		v_page_sid_id := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_parent_sid_id, 'authenticate.asp');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.web_pkg.CreateResource(security.security_pkg.getACT, v_web_root_sid_id, v_parent_sid_id, 'authenticate.asp', v_page_sid_id);
	end;
	
	update security.web_resource set ip_rule_id = v_ip_rule_id where sid_id = v_page_sid_id;
	
	begin
		v_page_sid_id := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_parent_sid_id, 'authenticatewithclientcert.aspx');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.web_pkg.CreateResource(security.security_pkg.getACT, v_web_root_sid_id, v_parent_sid_id, 'authenticatewithclientcert.aspx', v_page_sid_id);
	end;
	
	update security.web_resource set ip_rule_id = v_ip_rule_id where sid_id = v_page_sid_id;

	begin
		v_page_sid_id := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, v_parent_sid_id, 'authenticatewithpassword.aspx');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.web_pkg.CreateResource(security.security_pkg.getACT, v_web_root_sid_id, v_parent_sid_id, 'authenticatewithpassword.aspx', v_page_sid_id);
	end;
	
	update security.web_resource set ip_rule_id = v_ip_rule_id where sid_id = v_page_sid_id;

end;
/
