PROMPT >> host
define host='&&1'
PROMPT >> company type lookup
define cmpTypeLookup='&&2'

exec security.user_pkg.logonadmin('&&host');

BEGIN
	UPDATE chain.company_type
	   SET use_user_role = 1
	 WHERE lookup_key = '&&cmpTypeLookup';
	 
	 csr.supplier_pkg.SyncCompanyTypeRoles(NULL);
END;
/

commit;
exit
