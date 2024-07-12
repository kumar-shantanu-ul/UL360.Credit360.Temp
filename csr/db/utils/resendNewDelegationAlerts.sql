prompt Enter host, delegation Sid:
define host='&&1'


declare
    v_delegation_sid	security.security_pkg.T_SID_ID := &&2; 
begin
    user_pkg.logonadmin('&&host');
	FOR r in (
		select s.SHEET_ID
			from csr.delegation d 
			join csr.sheet s on s.delegation_sid = d.DELEGATION_SID AND d.START_DTM = s.START_DTM
			START WITH d.delegation_sid = v_delegation_sid
			CONNECT BY PRIOR d.delegation_sid = d.parent_sid)
	LOOP
		csr.sheet_pkg.RaiseNewSheetAlert(r.sheet_id);
	END LOOP;
	COMMIT;
END;
/