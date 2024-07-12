SET SERVEROUTPUT ON FORMAT WRAPPED;
SET VERIFY OFF;
SET FEEDBACK OFF;
SET LIN 200;

DECLARE
	TYPE host_list_type IS TABLE OF varchar(80);
	-- update recalcInMemoryScenariosForScragTestsEndOfSprintSubset to keep the lists in sync
	host_list host_list_type := host_list_type ('centrica.credit360.com',
	                                            'dsm.credit360.com',
	                                            'gsk.credit360.com',
	                                            'heineken.credit360.com',
	                                            'heinekenehs.credit360.com',
	                                            'hm.credit360.com',
	                                            'mcd-de.credit360.com',
	                                            'mcdonalds-impact.credit360.com',
	                                            'mcdonalds-nalc.credit360.com',
	                                            'mcdonalds-palmoil.credit360.com',
	                                            'nestle.credit360.com',
	                                            'nokia.credit360.com',
	                                            'philips.credit360.com',
	                                            'sabmiller.credit360.com',
	                                            'spm.credit360.com',
	                                            'vestas.credit360.com',
	                                            'zurich.credit360.com'
	                                           );

	PROCEDURE mockRecalc(
		in_hostname     VARCHAR
	)
	AS
	BEGIN
		DBMS_OUTPUT.PUT_LINE(in_hostname);
	END;

	PROCEDURE requestRecalc(
		in_hostname	  varchar
	)
	AS
		v_calc_start_dtm				csr.customer.calc_start_dtm%TYPE;
		v_calc_end_dtm					csr.customer.calc_end_dtm%TYPE;
	BEGIN
		security.user_pkg.logonadmin(in_hostname);

		DELETE FROM csr.val_change_log
		 WHERE app_sid = SYS_CONTEXT('security','app');

		SELECT calc_start_dtm, calc_end_dtm
		  INTO v_calc_start_dtm, v_calc_end_dtm
		  FROM csr.customer;

		INSERT INTO csr.val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
			SELECT i.app_sid, i.ind_sid, v_calc_start_dtm, v_calc_end_dtm
			  FROM csr.ind i
			 WHERE i.app_sid = SYS_CONTEXT('security','app')
			 GROUP BY i.app_sid, i.ind_sid;

		DELETE FROM csr.aggregate_ind_calc_job
		 WHERE app_sid = SYS_CONTEXT('security','app');

		INSERT INTO csr.aggregate_ind_calc_job (app_sid, aggregate_ind_group_id, start_dtm, end_dtm)
			SELECT aig.app_sid, aig.aggregate_ind_group_id, c.calc_start_dtm, c.calc_end_dtm
			  FROM csr.customer c, csr.aggregate_ind_group aig
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND c.app_sid = aig.app_sid;

		-- if it's scrag++, request recalculation of in-memory scenarios
		DELETE FROM csr.scenario_auto_run_request
		 WHERE app_sid = SYS_CONTEXT('security','app');

		INSERT INTO csr.scenario_auto_run_request (app_sid, scenario_sid, full_recompute, delay_publish_scenario)
			SELECT app_sid, scenario_sid, 1, 0
			  FROM csr.scenario
			 WHERE file_based = 1
			   AND app_sid = SYS_CONTEXT('security', 'app');

		-- bump the recalc priority so these will run first when we come to recalc all in-memory scenarios later
		UPDATE csr.customer
		   SET calc_job_priority = 200
		 WHERE app_sid = SYS_CONTEXT('security', 'app');

		dbms_output.put_line('Requested recalc of ' || in_hostname);
	END;
BEGIN
    FOR i IN 1..host_list.COUNT LOOP
        requestRecalc(host_list(i));
    END LOOP;

	security.user_pkg.logonadmin();

	DBMS_OUTPUT.PUT_LINE('Now commit if everything went well');
END;
/


