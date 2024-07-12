-- Please update version.sql too -- this keeps clean builds in sync
define version=865
@update_header

@../actions/initiative_body

BEGIN
	FOR r IN (
		SELECT host
		  FROM csr.customer
		 WHERE host IN (
		 	'barclays.credit360.com',
		 	'mattel.credit360.com'
		 )
	) LOOP
		security.user_pkg.logonadmin(r.host);
		UPDATE actions.ind_template_group
		   SET is_group_mandatory = 0
		 WHERE app_sid = security.security_pkg.GetAPP;
		UPDATE actions.project_ind_template
		   SET is_mandatory = 1
		 WHERE app_sid = security.security_pkg.GetAPP
		   AND update_per_period = 1;
		security.user_pkg.logonadmin(NULL);
	END LOOP;
END;
/

@update_tail
