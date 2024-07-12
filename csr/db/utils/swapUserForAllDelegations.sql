PROMPT Enter:

PROMPT 1) Host
define 	host          = "&&1"

PROMPT 2) Existing User SID to replace
define  from_user_sid = "&&2"

PROMPT 3) User SID to put in their place
define  to_user_sid   = "&&3"


declare
	v_act varchar(38);
	v_app_sid NUMBER(36);
	v_from_user_name VARCHAR(256);
	v_to_user_name VARCHAR(256);
	v_from_user_sid	security_pkg.T_SID_ID :=  &from_user_sid;
	v_to_user_sid	security_pkg.T_SID_ID := &to_user_sid;
	v_host	varchar(100) := '&host';
begin
	user_pkg.logonadmin(v_host);
	
	v_act := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT full_name 
	  INTO v_from_user_name 
	  FROM csr_user 
	 WHERE csr_user_sid = v_from_user_sid;
	 
	SELECT full_name 
	  INTO v_to_user_name 
	  FROM csr_user 
	 WHERE csr_user_sid = v_to_user_sid;
	
	FOR r IN (
		SELECT delegation_sid 
		  FROM delegation_user 
		 WHERE user_sid = v_from_user_sid
	)
	LOOP
		-- <audit>		
		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, r.delegation_sid,
			'Removed delegation user "{0}" ({1})', v_from_user_name, v_from_user_sid);		
	
		-- delete old user
		DELETE FROM delegation_user
		 WHERE user_sid = v_from_user_sid
		   AND delegation_sid = r.delegation_sid;
		group_pkg.DeleteMember(v_act, v_from_user_sid,  r.delegation_sid);
		
		-- <audit>
		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, r.delegation_sid,
			'Assigned delegation user "{0}" ({1})', v_to_user_name, v_to_user_sid);	
		
		-- assign new user
		INSERT INTO DELEGATION_USER
			(delegation_sid, user_sid)
		VALUES
			(r.delegation_sid, v_to_user_sid);
		group_pkg.AddMember(v_act, v_to_user_sid, r.delegation_sid);

	END LOOP;
	
	commit;
end;
/

exit



