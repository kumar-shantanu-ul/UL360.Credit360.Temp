CREATE OR REPLACE PACKAGE BODY CHEM.SUBSTANCE_HELPER_PKG AS

PROCEDURE UNSEC_CopyForward(
	in_sheet_Id			IN	security_pkg.T_SID_ID,
	out_cnt				OUT	NUMBER	
)
AS
	v_root_delegation_sid  security_pkg.T_SID_ID;
	v_start_dtm			   DATE;
	v_end_dtm			   DATE;
	v_substance_process_use_id	substance_process_use.substance_process_use_id%TYPE;
	v_subst_proc_use_change_id	substance_process_use_change.subst_proc_use_change_id%TYPE;
BEGIN
	-- this is unsecured because we get called by csr.sheet_pkg.copyforward
	SELECT csr.delegation_pkg.getRootDelegationSid(delegation_sid), start_dtm, end_dtm
	  INTO v_root_delegation_sid, v_start_dtm, v_end_dtm
	  FROM csr.sheet
	 WHERE sheet_id = in_sheet_id;
	
	out_cnt := 0;
	FOR r IN (
		SELECT substance_process_use_id, substance_id, region_sid, process_id, root_delegation_sid, mass_value, 
			note, start_dtm, end_dtm, entry_std_measure_conv_id, entry_mass_value
		  FROM substance_process_use
		 WHERE (root_delegation_sid IN (
			SELECT DISTINCT csr.delegation_pkg.getRootDelegationSid(d.delegation_sid) -- previous period, BUT different delegation
			  FROM csr.delegation d
			  JOIN csr.delegation_ind di ON d.delegation_sid = di.delegation_sid
			  JOIN csr.delegation_plugin dp ON dp.ind_sid = di.ind_sid
			  JOIN csr.delegation_region dr ON dr.delegation_sid = d.delegation_sid
			 WHERE (dr.region_sid, di.ind_sid, d.end_dtm) IN (
				SELECT dr.region_sid, di.ind_sid, d.start_dtm
				  FROM csr.delegation d
				  JOIN csr.delegation_ind di ON d.delegation_sid = di.delegation_sid
				  JOIN csr.delegation_plugin dp ON dp.ind_sid = di.ind_sid
				  JOIN csr.delegation_region dr ON dr.delegation_sid = d.delegation_sid
				 WHERE d.delegation_sid = v_root_delegation_sid
			)
		 ) OR root_delegation_sid = v_root_delegation_sid) AND end_dtm = v_start_dtm -- previous period
	)
	LOOP
		SELECT substance_process_use_id_seq.NEXTVAL 
		  INTO v_substance_process_use_id
		  FROM dual;
		
		-- Copy forward substance_process_use
		FOR spu IN (	
			SELECT substance_id, region_sid, process_id, note
			  FROM substance_process_use 
			 WHERE substance_process_use_id = r.substance_process_use_id
		) LOOP 
			INSERT INTO substance_process_use (substance_process_use_id, substance_id, region_sid, process_id, 
				root_delegation_sid, mass_value, note, start_dtm, end_dtm, entry_std_measure_conv_id, entry_mass_value)
			VALUES (v_substance_process_use_id, spu.substance_id, spu.region_sid, spu.process_id,
				v_root_delegation_sid, NULL, spu.note, v_start_dtm, v_end_dtm, NULL, NULL);
			
			audit_pkg.WriteUsageLogEntry(spu.substance_id, v_root_delegation_sid, spu.region_sid, v_start_dtm, v_end_dtm, 'Copied forward substance {0}', null, null);
		END LOOP;
		
		-- Now copy substance_process_cas_dest 
		INSERT INTO substance_process_cas_dest (substance_process_use_id, substance_id, 
			cas_code, to_air_pct, to_product_pct, to_waste_pct, to_water_pct, remaining_pct, remaining_dest)
			SELECT v_substance_process_use_id, substance_id, 
				cas_code, to_air_pct, to_product_pct, to_waste_pct, to_water_pct, remaining_pct, remaining_dest
			  FROM substance_process_cas_dest
			 WHERE substance_process_use_id = r.substance_process_use_id;

		-- Insert the new substance_process_use value into change table
		SELECT subst_proc_use_change_id_seq.NEXTVAL
		  INTO v_subst_proc_use_change_id
		  FROM DUAL;

		INSERT INTO substance_process_use_change (
		   subst_proc_use_change_id, substance_id, region_sid, process_id, 
		   root_delegation_sid, mass_value, note, start_dtm, end_dtm, entry_std_measure_conv_id, entry_mass_value
		)
		SELECT v_subst_proc_use_change_id, substance_id, region_sid, process_id,
			   v_root_delegation_sid, NULL, note, v_start_dtm, v_end_dtm, NULL, NULL
		  FROM substance_process_use 
		 WHERE substance_process_use_id = v_substance_process_use_id;

		INSERT INTO subst_process_cas_dest_change (
			subst_proc_cas_dest_change_id, subst_proc_use_change_id, cas_code, to_air_pct, to_product_pct, to_waste_pct, to_water_pct, remaining_pct, 
				remaining_dest
		)
		SELECT subst_proc_cas_dest_chg_id_seq.nextval, v_subst_proc_use_change_id, cas_code, to_air_pct, to_product_pct, to_waste_pct, to_water_pct, remaining_pct, 
			remaining_dest
		  FROM substance_process_cas_dest
		 WHERE substance_process_use_id = v_substance_process_use_id;

		-- Copy forward substance_process_use_file
		INSERT INTO substance_process_use_file (substance_process_use_file_id, substance_process_use_id, data, uploaded_dtm, 
			uploaded_user_sid, mime_type, filename)
			SELECT subst_proc_use_file_id_seq.NEXTVAL, v_substance_process_use_id, data, uploaded_dtm, 
				uploaded_user_sid, mime_type, filename
			  FROM substance_process_use_file
			 WHERE substance_process_use_id = r.substance_process_use_id;
		
		out_cnt := out_cnt + 1;
	END LOOP;
END;

END;
/