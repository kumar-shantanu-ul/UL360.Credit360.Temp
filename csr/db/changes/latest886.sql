-- Please update version.sql too -- this keeps clean builds in sync
define version=886
@update_header

@../actions/ind_template_body

-- Tidy up after initiatives NPV bug
BEGIN
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer
		 WHERE app_sid IN (
		 	SELECT DISTINCT app_sid
		 	  FROM actions.ind_template
		 	 WHERE is_npv = 1
		 )
	) LOOP
		security.user_pkg.logonadmin(r.host);
		UPDATE csr.ind 
		   SET calc_fixed_start_dtm = null, 
		       calc_fixed_end_dtm = null
		 WHERE ind_sid IN (
			  SELECT ind_sid 
			    FROM csr.ind
			   WHERE app_sid = r.app_sid
			  MINUS
			  SELECT inst.ind_sid 
			    FROM actions.task_ind_template_instance inst, actions.ind_template it
			   WHERE inst.app_sid = r.app_sid
			     AND inst.from_ind_template_id = it.ind_template_id
			     AND it.is_npv = 1
		);
		security.user_pkg.logonadmin(NULL);
	END LOOP;
END;
/


@update_tail
