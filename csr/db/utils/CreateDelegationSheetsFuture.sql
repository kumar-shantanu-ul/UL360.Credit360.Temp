-- Create sheets in the future for a delegation.
PROMPT Enter host, delegationsid and date (as YYYY-MM-DD)
PROMPT Date parameter is the maximum date to create sheets for.
DECLARE
	v_cur	SYS_REFCURSOR;
BEGIN
	security.user_pkg.logonadmin('&&1');

	csr.delegation_pkg.CreateSheetsForDelegation(&&2,0,date '&&3', v_cur);
END;
/
