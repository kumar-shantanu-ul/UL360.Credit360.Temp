SET SERVEROUTPUT ON FORMAT WRAPPED;
SET VERIFY OFF;
SET FEEDBACK OFF;
SET LIN 200;

DECLARE
	TYPE host_list_type IS TABLE OF varchar(80);
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
	                                            'mcdonalds.credit360.com',
	                                            'nestle.credit360.com',
	                                            'nokia.credit360.com',
	                                            'philips.credit360.com',
	                                            'sabmiller.credit360.com',
	                                            'vale.credit360.com',
	                                            'vestas.credit360.com',
	                                            'zurich.credit360.com'
	                                           );




	PROCEDURE mockRecalc(
		in_hostname     VARCHAR
	)
	AS
	BEGIN
		dbms_output.put_line(in_hostname);
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
		 WHERE app_sid = sys_context('security','app');

		SELECT calc_start_dtm, calc_end_dtm
		  INTO v_calc_start_dtm, v_calc_end_dtm
		  FROM csr.customer;

		INSERT INTO csr.val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
			SELECT i.app_sid, i.ind_sid, v_calc_start_dtm, v_calc_end_dtm
			  FROM csr.ind i
			 WHERE i.app_sid = SYS_CONTEXT('security','app')
			 GROUP BY i.app_sid, i.ind_sid;

		INSERT INTO csr.aggregate_ind_calc_job (app_sid, aggregate_ind_group_id, start_dtm, end_dtm)
			SELECT c.app_sid, aig.aggregate_ind_group_id, v_calc_start_dtm, v_calc_end_dtm
			  FROM csr.aggregate_ind_group aig
			 WHERE aig.app_sid = sys_context('security','app');

		dbms_output.put_line('Requested recalc of ' || in_hostname);
	END;
begin
    FOR i IN 1..host_list.count loop
        requestRecalc(host_list(i));
    END loop;
END;
/

