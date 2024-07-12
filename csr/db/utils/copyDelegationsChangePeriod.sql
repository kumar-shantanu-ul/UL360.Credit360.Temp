/*
 * Copies all delegations with given start and end dates to new start
 * and end dates.
 *
 * Note that you can use the UI to copy a single delegation
 */
DECLARE
	in_host							csr.customer.host%TYPE			:= '&&1';
	in_start_dtm					csr.delegation.start_dtm%TYPE	:= DATE '&&2';
	in_end_dtm						csr.delegation.end_dtm%TYPE		:= DATE '&&3';
	in_new_start_dtm				csr.delegation.start_dtm%TYPE	:= DATE '&&4';
	in_new_end_dtm					csr.delegation.end_dtm%TYPE		:= DATE '&&5';
	
	v_act_id						security.security_pkg.T_ACT_ID;
	v_inds							security.security_pkg.T_SID_IDS;
	v_regs							security.security_pkg.T_SID_IDS;
	v_deleg_cur						csr.delegation_pkg.T_OVERLAP_DELEG_CUR;
	v_deleg_inds_cur				csr.delegation_pkg.T_OVERLAP_DELEG_INDS_CUR;
	v_deleg_regs_cur				csr.delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR;
	v_overlap_rec					csr.delegation_pkg.T_OVERLAP_DELEG_REC;
	v_new_deleg_cursor				SYS_REFCURSOR;
	v_from_sid						security.security_pkg.T_SID_ID;
	v_to_sid						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonAdmin(in_host);
	v_act_id := security.security_pkg.GetACT;
	
	FOR r_d IN (
		SELECT delegation_sid, parent_sid, name, period_set_id, period_interval_id
		  FROM csr.delegation
		 WHERE parent_sid = app_sid AND start_dtm = in_start_dtm AND end_dtm = in_end_dtm
	) LOOP
		SELECT ind_sid
		  BULK COLLECT INTO v_inds
		  FROM csr.delegation_ind
		 WHERE delegation_sid = r_d.delegation_sid;
		 
		SELECT region_sid
		  BULK COLLECT INTO v_regs
		  FROM csr.delegation_region
		 WHERE delegation_sid = r_d.delegation_sid;
		 
		csr.delegation_pkg.ExFindOverlaps(
			in_act_id				=> v_act_id,
			in_delegation_sid		=> r_d.delegation_sid,
			in_ignore_self			=> 1,
			in_parent_sid			=> r_d.parent_sid,
			in_start_dtm			=> in_new_start_dtm,
			in_end_dtm				=> in_new_end_dtm,
			in_indicators_list		=> v_inds,
			in_regions_list			=> v_regs,
			out_deleg_cur			=> v_deleg_cur,
			out_deleg_inds_cur		=> v_deleg_inds_cur,
			out_deleg_regions_cur	=> v_deleg_regs_cur
		);
		
		FETCH v_deleg_cur
		 INTO v_overlap_rec;

		IF v_deleg_cur%FOUND THEN
			dbms_output.put_line('Skipping delegation ' || r_d.delegation_sid || ' (' || r_d.name || ') - overlaps found.');
		ELSE
			dbms_output.put_line('Copying delegation ' || r_d.delegation_sid || ' (' || r_d.name || ')...');
			csr.delegation_pkg.CopyDelegationChangePeriod(
				in_act_id				=> v_act_id,
				in_copy_delegation_sid	=> r_d.delegation_sid,
				in_new_name				=> r_d.name,
				in_start_dtm			=> in_new_start_dtm,
				in_end_dtm				=> in_new_end_dtm,
				in_period_set_id		=> r_d.period_set_id,
				in_period_interval_id	=> r_d.period_interval_id,
				out_cur					=> v_new_deleg_cursor
			);
			LOOP
				FETCH v_new_deleg_cursor INTO v_from_sid, v_to_sid;
				EXIT WHEN v_new_deleg_cursor%NOTFOUND;
				dbms_output.put_line(' copied ' || v_from_sid || ' to ' || v_to_sid || '.');
				csr.delegation_pkg.CreateSheetsForDelegation(v_to_sid);
			END LOOP;
		END IF;
	END LOOP;
END;
/
