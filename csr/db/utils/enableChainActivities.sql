PROMPT please enter: host
define host = '&&1'

BEGIN
	security.user_pkg.LogonAdmin('&&host');
	
	chain.setup_pkg.EnableActivities;
END;
/