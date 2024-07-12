--logon as admin and set chain_company sys_context
--example @logonC m.credit360.com maersk kostas kostas 
DECLARE
	v_act security_pkg.T_ACT_ID;
	v_company_sid chain.company.company_sid%TYPE;
BEGIN
	security.user_pkg.logonAdmin('&1');
	security.user_pkg.logonFullPath(security_pkg.getapp, '//csr/users/&3', '&4', 10000, v_act); 
	SELECT company_sid
	  INTO v_company_sid
	  FROM chain.company
	 WHERE lower(name) = lower('&2');
	 
	security_pkg.setContext('CHAIN_COMPANY', v_company_sid); 
	
end;
/
