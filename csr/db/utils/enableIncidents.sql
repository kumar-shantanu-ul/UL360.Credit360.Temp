
PROMPT please enter: host

DECLARE
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');
	
	csr.enable_pkg.EnableIncidents;
	COMMIT;
END;
/
