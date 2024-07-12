-- inserts approval step beneath "v_root_step_id" containing
-- the same users as v_root_step_id, but the attributes of the
-- child steps. Top level user swapped out for "admin"
DECLARE
	v_new_aps_Id	number(10);
	v_root_step_id	 number(10) := 21815;
BEGIN
	FOR r in (
		SELECT * 
		  FROM approval_step
	 	 WHERE parent_step_id = v_root_Step_id
	)
	LOOP
		-- put new step above this one
		INSERT INTO approval_step (
			approval_step_id, parent_step_id, pending_dataset_Id, based_on_step_Id, label, layout_type, max_sheet_value_count, working_day_offset_from_due
		) VALUES (
			approval_step_id_seq.nextval, r.parent_step_id, r.pending_dataset_id, null, r.label, r.layout_type, r.max_sheet_value_count, r.working_day_offset_from_due
		) RETURNING approval_Step_id INTO v_new_aps_Id;
		UPDATE approval_step 
		   SET parent_step_Id = v_new_aps_Id 
		 WHERE approval_step_id = r.approval_step_id;
		 -- mark as no values submitted
		INSERT INTO approval_step_sheet
			SELECT v_new_aps_id, sheet_Key, label, pending_period_Id, pending_ind_Id ,pending_region_id, 0, 0, visible, due_dtm, approver_response_due_dtm
	    	  FROM approval_step_sheet 
	    	 WHERE approval_step_id = r.approval_step_id;
		 -- put the parent step users in place here
		INSERT INTO approval_step_user (approval_step_id, user_sid, fallback_user_sid, read_only, is_Lurker)
			SELECT v_new_aps_id, user_sid, fallback_user_sid, read_only, is_lurker
		      FROM approval_step_user 
		     WHERE approval_step_id = v_root_step_id;
		INSERT INTO approval_step_region (approval_step_id, pending_region_id, rolls_up_to_region_id)
			SELECT v_new_aps_id, pending_region_id, pending_region_id
	    	  FROM approval_step_region 
	    	 WHERE approval_step_id = r.approval_step_id;
		INSERT INTO approval_step_ind (approval_step_id, pending_ind_id)
			SELECT v_new_aps_id, pending_ind_id
	    	  FROM approval_step_ind 
	    	 WHERE approval_step_id = r.approval_step_id;
		INSERT INTO approval_step_milestone
			SELECT v_new_aps_id, milestone_sid
	    	  FROM approval_step_milestone 
	    	 WHERE approval_step_id = r.approval_step_id;
		 -- move submission values to point to this step instaed of the root step
		UPDATE pending_val 
		   SET approval_step_id = v_new_aps_id 
		 WHERE approval_step_id = v_root_step_id
	       AND pending_regioN_id IN (
	       	SELECT pending_region_id 
	       	  FROM approval_step_Region 
	       	 WHERE approval_step_Id = r.approval_step_id
	      );
	END LOOP;

	-- swap top level user
	DELETE FROM approval_step_user 
	 WHERE approval_step_id = v_root_Step_id;

	INSERT INTO approval_step_user 
		(approval_step_id, user_sid, fallback_user_sid, read_only, is_Lurker)
		SELECT v_root_step_id, cu.csr_user_sid, null, 0, 0
		  FROM csr_user cu, approval_step aps, pending_dataset pds
		 WHERE aps.approval_step_id = v_root_step_id
		   AND aps.pending_dataset_id = pds.pending_dataset_id
		   AND pds.app_sid = cu.app_sid
		   AND cu.user_name = 'admin';
END;

