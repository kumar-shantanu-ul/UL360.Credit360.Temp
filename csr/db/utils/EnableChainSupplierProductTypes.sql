PROMPT please enter: host, top company type lookup, secondary company type lookup
define host = '&&1'
define topCompanyType = '&&2'
define secondaryCompanyType = '&&3'

BEGIN
	security.user_pkg.LogonAdmin('&&host');
	
	chain.setup_pkg.EnableSupplierProductTypes('&&topCompanyType', '&&secondaryCompanyType');
END;
/