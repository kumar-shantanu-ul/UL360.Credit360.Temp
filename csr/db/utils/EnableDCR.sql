SET SERVEROUTPUT ON;

PROMPT please enter: host

DECLARE
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');

	-- capability
	csr.csr_data_pkg.enablecapability('Allow users to raise data change requests');
END;
/

COMMIT;

SET SERVEROUTPUT OFF;

EXIT;
