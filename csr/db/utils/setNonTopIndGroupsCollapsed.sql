PROMPT This will set all groups to start collapsed apart from the first. For all delegations which have atleast 1 delegation ind group

BEGIN
  security.user_pkg.logonadmin('&Host');

  UPDATE csr.deleg_ind_group 
	 SET start_collapsed = 0 
   WHERE deleg_ind_group_id IN (
		SELECT deleg_ind_group_id 
		  FROM csr.deleg_ind_group_member 
		 WHERE ind_sid IN (
				SELECT ind_sid
				  FROM csr.delegation_ind di
				 WHERE delegation_sid IN (SELECT DISTINCT d.delegation_sid 
										    FROM csr.delegation d JOIN csr.deleg_ind_group dig ON d.delegation_sid = dig.delegation_sid)
				   AND pos = 0)
  );
  
  UPDATE csr.deleg_ind_group 
	 SET start_collapsed = 1 
   WHERE deleg_ind_group_id NOT IN (
		SELECT deleg_ind_group_id 
		  FROM csr.deleg_ind_group_member 
		 WHERE ind_sid IN (
				SELECT ind_sid
				  FROM csr.delegation_ind di
				 WHERE delegation_sid IN (SELECT DISTINCT d.delegation_sid 
										    FROM csr.delegation d JOIN csr.deleg_ind_group dig ON d.delegation_sid = dig.delegation_sid)
				   AND pos = 0)
  );
  
  COMMIT;
END;
/
