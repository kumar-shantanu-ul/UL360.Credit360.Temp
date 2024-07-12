CREATE OR REPLACE PACKAGE BODY CSR.util_script_pkg IS



/*
	ADDING A UTIL SCRIPT HERE? Please add it to the util scripts page!
	https://fogbugz.credit360.com/default.asp?W1721
*/

PROCEDURE AssertSuperAdmin
AS
BEGIN
-- Security should be already being checked in the page but anyway.
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Functionality for super admin only.');
	END IF;
END;

PROCEDURE AddNewBranding(
	in_folder IN VARCHAR2,
	in_brandname IN VARCHAR2,
	in_author IN VARCHAR2
) 
AS
BEGIN
	csr.branding_pkg.AddBranding(in_folder, in_brandname, in_author);
END;

PROCEDURE CreateDelegationSheetsFuture(
	in_deleg_sid			NUMBER,
	in_date					VARCHAR2
)
AS
	v_cur	SYS_REFCURSOR;
BEGIN
	csr.delegation_pkg.CreateSheetsForDelegation(in_deleg_sid, 0, TO_DATE(in_date, 'YYYY-MM-DD'), 0, v_cur);
END;


PROCEDURE RecalcOneWithDates(
	in_start_dtm	DATE,
	in_end_dtm		DATE
)
AS
	v_app_sid		security.security_pkg.T_SID_ID := security.security_pkg.getApp;
BEGIN
	DELETE FROM csr.val_change_log
	 WHERE app_sid = v_app_sid;
	 
	INSERT INTO csr.val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
		SELECT i.app_sid, i.ind_sid, in_start_dtm, in_end_dtm
		  FROM csr.ind i
		 WHERE i.app_sid = v_app_sid
		 GROUP BY i.app_sid, i.ind_sid;

	INSERT INTO csr.aggregate_ind_calc_job (app_sid, aggregate_ind_group_id, start_dtm, end_dtm)
		SELECT aig.app_sid, aig.aggregate_ind_group_id, in_start_dtm, in_end_dtm
		  FROM csr.aggregate_ind_group aig
		 WHERE aig.app_sid = v_app_sid;
END;


PROCEDURE RecalcOneRestricted(
	in_start_year	NUMBER,
	in_end_year		NUMBER
)
AS
	v_calc_start_dtm	csr.customer.calc_start_dtm%TYPE;
	v_calc_end_dtm		csr.customer.calc_end_dtm%TYPE;
	v_is_clone			NUMBER;
BEGIN

	-- Don't let this run on live - this isn't an ideal mechanism perhaps, but works for now.
	-- Should there be a db flag inserted into the clones that indicates "clone"?
	-- This also stops it from running on your local laptop, but you can get around that...!
	SELECT COUNT(*)
	  INTO v_is_clone
	  FROM security.website w
	  JOIN csr.customer c ON c.app_sid = w.application_sid_id
	 WHERE application_sid_id = security.security_pkg.getApp
	   AND lower(c.host) NOT LIKE '%.com'
	   AND lower(w.website_name) NOT LIKE '%npsl.co.uk%';

	IF v_is_clone = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'This script should not be run on production databases.');
	END IF;

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM csr.customer
	 WHERE app_sid = security.security_pkg.getApp;
	
	v_calc_start_dtm := TO_DATE(EXTRACT(Day FROM v_calc_start_dtm)||'/'||EXTRACT(Month FROM v_calc_start_dtm)||'/' || in_start_year, 'dd/mm/yyyy');
	v_calc_end_dtm := TO_DATE(EXTRACT(Day FROM v_calc_end_dtm)||'/'||EXTRACT(Month FROM v_calc_end_dtm)||'/' || in_end_year, 'dd/mm/yyyy');

	UPDATE csr.customer
	   SET calc_start_dtm = v_calc_start_dtm,
		   calc_end_dtm = v_calc_end_dtm
	 WHERE app_sid = security.security_pkg.getApp;

	RecalcOneWithDates(
		in_start_dtm => v_calc_start_dtm,
		in_end_dtm => v_calc_end_dtm
	);
END;


PROCEDURE RecalcOne
AS
	v_calc_start_dtm				csr.customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					csr.customer.calc_end_dtm%TYPE;
BEGIN
	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM csr.customer;

	RecalcOneWithDates(
		in_start_dtm => v_calc_start_dtm,
		in_end_dtm => v_calc_end_dtm
	);
END;

PROCEDURE CreateImapFolder(
	in_folder_name			VARCHAR2,
	in_suffixes				VARCHAR2
)
AS
	TYPE T_DOMAINS IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
	v_client_name			VARCHAR2(255);
	v_domains				T_DOMAINS;
	v_bb_account_sid		security_pkg.T_SID_ID;
	v_bb_inbox_sid			security_pkg.T_SID_ID;
	v_client_mailbox_sid 	security_pkg.T_SID_ID;
	v_msg_filter_id			NUMBER(10);
	v_moved					NUMBER(10);
	v_run_mailbox_sids		security.security_pkg.T_SID_IDS;
	v_run_msg_filter_ids	security.security_pkg.T_SID_IDS;
	v_cnt					NUMBER(10) := 1;
BEGIN
	user_pkg.logonadmin;
	
	v_client_name := REPLACE(LOWER(in_folder_name), ' ');
	FOR r IN (
		SELECT LOWER(TRIM(item)) item FROM TABLE(aspen2.utils_pkg.SplitString(in_suffixes))
	)
	LOOP
		DBMS_OUTPUT.PUT_LINE('filtering for @'||r.item);
		v_domains(v_cnt) := '@'||r.item;
		v_cnt := v_cnt + 1;
	END LOOP;
	--v_domains(1) := '@kuoni.ch';
	--v_domains(2) := '@kuoni.com';

	SELECT account_sid, inbox_sid
	  INTO v_bb_account_sid, v_bb_inbox_sid
	  FROM mail.account
	 WHERE email_address = 'bb@credit360.com';

	-- create mailbox
	mail.mailbox_pkg.createMailbox(
		in_parent_sid_id	=> securableobject_pkg.getsidfrompath(security_pkg.getact, 0, 'Mail/Folders/bb@credit360.com/shared folders/Clients'),
		in_name				=> v_client_name,
		in_account_sid 		=> v_bb_account_sid,
		out_mailbox_sid		=> v_client_mailbox_sid
	);

	-- add filter
	mail.message_filter_pkg.saveFilter(
		in_account_sid			=> v_bb_account_sid,
		in_message_filter_id	=> null,
		in_description			=> v_client_name,
		in_match_type			=> 'any',
		in_to_mailbox_sid		=> v_client_mailbox_sid,
		in_matched_action		=> 'move',
		out_message_filter_id	=> v_msg_filter_id
	);
	
	mail.message_filter_pkg.addFilterEntry(v_msg_filter_id, 'Subject', '['||v_client_name||']', 'in');
	FOR i IN v_domains.FIRST..v_domains.LAST
	LOOP	
		DBMS_OUTPUT.PUT_LINE('adding filter for "'||v_domains(i)||'"...');
		mail.message_filter_pkg.addFilterEntry(v_msg_filter_id, 'To', v_domains(i), 'in');
		mail.message_filter_pkg.addFilterEntry(v_msg_filter_id, 'From', v_domains(i), 'in');
		mail.message_filter_pkg.addFilterEntry(v_msg_filter_id, 'Cc', v_domains(i), 'in');
	END LOOP;

	commit;
	
	-- run filter
	v_run_mailbox_sids(1) := v_bb_inbox_sid;
	v_run_msg_filter_ids(1) := v_msg_filter_id;
	mail.message_filter_pkg.runFilters(
		in_account_sid			=> v_bb_account_sid,
		in_mailbox_sids			=> v_run_mailbox_sids,
		in_message_filter_ids	=> v_run_msg_filter_ids,
		out_count_affected		=> v_moved
	);
	DBMS_OUTPUT.PUT_LINE(v_moved||' messages matched.');	
	
	commit;
END;

PROCEDURE CreateCustomDelegLayout(
	in_deleg_sid			NUMBER
)
AS
	layout_id csr.delegation_layout.layout_id%TYPE;
BEGIN
	csr.delegation_pkg.CreateLayoutTemplate( 
		XMLTYPE(
			'<table>'||chr(10)||
			'  <tbody>'||chr(10)||
			'    <tr>'||chr(10)||
			'      <td></td>'||chr(10)||
			'      <td>Unit</td>'||chr(10)||
			'      <td for="$region" in="Regions">$region</td>'||chr(10)||
			'    </tr>'||chr(10)||
			'    <tr for="$indicator" in="Indicators">'||chr(10)||
			'      <th>$indicator</th>'||chr(10)||
			'      <td conversion-id="uom" />'||chr(10)||
			'      <td for="$region" in="regions"'||chr(10)||
			'          indicator="$indicator" region="$region"'||chr(10)||
			'          conversion-ref="uom" />'||chr(10)||
			'    </tr>'||chr(10)||
			'  </tbody>'||chr(10)||
			'</table>'),
		'Auto generated layout',
		layout_id);
		
	csr.delegation_pkg.SetLayoutTemplate(in_deleg_sid, layout_id);
END;

PROCEDURE ToggleDelegMultiPeriodFlag(
	in_deleg_sid			NUMBER
)
AS
	v_new_state				NUMBER;
BEGIN

	BEGIN
		SELECT CASE allow_multi_period WHEN 1 THEN 0 ELSE 1 END
		  INTO v_new_state
		  FROM delegation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND delegation_sid = in_deleg_sid;
	   
		UPDATE delegation
		   SET allow_multi_period = v_new_state
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND delegation_sid in (
				SELECT delegation_sid
				  FROM delegation
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   CONNECT BY PRIOR delegation_sid = PARENT_SID START WITH delegation_sid = in_deleg_sid
		);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'No delegation could be found for sid; '||in_deleg_sid);
	END;

END;

PROCEDURE AddQualityFlags
AS
	v_flag_ind						csr.ind.ind_sid%TYPE;
	v_residue						NUMBER;
	v_pos							NUMBER;
	v_create 						BOOLEAN;
	v_split_count					NUMBER;
	v_xml							VARCHAR2(4000);
	v_path							VARCHAR2(4000);
	v_sheet_value_id				csr.sheet_value.sheet_value_id%TYPE;
	v_sheet_value_change_id			csr.sheet_value_change.sheet_value_change_id%TYPE;
	v_region_sid					csr.sheet_value_change.region_sid%TYPE;
	v_reason						csr.sheet_value_change.reason%TYPE;
	v_changed_by_sid				csr.sheet_value_change.changed_by_sid%TYPE;
	v_changed_dtm					csr.sheet_value_change.changed_dtm%TYPE;
	v_note							csr.sheet_value_change.note%TYPE;
	v_exists						BOOLEAN;
	v_existing_note_length			NUMBER;
	v_is_managed_content_site		NUMBER;
BEGIN
	--dbms_output.enable(NULL);

	SELECT COUNT(*)
	  INTO v_is_managed_content_site
	  FROM csr.managed_package;

	IF v_is_managed_content_site > 0 THEN
		raise_application_error(-20001, 'This site is set up for managed content. You cannot enable data quality flags on a managed content site!');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_split_count
	  FROM csr.delegation_region
	 WHERE aggregate_to_region_sid != region_sid
	   AND delegation_sid IN (SELECT delegation_sid
	   							FROM csr.delegation_ind 
	   						   WHERE ind_sid IN (SELECT ind_sid
	   						   					   FROM csr.ind_flag)); 
	IF v_split_count != 0 THEN
		raise_application_error(-20001, 'This script doesn''t work properly with regionally split delegations (sheet_inherited_value IS not handled properly)');
	END IF;
	
	FOR r IN (SELECT i.*
	  			FROM csr.v$ind i
	  		   WHERE i.ind_type = 0 
			     AND i.measure_sid IS not NULL
	  		   	 AND exists (SELECT 1 
	  		   				   FROM csr.ind_flag IF
	  		   				  WHERE i.app_sid = IF.app_sid AND i.ind_sid = IF.ind_sid))
	LOOP	  		   				  	
		INSERT INTO csr.ind_selection_group (master_ind_sid)
		VALUES (r.ind_sid);

		--dbms_output.put_line('doing '||r.description||' ('||r.ind_sid||')');
		FOR s IN (SELECT IF.description, IF.flag
					FROM csr.ind_flag IF
				   WHERE IF.ind_sid = r.ind_sid
				   UNION ALL
				  SELECT 'Unknown' description, NULL flag
				    FROM dual
				   ORDER BY flag ASC nulls LAST)
		LOOP
			v_create := TRUE;
			IF s.flag IS NULL THEN
				SELECT nvl(COUNT(*), 0)
				  INTO v_residue
				  FROM csr.sheet_value
				 WHERE ind_sid = r.ind_sid;
				SELECT nvl(COUNT(*), 0) + v_residue
				  INTO v_residue
				  FROM csr.val
				 WHERE ind_sid = r.ind_sid;
				IF v_residue != 0 THEN
					-- create an indicator FOR 'unknown' data
					dbms_output.put_line(v_residue || ' VALUES found with no quality flag, creating an "Unknown" indicator');
				ELSE
					v_create := FALSE;					
				END IF;
			END IF;		
		
			IF v_create THEN			
				csr.indicator_pkg.CreateIndicator(
          			in_parent_sid_id				=> r.ind_sid,
          			in_name							=> r.name || '_' || LOWER(s.description),
					in_description					=> r.description || ' - ' || s.description,
					in_active						=> r.active,
					in_measure_sid					=> r.measure_sid,
					in_multiplier					=> r.multiplier,
					in_scale						=> r.scale,
					in_format_mask					=> r.format_mask,
					in_target_direction				=> r.target_direction,
					in_gri							=> r.gri,
					in_pos							=> s.flag,
					in_info_xml						=> r.info_xml,
					in_divisibility					=> r.divisibility,
					in_start_month					=> r.start_month,
					in_ind_type         			=> r.ind_type,
          			in_aggregate					=> r.aggregate,
					in_is_gas_ind					=> CASE WHEN r.factor_type_id IS NOT NULL THEN 1 ELSE 0 END,
					in_factor_type_id				=> r.factor_type_id,
					in_gas_measure_sid				=> r.gas_measure_sid,
          			in_gas_type_id					=> r.gas_type_id,
					in_core							=> r.core,
					in_roll_forward					=> r.roll_forward,
					in_normalize					=> r.normalize,
					in_prop_down_region_tree_sid	=> r.prop_down_region_tree_sid,
					in_is_system_managed			=> 1,
					in_lookup_key					=> r.lookup_key,
          			in_calc_output_round_dp			=> r.calc_output_round_dp,
					out_sid_id						=> v_flag_ind);
	
				IF s.flag IS NULL THEN
					SELECT nvl(max(pos), 0) + 1
					  INTO v_pos
					  FROM csr.ind_selection_group_member
					 WHERE master_ind_sid = ind_sid;
				ELSE
					v_pos := s.flag;
				END IF;	 				

				INSERT INTO csr.ind_selection_group_member (master_ind_sid, ind_sid, pos)
				VALUES (r.ind_sid, v_flag_ind, v_pos);

				INSERT INTO csr.ind_sel_group_member_desc (ind_sid, lang, description)
				SELECT v_flag_ind, cl.lang, s.description
				FROM csr.v$customer_lang cl;
							
				-- Insert the new ind INTO all delegations that had the old ind
				-- Explicitly SET the new flag indicators to hide as we don't want them visible IN the sheets/delegations
				INSERT INTO csr.delegation_ind (delegation_sid, ind_sid, pos, visibility)
					SELECT delegation_sid, v_flag_ind, di.pos, 'HIDE'
					  FROM csr.delegation_ind di
					 WHERE di.ind_sid = r.ind_sid;
					 
				--dbms_output.put_line(r.description || ' - ' || s.description || ' added to '||sql%rowcount||' delegations');
				
				-- move data
				UPDATE csr.sheet_value
				   SET ind_sid = v_flag_ind, flag = NULL
				 WHERE ind_sid = r.ind_sid 
				   AND ((flag IS NULL AND s.flag IS NULL) OR flag = s.flag);
				--dbms_output.put_line(sql%rowcount || ' sheet_value rows moved');
				UPDATE csr.sheet_value_change
				   SET ind_sid = v_flag_ind, flag = NULL
				 WHERE ind_sid = r.ind_sid
				   AND ((flag IS NULL AND s.flag IS NULL) OR flag = s.flag);
				--dbms_output.put_line(sql%rowcount || ' sheet_value_change rows moved');
				IF s.flag IS NULL THEN
					UPDATE csr.val
					   SET ind_sid = v_flag_ind
					 WHERE ind_sid = r.ind_sid;
				END IF;
			END IF;
		END LOOP;
				
		DELETE FROM csr.ind_flag 
		 WHERE ind_sid = r.ind_sid;
		 
		-- move any notes OR attachments to the calc
		FOR s IN (SELECT sheet_value_id, sheet_id, ind_sid, region_sid, set_by_user_sid, set_dtm, note, status, var_expl_note, last_sheet_value_change_id, length(note) note_length
					FROM csr.sheet_value
				   WHERE ind_sid IN (SELECT ind_sid
				   					   FROM csr.ind_selection_group_member
				   					  WHERE master_ind_sid = r.ind_sid))
		LOOP
			v_exists := FALSE;
			BEGIN
				INSERT INTO csr.sheet_value 
					(sheet_value_id, sheet_id, ind_sid, region_sid, set_by_user_sid, set_dtm, note, status, var_expl_note)
				VALUES 
					(csr.sheet_value_id_seq.nextval, s.sheet_id, r.ind_sid, s.region_sid, s.set_by_user_sid, s.set_dtm, s.note, s.status, s.var_expl_note)
				returning
					sheet_value_id INTO v_sheet_value_id;
			EXCEPTION
				WHEN dup_val_on_index THEN
					v_exists := TRUE;
					-- duplicate, so we have a more recent value against the calc
					-- IF the calc value doesn't have a note, AND the old value did THEN copy it over
					SELECT sheet_value_id, nvl(LENGTH(note),0) note_length
					  INTO v_sheet_value_id, v_existing_note_length
					  FROM csr.sheet_value
					 WHERE sheet_id = s.sheet_id 
					   AND ind_sid = r.ind_sid
					   AND region_sid = s.region_sid;
					   
					IF v_existing_note_length = 0 AND s.note_length > 0 THEN
						--dbms_output.put_line('SET note '||s.note||' against '||v_sheet_value_id||' FROM '||s.sheet_value_id);
						UPDATE csr.sheet_value
						   SET note = s.note
						 WHERE sheet_value_id = v_sheet_value_id;
					END IF;
			END;

			IF NOT v_exists THEN
				--dbms_output.put_line('fetch data FOR '||s.last_sheet_value_change_id);
				BEGIN
					SELECT region_sid, reason, changed_by_sid, changed_dtm, note
					  INTO v_region_sid, v_reason, v_changed_by_sid, v_changed_dtm, v_note
					  FROM csr.sheet_value_change
					 WHERE sheet_value_change_id = s.last_sheet_value_change_id;
				EXCEPTION
					WHEN no_data_found THEN
						-- weird, I thought last_sheet_value_change_id used to have a deferred not NULL constraint on it
						v_region_sid := s.region_sid;
						v_reason := 'New value';
						v_changed_by_sid := 3; 
						v_changed_dtm := s.set_dtm;
						v_note := s.note;
				END LOOP;

				INSERT INTO csr.sheet_value_change 
					(sheet_value_change_id, sheet_value_id, ind_sid, region_sid, reason, changed_by_sid, changed_dtm, note)
				VALUES
					(csr.sheet_value_change_id_seq.nextval, v_sheet_value_id, s.ind_sid, v_region_sid, v_reason, v_changed_by_sid, v_changed_dtm, v_note)
				returning
					sheet_value_change_id INTO v_sheet_value_change_id;
					 
				UPDATE csr.sheet_value
				   SET last_sheet_value_change_id = v_sheet_value_change_id
				 WHERE sheet_value_id = v_sheet_value_id;
			END IF;
 
			-- move any files over to the calc
			--dbms_output.put_line('moving files FROM '||s.sheet_value_id||' to '||v_sheet_value_id);
			FOR t IN (SELECT file_upload_sid
						FROM csr.sheet_value_file
					   WHERE sheet_value_id = s.sheet_value_id)
			LOOP
				--dbms_output.put_line('move file ' ||t.file_upload_sid||' FROM '||s.sheet_value_id||' to '||v_sheet_value_id);
				BEGIN
					UPDATE csr.sheet_value_file
					   SET sheet_value_id = v_sheet_value_id
					 WHERE sheet_value_id = s.sheet_value_id
					   AND file_upload_sid = t.file_upload_sid;
				EXCEPTION
					WHEN dup_val_on_index THEN
						-- happens IF the file exists on more than one child indicator
						NULL; 
				END;
			END LOOP;
		END LOOP;
		 		
		v_xml := NULL;
		FOR s IN (SELECT ind_sid 
					FROM csr.ind_selection_group_member isg
				   WHERE master_ind_sid = r.ind_sid
				   ORDER BY pos)
		LOOP
				   	
			v_path := '<path sid="' || s.ind_sid || '" />';
			IF v_xml IS NULL THEN
				v_xml := v_path;
			ELSE
				v_xml := '<add><left>' || v_xml || '</left><right>' || v_path || '</right></add>';
			END IF;
		END LOOP;
		
		csr.calc_pkg.SetCalcXMLAndDeps(
			SYS_CONTEXT('SECURITY', 'ACT'),
			r.ind_sid,
			v_xml,
			0,
			r.period_set_id,
			r.period_interval_id,
			0,
			NULL
		);
		
		IF r.factor_type_id IS not NULL THEN
			csr.indicator_pkg.CreateGasIndicators(r.ind_sid);
		END IF;
	END LOOP;
	
	UPDATE csr.customer
	   SET ind_selections_enabled = 1, unmerged_consistent = 1
	 WHERE app_sid = sys_context('security', 'app');
	 
	 -- Resync ind selection flags IN VAL with those on the sheets.
	 FOR r IN (
		SELECT v.ind_sid AS val_ind_sid, sv.ind_sid AS sv_ind_sid, v.val_id
		  FROM csr.val v
		  JOIN csr.sheet_value sv
		    ON v.source_id = sv.sheet_value_id
		 WHERE ((sv.entry_val_number IS NOT NULL
					AND sv.entry_val_number = v.entry_val_number
					AND DECODE(v.entry_measure_conversion_id, sv.entry_measure_conversion_id, 1) = 1
				)
				OR (sv.entry_val_number IS NULL
					AND sv.val_number = v.val_number)
		   )
		AND v.region_sid = sv.region_sid
		AND v.source_type_id = 1
		AND v.ind_sid != sv.ind_sid
	)
	LOOP
		--dbms_output.put_line('#Moving ind:'||r.val_ind_sid||' to: '||r.sv_ind_sid||' FOR val: '||r.val_id);
		UPDATE csr.val
		SET ind_sid = r.sv_ind_sid
		WHERE val_id = r.val_id;
	END LOOP;
END;

PROCEDURE SetStartMonth(
	in_start_month				NUMBER,
	in_start_year				NUMBER,
	in_end_year					NUMBER
)
AS
	v_act_id					security_pkg.T_ACT_ID;
	v_curr_reporting_period_sid	security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_potential_probs			NUMBER(10);
BEGIN
	v_act_id := security_pkg.getact;
	v_app_sid := security.security_pkg.getApp;

	SELECT current_reporting_period_sid
	  INTO v_curr_reporting_period_sid
	  FROM csr.customer
	 WHERE app_sid = v_app_sid;

	-- set sec obj
	UPDATE csr.customer
	   SET start_month = in_start_month
	 WHERE app_sid = v_app_Sid;

	-- alter any months for all indicators
	UPDATE csr.ind
	   SET start_month = in_start_month 
	 WHERE app_sid = v_app_sid;

	-- update current reporting period
	UPDATE csr.reporting_period
	   SET start_dtm = TO_DATE('1/'||in_start_month||'/' || in_start_year, 'dd/mm/yyyy'),
	   	end_dtm = TO_DATE('1/'||in_start_month||'/' || in_end_year, 'dd/mm/yyyy')
	 WHERE reporting_period_sid = v_curr_reporting_period_sid;

	-- now check if values are out of synch
	-- TODO: check delegations? forms?
	SELECT COUNT(*)
	  INTO v_potential_probs
	  FROM csr.val v
	  JOIN csr.ind i ON v.ind_sid = i.ind_sid AND v.app_sid = i.app_sid
	 WHERE (
		-- quarterly
		period_end_dtm = add_months(period_start_dtm, 3)
		AND mod(extract(month from period_start_dtm), 3) != mod(in_start_month, 3)
	 ) OR (
		-- halfly
		period_end_dtm = add_months(period_start_dtm, 6)
		AND mod(extract(month from period_start_dtm), 6) != mod(in_start_month, 6)
	 ) OR (
		-- annually
		period_end_dtm = add_months(period_start_dtm, 12)
		AND extract(month from period_start_dtm) != in_start_month
	 ) OR (
		-- weirdly
		MONTHS_BETWEEN(period_end_dtm, period_start_dtm) NOT IN (1, 3, 6, 12)
	 );

	IF v_potential_probs > 0 then
		RAISE_APPLICATION_ERROR(-20001, '========= '||v_potential_probs||' potential values out of synch if you make this change - cancelled =======');
	END IF;
	COMMIT;
END;

PROCEDURE AddMissingAlert(
	in_std_alert_type_id		NUMBER
)
AS
	v_customer_alert_type_id NUMBER;
	v_app_sid 				 NUMBER;
	v_alert_frame_id		 NUMBER;
BEGIN
	v_app_sid := security.security_pkg.getApp;

	-- Get the next value for customer alert type
	SELECT csr.customer_alert_type_id_seq.nextval INTO v_customer_alert_type_id
	  FROM dual;

	-- Add in the new customer alert type
	INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
	 	 VALUES (v_customer_alert_type_id, in_std_alert_type_id);
		 
	-- Get the default alert frame
	SELECT MAX(alert_frame_id)
	  INTO v_alert_frame_id
	  FROM csr.alert_frame
	 WHERE name = 'Default';

	-- and the default templates
	INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		 VALUES (v_app_sid, v_customer_alert_type_id, v_alert_frame_id, 'manual');

	-- Add the body template for each language in the app translation_set
	FOR r IN (
		SELECT lang
		  FROM aspen2.translation_set
		 WHERE application_sid = v_app_sid
	)
	LOOP
		-- Add the template body for this customer copied from default template body
		INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			 SELECT v_app_sid, v_customer_alert_type_id, r.lang, subject, body_html, item_html
			   FROM csr.default_alert_template_body
			  WHERE std_alert_type_id = in_std_alert_type_id;
	END LOOP;
END;

PROCEDURE SetToleranceChkrMergedDataReq(
	in_setting			NUMBER
)
AS
	v_app_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	
	UPDATE csr.customer
	   SET tolerance_checker_req_merged = in_setting
	 WHERE app_sid = v_app_sid;
	
END;

PROCEDURE MapIndicatorsFromSurvey(
	in_survey_sid		NUMBER,
	in_score_type_id	NUMBER
)
AS
BEGIN
	csr.quick_survey_pkg.SynchroniseIndicators(in_survey_sid, in_score_type_id);
	csr.aggregate_ind_pkg.refreshall();
END;

PROCEDURE SetSelfRegistrationPermissions(
	in_setting				IN	NUMBER
)
AS
BEGIN
	csr.csr_data_pkg.SetSelfRegistrationPermissions(in_setting);
END;

PROCEDURE FixPropertyCompanyRegionTree(
	in_root_region_sid			IN	NUMBER
)
AS
  v_company_sid       		NUMBER(10);
  v_company_type_id   		NUMBER(10) := chain.company_type_pkg.GetDefaultCompanyTypeId;
BEGIN
	security.security_pkg.DebugMsg('Running supplier region / company fix script');

	FOR r IN (
		SELECT *
		  FROM (
			  SELECT * 
				FROM csr.v$region 
			   START WITH region_sid = in_root_region_sid --only look under this region tree node
			 CONNECT BY PRIOR region_sid = parent_sid )
		 WHERE region_type = csr_data_pkg.REGION_TYPE_SUPPLIER
		   AND region_sid NOT IN ( SELECT region_sid FROM csr.supplier )
		   AND region_sid != in_root_region_sid 
	) LOOP
		BEGIN
			--create the company from the region
			csr.supplier_pkg.AddCompanyFromRegion(
			  in_region_sid => r.region_sid, 
			  in_company_type_id => v_company_type_id, 
			  out_company_sid => v_company_sid
			);

			chain.company_pkg.ActivateCompany(v_company_sid);

			--update the properties under the company region and link them to the newly created company
			UPDATE csr.property
			   SET company_sid = v_company_sid
			 WHERE region_sid IN ( 
				SELECT p.region_sid
				  FROM csr.property p
				  JOIN csr.region rt
					ON p.region_sid = rt.region_sid
				 WHERE rt.parent_sid = r.region_sid 
				);
				
			--go through all users that have region start points pointing at a supplier region and try to add them to the existing companies
			FOR r IN (
				SELECT *
				  FROM csr.region_start_point rsp
				  JOIN csr.supplier s
					ON rsp.region_sid = s.region_sid 
				 WHERE s.company_sid = v_company_sid
			) LOOP
				chain.company_user_pkg.AddUserToCompany(r.company_sid, r.user_sid);
			END LOOP;
		EXCEPTION
			WHEN OTHERS THEN
				DECLARE 
					v_err_msg	VARCHAR2(255);
				BEGIN
					v_err_msg := SUBSTR(SQLERRM, 1, 255);
					security.security_pkg.DebugMsg('Error processing region sid '||r.region_sid||'. '||v_err_msg);
				END;
		END;
	END LOOP;

	security.security_pkg.DebugMsg('Supplier region / company fix script finished running');
END;

PROCEDURE EnableMeterWashingMachine
AS
BEGIN
	BEGIN
		INSERT INTO metering_options (meter_page_url, analytics_months, analytics_current_month, period_set_id, period_interval_id) 
		VALUES ('/csr/site/meter/view.acds', NULL, 0, 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE metering_options
			   SET meter_page_url = '/csr/site/meter/view.acds'
			 WHERE app_sid = security_pkg.GetApp;
	END;
	
	-- Relevant issue types.
	BEGIN
		INSERT INTO csr.issue_type (app_sid, issue_type_id, label)
			VALUES (security.security_pkg.GetAPP, csr.csr_data_pkg.ISSUE_METER, 'Meter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE SynchScoreTypeAggTypes
AS
BEGIN
	-- Create Audit score agg types for combinations that don't already exist
	FOR r IN (
		SELECT anal_funcs.analytic_function, score_types.score_type_id,
			   score_types.applies_to_nc_score, score_types.applies_to_primary_audit_survy,
			   score_types.applies_to_audits, score_types.ia_type_survey_group_id
		  FROM (
			SELECT chain.filter_pkg.AFUNC_MIN analytic_function FROM dual
			 UNION SELECT chain.filter_pkg.AFUNC_MAX FROM dual
			 UNION SELECT chain.filter_pkg.AFUNC_AVERAGE FROM dual
			 UNION SELECT chain.filter_pkg.AFUNC_SUM FROM dual
		  ) anal_funcs
		  CROSS JOIN (
			SELECT st.score_type_id, st.label score_type_label, a.applies_to_nc_score, a.applies_to_primary_audit_survy,
				   a.applies_to_audits, a.ia_type_survey_group_id, a.survey_group_label
			  FROM score_type st
			  JOIN (
				SELECT DISTINCT iat.nc_score_type_id score_type_id, 1 applies_to_nc_score, 0 applies_to_primary_audit_survy,
					   0 applies_to_audits, NULL ia_type_survey_group_id, NULL survey_group_label
				  FROM internal_audit_type iat
				 WHERE active = 1
				 UNION
				SELECT DISTINCT qs.score_type_id, 0, 1, 0, NULL, NULL
				  FROM internal_audit_type iat
				  JOIN quick_survey qs ON iat.app_sid = qs.app_sid AND iat.default_survey_sid = qs.survey_sid
				 WHERE iat.active = 1
				 UNION
				SELECT DISTINCT qs.score_type_id, 0, 0, 0, g.ia_type_survey_group_id, g.label
				  FROM ia_type_survey_group g
				  JOIN internal_audit_type_survey iats ON g.app_sid = iats.app_sid AND g.ia_type_survey_group_id = iats.ia_type_survey_group_id
				  JOIN quick_survey qs ON g.app_sid = qs.app_sid
				   AND (iats.survey_group_key = qs.group_key OR iats.default_survey_sid = qs.survey_sid)
				 UNION
				SELECT DISTINCT score_type_id, 0, 0, 1, NULL, NULL
				  FROM internal_audit_score
				) a ON st.score_type_id = a.score_type_id
		  ) score_types
		 MINUS 
		SELECT stat.analytic_function, stat.score_type_id, stat.applies_to_nc_score,
			   stat.applies_to_primary_audit_survy, stat.applies_to_audits, stat.ia_type_survey_group_id
		  FROM score_type_agg_type stat
		 ORDER BY applies_to_nc_score DESC, applies_to_primary_audit_survy DESC,
			   ia_type_survey_group_id, score_type_id, analytic_function
	) LOOP
		csr.quick_survey_pkg.CreateScoreTypeAggType(
			in_analytic_function			=> r.analytic_function,
			in_score_type_id				=> r.score_type_id,
			in_applies_to_nc_score			=> r.applies_to_nc_score,
			in_applies_to_primary_survey	=> r.applies_to_primary_audit_survy,
			in_applies_to_audits 			=> r.applies_to_audits,
			in_ia_type_survey_group_id		=> r.ia_type_survey_group_id
		);
	END LOOP;
END;

PROCEDURE EnableCalculationSurveyScore
AS
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.quick_survey_type
	 WHERE cs_class = 'Credit360.QuickSurvey.CalculationSurveyType';
	
	IF v_count = 0 THEN
		INSERT INTO csr.quick_survey_type (quick_survey_type_id, description, cs_class)
		VALUES (csr.quick_survey_type_id_seq.NEXTVAL, 'Calculation survey type', 'Credit360.QuickSurvey.CalculationSurveyType');
	END IF;
END;

PROCEDURE SyncDelegPlanNames(
    in_deleg_template_sid           IN NUMBER
)
AS
    master_deleg_name               csr.delegation.name%TYPE;
    master_deleg_desc               csr.delegation_description.description%TYPE;
BEGIN
    -- Get the name from the master delegation
    SELECT name
      INTO master_deleg_name
      FROM csr.delegation
     WHERE delegation_sid = in_deleg_template_sid;

    -- For each delegation created from the given template
	FOR deleg IN (
        SELECT * FROM csr.delegation
         WHERE master_delegation_sid = in_deleg_template_sid
    ) LOOP
        -- Fix the delegation name
        IF deleg.name <> master_deleg_name THEN
            UPDATE csr.delegation
               SET name = master_deleg_name
             WHERE delegation_sid = deleg.delegation_sid;
        END IF;

        -- For each description translation for the current delegation
        FOR deleg_description IN (
            SELECT * FROM csr.delegation_description
             WHERE delegation_sid = deleg.delegation_sid)
        LOOP
            BEGIN
                SELECT description
                  INTO master_deleg_desc
                  FROM csr.delegation_description
                 WHERE lang = deleg_description.lang
                   AND delegation_sid = deleg.master_delegation_sid;

                IF deleg_description.description <> master_deleg_desc THEN
                    UPDATE csr.delegation_description
                       SET description = master_deleg_desc
                     WHERE delegation_sid = deleg_description.delegation_sid
                       AND lang = deleg_description.lang;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;
            END;
        END LOOP;
    END LOOP;
END;

PROCEDURE SetAutoPCSheetStatusFlag(
	in_flag_value		IN	NUMBER
)
AS
	v_app_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;

   UPDATE csr.customer 
	  SET status_from_parent_on_subdeleg = in_flag_value 
	WHERE app_sid = v_app_sid;
END;

PROCEDURE AllowOldChartEngine(
	in_allow			IN	NUMBER
)
AS
BEGIN
	UPDATE customer
	   SET allow_old_chart_engine = in_allow
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE ChartAlgorithmVersion(
	in_ver			IN	NUMBER
)
AS
BEGIN
	UPDATE customer
	   SET chart_algorithm_version = in_ver
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE AddNewRelicToSite
AS
BEGIN
	UPDATE aspen2.application
	   SET monitor_with_new_relic = 1
	 WHERE app_sid = security_pkg.GetApp;
END;


PROCEDURE RemoveNewRelicFromSite
AS
BEGIN
	UPDATE aspen2.application
	   SET monitor_with_new_relic = 0
	 WHERE app_sid = security_pkg.GetApp;
END;


PROCEDURE SetCDNServer (
	in_cdn_server_name	IN	VARCHAR2
)
AS
BEGIN
	UPDATE aspen2.application
	   SET cdn_server = in_cdn_server_name
	 WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE RemoveCDNServer
AS
BEGIN
	SetCDNServer(NULL);
END;

PROCEDURE SetUserPickerExtraFields(
	in_extra_fields				IN	customer.user_picker_extra_fields%TYPE
)
AS
	v_allowed_fields_tbl			aspen2.T_VARCHAR2_TABLE := aspen2.T_VARCHAR2_TABLE('email', 'user_name', 'user_ref');
	v_extra_fields					customer.user_picker_extra_fields%TYPE;
	v_extra_fields_tbl				aspen2.T_VARCHAR2_TABLE;
	v_invalid						NUMBER;
BEGIN
	v_extra_fields := LOWER(REGEXP_REPLACE(in_extra_fields, ' ', ''));
	v_extra_fields_tbl := aspen2.utils_pkg.SplitString2(v_extra_fields);
	
	SELECT COUNT(*)
	  INTO v_invalid
	  FROM TABLE(v_extra_fields_tbl)
	 WHERE column_value NOT IN (SELECT column_value FROM TABLE(v_allowed_fields_tbl));

	IF v_invalid != 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'One or more of the field names specified is not in the list of allowed fields.');
		RETURN;
	END IF;
	
	UPDATE customer
	   SET user_picker_extra_fields = v_extra_fields
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AddMissingProperties(
	in_property_type		IN	VARCHAR2
)
AS
	v_company_sid			security_pkg.T_SID_ID;
	v_default_prop_type_id	property.property_type_id%TYPE;
	v_property_type_id		property.property_type_id%TYPE;
	v_property_sub_type_id	property.property_sub_type_id%TYPE;
	v_street_addr_1			property.street_addr_2%TYPE;
	v_street_addr_2			property.street_addr_2%TYPE;
	v_city					property.city%TYPE;
	v_state					property.state%TYPE;
	v_postcode				property.postcode%TYPE;
BEGIN
	BEGIN
		SELECT property_type_id 
		  INTO v_default_prop_type_id
		  FROM property_type
		 WHERE UPPER(label) = UPPER(in_property_type)
		   AND app_sid = security.security_pkg.GetApp
		   AND rownum = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			property_pkg.SavePropertyType(
					in_property_type_id => null,
					in_property_type_name => in_property_type,
					in_space_type_ids => null,
					in_gresb_prop_type => null,
					out_property_type_id => v_default_prop_type_id
			);
	END;

	FOR p IN (
		SELECT region_sid 
		  FROM (
			SELECT r.region_sid
			  FROM v$region r
			 WHERE r.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
			   AND r.link_to_region_sid IS NULL 
		   CONNECT BY PRIOR r.region_sid = r.parent_sid
			 START WITH parent_sid = region_tree_pkg.GetPrimaryRegionTreeRootSid
			 UNION
			SELECT region_sid FROM (
				SELECT trash_sid 
				  FROM csr.trash
			   CONNECT BY PRIOR previous_parent_sid = trash_sid  
			     START WITH previous_parent_sid IN (
					SELECT r.region_sid
					  FROM csr.v$region r
				   CONNECT BY PRIOR r.region_sid = r.parent_sid
					 START WITH parent_sid = csr.region_tree_pkg.getprimaryregiontreerootsid
				)
			) t
			JOIN csr.v$region r ON t.trash_sid = r.region_sid
			 AND r.region_type =3
			 AND r.link_to_region_sid IS NULL
		)
		WHERE region_sid NOT IN (
			SELECT region_sid 
			  FROM property 
			 WHERE flow_item_id IS NOT NULL
		)
	)
	LOOP
		BEGIN
			SELECT company_sid, property_type_id, property_sub_type_id, street_addr_1, street_addr_2, city, state, postcode
			  INTO v_company_sid, v_property_type_id, v_property_sub_type_id, v_street_addr_1, v_street_addr_2, v_city, v_state, v_postcode
			  FROM property
			 WHERE region_sid = p.region_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				SELECT null, null, null, null, null, null, null, null
				  INTO v_company_sid, v_property_type_id, v_property_sub_type_id, v_street_addr_1, v_street_addr_2, v_city, v_state, v_postcode
				  FROM dual; 
		END;
			
		property_pkg.MakeProperty(
			in_act_id => security_pkg.getACT,
			in_region_sid => p.region_sid,
			in_property_type_id => NVL(v_property_type_id, v_default_prop_type_id),
			in_property_sub_type_id => v_property_sub_type_id,
			in_street_addr_1 => v_street_addr_1,
			in_street_addr_2 => v_street_addr_2,
			in_city => v_city,
			in_state => v_state,
			in_postcode => v_postcode,
			in_is_create => 1
		);
	END LOOP;
END;

PROCEDURE AddMissingCompanyDocFolders
AS
BEGIN
	supplier_pkg.AddMissingCompanyDocFolders;
END;

PROCEDURE RecordTimeInFlowStates (
	in_flow_sid			IN flow.flow_sid%TYPE
)
AS
	v_act_id				security.security_pkg.T_ACT_ID := sys_context('security','act');
	v_app_sid				security.security_pkg.T_SID_ID := sys_context('security','app');
	v_flow_class			flow_alert_class.flow_alert_class%TYPE;
	v_flow_class_label		flow_alert_class.label%TYPE;
	v_ind_root_sid			security.security_pkg.T_SID_ID;
	v_parent_ind_sid		security.security_pkg.T_SID_ID;
BEGIN
	-- Get type of workflow. Currently this only works for specific workflow types, not all/generic workflow.
	SELECT fac.flow_alert_class, fac.label
	  INTO v_flow_class, v_flow_class_label
	  FROM flow f
	  JOIN flow_alert_class fac ON fac.flow_alert_class = f.flow_alert_class
	 WHERE f.app_sid = v_app_sid
	   AND f.flow_sid = in_flow_sid;
   
 	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer;
	
	BEGIN
		v_parent_ind_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_ind_root_sid, v_flow_class);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> v_ind_root_sid,
				in_name 				=> v_flow_class,
				in_description 			=> v_flow_class_label,
				in_active	 			=> 1,
				out_sid_id				=> v_parent_ind_sid
			);
			
		UPDATE ind SET lookup_key = UPPER(v_flow_class || '_ROOT')
		 WHERE ind_sid = v_parent_ind_sid;
	END;
 
	flow_report_pkg.RecordTimeInFlowStates(in_flow_sid, v_parent_ind_sid, 1);

END;

PROCEDURE ClearLastUsdMeasureConversions (
	in_user_sid	NUMBER
)
AS
	v_app_sid				security.security_pkg.T_SID_ID := sys_context('security','app');
BEGIN
	AssertSuperAdmin;

	DELETE FROM csr.user_measure_conversion
	 WHERE app_sid = v_app_sid
	   AND csr_user_sid = in_user_sid;

END;

PROCEDURE MigrateEmissionFactorTool (
	in_profile_name	VARCHAR2
)
AS
	v_app_sid				security.security_pkg.T_SID_ID := sys_context('security','app');
	v_profile_id			emission_factor_profile.profile_id%TYPE;
	v_start_date_profile	DATE;
	v_profile_name			VARCHAR2(50);
	v_bespoke_set_id		custom_factor.custom_factor_set_id%TYPE;
	v_overrides_set_id		custom_factor.custom_factor_set_id%TYPE;
BEGIN
	AssertSuperAdmin;

	v_start_date_profile := factor_pkg.GetDateForMigratedNewProfile;

	IF v_start_date_profile IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'There are no factors to migrate.');
	END IF;

	factor_pkg.UNSEC_DetachFactorsForMigraton;

	v_profile_name := in_profile_name;
	IF v_profile_name IS NULL THEN
		v_profile_name := factor_pkg.DEFAULT_PROFILE_NAME;
	END IF;

	factor_pkg.RunProfileChecksForMigration(v_profile_name);
	factor_pkg.CreateEmissionProfile(
		in_name => v_profile_name,
		in_applied => 0,
		in_start_dtm => v_start_date_profile,
		out_profile_id => v_profile_id
	);
	factor_pkg.SetEndDateProfileOnMigration(v_profile_id);

	factor_pkg.AddStdProfleFactorsFromFactors(v_profile_id);

	factor_set_group_pkg.SetFactorSetsActiveOnMigration;

	IF factor_pkg.CheckExistingCustomSets(0) > 1 THEN
		v_bespoke_set_id := factor_pkg.CreateCustomFactorSet(
			in_name => factor_pkg.MIGRATED_CSTM_SET_NAME,
			in_factor_set_group_id => 0
		);
		factor_pkg.CreateCustomFactorsFromFactors (
			in_custom_factor_set_id => v_bespoke_set_id,
			in_get_overrides => 0
		);
	END IF;

	IF factor_pkg.CheckExistingCustomSets(1) > 1 THEN
		v_overrides_set_id := factor_pkg.CreateCustomFactorSet(
			in_name => factor_pkg.MIGRATED_OVERRS_SET_NAME,
			in_factor_set_group_id => 0
		);
		factor_pkg.CreateCustomFactorsFromFactors (
			in_custom_factor_set_id => v_overrides_set_id,
			in_get_overrides => 1
		);
	END IF;

	factor_pkg.AddCustomFactorsToProfile(v_profile_id);

END;

PROCEDURE ResyncDefaultComplianceFlows
AS
	v_reg_flow_sid					security_pkg.T_SID_ID;
	v_req_flow_sid					security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT regulation_flow_sid, requirement_flow_sid
		  INTO v_reg_flow_sid, v_req_flow_sid
		  FROM compliance_options
		 WHERE app_sid = security_pkg.GetApp;

		IF v_reg_flow_sid IS NOT NULL THEN
			compliance_setup_pkg.UpdateDefaultWorkflow(v_reg_flow_sid, 'regulation');
		END IF;
		
		IF v_req_flow_sid IS NOT NULL THEN
			compliance_setup_pkg.UpdateDefaultWorkflow(v_req_flow_sid, 'requirement');
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
END;

PROCEDURE ResyncDefaultPermitFlows
AS
	v_permit_flow_sid				security_pkg.T_SID_ID;
	v_application_flow_sid			security_pkg.T_SID_ID;
	v_condition_flow_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT permit_flow_sid, application_flow_sid, condition_flow_sid
		  INTO v_permit_flow_sid, v_application_flow_sid, v_condition_flow_sid
		  FROM compliance_options
		 WHERE app_sid = security_pkg.GetApp;

		IF v_permit_flow_sid IS NOT NULL THEN
			compliance_setup_pkg.UpdatePermitWorkflow(v_permit_flow_sid, 'permit');
		END IF;
		
		IF v_application_flow_sid IS NOT NULL THEN
			compliance_setup_pkg.UpdatePermApplicationWorkflow(v_application_flow_sid, 'application');
		END IF;

		IF v_condition_flow_sid IS NOT NULL THEN
			compliance_setup_pkg.UpdatePermitConditionWorkflow(v_condition_flow_sid, 'condition');
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
END;

PROCEDURE SetBatchJobTimeoutOverride(
	in_batch_job_type_id		NUMBER,
	in_timeout_mins				NUMBER
)
AS
BEGIN

	batch_job_pkg.SetCustomerTimeoutForType (
		in_batch_job_type_id	=> in_batch_job_type_id,
		in_timeout_mins			=> in_timeout_mins
	);

END;

PROCEDURE ShowHideDelegPlan (
	in_deleg_plan_sid		IN  deleg_plan.deleg_plan_sid%TYPE,
	in_show					IN  NUMBER
)
AS
BEGIN
	AssertSuperAdmin;
	
	UPDATE deleg_plan
	   SET active = in_show
	 WHERE deleg_plan_sid = in_deleg_plan_sid;
END;

PROCEDURE ChangeIntApiCompanyUserGroup(
	in_group_name			IN	VARCHAR2,
	in_delete				IN	NUMBER DEFAULT 0
)
AS
	v_group_sid					NUMBER;
BEGIN
	AssertSuperAdmin;
	
	BEGIN 
		SELECT gt.sid_id
		  INTO v_group_sid
		  FROM security.securable_object so 
		  JOIN security.group_table gt ON gt.sid_id = so.sid_id
		  JOIN security.securable_object_class soc ON soc.class_id = so.class_id AND soc.class_name IN ('Group', 'CSRUserGroup')
		 WHERE so.name = in_group_name;
	EXCEPTION
		WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, in_group_name||' is not a distinct Group name.');
	END;
	
	IF in_delete = 0 THEN
		BEGIN
			INSERT INTO intapi_company_user_group (group_sid_id)
			VALUES (v_group_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	ELSE
		DELETE FROM intapi_company_user_group
		 WHERE group_sid_id = v_group_sid;
	END IF;
END;

PROCEDURE CreateAPIClient(
	in_user_name			IN	VARCHAR2,
	in_client_id			IN	VARCHAR2,
	in_client_secret		IN	VARCHAR2
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	-- New user sid
	v_user_sid						security_pkg.T_SID_ID;
BEGIN

	v_groups_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	BEGIN
		SELECT csr_user_sid
		  INTO v_user_sid
		  FROM csr_user
		 WHERE LOWER(user_name) = LOWER(in_user_name)
		   AND app_sid = v_app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Create the user
			csr_user_pkg.createUser(
				in_act			 				=> v_act_id,
				in_app_sid						=> v_app_sid,
				in_user_name					=> in_user_name,
				in_password 					=> NULL,
				in_full_name					=> in_user_name,
				in_friendly_name				=> in_user_name,
				in_email		 				=> in_user_name||'@credit360.com',
				in_send_alerts					=> 0,
				in_info_xml						=> NULL,
				in_user_ref						=> in_user_name,
				in_account_expiry_enabled		=> 0,
				out_user_sid 					=> v_user_sid
			);
			
			UPDATE csr_user
			   SET hidden = 1
			 WHERE csr_user_sid = v_user_sid;
			
			security.Group_Pkg.addMember(v_act_id, v_user_sid, v_admins_sid);
	END;
	
	-- Create the API logon
	security.user_pkg.CreateApiLogon(
		in_app_sid			=> v_app_sid,
		in_client_id		=> in_client_id,
		in_client_secret	=> in_client_secret,
		in_user_sid			=> v_user_sid
	);
END;

PROCEDURE UpdateAPIClientSecret(
	in_client_id			IN	VARCHAR2,
	in_client_secret		IN	VARCHAR2
)
AS
BEGIN

	security.user_pkg.UpdateApiLogon(
		in_app_sid			=>	security.security_pkg.GetApp,
		in_client_id		=>	in_client_id,
		in_client_secret	=>	in_client_secret
	);
END;

PROCEDURE CreateProfilesForUsers
AS
BEGIN
	csr.user_profile_pkg.CreateProfilesForUsers();
END;

PROCEDURE SetUserRegionRoleLazyLoad(
	in_lazy_load				IN	customer.lazy_load_role_membership%TYPE
)
AS
BEGIN
	UPDATE customer
	   SET lazy_load_role_membership = in_lazy_load;
END;

PROCEDURE SetCalcFutureWindow(
	in_calc_future_window				IN	customer.calc_future_window%TYPE
)
AS
BEGIN
	UPDATE customer
	   SET calc_future_window = in_calc_future_window;
	 
	csr.customer_pkg.RefreshCalcWindows;
END;

PROCEDURE SetCalcStartDate(
	in_date							IN	VARCHAR2
)
AS
	v_new_calc_start_dtm				csr.customer.calc_start_dtm%TYPE;
	v_current_calc_end_dtm				csr.customer.calc_start_dtm%TYPE;
	v_beginning_of_time_dtm				csr.customer.calc_start_dtm%TYPE;
BEGIN
	v_beginning_of_time_dtm := DATE '1990-01-01';
	v_new_calc_start_dtm := TO_DATE(in_date, 'YYYY-MM-DD');
	
	SELECT calc_end_dtm
	  INTO v_current_calc_end_dtm
	  FROM customer;
	
	IF v_new_calc_start_dtm >= v_beginning_of_time_dtm AND v_new_calc_start_dtm <= v_current_calc_end_dtm
	THEN
		UPDATE customer
		   SET calc_start_dtm = v_new_calc_start_dtm;
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 
			'Date must be between ' || TO_CHAR(v_beginning_of_time_dtm, 'YYYY-MM-DD') || ' and current calc_start_dtm ' || TO_CHAR(v_current_calc_end_dtm, 'YYYY-MM-DD')
		);
	END IF;
END;

PROCEDURE RemoveMatrixLayout(
	in_deleg_sid		IN	security.security_pkg.T_SID_ID
)
AS
	v_deleg_count		NUMBER;
	v_cur_layout_id		delegation.layout_id%TYPE;
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	BEGIN
		SELECT layout_id
		  INTO v_cur_layout_id
		  FROM delegation
		 WHERE delegation_sid = in_deleg_sid
		   AND app_sid = v_app_sid;

		SELECT COUNT(*)
		  INTO v_deleg_count
		  FROM delegation
		 WHERE layout_id = v_cur_layout_id
		   AND delegation_sid != in_deleg_sid
		   AND app_sid = v_app_sid;

		UPDATE delegation
		   SET layout_id = NULL
		 WHERE delegation_sid = in_deleg_sid
		   AND app_sid = v_app_sid;

		IF v_deleg_count = 0 THEN
			DELETE FROM delegation_layout
			 WHERE layout_id = v_cur_layout_id
			   AND app_sid = v_app_sid;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'No delegation could be found for sid; '||in_deleg_sid);
	END;
END;

PROCEDURE CreateUniqueMatrixLayoutCopy(
	in_deleg_sid		IN	security.security_pkg.T_SID_ID
)
AS
	v_cur_layout_id		delegation.layout_id%TYPE;
	v_layout_id			delegation_layout.layout_id%TYPE;
	v_xml				delegation_layout.layout_xhtml%TYPE;
	v_name				delegation_layout.name%TYPE DEFAULT NULL;
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	BEGIN
		SELECT layout_id
		  INTO v_cur_layout_id
		  FROM delegation
		 WHERE delegation_sid = in_deleg_sid
		   AND app_sid = v_app_sid;

		SELECT name || ' (' || in_deleg_sid || ')', layout_xhtml
		  INTO v_name, v_xml
		  FROM delegation_layout
		 WHERE layout_id = v_cur_layout_id
		   AND app_sid = v_app_sid;

		delegation_pkg.CreateLayoutTemplate(
			in_xml	=> v_xml,
			in_name	=> v_name,
			out_id	=> v_layout_id
		);

		delegation_pkg.SetLayoutTemplate( 
			in_delegation_sid	=> in_deleg_sid,
			in_layout_id		=> v_layout_id
		);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'No delegation could be found for sid; '||in_deleg_sid);
	END;
END;

PROCEDURE DeleteOutOfScopeCompItems(
	in_delete_comp_items_w_issues		IN	VARCHAR2		-- 'y' = also delete compliance items with issues and sched issues.
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
	v_has_issues				BOOLEAN;
	v_num_sched_issues			NUMBER;
BEGIN
	FOR r IN (
		SELECT compliance_item_id, region_sid, flow_item_id
		  FROM compliance_item_region
		 WHERE out_of_scope = 1
		   AND app_sid = v_app_sid
	)
	LOOP
		v_has_issues := FALSE;
		v_num_sched_issues := 0;
	
		FOR s IN (
			SELECT i.issue_id
			  FROM issue_compliance_region icr
			  JOIN issue i
			    ON icr.issue_compliance_region_id = i.issue_compliance_region_id
			 WHERE icr.flow_item_id = r.flow_item_id
			   AND icr.app_sid = v_app_sid
		)
		LOOP
			IF LOWER(in_delete_comp_items_w_issues) = 'y' THEN
				-- The user wants to DELETE issues associated with the compliance item.
				issue_pkg.UNSEC_DeleteIssue(s.issue_id);
			ELSE
				-- Compliance item has issues but we don't want to delete them - skip!
				v_has_issues := TRUE;
				EXIT;
			END IF;
		END LOOP;
		
		IF v_has_issues THEN
			CONTINUE;
		END IF;
		
		-- Work out if the compliance item has any scheduled issues. If so, delete only if we're supposed to!
		SELECT COUNT(*)
		  INTO v_num_sched_issues
		  FROM comp_item_region_sched_issue
		 WHERE flow_item_id = r.flow_item_id
		   AND app_sid = v_app_sid;
		
		IF v_num_sched_issues > 0 AND LOWER(in_delete_comp_items_w_issues) = 'y' THEN
			DELETE FROM comp_item_region_sched_issue
			 WHERE flow_item_id = r.flow_item_id
			   AND app_sid = v_app_sid;
		ELSIF v_num_sched_issues > 0 THEN
			CONTINUE;
		END IF;
		
		DELETE FROM issue_compliance_region
		 WHERE flow_item_id = r.flow_item_id
		   AND app_sid = v_app_sid;

		DELETE FROM compliance_item_region
		 WHERE flow_item_id = r.flow_item_id
		   AND app_sid = v_app_sid;
	END LOOP;
END;

PROCEDURE SetEnhesaDupesOutOfScope
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_item_type					NUMBER;
BEGIN
	FOR item IN (
		SELECT ci.compliance_item_id, cireg.flow_item_id 
		  FROM compliance_item ci 
		  JOIN compliance_requirement cr ON ci.compliance_item_id = cr.compliance_item_id
		  JOIN compliance_item_rollout cir ON ci.compliance_item_id = cir.compliance_item_id
		  JOIN compliance_item_region cireg ON ci.compliance_item_id = cireg.compliance_item_id
		WHERE ci.source = 1 AND ci.reference_code LIKE '__Q________'
		  AND ci.app_sid = v_app_sid)
	LOOP
		SELECT compliance_item_type
		  INTO v_item_type
		  FROM compliance_item ci
		 WHERE ci.compliance_item_id = item.compliance_item_id
		   AND ci.app_sid = v_app_sid;

		SELECT requirement_flow_sid
		  INTO v_flow_sid
		  FROM compliance_options
		 WHERE app_sid = v_app_sid;

	IF (v_flow_sid IS NOT null ) THEN
		-- csr_data_pkg.NATURE_REQUIREMENT_UPDATED = 12
		flow_pkg.SetItemStateNature(item.flow_item_id, 12, 'Duplicated library item');

		UPDATE compliance_item_region
		   SET out_of_scope = 1
		 WHERE flow_item_id = item.flow_item_id;
	END IF;

	-- mark NAT items out ouf scope that have been superceded by local items
	END LOOP;

END;

PROCEDURE RestartFailedCampaign(
	in_campaign_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	campaigns.campaign_pkg.RestartFailedCampaign(in_campaign_sid);
END;

PROCEDURE GeotagCompanies
AS
	v_geotag_job_id				NUMBER;
BEGIN
	v_geotag_job_id := chain.company_pkg.CreateGeotagBatchJob(
		in_geotag_source	=> chain.chain_pkg.GEOTAG_SRC_ALL_COMPANIES
	);
END;

PROCEDURE ResubmitFailedRawMeterData(
	in_from_dtm					IN	VARCHAR2
)
AS
	out_cur						security.security_pkg.T_OUTPUT_CUR;
	v_from_dtm					DATE := TO_DATE(in_from_dtm, 'YYYY-MM-DD');
BEGIN
	IF v_from_dtm < DATE '2021-01-01'
	THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid date (must be greater than 2021-01-01)');
	END IF;

	FOR r IN (
		SELECT meter_raw_data_id
		  FROM csr.meter_raw_data
		 WHERE start_dtm IS NULL AND
			   status_id = meter_monitor_pkg.RAW_DATA_STATUS_HAS_ERRORS AND
			   received_dtm > v_from_dtm
	)
	LOOP
		meter_monitor_pkg.ResubmitRawData(r.meter_raw_data_id, out_cur);
	END LOOP;
END;

PROCEDURE INTERNAL_InsertMeterAlarmStat (
	in_bucket_id					IN	meter_alarm_statistic.meter_bucket_id%TYPE,
	in_stat_name					IN	meter_alarm_statistic.name%TYPE,
	in_is_avg						IN	meter_alarm_statistic.is_average%TYPE,
	in_is_sum						IN	meter_alarm_statistic.is_sum%TYPE,
	in_comp_proc					IN	meter_alarm_statistic.comp_proc%TYPE,
	in_input_id						IN	meter_alarm_statistic.meter_input_id%TYPE,
	in_aggregator					IN	meter_alarm_statistic.aggregator%TYPE,
	in_pos							IN	meter_alarm_statistic.pos%TYPE,
	in_core_working_hours			IN	meter_alarm_statistic.core_working_hours%TYPE DEFAULT 0,
	in_all_meters					IN	meter_alarm_statistic.all_meters%TYPE	DEFAULT 0,
	in_lookup						IN	meter_alarm_statistic.lookup_key%TYPE	DEFAULT NULL
)
AS
	v_id							meter_alarm_statistic.statistic_id%TYPE;
BEGIN
	BEGIN
		BEGIN
			SELECT statistic_id
			  INTO v_id
			  FROM meter_alarm_statistic
			 WHERE name = in_stat_name;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				INSERT INTO meter_alarm_statistic (app_sid, statistic_id, meter_bucket_id, name, is_average, is_sum, 
					comp_proc, meter_input_id, aggregator, pos, core_working_hours, all_meters, lookup_key)
				VALUES (security.security_pkg.GetAPP, meter_statistic_id_seq.nextval, in_bucket_id, in_stat_name, in_is_avg, in_is_sum, in_comp_proc, 
					in_input_id, in_aggregator, in_pos, in_core_working_hours, in_all_meters, in_lookup);
		END;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- IGNORE DUPE LOOKUP KEY
	END;
END;

PROCEDURE INTERNAL_RemoveMeterAlarmStat (
	in_stat_name				IN	meter_alarm_statistic.name%TYPE
)
AS
	v_statistic_id				meter_alarm_statistic.statistic_id%TYPE;
BEGIN
	BEGIN
		SELECT statistic_id
		  INTO v_statistic_id
		  FROM meter_alarm_statistic
		 WHERE name = in_stat_name;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN; -- Nothing to do
	END;

	-- ** WARNING ** 
	-- THIS WILL REMOVE ALL THE DATA ASSOCIATED WITH THE SPECIFIED STATISTIC

	DELETE FROM meter_alarm_stat_run
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND statistic_id = v_statistic_id;

	DELETE FROM meter_meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND statistic_id = v_statistic_id;

	DELETE FROM meter_alarm_statistic_period
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND statistic_id = v_statistic_id;

	DELETE FROM meter_alarm_statistic_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND statistic_id = v_statistic_id;

	FOR r IN (
		SELECT meter_alarm_id
		  FROM meter_alarm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ( look_at_statistic_id = v_statistic_id
		    OR compare_statistic_id = v_statistic_id )
	) LOOP

		DELETE FROM meter_alarm_event
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_alarm_id = r.meter_alarm_id;

		 DELETE FROM region_meter_alarm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_alarm_id = r.meter_alarm_id;

		UPDATE issue
		   SET issue_meter_alarm_id = NULL
		 WHERE issue_meter_alarm_id IN (
			SELECT issue_meter_alarm_id
			  FROM issue_meter_alarm
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND meter_alarm_id = r.meter_alarm_id
		 );

		DELETE FROM issue_meter_alarm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_alarm_id = r.meter_alarm_id;

	END LOOP;

	DELETE FROM meter_alarm_statistic
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND statistic_id = v_statistic_id;
END;

PROCEDURE EnableMeteringSameDayAvg(
	in_enable				IN	NUMBER
)
AS
	v_meter_input_id		meter_input.meter_input_id%TYPE;
	v_daily_bucket_id		meter_bucket.meter_bucket_id%TYPE;
BEGIN
	IF in_enable != 0 AND in_enable != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid enable/disable flag (Enable = 1, Disable = 0)');
	END IF;

	IF in_enable = 0 THEN
		INTERNAL_RemoveMeterAlarmStat('Same day of the week average');
	ELSE
		SELECT meter_input_id
		  INTO v_meter_input_id
		  FROM meter_input
		 WHERE lookup_key = 'CONSUMPTION';

		SELECT meter_bucket_id
		  INTO v_daily_bucket_id
		  FROM meter_bucket
		 WHERE is_hours = 1
		   AND duration = 24;

		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Same day of the week average', 1, 0, 'meter_alarm_stat_pkg.ComputeSameDayAvg', v_meter_input_id, 'SUM', 10);
	END IF;
END;

PROCEDURE EnableMeteringCoreSameDayAvg(
	in_enable				IN	NUMBER
)
AS
	v_meter_input_id		meter_input.meter_input_id%TYPE;
	v_hourly_bucket_id		meter_bucket.meter_bucket_id%TYPE;
BEGIN
	IF in_enable != 0 AND in_enable != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid enable/disable flag (Enable = 1, Disable = 0)');
	END IF;

	IF in_enable = 0 THEN
		INTERNAL_RemoveMeterAlarmStat('Core working hours - same day of the week average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours - same day of the week average');
	ELSE
		SELECT meter_input_id
		  INTO v_meter_input_id
		  FROM meter_input
		 WHERE lookup_key = 'CONSUMPTION';

		SELECT meter_bucket_id
		  INTO v_hourly_bucket_id
		  FROM meter_bucket
		 WHERE duration = 1
		   AND is_hours = 1;

		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours - same day of the week average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreSameDayAvg', v_meter_input_id, 'SUM', 102, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours - same day of the week average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreSameDayAvg', v_meter_input_id, 'SUM', 105, 1);
	END IF;
END;

PROCEDURE EnableMeteringCoreDayNorm(
	in_enable				IN	NUMBER
)
AS
	v_meter_input_id		meter_input.meter_input_id%TYPE;
	v_hourly_bucket_id		meter_bucket.meter_bucket_id%TYPE;
BEGIN
	IF in_enable != 0 AND in_enable != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid enable/disable flag (Enable = 1, Disable = 0)');
	END IF;

	IF in_enable = 0 THEN
		INTERNAL_RemoveMeterAlarmStat('Core working hours - day normalised usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours - day normalised average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours - day normalised usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours - day normalised average');
	ELSE
		SELECT meter_input_id
		  INTO v_meter_input_id
		  FROM meter_input
		 WHERE lookup_key = 'CONSUMPTION';

		SELECT meter_bucket_id
		  INTO v_hourly_bucket_id
		  FROM meter_bucket
		 WHERE duration = 1
		   AND is_hours = 1;
		
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours - day normalised usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreDayNormUse', v_meter_input_id, 'SUM', 200, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours - day normalised average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreDayNormAvg', v_meter_input_id, 'SUM', 201, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours - day normalised usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreDayNormUse', v_meter_input_id, 'SUM', 202, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours - day normalised average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreDayNormAvg', v_meter_input_id, 'SUM', 203, 1);
	END IF;
END;

PROCEDURE EnableMeteringCoreExtended(
	in_enable				IN	NUMBER
)
AS
	v_meter_input_id		meter_input.meter_input_id%TYPE;
	v_hourly_bucket_id		meter_bucket.meter_bucket_id%TYPE;
BEGIN
	IF in_enable != 0 AND in_enable != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid enable/disable flag (Enable = 1, Disable = 0)');
	END IF;

	IF in_enable = 0 THEN
		INTERNAL_RemoveMeterAlarmStat('Core working hours week day usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours weekend day usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours week day average');
		INTERNAL_RemoveMeterAlarmStat('Core working hours weekend day average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours week day usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours weekend day usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours week day average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours weekend day average');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Monday usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Tuesday usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Wednesday usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Thursday usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Friday usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Saturday usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Sunday usage');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Monday average');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Tuesday average');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Wednesday average');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Thursday average');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Friday average');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Saturday average');
		INTERNAL_RemoveMeterAlarmStat('Core working hours Sunday average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Monday usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Tuesday usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Wednesday usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Thursday usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Friday usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Saturday usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Sunday usage');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Monday average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Tuesday average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Wednesday average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Thursday average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Friday average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Saturday average');
		INTERNAL_RemoveMeterAlarmStat('Non-core working hours Sunday average');
	ELSE
		SELECT meter_input_id
		  INTO v_meter_input_id
		  FROM meter_input
		 WHERE lookup_key = 'CONSUMPTION';

		SELECT meter_bucket_id
		  INTO v_hourly_bucket_id
		  FROM meter_bucket
		 WHERE duration = 1
		   AND is_hours = 1;
		
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours week day usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreWeekDayUse', v_meter_input_id, 'SUM', 404, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours weekend day usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreWeekendUse', v_meter_input_id, 'SUM', 405, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours week day average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreWeekDayAvg', v_meter_input_id, 'SUM', 406, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours weekend day average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreWeekendAvg', v_meter_input_id, 'SUM', 407, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours week day usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreWeekDayUse', v_meter_input_id, 'SUM', 408, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours weekend day usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreWeekendUse', v_meter_input_id, 'SUM', 409, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours week day average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreWeekDayAvg', v_meter_input_id, 'SUM', 410, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours weekend day average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreWeekendAvg', v_meter_input_id, 'SUM', 411, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Monday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreMondayUse', v_meter_input_id, 'SUM', 412, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Tuesday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreTuesdayUse', v_meter_input_id, 'SUM', 413, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Wednesday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreWednesdayUse', v_meter_input_id, 'SUM', 414, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Thursday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreThursdayUse', v_meter_input_id, 'SUM', 415, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Friday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreFridayUse', v_meter_input_id, 'SUM', 416, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Saturday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreSaturdayUse', v_meter_input_id, 'SUM', 417, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Sunday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeCoreSundayUse', v_meter_input_id, 'SUM', 418, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Monday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreMondayAvg', v_meter_input_id, 'SUM', 419, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Tuesday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreTuesdayAvg', v_meter_input_id, 'SUM', 420, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Wednesday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreWednesdayAvg', v_meter_input_id, 'SUM', 421, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Thursday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreThursdayAvg', v_meter_input_id, 'SUM', 422, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Friday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreFridayAvg', v_meter_input_id, 'SUM', 423, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Saturday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreSaturdayAvg', v_meter_input_id, 'SUM', 424, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Core working hours Sunday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeCoreSundayAvg', v_meter_input_id, 'SUM', 425, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Monday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreMondayUse', v_meter_input_id, 'SUM', 426, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Tuesday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreTuesdayUse', v_meter_input_id, 'SUM', 427, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Wednesday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreWednesdayUse', v_meter_input_id, 'SUM', 428, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Thursday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreThursdayUse', v_meter_input_id, 'SUM', 429, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Friday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreFridayUse', v_meter_input_id, 'SUM', 430, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Saturday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreSaturdayUse', v_meter_input_id, 'SUM', 431, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Sunday usage', 0, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreSundayUse', v_meter_input_id, 'SUM', 432, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Monday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreMondayAvg', v_meter_input_id, 'SUM', 433, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Tuesday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreTuesdayAvg', v_meter_input_id, 'SUM', 434, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Wednesday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreWednesdayAvg', v_meter_input_id, 'SUM', 435, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Thursday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreThursdayAvg', v_meter_input_id, 'SUM', 436, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Friday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreFridayAvg', v_meter_input_id, 'SUM', 437, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Saturday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreSaturdayAvg', v_meter_input_id, 'SUM', 438, 1);
		INTERNAL_InsertMeterAlarmStat(v_hourly_bucket_id, 'Non-core working hours Sunday average', 1, 0, 'meter_alarm_core_stat_pkg.ComputeNonCoreSundayAvg', v_meter_input_id, 'SUM', 439, 1);
	END IF;
END;

PROCEDURE EnableMeteringDayStats(
	in_enable				IN	NUMBER
)
AS
	v_meter_input_id		meter_input.meter_input_id%TYPE;
	v_daily_bucket_id		meter_bucket.meter_bucket_id%TYPE;
BEGIN
	IF in_enable != 0 AND in_enable != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid enable/disable flag (Enable = 1, Disable = 0)');
	END IF;

	IF in_enable = 0 THEN
		INTERNAL_RemoveMeterAlarmStat('Same day of the week average');

		INTERNAL_RemoveMeterAlarmStat('Monday''s usage');
		INTERNAL_RemoveMeterAlarmStat('Tuesday''s usage');
		INTERNAL_RemoveMeterAlarmStat('Wednesday''s usage');
		INTERNAL_RemoveMeterAlarmStat('Thursday''s usage');
		INTERNAL_RemoveMeterAlarmStat('Friday''s usage');
		INTERNAL_RemoveMeterAlarmStat('Saturday''s usage');
		INTERNAL_RemoveMeterAlarmStat('Sunday''s usage');
		
		INTERNAL_RemoveMeterAlarmStat('Average Monday usage');
		INTERNAL_RemoveMeterAlarmStat('Average Tuesday usage');
		INTERNAL_RemoveMeterAlarmStat('Average Wednesday usage');
		INTERNAL_RemoveMeterAlarmStat('Average Thursday usage');
		INTERNAL_RemoveMeterAlarmStat('Average Friday usage');
		INTERNAL_RemoveMeterAlarmStat('Average Saturday usage');
		INTERNAL_RemoveMeterAlarmStat('Average Sunday usage');
	ELSE
		SELECT meter_input_id
		  INTO v_meter_input_id
		  FROM meter_input
		 WHERE lookup_key = 'CONSUMPTION';

		SELECT meter_bucket_id
		  INTO v_daily_bucket_id
		  FROM meter_bucket
		 WHERE is_hours = 1
		   AND duration = 24;

		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Monday''s usage', 0, 0, 'meter_alarm_stat_pkg.ComputeMondayUsage', v_meter_input_id, 'SUM', 50);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Tuesday''s usage', 0, 0, 'meter_alarm_stat_pkg.ComputeTuesdayUsage', v_meter_input_id, 'SUM', 51);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Wednesday''s usage', 0, 0, 'meter_alarm_stat_pkg.ComputeWednesdayUsage', v_meter_input_id, 'SUM', 52);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Thursday''s usage', 0, 0, 'meter_alarm_stat_pkg.ComputeThursdayUsage', v_meter_input_id, 'SUM', 53);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Friday''s usage', 0, 0, 'meter_alarm_stat_pkg.ComputeFridayUsage', v_meter_input_id, 'SUM', 54);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Saturday''s usage', 0, 0, 'meter_alarm_stat_pkg.ComputeSaturdayUsage', v_meter_input_id, 'SUM', 55);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Sunday''s usage', 0, 0, 'meter_alarm_stat_pkg.ComputeSundayUsage', v_meter_input_id, 'SUM', 56);
		
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average Monday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgMondayUsage', v_meter_input_id, 'SUM', 57);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average Tuesday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgTuesdayUsage', v_meter_input_id, 'SUM', 58);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average Wednesday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgWednesdayUsage', v_meter_input_id, 'SUM', 59);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average Thursday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgThursdayUsage', v_meter_input_id, 'SUM', 60);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average Friday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgFridayUsage', v_meter_input_id, 'SUM', 61);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average Saturday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgSaturdayUsage', v_meter_input_id, 'SUM', 62);
		INTERNAL_InsertMeterAlarmStat(v_daily_bucket_id, 'Average Sunday usage', 1, 0, 'meter_alarm_stat_pkg.ComputeAvgSundayUsage', v_meter_input_id, 'SUM', 63);
	END IF;
END;

PROCEDURE EnableUrjanetStatementIdAggr(
	in_enable				IN	NUMBER
)
AS
	v_count					NUMBER;
BEGIN
	IF in_enable = 0  THEN
		UPDATE csr.auto_imp_importer_settings
		   SET mapping_xml = 
				DELETEXML(mapping_xml, '/columnMappings/column[@column-type="statement-id"]')
		 WHERE (app_sid, automated_import_class_sid) IN (
		 	SELECT app_sid, automated_import_class_sid
		 	  FROM csr.meter_raw_data_source
		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND LOWER(label) = 'urjanet importer'
		 );
	ELSE
		UPDATE csr.auto_imp_importer_settings
		   SET mapping_xml = 
			INSERTCHILDXML(mapping_xml, '/columnMappings', 'column',
				XMLTYPE('<column name="StatementId" column-type="statement-id"/>'))
		 WHERE EXISTSNODE(mapping_xml, '/columnMappings/column[@column-type="statement-id"]') = 0
		   AND (app_sid, automated_import_class_sid) IN (
		 	SELECT app_sid, automated_import_class_sid
		 	  FROM csr.meter_raw_data_source
		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND LOWER(label) = 'urjanet importer'
		 );
	END IF;
END;

PROCEDURE EnableDisplayCookiePolicy(
	in_enable				IN	NUMBER
)
AS
BEGIN
	UPDATE aspen2.application
	   SET display_cookie_policy = in_enable
	 WHERE app_sid = security.security_pkg.getApp;
END;

PROCEDURE INTERNAL_DelMeterInputNotInUse(
	in_lookup_key		IN	meter_input.lookup_key%TYPE
)
AS
	v_id				NUMBER(10);
BEGIN
	BEGIN
		SELECT meter_input_id
		  INTO v_id
		  FROM meter_input
		 WHERE lookup_key = in_lookup_key;
		
		meter_pkg.DeleteMeterInput(
			in_meter_input_id => v_id
		);

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- Ignore input doesn't exist
		WHEN OTHERS THEN
			-- Ignore input in use integrity violation
			IF SQLCODE != ERR_INTEGRITY_CONSTRAINT THEN
				RAISE;
			END IF;
	END;
END;

PROCEDURE INTERNAL_EnsureMeterInput(
	in_lookup_key		IN	meter_input.lookup_key%TYPE,
	in_label			IN	meter_input.label%TYPE
)
AS
	v_id				NUMBER(10);
	v_aggrs				security.security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	BEGIN
		v_aggrs(1) := 'SUM';
		meter_pkg.SaveMeterInput(
			in_meter_input_id		=> NULL, -- new input
			in_label				=> in_label,
			in_lookup_key			=> in_lookup_key,
			in_is_consumption_based	=> 1,
			in_aggregators			=> v_aggrs,
			out_meter_input_id		=> v_id
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL; -- Ignore dupes
	END;
END;

PROCEDURE EnableUrjanetRenewEnergy(
	in_enable			IN	NUMBER
)
AS
BEGIN
	IF in_enable = 0  THEN
		-- Remove the meter inputs if possible
		INTERNAL_DelMeterInputNotInUse(
			in_lookup_key => 'RENEW_ENERGY_CONSUMPTION'
		);
		INTERNAL_DelMeterInputNotInUse(
			in_lookup_key => 'RENEW_ENERGY_COST'
		);
		-- Remove the mappings
		UPDATE csr.auto_imp_importer_settings
		   SET mapping_xml = 
				DELETEXML(mapping_xml, '/columnMappings/column[contains(@format, "RENEW_ENERGY_")]')
		 WHERE (app_sid, automated_import_class_sid) IN (
		 	SELECT app_sid, automated_import_class_sid
		 	  FROM csr.meter_raw_data_source
		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND LOWER(label) = 'urjanet importer'
		 );
	ELSE
		-- Add the meter inputs if required
		INTERNAL_EnsureMeterInput(
			in_lookup_key	=> 'RENEW_ENERGY_CONSUMPTION', 
			in_label		=> 'Renewable Energy Consumption'
		);
		INTERNAL_EnsureMeterInput(
			in_lookup_key	=> 'RENEW_ENERGY_COST', 
			in_label		=> 'Renewable Energy Cost'
		);
		-- Add the new mappings
		UPDATE csr.auto_imp_importer_settings
		   SET mapping_xml = 
			INSERTCHILDXML(
			INSERTCHILDXML(
			INSERTCHILDXML(
			INSERTCHILDXML(mapping_xml, 
				'/columnMappings', 'column', XMLTYPE('<column name="RenewElecUsage" column-type="meter-input" format="RENEW_ENERGY_CONSUMPTION"/>')),
				'/columnMappings', 'column', XMLTYPE('<column name="RenewElecUsageUnit" column-type="meter-input-unit" format="RENEW_ENERGY_CONSUMPTION"/>')),
				'/columnMappings', 'column', XMLTYPE('<column name="RenewElecCost" column-type="meter-input" format="RENEW_ENERGY_COST"/>')),
				'/columnMappings', 'column', XMLTYPE('<column name="RenewElecCurrency" column-type="meter-input-unit" format="RENEW_ENERGY_COST"/>'))
		 WHERE EXISTSNODE(mapping_xml, '/columnMappings/column[contains(@format, "RENEW_ENERGY_")]') = 0 -- NOT exists
		   AND (app_sid, automated_import_class_sid) IN (
		 	SELECT app_sid, automated_import_class_sid
		 	  FROM csr.meter_raw_data_source
		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND LOWER(label) = 'urjanet importer'
		 );
	END IF;
END;

PROCEDURE CanMigrateAudits
AS
	v_err_msg			VARCHAR2(512) := NULL;
	v_result			audit_migration_pkg.T_VALIDATION_RESULT;
BEGIN
	v_result := audit_migration_pkg.ValidateSiteMigration;

	IF bitwise_pkg.bitand(v_result, audit_migration_pkg.FAIL_AUDIT_DACL_MATCH) = audit_migration_pkg.FAIL_AUDIT_DACL_MATCH THEN
		v_err_msg := 'Differences found in SO permissions between the Audit Node and the audit SOs.';
	END IF;

	IF bitwise_pkg.bitand(v_result, audit_migration_pkg.FAIL_DENY_ACL) = audit_migration_pkg.FAIL_DENY_ACL THEN
		v_err_msg := v_err_msg || ' Deny permissions were found.';
	END IF;

	IF bitwise_pkg.bitand(v_result, audit_migration_pkg.FAIL_CSR_CAPABILITY) = audit_migration_pkg.FAIL_CSR_CAPABILITY THEN
		v_err_msg := v_err_msg || ' Current CSR capabilities grants are not suitable for audits migration.';
	END IF;
	
	IF bitwise_pkg.bitand(v_result, audit_migration_pkg.FAIL_AUDIT_SUPPORT_SO) = audit_migration_pkg.FAIL_AUDIT_SUPPORT_SO THEN
		v_err_msg := v_err_msg || ' Found non-migratable SO objects in Audits Node.';
	END IF;

	IF bitwise_pkg.bitand(v_result, audit_migration_pkg.AUDIT_TYPES_WITH_ROLES) = audit_migration_pkg.AUDIT_TYPES_WITH_ROLES THEN
		v_err_msg := v_err_msg || ' Found audit types with auditor/ audit contact roles.';
	END IF;

	IF v_result = audit_migration_pkg.NO_NON_WF_AUDITS_FOUND THEN
		RAISE_APPLICATION_ERROR(-20001, TRIM(v_err_msg) || ' No non-WF audits found. Nothing to migrate');
	END IF;

	IF v_result != audit_migration_pkg.VALID_SUCCESS THEN
		RAISE_APPLICATION_ERROR(-20001, TRIM(v_err_msg) || ' This site is not suitable for audit migration. See details in "csr/site/admin/auditmigration/validationfailures.acds" page.');
	END IF;
END;

PROCEDURE EnableTestCube
AS
BEGIN
	csr.scrag_pp_pkg.EnableTestCube;
END;

PROCEDURE EnableScragPP(
	in_approved_ref					IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	csr.scrag_pp_pkg.EnableScragPP(in_approved_ref);
END;

PROCEDURE MigrateAudits	(
	in_force				IN	NUMBER DEFAULT 0
)
AS
BEGIN
	audit_migration_pkg.MigrateAudits(in_force);
END;

PROCEDURE EnableCCOnAlerts
AS
BEGIN
	UPDATE customer
	   SET allow_cc_on_alerts = 1
	 WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE DisableCCOnAlerts
AS
BEGIN
	UPDATE customer
	   SET allow_cc_on_alerts = 0
	 WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE ClearTrashedIndCalcXml(
	in_ind_sid					IN csr.ind.ind_sid%TYPE
)
AS
	v_calcinds_notintrash_count				NUMBER;
	v_inds_referencing_trashed_inds_count	NUMBER;

	v_ind_sids					security_pkg.T_SID_IDS;
	t_sids						security.T_SID_TABLE;	

	v_failing_ind_sid			security_pkg.T_SID_ID;
	v_failing_calc_ind_sid		security_pkg.T_SID_ID;
	v_trashed_ind_sid_count		NUMBER;
	v_max_inds_at_once			NUMBER := 200;
BEGIN

	IF in_ind_sid = -1 OR in_ind_sid = -2 THEN
		t_sids := indicator_pkg.GetTrashedIndSids();
	ELSIF in_ind_sid > 0 THEN
		IF trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid) = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Indicator ' || in_ind_sid || ' is not trashed.');
		END IF;

		v_ind_sids(0) := in_ind_sid;
		t_sids	:= security_pkg.SidArrayToTable(v_ind_sids);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Indicator ' || in_ind_sid || ' is not valid.');
	END IF;

	IF in_ind_sid != -2 THEN
		
		SELECT COUNT(*) 
		  INTO v_trashed_ind_sid_count
		  FROM TABLE(t_sids);

		IF v_trashed_ind_sid_count > v_max_inds_at_once THEN
			-- take first v_max_inds_at_once
			SELECT ind_sid
			  BULK COLLECT INTO t_sids
			  FROM (
					SELECT column_value ind_sid
					  FROM indicator_pkg.GetTrashedIndSids()
					  FETCH FIRST v_max_inds_at_once ROWS ONLY
				);
		END IF;

		SELECT MIN(count(*)), MIN(i.ind_sid), MIN(x.sid)
		  INTO v_calcinds_notintrash_count, v_failing_ind_sid, v_failing_calc_ind_sid
		  FROM csr.ind i
		 CROSS JOIN xmltable('//*' PASSING XMLTYPE.CREATEXML(calc_xml) COLUMNS sid NUMBER(10) PATH '@sid') x
		  JOIN csr.ind ii on ii.ind_sid = x.sid
		 WHERE i.ind_sid IN (SELECT column_value FROM TABLE(t_sids))
		   AND i.calc_xml IS NOT NULL
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND x.sid IS NOT NULL
		   AND trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY', 'ACT'), x.sid) = 0
		 GROUP BY (i.ind_sid, x.sid)
		;

		IF v_calcinds_notintrash_count > 0 AND in_ind_sid > 0
		THEN
			RAISE_APPLICATION_ERROR(-20001, 'Indicator ' || in_ind_sid || ' - not all the indicators referenced in its calc_xml have been trashed.');
		END IF;
		IF v_calcinds_notintrash_count > 0 AND in_ind_sid = -1
		THEN
			RAISE_APPLICATION_ERROR(-20001, 'All Indicators cannot be processed as not all the indicators referenced in the trashed indicator calc_xml''s have been trashed.'||
				' Check Ind '||v_failing_ind_sid||', calc sid '||v_failing_calc_ind_sid);
		END IF;
	END IF;

	UPDATE csr.ind
	   SET ind_type = 0, calc_xml = NULL
	 WHERE ind_sid IN (SELECT column_value FROM TABLE(t_sids))
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM csr.calc_dependency
	 WHERE calc_ind_sid IN (SELECT column_value FROM TABLE(t_sids))
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetCustomerHelperAssembly(
	in_helper_assembly			IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	UPDATE csr.customer
	   SET helper_assembly = in_helper_assembly
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE SetCmsFormsImpSP(
	in_form_id					IN VARCHAR2,
	in_helper_sp				IN VARCHAR2,
	in_delete					IN VARCHAR2,
	in_use_new_sp_sig			IN VARCHAR2,
	in_child_helper_sp			IN VARCHAR2
)
AS
	v_uses_new_sp_sig			NUMBER := 0;
	v_child_helper_sp			VARCHAR2(255);
BEGIN
	IF UPPER(TRIM(in_child_helper_sp)) = 'NULL' OR TRIM(in_child_helper_sp) IS NULL THEN
		v_child_helper_sp := NULL;
	ELSE
		v_child_helper_sp := in_child_helper_sp;
	END IF;

	IF UPPER(in_delete) = 'Y' THEN
		DELETE FROM cms.form_response_import_options
		 WHERE form_id = in_form_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	ELSE
		IF UPPER(in_use_new_sp_sig) = 'Y' THEN
			v_uses_new_sp_sig := 1;
		END IF;
	
		BEGIN
			INSERT INTO cms.form_response_import_options(app_sid, form_id, helper_sp, child_helper_sp, uses_new_sp_signature)
			VALUES(SYS_CONTEXT('SECURITY', 'APP'), in_form_id, in_helper_sp, v_child_helper_sp, v_uses_new_sp_sig);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE cms.form_response_import_options
				   SET helper_sp = in_helper_sp,
					   uses_new_sp_signature = v_uses_new_sp_sig,
					   child_helper_sp = v_child_helper_sp
				 WHERE form_id = in_form_id
				   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END;
	END IF;
END;
FUNCTION SanitiseIndDescForXml(
	in_description		IN	csr.ind_description.description%TYPE
)
RETURN VARCHAR2
AS
	v_description		csr.ind_description.description%TYPE;
BEGIN
	-- Replace characters that mess up the XML. Eg speech marks, angle brackets and
	-- ampersands
	v_description := 
		REPLACE(REPLACE(REPLACE(REPLACE(in_description, '"', CHR(38) || 'quot;'), '<', CHR(38) || 'lt;'), '>', CHR(38) || 'gt;'), CHR(38), CHR(38)||'amp;');
	RETURN v_description;
END;

PROCEDURE CreateAllDataExport(
	in_export_name		IN	automated_export_class.label%TYPE,
	in_dataview_sid		IN	csr.dataview.dataview_sid%TYPE
)
AS
	v_dataview_type_id			csr.dataview.dataview_type_id%TYPE;
	v_class_sid					automated_export_class.automated_export_class_sid%TYPE;
	v_exporter_plugin_id		automated_export_class.exporter_plugin_id%TYPE;
	v_file_writer_plugin_id		automated_export_class.file_writer_plugin_id%TYPE;
	v_dv_settings_id			NUMBER(10);
	v_psp_id					NUMBER(10);
	v_ind_root					csr.ind.ind_sid%TYPE;
	v_langs 					security_pkg.T_VARCHAR2_ARRAY;
	v_translations 				security_pkg.T_VARCHAR2_ARRAY;
	v_impexp_sid				security.security_pkg.T_SID_ID;
BEGIN

	-- Must have imp/exp enabled
	BEGIN
		v_impexp_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'AutomatedExportImport');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'AutomatedExportImport object not found -- Automated import/export must be enabled.');
	END;

	-- Make sure the dataview is a chart
	SELECT dataview_type_id
	  INTO v_dataview_type_id
	  FROM dataview
	 WHERE dataview_sid = in_dataview_sid;
	-- Chart/Data explorer = 1
	IF v_dataview_type_id != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Only charts/Data explorer dataviews are supported.');
	END IF;
	
	SELECT plugin_id
	  INTO v_file_writer_plugin_id
	  FROM auto_exp_file_writer_plugin 
	 WHERE LOWER(label) = 'manual download';
	SELECT plugin_id 
	  INTO v_exporter_plugin_id
	  FROM auto_exp_exporter_plugin 
	 WHERE LOWER(label) = 'dataview - xml mapped dsv';
	csr.automated_export_pkg.CreateDataviewExporterClass(
		in_label					=> in_export_name,
		in_schedule_xml				=> NULL,
		in_file_mask				=> 'all_data.csv',
		in_file_mask_date_format	=> NULL,
		in_email_on_error			=> NULL,
		in_email_on_success			=> NULL,
		in_exporter_plugin_id		=> v_exporter_plugin_id,
		in_file_writer_plugin_id	=> v_file_writer_plugin_id,
		in_include_headings			=> 1,
		in_output_empty_as			=> 'n/a',
		in_dataview_sid				=> in_dataview_sid,
		in_ignore_null_values		=> 0,
		in_mapping_xml				=> SYS.XMLTYPE.CREATEXML('<mappings><column from="SCENARIO_NAME" to="Scenario"/><column from="REGION_SID" to="Region sid"/><column from="REGION_DESCRIPTION" to="Region"/><column from="REGION_EGRID" to="EGrid"/><column from="REGION_GEO_COUNTRY" to="Country"/><column from="IND_SID" to="Indicator sid"/><column from="IND_DESCRIPTION" to="Indicator"/><column from="START_DATE" to="Start Date"/><column from="END_DATE" to="End Date"/><column from="VALUE" to="Value"/><column from="NOTE" to="Note"/></mappings>'),
		in_region_selection_type_id	=> 6,
		in_tag_id					=> NULL,
		in_ind_selection_type_id	=> 0,
		out_class_sid				=> v_class_sid
	);
	
	-- Set the DSV settings
	csr.automated_export_pkg.UpdateDsvSettings(
		in_automated_export_class_sid		=> v_class_sid,
		in_delimiter_id						=> 0, -- Comma
		in_secondary_delimiter_id			=> 1, -- Pipe
		in_encoding_name					=> 'UTF-8'
	);
	
	-- Update the period span
	SELECT aerd.period_span_pattern_id
	  INTO v_psp_id
	  FROM automated_export_class aec
	  JOIN auto_exp_retrieval_dataview aerd on aerd.auto_exp_retrieval_dataview_id = aec.auto_exp_retrieval_dataview_id
	 WHERE automated_export_class_sid = v_class_sid;
	
	csr.period_span_pattern_pkg.UpdatePeriodSpanPattern(
		in_period_span_pattern_id		=> v_psp_id,
		in_period_span_pattern_type_id	=> 1, -- Fixed to now
		in_period_interval_id			=> 1, -- Calendar
		in_period_set_id				=> 1, -- Monthly
		in_from_date					=> add_months(TRUNC(SYSDATE, 'yyyy'), 12*-10),
		in_to_date						=> null,
		in_offset						=> 12,
		in_no_of_rolling_periods		=> 0,
		in_period_in_year				=> 0,
		in_year_offset					=> 0,
		in_end_period_in_year			=> 0,
		in_end_year_offset				=> 0
	);
	
	-- Set the indicators into the dataview
	csr.dataview_pkg.RemoveIndicators(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_sid_id		=> in_dataview_sid
	);
	SELECT ind_root_sid
	  INTO v_ind_root
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	FOR r IN (
		SELECT DISTINCT ind_sid, level lvl, rownum rn, description, format_mask
		  FROM v$ind
	   CONNECT BY PRIOR ind_sid = parent_sid
		 START WITH ind_sid = v_ind_root
		 ORDER BY LEVEL, description
	)
	LOOP
		csr.dataview_pkg.AddIndicator(
			in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_dataview_sid				=> in_dataview_sid,
			in_ind_sid					=> r.ind_sid,
			in_calculation_type_id		=> 0,
			in_format_mask				=> r.format_mask,
			in_measure_conversion_id	=> null,
			in_normalization_ind_sid	=> null,
			in_show_as_rank				=> 0,
			in_langs					=> v_langs,
			in_translations				=> v_translations
		);

	END LOOP;
	
END;

PROCEDURE TerminatedClientData(
	in_setup			IN 	NUMBER
)
AS
	v_class_sid					automated_export_class.automated_export_class_sid%TYPE;
	v_exporter_plugin_id		automated_export_class.exporter_plugin_id%TYPE;
	v_file_writer_plugin_id		automated_export_class.file_writer_plugin_id%TYPE;
	v_impexp_sid				security.security_pkg.T_SID_ID;
	v_export_class_label		automated_export_class.label%TYPE := 'Terminated Client Data Export';
	v_count						NUMBER := 0;
BEGIN

	BEGIN
		  IF in_setup NOT IN (0, 1) THEN
			RAISE_APPLICATION_ERROR(-20001, 'in_setup value must be 0 or 1');
		  END IF;
	END;

	BEGIN
		v_impexp_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'AutomatedExportImport');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'AutomatedExportImport object not found -- Automated import/export must be enabled.');
	END;
	
	SELECT plugin_id
	  INTO v_file_writer_plugin_id
	  FROM auto_exp_file_writer_plugin 
	 WHERE LOWER(label) = 'manual download';

	SELECT plugin_id 
	  INTO v_exporter_plugin_id
	  FROM auto_exp_exporter_plugin 
	 WHERE LOWER(label) = 'client termination dsv';

	BEGIN
		csr.automated_export_pkg.GetClassCountByLabel(
			in_label		=> v_export_class_label,
			out_count		=> v_count
		);

		IF v_count > 0 AND in_setup = 0 THEN

			SELECT automated_export_class_sid
			  INTO v_class_sid
			  FROM automated_export_class
			 WHERE label = v_export_class_label
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

			DELETE
		  	  FROM automated_export_instance 
		 	 WHERE automated_export_class_sid = v_class_sid
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

			security.securableobject_pkg.DeleteSO(
				in_act_id		=> security.security_pkg.GetACT,
				in_sid_id		=> v_class_sid
			);
			
		ELSIF v_count = 0 AND in_setup = 1 THEN

			csr.automated_export_pkg.CreateClass(
				in_parent					=> v_impexp_sid,
				in_label					=> v_export_class_label,
				in_schedule_xml				=> NULL,
				in_file_mask				=> 'all_data.csv',
				in_file_mask_date_format	=> NULL,
				in_email_on_error			=> NULL,
				in_email_on_success			=> NULL,
				in_exporter_plugin_id		=> v_exporter_plugin_id,
				in_file_writer_plugin_id	=> v_file_writer_plugin_id,
				in_include_headings			=> 1,
				in_output_empty_as			=> 'n/a',
				in_lookup_key				=> sys_guid(),
				out_class_sid				=> v_class_sid
			);

			-- Set the DSV settings
			csr.automated_export_pkg.UpdateDsvSettings(
				in_automated_export_class_sid		=> v_class_sid,
				in_delimiter_id						=> 0, -- Comma
				in_secondary_delimiter_id			=> 1, -- Pipe
				in_encoding_name					=> 'UTF-8'
			);
		END IF;
	END;
END;

PROCEDURE ToggleViewSourceToDeepestSheet(
	in_enable			IN	NUMBER
)
AS
BEGIN
	IF in_enable != 0 AND in_enable != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid enable/disable flag (Enable = 1, Disable = 0)');
	END IF;

	UPDATE csr.customer
	   SET iss_view_src_to_deepest_sheet = in_enable
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

-- Internal
PROCEDURE SetCaldDependenciesInDataExport(
	in_calc_ind_sid				IN	csr.ind.ind_sid%TYPE,
	in_dataview_sid				IN	csr.dataview.dataview_sid%TYPE
)
AS
	v_langs 			security_pkg.T_VARCHAR2_ARRAY;
	v_translations 		security_pkg.T_VARCHAR2_ARRAY;
	v_chart_config 		csr.dataview.chart_config_xml%TYPE := '<worksheets><worksheet sid="-1" instance="0" label="Values" dataview_ind_sid="0" show_as_rank="0" >';
	v_last_level		NUMBER := -1;
	v_unclosed_nodes	NUMBER := 0;
BEGIN

	csr.dataview_pkg.RemoveIndicators(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_sid_id		=> in_dataview_sid
	);

		FOR r IN (
		SELECT DISTINCT cd.ind_sid, level lvl, rownum rn, 
		       util_script_pkg.SanitiseIndDescForXml(description) description, format_mask
		  FROM csr.v$calc_dependency cd 
		  JOIN v$ind i ON i.ind_sid = cd.ind_sid
	   CONNECT BY PRIOR cd.ind_sid = calc_ind_sid
		 START WITH calc_ind_sid = in_calc_ind_sid
		UNION
		SELECT ind_sid, 0 lvl, 0 rn, 
			   util_script_pkg.SanitiseIndDescForXml(description) description, format_mask
		  FROM v$ind
		 WHERE ind_sid = in_calc_ind_sid
		 ORDER BY rn ASC
	)
	LOOP
		IF v_last_level > -1 THEN
			IF v_last_level = r.lvl THEN
				-- Same level, so no children. Close the node.
				dbms_lob.append(v_chart_config, '/>');
			ELSIF r.lvl < v_last_level THEN
				-- We're going back up the tree so close the current node
				dbms_lob.append(v_chart_config, '/>');
				-- And now close the parent levels we have gone back through
				FOR i IN r.lvl..v_last_level-1
				LOOP
					dbms_lob.append(v_chart_config, '</section-or-ind>');
					v_unclosed_nodes := v_unclosed_nodes - 1;
				END LOOP;
			ELSE
				-- Deeper level, so this ind has children. Make it an open node.
				dbms_lob.append(v_chart_config, '>');
				v_unclosed_nodes := v_unclosed_nodes + 1;
			END IF;
		END IF;
		
		v_langs(1) := 'en';
		v_translations(1) := r.description;
		csr.dataview_pkg.AddIndicator(
			in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_dataview_sid				=> in_dataview_sid,
			in_ind_sid					=> r.ind_sid,
			in_calculation_type_id		=> 0,
			in_format_mask				=> r.format_mask,
			in_measure_conversion_id	=> null,
			in_normalization_ind_sid	=> null,
			in_show_as_rank				=> 0,
			in_langs					=> v_langs,
			in_translations				=> v_translations
		);
		dbms_lob.append(v_chart_config, '<section-or-ind sid="' ||r.ind_sid|| '" instance="0" label="'||r.description||'" dataview_ind_sid="'||r.ind_sid||'" show_as_rank="0" ');

		v_last_level := r.lvl;

	END LOOP;
	-- Close all remaining nodes
	dbms_lob.append(v_chart_config, '/>');
	FOR i IN 0..v_unclosed_nodes-1
	LOOP
		dbms_lob.append(v_chart_config, '</section-or-ind>');
	END LOOP;
	
	dbms_lob.append(v_chart_config, '</worksheet></worksheets>');
	UPDATE csr.dataview
	   SET chart_config_xml = v_chart_config
	 WHERE dataview_sid = in_dataview_sid;
END;

-- Internal
PROCEDURE SetCaldDependenciesInDataExplorer(
	in_calc_ind_sid				IN	csr.ind.ind_sid%TYPE,
	in_dataview_sid				IN	csr.dataview.dataview_sid%TYPE
)
AS
	v_langs security_pkg.T_VARCHAR2_ARRAY;
	v_translations security_pkg.T_VARCHAR2_ARRAY;
BEGIN

	csr.dataview_pkg.RemoveIndicators(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_sid_id		=> in_dataview_sid
	);

	FOR r IN (
		SELECT DISTINCT cd.ind_sid, level lvl, rownum rn, 
		       util_script_pkg.SanitiseIndDescForXml(description) description, format_mask
		  FROM csr.v$calc_dependency cd 
		  JOIN v$ind i ON i.ind_sid = cd.ind_sid
	   CONNECT BY PRIOR cd.ind_sid = calc_ind_sid
		 START WITH calc_ind_sid = in_calc_ind_sid
		UNION
		SELECT ind_sid, 0 lvl, 0 rn, 
			   util_script_pkg.SanitiseIndDescForXml(description) description, format_mask
		  FROM v$ind
		 WHERE ind_sid = in_calc_ind_sid
		 ORDER BY rn ASC
	)
	LOOP
		csr.dataview_pkg.AddIndicator(
			in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_dataview_sid				=> in_dataview_sid,
			in_ind_sid					=> r.ind_sid,
			in_calculation_type_id		=> 0,
			in_format_mask				=> r.format_mask,
			in_measure_conversion_id	=> null,
			in_normalization_ind_sid	=> null,
			in_show_as_rank				=> 0,
			in_langs					=> v_langs,
			in_translations				=> v_translations
		);

	END LOOP;
END;

PROCEDURE SetCalcDependenciesInDataview(
	in_calc_ind_sid				IN	csr.ind.ind_sid%TYPE,
	in_dataview_sid				IN	csr.dataview.dataview_sid%TYPE
)
AS
	v_dataview_type_id			csr.dataview.dataview_type_id%TYPE;
	v_ind_type					csr.ind.ind_type%TYPE;
	v_calc_xml					csr.ind.calc_xml%TYPE;
BEGIN
	-- Validate ind is a calc
	SELECT ind_type, calc_xml
	  INTO v_ind_type, v_calc_xml
	  FROM csr.ind
	 WHERE ind_sid = in_calc_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_ind_type NOT IN (1, 2) OR v_calc_xml IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Indicator is not a calc.');
	END IF;
	
	-- Get dataview type
	SELECT dataview_type_id
	  INTO v_dataview_type_id
	  FROM dataview
	 WHERE dataview_sid = in_dataview_sid;
	 
	-- Excel/Data export = 2
	-- Chart/Data explorer = 1
	IF v_dataview_type_id = 1 THEN
		SetCaldDependenciesInDataExplorer(
			in_calc_ind_sid		=> in_calc_ind_sid,
			in_dataview_sid		=> in_dataview_sid
		);
	ELSIF v_dataview_type_id = 2 THEN
		SetCaldDependenciesInDataExport(
			in_calc_ind_sid		=> in_calc_ind_sid,
			in_dataview_sid		=> in_dataview_sid
		);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised dataview type.');
	END IF;
END;

/*
	Util script page procedures
	
	Please place the actual enable scripts above this block.
*/
FUNCTION CleanLookupKey (
	in_label	VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	RETURN UPPER(
			REPLACE(
				REGEXP_REPLACE(
					REGEXP_REPLACE(in_label, '( *[[:punct:]])', ' '),
					'( ){2,}',
					' '),
				' ',
				'_')
		   );
END;

PROCEDURE AddClientUtilScript(
    in_util_script_name             IN  client_util_script.util_script_name%TYPE,
    in_description                  IN  client_util_script.description%TYPE,
    in_util_script_sp               IN  client_util_script.util_script_sp%TYPE,
    in_wiki_article                 IN  client_util_script.wiki_article%TYPE,
    out_util_script_id              OUT client_util_script.client_util_script_id%TYPE
)
AS
BEGIN
	INSERT INTO csr.client_util_script (client_util_script_id, util_script_name, description, util_script_sp, wiki_article)
		 VALUES (client_util_script_id_seq.NEXTVAL, in_util_script_name, in_description, in_util_script_sp, in_wiki_article)
	  RETURNING client_util_script_id INTO out_util_script_id;
END;

PROCEDURE AddClientUtilScriptParam(
    in_client_util_script_id        IN client_util_script_param.client_util_script_id%TYPE,
    in_param_name                   IN client_util_script_param.param_name%TYPE,
    in_param_hint                   IN client_util_script_param.param_hint%TYPE,
    in_param_pos                    IN client_util_script_param.pos%TYPE,
    in_param_value                  IN client_util_script_param.param_value%TYPE,
    in_param_hidden                 IN client_util_script_param.param_hidden%TYPE
)
AS
BEGIN
	INSERT INTO csr.client_util_script_param (client_util_script_id, param_name, param_hint, pos, param_value, param_hidden)
		 VALUES (in_client_util_script_id, in_param_name, in_param_hint, in_param_pos, in_param_value, in_param_hidden);
END;

PROCEDURE GetAllUtilScripts(
    out_generic_cur                 OUT SYS_REFCURSOR,
    out_specific_cur                OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_generic_cur FOR
		SELECT util_script_id, util_script_name, description, wiki_article
          FROM csr.util_script
		 ORDER BY util_script_name ASC;

    OPEN out_specific_cur FOR
        SELECT client_util_script_id, util_script_name, description, wiki_article
          FROM csr.client_util_script
      ORDER BY util_script_name ASC;
END;

PROCEDURE GetUtilScriptParams(
	in_util_script_id	IN util_script.util_script_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT param_name, param_hint, pos, param_value, param_hidden
		  FROM util_script_param
		 WHERE util_script_id = in_util_script_id
		 ORDER BY pos ASC;
END;

PROCEDURE GetClientUtilScriptParams(
	in_client_util_script_id	IN client_util_script.client_util_script_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT param_name, param_hint, pos, param_value, param_hidden
		  FROM client_util_script_param
		 WHERE client_util_script_id = in_client_util_script_id
		 ORDER BY pos ASC;
END;

PROCEDURE GetEnableSP(
	in_util_script_id	IN util_script.util_script_id%TYPE,
	out_script_sp		OUT util_script.util_script_sp%TYPE
)
AS
BEGIN
	SELECT util_script_sp
	  INTO out_script_sp
	  FROM util_script
	 WHERE util_script_id = in_util_script_id;
END;

PROCEDURE GetClientEnableSP(
	in_client_util_script_id	IN  client_util_script.client_util_script_id%TYPE,
	out_script_sp				OUT client_util_script.util_script_sp%TYPE
)
AS
BEGIN
	SELECT util_script_sp
	  INTO out_script_sp
	  FROM client_util_script
	 WHERE client_util_script_id = in_client_util_script_id;
END;

PROCEDURE LogScriptRun(
	in_util_script_id	IN	util_script.util_script_id%TYPE,
	in_user_sid			IN	util_script_run_log.csr_user_sid%TYPE,
	in_param_string		IN	util_script_run_log.params%TYPE
)
AS
BEGIN
	INSERT INTO util_script_run_log (util_script_id, csr_user_sid, run_dtm)
		 VALUES (in_util_script_id, in_user_sid, SYSDATE);
END;

PROCEDURE LogClientScriptRun(
	in_client_util_script_id	IN	client_util_script.client_util_script_id%TYPE,
	in_user_sid					IN	util_script_run_log.csr_user_sid%TYPE,
	in_param_string				IN	util_script_run_log.params%TYPE
)
AS
BEGIN
	INSERT INTO util_script_run_log (client_util_script_id, csr_user_sid, run_dtm)
		 VALUES (in_client_util_script_id, in_user_sid, SYSDATE);
END;

PROCEDURE SetRegionLookupKey(
	in_region_sid				IN SECURITY_PKG.T_SID_ID,
	in_lookup_key				IN csr.region.lookup_key%TYPE
)
AS
	v_lookup_key				csr.region.lookup_key%TYPE := in_lookup_key;
BEGIN
	IF in_lookup_key = '#CLEAR#' THEN
		v_lookup_key := NULL;
	END IF;

	UPDATE csr.region
	   SET lookup_key = v_lookup_key
	 WHERE region_sid = in_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE EnableJavaAuth
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_users							security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Users');
BEGIN
	UPDATE customer
	   SET enable_java_auth = 1
	 WHERE customer.app_sid = v_app_sid;

	-- Apply to users that are directly owned by the site (i.e. exclude super admins, but include trashed users)
	FOR u IN (SELECT cu.csr_user_sid
		        FROM csr.csr_user cu
				JOIN security.securable_object so ON so.sid_id = cu.csr_user_sid
		   LEFT JOIN csr.trash t ON t.app_sid = so.application_sid_id AND t.trash_sid = so.sid_id
			   WHERE so.parent_sid_id = v_users OR t.previous_parent_sid = v_users)
	LOOP
		security.user_pkg.EnableJavaAuth(u.csr_user_sid);
	END LOOP;
END;

PROCEDURE DisableJavaAuth
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act							security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_users							security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Users');
BEGIN
	UPDATE customer
	   SET enable_java_auth = 0
	 WHERE customer.app_sid = v_app_sid;

	FOR u IN (SELECT cu.csr_user_sid
		        FROM csr.csr_user cu
				JOIN security.securable_object so ON so.sid_id = cu.csr_user_sid
		   LEFT JOIN csr.trash t ON t.app_sid = so.application_sid_id AND t.trash_sid = so.sid_id
			   WHERE so.parent_sid_id = v_users OR t.previous_parent_sid = v_users)
	LOOP
		security.user_pkg.DisableJavaAuth(u.csr_user_sid);
	END LOOP;
END;

PROCEDURE SetupStandaloneIssueType
AS
BEGIN
	issue_pkg.SetupStandaloneIssueType;
END;

PROCEDURE RecalcLogistics (
	in_transport_mode			IN transport_mode.transport_mode_id%TYPE
)
AS
	v_test_id NUMBER;
BEGIN
	AssertSuperAdmin;
	
	SELECT MIN(app_sid)
	  INTO v_test_id
	  FROM logistics_tab_mode
	 WHERE app_sid = security.security_pkg.GetApp;
	
	IF v_test_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Logistics is not enabled.');
	END IF;
	
	SELECT MIN(transport_mode_id)
	  INTO v_test_id
	  FROM transport_mode
	 WHERE transport_mode_id = in_transport_mode;
	 
	IF v_test_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown transport mode.');
	END IF;
	
	UPDATE logistics_tab_mode
	   SET processing = 0, is_dirty = 1
	 WHERE app_sid = security.security_pkg.GetApp 
	   AND transport_mode_id = in_transport_mode;
END;
PROCEDURE ToggleRenderChartsAsSvg
AS
BEGIN
	csr.customer_pkg.ToggleRenderChartsAsSvg;
END;

PROCEDURE SetAuditCalcChangesFlag(
	in_flag_value			IN NUMBER
)
AS
BEGIN
	UPDATE csr.customer 
	   SET audit_calc_changes = in_flag_value 
	 WHERE app_sid = security.security_pkg.getApp;
END;

PROCEDURE SetCheckToleranceAgainstZeroFlag(
	in_flag_value			IN NUMBER
)
AS
BEGIN
	UPDATE csr.customer 
	   SET check_tolerance_against_zero = in_flag_value 
	 WHERE app_sid = security.security_pkg.getApp;
END;

PROCEDURE ResetAnonymisePiiDataPermissions
AS
v_act_id					security.security_pkg.T_ACT_ID;
v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
v_capabilities				security.security_pkg.T_SID_ID;
v_anonymise_pii				security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_act_id := security.security_pkg.GetAct;
		v_capabilities := security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.getApp, 'Capabilities');
		v_anonymise_pii := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities, 'Anonymise PII data');

		security.securableobject_pkg.SetFlags(v_act_id, v_anonymise_pii, 0);
		security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_anonymise_pii));
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_anonymise_pii), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Please enable the "Anonymise PII data" capability first');
	END;
END;

PROCEDURE INTERNAL_AddAceForCapability (
	in_capability_name			IN	VARCHAR2,
	in_sid						IN	security.security_pkg.T_SID_ID
)
AS
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_count					NUMBER;
BEGIN
	v_capability_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, '/Capabilities/'||in_capability_name);

	SELECT COUNT(*)
	  INTO v_count
	  FROM security.ACL
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_capability_sid)
	   AND sid_id = in_sid
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_All;

	IF v_count = 0 THEN
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_capability_sid), security.security_pkg.ACL_INDEX_LAST,
			security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, in_sid, security.security_pkg.PERMISSION_STANDARD_All);
	END IF;
END;

PROCEDURE TryAddACE(
	in_act_id			SECURITY.SECURITY_PKG.T_ACT_ID,
	in_app_sid			SECURITY.SECURITY_PKG.T_SID_ID,
	in_so_sid			security.security_pkg.T_SID_ID,
	in_sid				security.security_pkg.T_SID_ID,
	in_permission		security.security_pkg.T_PERMISSION DEFAULT security.security_pkg.PERMISSION_STANDARD_READ
)
AS
	v_acl_id			security.security_pkg.T_ACL_ID;
BEGIN
	BEGIN
		v_acl_id := security.acl_pkg.GetDACLIDForSID(in_so_sid);
		
		security.acl_pkg.RemoveACEsForSid(in_act_id, v_acl_id, in_sid);		
		security.acl_pkg.AddACE(
			in_act_id,
			v_acl_id,
			security_pkg.ACL_INDEX_LAST,
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			in_sid,
			in_permission
		);
		
		security.acl_pkg.PropogateACEs(in_act_id, in_so_sid);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;

PROCEDURE TryAddACE(
	in_act_id			SECURITY.SECURITY_PKG.T_ACT_ID,
	in_app_sid			SECURITY.SECURITY_PKG.T_SID_ID,
	in_acl_path			VARCHAR2,
	in_sid				security.security_pkg.T_SID_ID,
	in_permission		security.security_pkg.T_PERMISSION DEFAULT security.security_pkg.PERMISSION_STANDARD_READ
)
AS
	v_sid_id			security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_sid_id := security.securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, in_acl_path);
		TryAddACE(in_act_id, in_app_sid, v_sid_id, in_sid, in_permission);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;

PROCEDURE CreateChainSystemAdminRole(
	in_secondary_company_type_id	IN  chain.company_type.company_type_id%TYPE
)
AS
	v_act_id				security.security_pkg.T_ACT_ID := SYS_CONTEXT('security','act');
	v_app_sid				security.security_pkg.T_SID_ID := SYS_CONTEXT('security','app');
	
	v_groups_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_admins_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_client_admins_sid		SECURITY.SECURITY_PKG.T_SID_ID;	
	v_chain_admins_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_superadmins_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_chain_users 			security.security_pkg.T_SID_ID;
	v_top_companies			security.security_pkg.T_SID_ID;
	v_dummy_cur				security.security_pkg.T_OUTPUT_CUR;
	v_out_sid				security.security_pkg.T_SID_ID;
	v_top_company_type_id	chain.company_type.company_type_id%TYPE;

	v_users_sid				SECURITY.SECURITY_PKG.T_SID_ID;
	v_perms_set				security.permission_name.permission%TYPE;
	
	v_role_sid				security.security_pkg.T_SID_ID;
	v_workflows_sid			security.security_pkg.T_SID_ID;
	v_campaigns_sid			security.security_pkg.T_SID_ID;
	v_dashboards_sid		security.security_pkg.T_SID_ID;	
BEGIN
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_client_admins_sid     := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');	
	v_chain_admins_sid    	:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Chain Administrators');
	v_chain_users    		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Chain Users');
	v_admins_sid 			:= security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'BuiltIn/Administrators');
	v_superadmins_sid 		:= security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	
	-- Create new role
	role_pkg.SetRole(v_act_id, v_app_sid, 'System Administrators', 'CHAIN_SYSTEM_ADMIN', v_role_sid);
	
	SELECT company_type_id
	  INTO v_top_company_type_id
	  FROM chain.company_type
	 WHERE is_top_company = 1;
	
	chain.company_type_pkg.SetCompanyTypeRole (
		in_company_type_id		=> v_top_company_type_id,
		in_role_sid				=> v_role_sid,
		in_role_name			=> 'System Administrators',
		in_mandatory			=> 0,
		in_cascade_to_supplier	=> 0,
		in_pos					=> NULL,
		in_lookup_key			=> 'CHAIN_SYSTEM_ADMIN',
		out_cur					=> v_dummy_cur
	);
	
	-- Give access to key players
	security.securableObject_pkg.ClearFlag(v_act_id, v_role_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_client_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_chain_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	-- Add role to existing groups
	security.group_pkg.AddMember(
		in_act_id		=> v_act_id,
		in_member_sid	=> v_role_sid,
		in_group_sid	=> security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Branding Administrator')
	);
	security.group_pkg.AddMember(
		in_act_id		=> v_act_id,
		in_member_sid	=> v_role_sid,
		in_group_sid	=> security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Supply Chain Managers')
	);
	-- Add Chain Admins to role
	security.group_pkg.AddMember(
		in_act_id		=> v_act_id,
		in_member_sid	=> v_chain_admins_sid,
		in_group_sid	=> v_role_sid
	);
	-- TOP -> Supplier
	BEGIN
	-- Company Details -> Suppliers
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SUPPLIERS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);	
	-- Company Details -> Alternative company names
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ALT_COMPANY_NAMES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Company Details -> Company scores
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPANY_SCORES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);
    -- Company Details -> Company Tags
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPANY_TAGS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);
    -- Company Details -> View company extra details
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_EXTRA_DETAILS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Company Details -> View company score log
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_COMPANY_SCORE_LOG),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Business Relationships -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPDATE_BUSINESS_REL_PERIODS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Users -> Company user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPANY_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);	
    -- Users -> Add user to company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ADD_USER_TO_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
	-- Users -> Create user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
	-- Users -> Edit user email address
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.EDIT_USERS_EMAIL_ADDRESS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
	-- Users -> Manage user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
	-- Users -> Promote user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PROMOTE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
	-- Users -> Remove user from company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.REMOVE_USER_FROM_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
	-- Users -> Reset password
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.RESET_PASSWORD),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	-- Users -> Specify user name
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.SPECIFY_USER_NAME),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Survey Invitation -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.APPROVE_QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_USER_WITH_INVITE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REJECT_QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUESTIONNAIRE_INVITE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUEST_INV_TO_EXIST_COMPAN),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUEST_INV_TO_NEW_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.AUDIT_QUESTIONNAIRE_RESPONSES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_QUESTIONNAIRE_TYPE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_QUESTIONNAIRE_SECURITY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.QUERY_QUESTIONNAIRE_ANSWERS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.SETUP_STUB_REGISTRATION),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.SUBMIT_QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Onboarding -> Change supplier follower
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CHANGE_SUPPLIER_FOLLOWER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Onboarding -> Create company as subsidiary
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_COMPANY_AS_SUBSIDIARY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Onboarding -> Create company user without invitation
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_USER_WITHOUT_INVITE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Onboarding -> Create company without invitation
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_COMPANY_WITHOUT_INVIT),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Onboarding -> Create relationship with supplier
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_RELATIONSHIP),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Onboarding -> Edit own followeer status
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Onboarding -> Supplier with no established relationship
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SUPPLIER_NO_RELATIONSHIP),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	
    -- Onboarding -> Deactivate company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.DEACTIVATE_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Advanced -> All False/None
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_COMPANY_INVITE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_INVITE_ON_BEHALF_OF),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ADD_PRODUCT_SUPPLIER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPONENTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_PRODUCTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CT_HOTSPOTTER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.EVENTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_ACTIVITIES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_PRODUCT_CERT_REQS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.METRICS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_CERTIFICATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_CODE_TYPES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_METRIC_VAL),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRD_SUPP_METRIC_VAL),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_SUPPLIER_CERTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_SUPPLIERS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.TASKS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> Manage Workflows: false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.MANAGE_WORKFLOWS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
    -- Other -> Actions: Read/Write
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ACTIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);
    -- Other -> Create supplier audit: true
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_SUPPLIER_AUDITS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Other -> Request audits: false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_AUDIT_REQUESTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> Uploaded file: Read/Write
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPLOADED_FILE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);
    -- Other -> View certifications: False
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_CERTIFICATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> View supplier audits: True
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_SUPPLIER_AUDITS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
	END;
	-- TOP -> Self
	BEGIN
	-- Company Details -> Company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);	
	-- Company Details -> Alternative company names
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ALT_COMPANY_NAMES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Company Details -> Company scores
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPANY_SCORES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Company Details -> Company Tags
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPANY_TAGS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Company Details -> View company score log
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_COMPANY_SCORE_LOG),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Business Relationships -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.UPDATE_BUSINESS_REL_PERIODS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Users -> Company user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPANY_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);
    -- Users -> Add user to company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ADD_USER_TO_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Users -> Create user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Users -> Edit own email address
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EDIT_OWN_EMAIL_ADDRESS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Users -> Edit user email address
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EDIT_USERS_EMAIL_ADDRESS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Users -> Manage user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.MANAGE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Users -> Promote user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PROMOTE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Users -> Remove user from company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.REMOVE_USER_FROM_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Users -> Reset password
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.RESET_PASSWORD),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Users -> Specify user name
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SPECIFY_USER_NAME),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Survey Invitation -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_QUESTIONNAIRE_TYPE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.MANAGE_QUESTIONNAIRE_SECURITY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SETUP_STUB_REGISTRATION),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SUBMIT_QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Advanced -> All False/None
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_CMS_COMPANIES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_COMPANY_AUDITS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.RECEIVE_USER_TARGETED_NEWS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_NEWSFLASH),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPONENTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_PRODUCTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CT_HOTSPOTTER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EVENTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.MANAGE_PRODUCT_CERT_REQS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.METRICS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_CERTIFICATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_CODE_TYPES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_METRIC_VAL),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_METRIC_VAL_AS_SUPP),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRD_SUPP_METRIC_VAL_AS_SUPP),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCTS_AS_SUPPLIER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.TASKS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> Is Top Company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.IS_TOP_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
    -- Other -> Actions
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ACTIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> Uploaded file
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.UPLOADED_FILE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> View certifications
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_CERTIFICATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> View country risk levels
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_COUNTRY_RISK_LEVELS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	END;
	-- Read access on "Chain Users" group
	TryAddACE(v_act_id, v_app_sid, 'groups/Chain Users', v_role_sid);
	-- Read access on "Top Companies"/"Companies" role
	TryAddACE(v_act_id, v_app_sid, 'groups/Top companies', v_role_sid); -- Chain 2 tier
	TryAddACE(v_act_id, v_app_sid, 'groups/Companies', v_role_sid); -- Chain 1 tier
	-- Add user page permissions
	BEGIN
	csr_data_pkg.enablecapability('Edit user accessibility', 1);
	INTERNAL_AddAceForCapability('Edit user accessibility', v_role_sid);
	csr_data_pkg.enablecapability('Edit user active', 1);
	INTERNAL_AddAceForCapability('Edit user active', v_role_sid);	
	csr_data_pkg.enablecapability('Edit user details', 1);
	INTERNAL_AddAceForCapability('Edit user details', v_role_sid);	
	csr_data_pkg.enablecapability('Edit user groups', 1);
	INTERNAL_AddAceForCapability('Edit user groups', v_role_sid);
	csr_data_pkg.enablecapability('Edit user line manager', 1);
	INTERNAL_AddAceForCapability('Edit user line manager', v_role_sid);	
	csr_data_pkg.enablecapability('Edit user region association', 1);
	INTERNAL_AddAceForCapability('Edit user region association', v_role_sid);
	csr_data_pkg.enablecapability('Edit user regional settings', 1);
	INTERNAL_AddAceForCapability('Edit user regional settings', v_role_sid);
	csr_data_pkg.enablecapability('Edit user roles', 1);
	INTERNAL_AddAceForCapability('Edit user roles', v_role_sid);
	csr_data_pkg.enablecapability('Edit user starting points', 1);
	INTERNAL_AddAceForCapability('Edit user starting points', v_role_sid);
	csr_data_pkg.enablecapability('Edit user delegation cover', 1);
	INTERNAL_AddAceForCapability('Edit user delegation cover', v_role_sid);
	csr_data_pkg.enablecapability('Issue management', 1);
	INTERNAL_AddAceForCapability('Issue management', v_role_sid);
	csr_data_pkg.enablecapability('View alert bounces', 1);
	INTERNAL_AddAceForCapability('View alert bounces', v_role_sid);
	csr_data_pkg.enablecapability('Manage any portal', 1);
	INTERNAL_AddAceForCapability('Manage any portal', v_role_sid);
	csr_data_pkg.enablecapability('Quick chart management', 1);
	INTERNAL_AddAceForCapability('Quick chart management', v_role_sid);
	END;	
	-- SO Permissions
	BEGIN
	TryAddACE(v_act_id, v_app_sid, '', v_role_sid, security_pkg.PERMISSION_STANDARD_ALL + csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA);
	
	SELECT permission
	  INTO v_perms_set
	  FROM security.permission_name pn
	  JOIN security.securable_object_class soc ON pn.class_id = soc.class_id
	 WHERE permission_name = 'Logon as another user'
	   AND class_name = 'CSRUserGroup';
	
	TryAddACE(v_act_id, v_app_sid, 'Groups/RegisteredUsers', v_role_sid, v_perms_set);
	TryAddACE(v_act_id, v_app_sid, 'Users', v_role_sid, 507); -- All - Delete and Add
	TryAddACE(v_act_id, v_app_sid, 'Workflows', v_role_sid, security_pkg.PERMISSION_STANDARD_ALL);
	TryAddACE(v_act_id, v_app_sid, 'Campaigns', v_role_sid, security_pkg.PERMISSION_STANDARD_ALL);
	TryAddACE(v_act_id, v_app_sid, 'Dashboards', v_role_sid, security_pkg.PERMISSION_STANDARD_ALL);
	TryAddACE(v_act_id, v_app_sid, 'Documents', v_role_sid, security_pkg.PERMISSION_STANDARD_ALL);
	TryAddACE(v_act_id, v_app_sid, 'Documents/Documents', v_role_sid, security_pkg.PERMISSION_STANDARD_ALL);
	TryAddACE(v_act_id, v_app_sid, 'Documents/Recycle bin', v_role_sid, security_pkg.PERMISSION_STANDARD_ALL);
	TryAddACE(v_act_id, v_app_sid, 'cms', v_role_sid);
	END;
	-- Remove write on users from Chain Users
	security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_users_sid), v_chain_users);
	-- Add read on users to Chain Users
	TryAddACE(v_act_id, v_app_sid, 'Users', v_chain_users);	
	-- Add write on users to Chain Admins
	TryAddACE(v_act_id, v_app_sid, 'Users', v_chain_admins_sid, security_pkg.PERMISSION_STANDARD_ALL);
	TryAddACE(v_act_id, v_app_sid, 'Users', v_role_sid, security_pkg.PERMISSION_STANDARD_ALL);
	-- Add menu items
	BEGIN
	TryAddACE(v_act_id, v_app_sid, 'menu/admin', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_users_list', v_role_sid); -- Users
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_quicksurvey_admin', v_role_sid); -- Surveys
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_quicksurvey_campaignlist', v_role_sid); -- Campaigns
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_portal_admin_tabmatrix', v_role_sid); -- Home Page Tabs	
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_alerts_template', v_role_sid); -- Alert Setup	
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_alerts_sent', v_role_sid); -- Sent alerts
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_alerts_messages', v_role_sid); -- Alert Outbox	
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_alerts_bounces', v_role_sid); -- Alert Bounces
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/filters_manage_alerts', v_role_sid); -- Filter Alerts
	BEGIN
		security.menu_pkg.CreateMenu(
			v_act_id,
			security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Menu/admin'),
			'filters_subscribe_alerts',
			'Filter alert subscriptions',
			'/csr/site/filters/alertsubscriptions.acds',
			-1, null, v_out_sid);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		NULL;
	END;
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/filters_subscribe_alerts', v_role_sid); -- Filter Alert Subscriptions	
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_flow_admin', v_role_sid); -- Workflows	
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_schema_tag_groups', v_role_sid); -- Categories
	TryAddACE(v_act_id, v_app_sid, 'menu/admin/csr_auditlog_reports', v_role_sid); -- Audit Logs
	TryAddACE(v_act_id, v_app_sid, 'menu/ia/csr_default_non_compliances', v_role_sid); -- Default Findings
	TryAddACE(v_act_id, v_app_sid, 'menu/data/csr_issue', v_role_sid); -- Actions
	TryAddACE(v_act_id, v_app_sid, 'menu/chain/csr_issue', v_role_sid); -- Actions (in case they have already moved it under chain)
	TryAddACE(v_act_id, v_app_sid, 'menu/data/csr_calendar', v_role_sid); -- Calendar
	TryAddACE(v_act_id, v_app_sid, 'menu/chain/csr_calendar', v_role_sid); -- Calendar (in case they have already moved it under chain)
	BEGIN
		security.menu_pkg.CreateMenu(
			v_act_id,
			security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Menu/chain'),
			'survey_resp',
			'Survey Responses',
			'/csr/site/quicksurvey/responselist.acds',
			-1, null, v_out_sid);
	EXCEPTION
	  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		NULL;
	END;
	TryAddACE(v_act_id, v_app_sid, 'menu/chain/survey_resp', v_role_sid); -- Survey Responses
	END;
	-- Add web resources
	BEGIN
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/surveys', v_role_sid, 197631); -- STANDARD ALL + View all results + Publish
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/users', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/alerts', v_role_sid);	
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/flow/admin', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/admin', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/portal/admin', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/auditlog', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/quickSurvey', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/quickSurvey/admin', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, 'wwwroot/csr/site/mail', v_role_sid);
	TryAddACE(v_act_id, v_app_sid, alert_pkg.GetSystemMailbox('Outbox'), v_role_sid);
	TryAddACE(v_act_id, v_app_sid, alert_pkg.GetSystemMailbox('Sent'), v_role_sid);
	END;
END;

PROCEDURE CreateSupplierAdminRole(
	in_secondary_company_type_id	IN  chain.company_type.company_type_id%TYPE
)
AS
	v_act_id				security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid				security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_dummy_cur				security.security_pkg.T_OUTPUT_CUR;
	v_top_company_type_id	chain.company_type.company_type_id%TYPE;
	v_role_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Create new role
	role_pkg.SetRole(v_act_id, v_app_sid, 'Supplier Administrators', 'CHAIN_SUPPLIER_ADMIN', v_role_sid);
	
	SELECT company_type_id
	  INTO v_top_company_type_id
	  FROM chain.company_type
	 WHERE is_top_company = 1;
	
	chain.company_type_pkg.SetCompanyTypeRole (
		in_company_type_id		=> v_top_company_type_id,
		in_role_sid				=> v_role_sid,
		in_role_name			=> 'Supplier Administrators',
		in_mandatory			=> 0,
		in_cascade_to_supplier	=> 0,
		in_pos					=> NULL,
		in_lookup_key			=> 'CHAIN_SUPPLIER_ADMIN',
		out_cur					=> v_dummy_cur
	);
	
	-- TOP -> Supplier
	BEGIN
	-- Company Details -> Suppliers
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SUPPLIERS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);	
	-- Company Details -> Alternative company names
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ALT_COMPANY_NAMES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Company Details -> Company scores
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPANY_SCORES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);
    -- Company Details -> Company Tags
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPANY_TAGS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ
	);
    -- Company Details -> View company extra details
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_EXTRA_DETAILS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Company Details -> View company score log
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_COMPANY_SCORE_LOG),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Business Relationships -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPDATE_BUSINESS_REL_PERIODS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Users -> Company user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPANY_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ
	);	
    -- Users -> Remaining: False
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ADD_USER_TO_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.EDIT_USERS_EMAIL_ADDRESS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PROMOTE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.REMOVE_USER_FROM_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.RESET_PASSWORD),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.SPECIFY_USER_NAME),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Survey Invitation -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.APPROVE_QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_USER_WITH_INVITE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REJECT_QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REQ_QNR_FROM_ESTABL_RELATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.REQ_QNR_FROM_EXIST_COMP_IN_DB),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUESTIONNAIRE_INVITE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUEST_INV_TO_EXIST_COMPAN),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_QUEST_INV_TO_NEW_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.AUDIT_QUESTIONNAIRE_RESPONSES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_QUESTIONNAIRE_TYPE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_QUESTIONNAIRE_SECURITY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.QUERY_QUESTIONNAIRE_ANSWERS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.SETUP_STUB_REGISTRATION),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.SUBMIT_QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Onboarding -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CHANGE_SUPPLIER_FOLLOWER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_COMPANY_AS_SUBSIDIARY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_USER_WITHOUT_INVITE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_COMPANY_WITHOUT_INVIT),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_RELATIONSHIP),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SUPPLIER_NO_RELATIONSHIP),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.DEACTIVATE_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Advanced -> All False/None
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_COMPANY_INVITE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_INVITE_ON_BEHALF_OF),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ADD_PRODUCT_SUPPLIER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.COMPONENTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_PRODUCTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CT_HOTSPOTTER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.EVENTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_ACTIVITIES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.MANAGE_PRODUCT_CERT_REQS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.METRICS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_CERTIFICATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_CODE_TYPES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_METRIC_VAL),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRD_SUPP_METRIC_VAL),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_SUPPLIER_CERTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCT_SUPPLIERS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.PRODUCTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.TASKS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> Manage Workflows: false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.MANAGE_WORKFLOWS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
    -- Other -> Actions: Read/Write
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.ACTIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);
    -- Other -> Create supplier audit: true
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_SUPPLIER_AUDITS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
    -- Other -> Request audits: false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_AUDIT_REQUESTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> Uploaded file: Read/Write
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPLOADED_FILE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE
	);
    -- Other -> View certifications: False
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_CERTIFICATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> View supplier audits: True
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_SUPPLIER_AUDITS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> in_secondary_company_type_id,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_WRITE -- Write is true
	);
	END;
	-- TOP -> Self
	BEGIN
	-- Company Details -> Company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ
	);	
	-- Company Details -> Alternative company names
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ALT_COMPANY_NAMES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Company Details -> Company scores
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPANY_SCORES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Company Details -> Company Tags
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPANY_TAGS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Company Details -> View company score log
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_COMPANY_SCORE_LOG),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Business Relationships -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.UPDATE_BUSINESS_REL_PERIODS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_BUSINESS_RELATIONSHIPS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Users -> Company user
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPANY_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> security.security_pkg.PERMISSION_READ
	);	
    -- Users -> Remaining: False
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ADD_USER_TO_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EDIT_OWN_EMAIL_ADDRESS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EDIT_USERS_EMAIL_ADDRESS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.MANAGE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PROMOTE_USER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.REMOVE_USER_FROM_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.RESET_PASSWORD),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SPECIFY_USER_NAME),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Survey Invitation -> All false
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_QUESTIONNAIRE_TYPE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.MANAGE_QUESTIONNAIRE_SECURITY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SETUP_STUB_REGISTRATION),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SUBMIT_QUESTIONNAIRE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Advanced -> All False/None
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_CMS_COMPANIES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_COMPANY_AUDITS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.RECEIVE_USER_TARGETED_NEWS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SEND_NEWSFLASH),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.COMPONENTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_PRODUCTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CT_HOTSPOTTER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.EVENTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.MANAGE_PRODUCT_CERT_REQS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.METRICS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_CERTIFICATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_CODE_TYPES),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_METRIC_VAL),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_METRIC_VAL_AS_SUPP),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRD_SUPP_METRIC_VAL_AS_SUPP),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCTS_AS_SUPPLIER),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCTS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.TASKS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> Is Top Company
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMMON, chain.chain_pkg.IS_TOP_COMPANY),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);	
    -- Other -> Actions
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.ACTIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> Uploaded file
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.UPLOADED_FILE),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> View certifications
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_CERTIFICATIONS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
    -- Other -> View country risk levels
	chain.type_capability_pkg.SetPermission (
		in_capability_id				=> chain.capability_pkg.GetCapabilityId(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_COUNTRY_RISK_LEVELS),
		in_primary_company_type_id		=> v_top_company_type_id,
		in_secondary_company_type_id	=> NULL,
		in_tertiary_company_type_id		=> NULL,
		in_company_group_type_id		=> NULL,
		in_role_sid						=> v_role_sid,
		in_permission_set				=> 0
	);
	END;
END;

END util_script_pkg;
/
