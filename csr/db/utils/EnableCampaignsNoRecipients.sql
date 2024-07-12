set echo on
whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

define host='&&1'

BEGIN
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnableCampaigns;
END;
/

COMMIT;
