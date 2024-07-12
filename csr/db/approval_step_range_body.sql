CREATE OR REPLACE PACKAGE BODY CSR.approval_step_range_pkg AS

PROCEDURE EnsurePendingValsExist
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	IF NOT m_pending_vals_selected THEN
		SelectPendingVals();
	END IF;
	
	IF m_pending_vals_count = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Assertion failure: pending_vals_count == 0');
	END IF;
END;

PROCEDURE GetPendingVals(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	EnsurePendingValsExist();
	
	OPEN out_cur FOR
		SELECT pvr.pending_val_Id, pvr.pending_ind_id, pvr.pending_region_id, pp.pending_period_id, 
			   pp.start_dtm, pp.end_dtm, pv.val_number, pv.val_string, pv.approval_step_id,
			   pv.from_val_number, pv.from_measure_conversion_id, pi.maps_to_ind_sid, pv.note,
			   pvv.explanation variance_explanation, pv.action,
			   (SELECT COUNT(*) FROM pending_val_file_upload pvfu WHERE pvfu.pending_val_id = pv.pending_val_id) file_upload_count
		  FROM pending_val pv, pending_period pp, pending_ind pi, pending_val_variance pvv,
		  	   TABLE(approval_step_range_pkg.GetPendingVals) pvr
		 WHERE pvr.pending_val_id = pv.pending_val_id
		   AND pvr.pending_period_id = pp.pending_period_id
		   AND pvr.pending_ind_id = pi.pending_ind_id
		   AND pv.app_sid = pvv.app_sid(+) AND pv.pending_val_id = pvv.pending_val_Id(+);
END;

PROCEDURE GetPendingValAccuracy(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	EnsurePendingValsExist();
	
	OPEN out_cur FOR
		SELECT pvr.pending_val_id, pvato.accuracy_type_option_id, pvato.pct, acto.accuracy_type_id, pvr.pending_ind_Id, pvr.pending_region_id, pvr.pending_period_id
		  FROM pending_val_accuracy_type_opt pvato, accuracy_type_option acto,
		  	TABLE(approval_step_range_pkg.GetPendingVals)pvr
		 WHERE pvr.pending_val_id =  pvato.pending_val_id
		   AND pvato.accuracy_type_option_id = acto.accuracy_type_option_id;
END;

PROCEDURE GetPendingValFiles(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	EnsurePendingValsExist();
	
	OPEN out_cur FOR
		SELECT pvr.pending_val_id, fu.file_upload_sid, fu.filename, fu.mime_type, pvr.pending_ind_Id, pvr.pending_region_id, pvr.pending_period_id
		  FROM pending_val_file_upload pvfu, file_upload fu,
		  	TABLE(approval_step_range_pkg.GetPendingVals)pvr
		 WHERE pvr.pending_val_id =  pvfu.pending_val_id
		   AND pvfu.file_upload_sid = fu.file_upload_sid;
END;

PROCEDURE GetCheckboxAndRadioSummary(
	out_checkbox_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_radio_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	EnsurePendingValsExist();

	OPEN out_checkbox_cur FOR
		-- checkbox breakdown
		SELECT ppi.description parent_ind_description, pi.parent_ind_id, 
			pi.description item_description, pi.pending_ind_id, pv.pending_period_id,
			SUM(CASE WHEN pv.val_number = 1 THEN 1 ELSE 0 END) count_checked, 
			ROUND(SUM(CASE WHEN pv.val_number = 1 THEN 1 ELSE 0 END)*100 / COUNT(*),2) pct_checked,
			COUNT(*) responses, 
			RANK() OVER (PARTITION BY pi.parent_ind_id ORDER BY SUM(CASE WHEN pv.val_number = 1 THEN 1 ELSE 0 END)*100 / COUNT(*) DESC) rank
		  FROM pending_val pv, pending_ind pi, pending_ind ppi
		 WHERE pi.pending_ind_id = pv.pending_ind_Id
		   AND pi.pending_ind_id IN (
				SELECT column_value FROM TABLE(approval_step_range_pkg.GetInds)
			)
		   AND pv.pending_region_id IN (
				SELECT column_value FROM TABLE(approval_step_range_pkg.GetRegions)
			)
		   AND pv.pending_period_Id IN (
		   		SELECT column_value FROM TABLE(approval_step_range_pkg.GetPeriods)
		   )
		   AND pi.parent_ind_Id = ppi.pending_ind_id
		   AND pi.element_type = csr_data_pkg.ELEMENT_TYPE_CHECKBOX -- checkbox
		 GROUP BY ppi.description, pi.description, pv.pending_period_id, pi.pending_ind_id, pi.parent_ind_id
		 ORDER BY parent_ind_id, pending_period_id, rank;

	OPEN out_radio_cur FOR
		-- radio breakdown
		SELECT pi.description, pi.pending_ind_id, pi.measure_sid, pv.pending_period_id, pv.val_number, 
			COUNT(*) count_selected, 
			ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (PARTITION BY pi.pending_ind_id),2) pct_selected,
			RANK() OVER (PARTITION BY pi.pending_ind_id ORDER BY COUNT(*) DESC) rank
		  FROM pending_val pv, pending_ind pi
		 WHERE pi.pending_ind_id = pv.pending_ind_Id
		   AND pi.pending_ind_id IN (
				SELECT column_value FROM TABLE(approval_step_range_pkg.GetInds)
			)
		   AND pv.pending_region_id IN (
				SELECT column_value FROM TABLE(approval_step_range_pkg.GetRegions)
			)
		   AND pv.pending_period_Id IN (
		   		SELECT column_value FROM TABLE(approval_step_range_pkg.GetPeriods)
		   )
		   AND pi.element_type IN (csr_data_pkg.ELEMENT_TYPE_RADIO, csr_data_pkg.ELEMENT_TYPE_DROPDOWN) -- radio or dropdown
		 GROUP BY pi.description, pv.pending_period_id, pi.pending_ind_id, pi.measure_sid, pv.val_number, parent_ind_id
		 ORDER BY pending_ind_id, pending_period_id, rank;
END;


PROCEDURE GetPendingValComments(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
    v_user_sid  security_pkg.T_SID_ID;
BEGIN
	EnsurePendingValsExist();
	user_pkg.GetSID(m_act_id, v_user_sid);
	OPEN out_cur FOR
		SELECT pending_val_id, pvr.pending_ind_id, pvr.pending_region_id, pvr.pending_period_Id,
			il.issue_log_id, cu.csr_user_sid logged_by_user_sid, cu.user_name logged_by_user_name,
			 cu.full_name logged_by_full_name, cu.email logged_by_email, logged_dtm, NVL(message, 'no message') message,
			  param_1, param_2, param_3, is_system_generated, sysdate now_dtm,
		 	  CASE WHEN v_user_sid = il.logged_by_user_sid OR ilr.read_dtm IS NOT NULL THEN 1 ELSE 0 END is_read,
			  CASE WHEN cu.csr_user_sid = v_user_sid THEN 1 ELSE 0 END is_you,
			  null logged_by_correspondent_id
		  FROM issue i, issue_log il, csr_user cu, issue_log_read ilr, TABLE(approval_step_range_pkg.GetPendingVals)pvr, issue_pending_val ipv
		 WHERE pvr.pending_ind_id = ipv.pending_ind_id   		   
  		   AND pvr.pending_region_id = ipv.pending_region_id   		   
  		   AND pvr.pending_period_id = ipv.pending_period_id   		   
  		   AND il.issue_id = i.issue_Id
  		   AND ipv.issue_pending_val_Id = i.issue_pending_val_id
		   AND il.logged_by_user_sid = cu.csr_user_sid 
  		   AND il.issue_log_id = ilr.issue_log_id(+) 
  		   AND ilr.csr_user_sid(+) = v_user_sid
	     ORDER BY pending_val_id, logged_dtm DESC;
END;


PROCEDURE GetPendingValCommentCounts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
    v_user_sid  security_pkg.T_SID_ID;
BEGIN
	EnsurePendingValsExist();
	user_pkg.GetSID(m_act_id, v_user_sid);
	OPEN out_cur FOR
        SELECT pvr.pending_val_id, count(il.issue_log_id) total,
			 max(CASE WHEN closed_dtm IS NULL THEN 0 ELSE 1 END) closed, -- should really be done in getPendingVal
			 max(CASE WHEN resolved_dtm IS NULL THEN 0 ELSE 1 END) resolved, -- should really be done in getPendingVal
        	 sum(CASE WHEN v_user_sid = il.logged_by_user_sid OR ilr.read_dtm IS NOT NULL THEN 1 ELSE 0 end) read 
          FROM issue_log il, issue_log_read ilr, TABLE(approval_step_range_pkg.GetPendingVals)pvr, issue_pending_val ipv, issue i
         WHERE pvr.pending_ind_id = ipv.pending_ind_id   		   
  		   AND pvr.pending_region_id = ipv.pending_region_id   		   
  		   AND pvr.pending_period_id = ipv.pending_period_id   		   
  		   AND ipv.issue_pending_val_id = i.issue_pending_val_id
  		   AND i.issue_id = il.issue_id
  		   AND il.issue_log_id = ilr.issue_log_id(+) 
  		   AND ilr.csr_user_sid(+) = v_user_sid
         GROUP BY pvr.pending_val_id;
END;

PROCEDURE Approve(
	in_note		IN	approval_step_sheet_log.note%TYPE	
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	IF m_sheet_key IS NOT NULL THEN
		user_pkg.GetSID(m_act_id, v_user_sid);

        -- TODO: check for rejected values and raise an error?
        INSERT INTO APPROVAL_STEP_SHEET_LOG
            (APPROVAL_STEP_ID, SHEET_KEY, BY_USER_SID, DTM, UP_OR_DOWN, NOTE)
        VALUES
            (m_approval_step_id, m_sheet_key, v_user_sid, SYSDATE, 0, in_note);	
    END IF;
END;


PROCEDURE Merge
AS
	v_set_val_id			val.val_id%TYPE;
    v_user_sid				security_pkg.T_SID_ID;
    v_note_clob_opened		BOOLEAN;
    v_note_clob				CLOB;
    v_helper_pkg			pending_dataset.helper_pkg%TYPE;
	CURSOR c_to_merge IS
    	SELECT /*+ALL_ROWS ORDERED*/ pv.pending_val_id, pv.val_number, pv.from_val_number, pv.val_string, pv.from_measure_conversion_id, pv.note,
			   pi.maps_to_ind_sid, pr.maps_to_region_sid, pp.start_dtm, pp.end_dtm, aps.parent_step_id, pv.merged_state
		  FROM pending_val pv, pending_period pp, pending_ind pi, pending_region pr, ind i, approval_step aps
		 WHERE pv.app_sid = pp.app_sid 
		   AND pv.app_sid = pi.app_sid 
		   AND pv.app_sid = aps.app_sid 
		   AND pp.app_sid = pr.app_sid 
		   AND pp.app_sid = i.app_sid
       	   AND pp.app_sid = pi.app_sid 
       	   AND pi.app_sid = pr.app_sid 
       	   AND pr.app_sid = i.app_sid 
       	   AND pi.app_sid = pr.app_sid 
       	   AND pi.app_sid = i.app_sid 
       	   AND pr.app_sid = i.app_sid
           AND pv.pending_val_id IN (SELECT pending_val_id FROM TABLE(approval_step_range_pkg.GetPendingVals))
		   AND pv.pending_period_id = pp.pending_period_id
		   AND pv.pending_ind_id = pi.pending_ind_id
		   AND pv.pending_region_id = pr.pending_region_id
		   AND pi.maps_to_ind_sid = i.ind_sid
		   AND pr.maps_to_region_sid IS NOT NULL
		   AND i.measure_sid IS NOT NULL
		   AND pv.approval_step_id = aps.approval_step_id
		   FOR UPDATE OF pv.merged_state;
BEGIN
	EnsurePendingValsExist();
	user_pkg.GetSID(m_act_id, v_user_sid);
	FOR r IN c_to_merge
	LOOP
		v_note_clob_opened := FALSE;
		
		-- Try and do something with notes
		-- We normally want to put string_value in there, but if it's missing, merge the note
		-- If both are present we glue them together and put the glued up string in there
		-- This isn't very pretty, but oh well.
		IF NVL(LENGTH(r.note), 0) > 0 THEN
			IF NVL(LENGTH(r.val_string), 0) > 0 THEN
				v_note_clob_opened := TRUE;
			    dbms_lob.createtemporary(v_note_clob, TRUE, dbms_lob.call);
				dbms_lob.open(v_note_clob, dbms_lob.lob_readwrite);
				dbms_lob.append(v_note_clob, r.val_string);
				dbms_lob.writeAppend(v_note_clob, 1, CHR(10));
				dbms_lob.append(v_note_clob, r.note);
			ELSE
				v_note_clob := r.note;
			END IF;
		ELSE
			IF NVL(LENGTH(r.val_string), 0) > 0 THEN
				v_note_clob := r.val_string;
			ELSE
				v_note_clob := NULL;
			END IF;
		END IF;

		Indicator_Pkg.SetValue(m_act_id, r.maps_to_ind_sid, r.maps_to_region_sid, r.start_dtm, r.end_dtm, r.val_number, 0, 
			csr_data_pkg.SOURCE_TYPE_PENDING, r.pending_val_id, r.from_measure_conversion_id, r.from_val_number, 
			0, v_note_clob, v_set_val_id);
			
		IF v_note_clob_opened THEN
			dbms_lob.close(v_note_clob);
		END IF;

		UPDATE pending_val
		   SET merged_state = CASE WHEN r.parent_step_id IS NULL THEN 'S' ELSE merged_state END
		 WHERE CURRENT OF c_to_merge;
	END LOOP;
	
	-- call helper function
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM approval_step aps
		JOIN pending_dataset pds ON aps.pending_dataset_Id = pds.pending_dataset_id
	 WHERE approval_step_Id = m_approval_step_id;
	
	IF v_helper_pkg IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.PostMerge(:1);end;'
			USING m_approval_step_id;
	END IF;

	INSERT INTO approval_step_sheet_log
		(approval_step_id, sheet_key, by_user_sid, dtm, up_or_down, note)
	VALUES
		(m_approval_step_id, m_sheet_key, v_user_sid, SYSDATE, 1, 'Merged with main database');
END;

-- Supposed to be internal but called by pending_pkg
PROCEDURE FillSheetFromParent
AS
	v_parent_step_id	approval_step.parent_step_id%TYPE;
BEGIN
	
	/* EnsurePendingValsExist();
	 * This breaks the pending import tool when setting up a new dataset
	 * I don't think we actually need to be trowing exceptions tho, so
	 * lets just call this: 				 */
	IF NOT m_pending_vals_selected THEN
		SelectPendingVals();
	END IF;
	
	-- Get the parent step
	SELECT parent_step_id
	  INTO v_parent_step_id
	  FROM approval_step
	 WHERE approval_step_id = m_approval_step_id;
	
	-- If there's no value in the parent sheet, make one up so it shows as belonging to the child sheet
	INSERT INTO pending_val (pending_val_id, pending_ind_id, pending_region_id, pending_period_id, approval_step_id)
		SELECT pending_val_id_seq.nextval, pending_ind_id, pending_region_id, pending_period_id, m_approval_step_id
		  FROM (
			SELECT pending_ind_id, pending_region_id, pending_period_id
			  FROM TABLE(m_pending_vals)
			 WHERE pending_val_id IS NULL
			  MINUS
			SELECT pending_ind_id, pending_region_id, pending_period_id
			  FROM pending_val
		)
		  ;
		 	
	-- Move all of our values down (but not ones that we don't control)
	UPDATE pending_val
	   SET approval_step_id = m_approval_step_id
	 WHERE approval_step_id = v_parent_step_id
	   AND pending_val_id IN (SELECT pending_val_id
	 							FROM TABLE(m_pending_vals));
END;
	
PROCEDURE Submit(
	in_note		IN	approval_step_sheet_log.note%TYPE	
)
AS
	v_blocked             		NUMBER(10);
	v_parent_approval_step_id	approval_step.approval_step_id%TYPE;
	v_user_sid					security_pkg.T_SID_ID;
	v_approver_response_window	customer.approver_response_window%TYPE;
BEGIN
	EnsurePendingValsExist();
	
	SELECT approver_response_window	
	  INTO v_approver_response_window	
	  FROM customer c, pending_dataset pds, approval_step aps
	 WHERE c.app_sid = pds.app_sid
	   AND pds.pending_dataset_id = aps.Pending_dataset_id 
	   AND aps.approval_step_id = m_approval_step_id;

    IF m_sheet_key IS NOT NULL THEN
        -- is it blocked?
        SELECT submit_blocked
          INTO v_blocked
          FROM approval_step_sheet
         WHERE approval_step_id = m_approval_step_id
           AND sheet_key = m_sheet_key;
        IF v_blocked = 1 THEN
            RAISE_APPLICATION_ERROR(csr_Data_pkg.ERR_SUBMISSION_BLOCKED, 'Submission blocked');
        END IF;
        UPDATE approval_step_sheet
           SET approver_response_due_dtm = TRUNC(pending_pkg.AddWorkingDays(SYSDATE, v_approver_response_window)) 
         WHERE approval_step_id = m_approval_step_id
           AND sheet_key = m_sheet_key;
    END IF;
	
	-- check that this approval step id is a parent
	SELECT parent_step_id
	  INTO v_parent_approval_step_id
	  FROM approval_step
	 WHERE approval_step_id = m_approval_step_id;
	 
	FOR r IN (
		SELECT * FROM TABLE(m_pending_vals) WHERE NVL(ACTION,'S')='S' -- just those marked submit
	)
	LOOP	
		-- if someone hasn't added an explanation (e.g. to a calculated field) it will
		-- show as not submitted as there is no pending_val id, so by INSERTING it
		-- will get shown as submitted
		IF r.pending_val_id IS NULL THEN
			INSERT INTO pending_val
				(pending_val_id, pending_ind_id, pending_region_id, pending_period_id, approval_step_id)
			VALUES 
				(pending_val_id_seq.nextval, r.pending_ind_id, r.pending_region_id, r.pending_period_Id, v_parent_approval_step_id);
		ELSIF NVL(r.approval_step_id, m_approval_step_id) = m_approval_step_id THEN
			-- if it's NULL or this approval step then we submit it
			-- don't update if it's already at another approval step
			UPDATE pending_val
			   SET approval_step_id = v_parent_approval_step_id
			 WHERE pending_val_id = r.pending_val_id;
		END IF;
	END LOOP;

	IF m_sheet_key IS NOT NULL THEN
		-- update log
		SelectPendingVals; -- we have to update our m_pending_vals collection
		user_pkg.GetSID(m_act_id, v_user_sid);
		INSERT INTO APPROVAL_STEP_SHEET_LOG
			(APPROVAL_STEP_ID, SHEET_KEY, BY_USER_SID, DTM, UP_OR_DOWN, NOTE)
		VALUES
			(m_approval_step_id, m_sheet_key, v_user_sid, SYSDATE, 1, in_note);
		-- update number of submitted values

		UPDATE approval_step_sheet
		   SET submitted_value_count = (
		    SELECT COUNT(*)
              FROM TABLE(approval_step_range_pkg.getPendingVals) pv, pending_ind pi, PENDING_ELEMENT_TYPE pet, IND i
             WHERE pv.pending_ind_id = pi.pending_ind_id
               AND pi.element_type = pet.element_type(+)
               AND pi.maps_to_ind_sid = i.ind_sid(+)
               AND (pet.is_number = 1 OR pet.is_string = 1)
               AND approval_step_id IN (
               		-- anything equal to the parent step we've submitted to (or above) in the chain
               		SELECT approval_step_Id
               		  FROM approval_step
               		 START WITH approval_step_id = v_parent_approval_step_id
               	   CONNECT BY PRIOR parent_step_id = approval_Step_id
               )
               AND NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) IN (csr_data_pkg.IND_TYPE_NORMAL)
            )
		 WHERE approval_step_id = m_approval_step_id
		   AND SHEET_KEY = m_sheet_key;       
	END IF;
END;

-- slightly odd, but easier this way round. We select the values we 
-- want to reject from the child step, and then set them using this
PROCEDURE RejectFromParentStep(
	in_parent_approval_step_id	IN	approval_step.approval_step_id%TYPE,
	in_note						IN	approval_step_sheet_log.note%TYPE,
	in_just_selected            IN  NUMBER,
	out_cur                     OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
	v_pending_period_id pending_period.pending_period_id%TYPE;
	v_check_parent_id	approval_step.approval_step_id%TYPE;
BEGIN
	EnsurePendingValsExist();
	

    -- TODO: this is fine for specific layout types 
    -- * LAYOUT_IND     - sub-delegation might have different pending_region_id but same period
    -- * LAYOUT_REGION  - ?
    -- * LAYOUT PERIOD  - ?
    -- etc - think it through?
    SELECT pending_period_id
      INTO v_pending_period_Id
      FROM approval_step_sheet
     WHERE approval_step_id = m_approval_step_id
       AND sheet_key = m_sheet_key;

	-- check that this approval step id is a child
	SELECT parent_step_id
	  INTO v_check_parent_id	
	  FROM approval_step
	 WHERE approval_step_id = m_approval_step_id;
	 
	IF v_check_parent_id != in_parent_approval_step_id THEN
		RAISE_APPLICATION_ERROR(-20001,'Approval step '||in_parent_approval_step_id
			||' is not the parent of the approval_step_range selected step '||m_approval_step_id);
	END IF;
	
	UPDATE pending_val
	   SET approval_step_id = m_approval_step_id, 
           action = 'S',
           merged_state = CASE merged_state WHEN 'S' THEN 'R' ELSE merged_state END
	 WHERE pending_val_id IN (
	 	SELECT pending_val_id 
	 	  FROM TABLE(m_pending_vals)
	 	 WHERE approval_Step_Id = in_parent_approval_step_id
	 	   AND pending_val_Id IS NOT NULL
	 	   AND (action ='R' OR in_just_selected = 0) -- ACTION MUST BE SET TO R
	 );

	
	IF m_sheet_key IS NOT NULL THEN
		-- update log
		user_pkg.GetSID(m_act_id, v_user_sid);
		INSERT INTO APPROVAL_STEP_SHEET_LOG
			(APPROVAL_STEP_ID, SHEET_KEY, BY_USER_SID, DTM, UP_OR_DOWN, NOTE)
		VALUES
			(m_approval_step_id, m_sheet_key, v_user_sid, SYSDATE, -1, in_note);
		-- update number of submitted values
		SelectPendingVals; -- we have to update our m_pending_vals collection


		UPDATE approval_step_sheet
		   SET submitted_value_count = (
		    SELECT COUNT(*)
              FROM TABLE(approval_step_range_pkg.getPendingVals) pv, pending_ind pi, PENDING_ELEMENT_TYPE pet, IND i
             WHERE pv.pending_ind_id = pi.pending_ind_id
               AND pi.element_type = pet.element_type(+)
               AND pi.maps_to_ind_sid = i.ind_sid(+)
               AND (pet.is_number = 1 OR pet.is_string = 1)
               AND approval_step_id IN (
               		-- anything equal to the parent step we've submitted to (or above) in the chain
               		SELECT approval_step_Id
               		  FROM approval_step
               		 START WITH approval_step_id = in_parent_approval_step_id
               	   CONNECT BY PRIOR parent_step_id = approval_Step_id
               )
               AND NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) IN (csr_data_pkg.IND_TYPE_NORMAL)
            ),
            approver_response_due_dtm = null
		 WHERE approval_step_id = m_approval_step_id
		   AND SHEET_KEY = m_sheet_key;       

	END IF;

    OPEN out_cur FOR    
        SELECT /*+ALL_ROWS*/ approval_step_id, send_to, user_sid, friendly_name, full_name, email, label, due_dtm, sheet_url
          FROM (SELECT ap.approval_step_id, 1 send_to, apsu.user_sid, cu.friendly_name, cu.full_name, cu.email, ap.label, apss.due_dtm,
		        	   c.approval_step_sheet_url||'apsId='||apss.approval_step_id||CHR(38)||'sheetKey='||apss.sheet_key sheet_url
		          FROM approval_step ap, approval_step_user apsu, csr_user cu, approval_step_sheet apss, customer c
		         WHERE ap.approval_step_id = m_approval_step_id
		           AND ap.app_sid = apsu.app_sid AND ap.approval_step_id = apsu.approval_step_id
		           AND apsu.app_sid = cu.app_sid AND apsu.user_sid = cu.csr_user_sid
		           AND apss.pending_period_id = v_pending_period_id
		           AND ap.app_sid = apss.app_sid AND ap.approval_step_id = apss.approval_step_id
		           AND c.app_sid = ap.app_sid)
         GROUP BY approval_step_id, send_to, user_sid, friendly_name, full_name, email, label, due_dtm, sheet_url
         ORDER BY send_to ASC; -- ccs come first
END;

-- slightly odd, but easier this way round. We select the values we 
-- want to reject from the child step, and then set them using this
PROCEDURE CascadeRejectFromParentStep(
	in_parent_approval_step_id	IN	approval_step.approval_step_id%TYPE,
	in_note						IN	approval_step_sheet_log.note%TYPE,
	in_just_selected            IN  NUMBER,
	out_cur                     OUT security_pkg.T_OUTPUT_CUR
)
AS
    t_pending_val_ids			pending_pkg.T_PENDING_VAL_IDS;
    t_approval_step_ids			security.T_SID_TABLE;
    t_distinct_aps_leaf_ids		security.T_SID_TABLE;
	v_user_sid					security_pkg.T_SID_ID;
	v_check_parent_id			approval_step.approval_step_id%TYPE;
	v_pending_period_id     	pending_period.pending_period_id%TYPE;
	v_sheet_key             	approval_step_sheet.sheet_key%TYPE;
BEGIN
	EnsurePendingValsExist();
	
	-- check that this approval step id is a child
	SELECT parent_step_id
	  INTO v_check_parent_id 
	  FROM approval_step
	 WHERE approval_step_id = m_approval_step_id;
	 
	IF v_check_parent_id != in_parent_approval_step_id THEN
		RAISE_APPLICATION_ERROR(-20001,'Approval step '||in_parent_approval_step_id
			||' is not the parent of the approval_step_range selected step '||m_approval_step_id);
	END IF;
	
	
    -- Bulk collect first, then use FORALL for speed
    SELECT pv.pending_val_id, lp.approval_step_id
      BULK COLLECT INTO t_pending_val_ids, t_approval_step_ids
      FROM TABLE(approval_step_range_pkg.GetLeafPoints)lp, TABLE(approval_step_range_pkg.getPendingVals) pv
     WHERE pv.pending_region_id = lp.pending_region_id
       AND pv.pending_ind_id = lp.pending_ind_id
       AND pv.approval_step_id = in_parent_approval_step_id
       AND pv.pending_val_Id IS NOT NULL -- getPendingVals returns stuff even where a saved value does not exist with pending_val_id set to NULL
       AND (action ='R' OR in_just_selected = 0); -- ACTION MUST BE SET TO R
	 
		  
    FORALL i IN t_pending_val_ids.FIRST .. t_pending_val_ids.LAST
		UPDATE pending_val 
	       SET action = 'S', approval_step_id = t_approval_step_ids(i), merged_state = CASE merged_state WHEN 'S' THEN 'R' ELSE merged_state END
	     WHERE pending_val_id = t_pending_val_ids(i);
    
    SELECT DISTINCT COLUMN_VALUE
      BULK COLLECT INTO t_distinct_aps_leaf_ids
      FROM TABLE(t_approval_step_ids);

	IF m_sheet_key IS NOT NULL THEN
		-- update log for all steps affected (i.e. distinct set of ancestors of leaf steps we moved values down to , below the step we're rejecting from)
		user_pkg.GetSID(m_act_id, v_user_sid);
		
        -- TODO: this is fine for specific layout types 
        -- * LAYOUT_IND     - sub-delegation might have different pending_region_id but same period
        -- * LAYOUT_REGION  - ?
        -- * LAYOUT PERIOD  - ?
        -- etc - think it through?
        SELECT pending_period_id
          INTO v_pending_period_Id
          FROM approval_step_sheet
         WHERE approval_step_id = m_approval_step_id
           AND sheet_key = m_sheet_key;
				  		
		-- update number of submitted values
        SelectPendingVals; -- we have to update our m_pending_vals collection
        
        FOR r IN (
            SELECT ap.approval_step_id, SUM( CASE WHEN ap.lvl > apt.lvl THEN 1 ELSE 0 END ) submitted_value_count
              FROM TABLE(approval_step_range_pkg.getPendingVals) pv, (
                  SELECT approval_step_id, level lvl
                    FROM approval_step
                   START WITH approval_step_id = in_parent_approval_step_id
                 CONNECT BY PRIOR approval_step_id = parent_step_id
             )apt, -- join of pv and apt - apt.lvl is the level that the value is stored at
              approval_step_region apsr, approval_step_ind apsi, (
                  SELECT approval_step_id, level lvl
                    FROM approval_step
                   START WITH approval_step_id = in_parent_approval_step_id
                 CONNECT BY PRIOR approval_step_id = parent_step_id
             )ap, pending_ind pi, PENDING_ELEMENT_TYPE pet, IND i
             WHERE pv.approval_step_id = apt.approval_step_id
               AND pv.pending_region_id = apsr.pending_region_id
               AND pv.pending_ind_id = apsi.pending_ind_id
               AND apsr.approval_step_Id = ap.approval_step_id
               AND apsi.approval_step_id = ap.approval_step_Id
               AND apsi.pending_ind_id = pi.pending_ind_id(+) -- TODO: why is this an outer join?
               AND pi.element_type = pet.element_type(+)
               AND pi.maps_to_ind_sid = i.ind_sid(+)
               AND NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) IN (csr_data_pkg.IND_TYPE_NORMAL)
               AND (pet.is_number = 1 OR pet.is_string = 1)
             GROUP BY ap.approval_step_id
        )
        LOOP
            UPDATE approval_step_sheet
               SET submitted_value_count = r.submitted_value_count,
                approver_response_due_dtm = null
             WHERE approval_step_id = r.approval_step_id
               AND pending_period_id = v_pending_period_id
            RETURNING sheet_key INTO v_sheet_key;		   

			-- TODO: do we really want to go assigning the same dates and the same message for 
			-- every step in the tree inclduing and below this one?
            INSERT INTO APPROVAL_STEP_SHEET_LOG
                (APPROVAL_STEP_ID, SHEET_KEY, BY_USER_SID, DTM, UP_OR_DOWN, NOTE)
            VALUES
                (r.approval_step_id, v_sheet_key, v_user_sid, SYSDATE, -1, in_note);

        END LOOP;            
	END IF;

    OPEN out_cur FOR
    	SELECT approval_step_id, send_to, user_sid, friendly_name, full_name, email, label, due_dtm, sheet_url
          FROM (SELECT x.approval_step_id, x.send_to, apsu.user_sid, cu.friendly_name, cu.full_name, cu.email, ap.label, apss.due_dtm,
		        	   c.approval_step_sheet_url||'apsId='||apss.approval_step_id||CHR(38)||'sheetKey='||apss.sheet_key sheet_url
		          FROM (
		            SELECT approval_step_id, CASE WHEN LEVEL = 1 THEN 1 ELSE 0 END send_to
		              FROM approval_step
		             WHERE approval_step_id NOT IN ( -- don't cc the approval step rejecting and above
		                   SELECT approval_step_id 
							 FROM approval_step 
							START WITH approval_step_id = in_parent_approval_step_id 
						  CONNECT BY PRIOR parent_step_id = approval_step_id
		  			   )
		             START WITH approval_step_id IN (
		                   SELECT COLUMN_VALUE FROM TABLE(t_distinct_aps_leaf_ids) -- bottom of chain
		             )
		            CONNECT BY PRIOR parent_step_id = approval_step_id 
		         ) x, approval_step ap, approval_step_user apsu, csr_user cu, approval_step_sheet apss, customer c
		         WHERE x.approval_step_id = ap.approval_step_id
		           AND ap.app_sid = apsu.app_sid AND ap.approval_step_id = apsu.approval_step_id
		           AND apsu.app_sid = cu.app_sid AND apsu.user_sid = cu.csr_user_sid
		           AND apss.pending_period_id = v_pending_period_id
		           AND ap.app_sid = apss.app_sid AND ap.approval_step_id = apss.approval_step_id
		           AND c.app_sid = ap.app_sid)
        GROUP BY approval_step_id, send_to, user_sid, friendly_name, full_name, email, label, due_dtm, sheet_url
        ORDER BY send_to ASC; -- ccs come first
END;



PROCEDURE SelectPendingVals
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	m_leaf_points :=pending_pkg.GetLeafPointsAsTable(m_approval_step_id);
	m_leaf_points_selected := TRUE;
	
	SELECT /*+ALL_ROWS*/ T_PENDING_VAL_ROW(t.pending_ind_Id, t.pending_region_id, t.root_region_id, t.pending_period_id, pv.approval_step_id, pv.pending_val_id, pv.action)
	  BULK COLLECT INTO m_pending_vals
	  FROM (
      	SELECT pending_ind_id, pending_region_id, root_region_id, p.column_value pending_period_id
          FROM TABLE(m_leaf_points), TABLE(approval_step_range_pkg.getperiods)p
          ) t, PENDING_VAL pv 
	 WHERE t.pending_ind_id = pv.pending_ind_id(+)
	   AND t.pending_region_id = pv.pending_region_id(+)
	   AND t.pending_period_id = pv.pending_period_id(+) 
	   AND t.pending_region_id IN (SELECT COLUMN_VALUE FROM TABLE(m_region_ids))
	   AND t.pending_ind_id IN (SELECT COLUMN_VALUE FROM TABLE(m_ind_ids));
	 
	m_pending_vals_count := m_pending_vals.COUNT;
	m_pending_vals_selected := TRUE;
END;


FUNCTION GetInds RETURN security.T_SID_TABLE
AS
	v	number(10);
BEGIN	
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this function');
	END IF;
	RETURN m_ind_ids;	
END;

FUNCTION GetRegions RETURN security.T_SID_TABLE
AS
	v	number(10);
BEGIN	
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this function');
	END IF;
	RETURN m_region_ids;	
END;

FUNCTION GetPeriods RETURN security.T_SID_TABLE
AS
	v	number(10);
BEGIN	
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this function');
	END IF;
	RETURN m_period_ids;	
END;

FUNCTION GetPendingVals RETURN T_PENDING_VAL_TABLE
AS
BEGIN	
	IF NOT m_pending_vals_selected THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call SelectPendingVals before this function');
	END IF;
	RETURN m_pending_vals;	
END;

FUNCTION GetLeafPoints RETURN T_PENDING_LEAF_TABLE
AS
BEGIN	
	IF NOT m_leaf_points_selected THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call SelectPendingVals before this function');
	END IF;
	RETURN m_leaf_points;	
END;

-- periods
PROCEDURE AddPeriodId(
	in_period_id IN PENDING_PERIOD.PENDING_PERIOD_ID%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	-- check it's valid
	SELECT count(*) 
	  INTO v_cnt
	  FROM pending_period pp, approval_step aps 
	 WHERE pp.pending_dataset_id = aps.pending_dataset_id
	   AND aps.approval_step_id = m_approval_step_id
	   AND pending_period_id = in_period_id;

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid period id ('||in_period_id||') for approval step ('||m_approval_step_id||')');
	END IF;
	
	m_period_ids.EXTEND();
	m_period_ids(m_period_ids.COUNT) := in_period_id;
	
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

PROCEDURE AddAllPeriods
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	-- we can safely overwrite as we're adding all of them
	SELECT pending_period_id
	  BULK COLLECT INTO m_period_ids
	  FROM PENDING_PERIOD pp, APPROVAL_STEP aps
	 WHERE aps.approval_step_id = m_approval_step_id
	   AND pp.pending_dataset_id = aps.pending_dataset_id;
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

-- indicators
PROCEDURE AddAllIndicators
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	-- we can safely overwrite as we're adding all of them
	SELECT pending_ind_id
	  BULK COLLECT INTO m_ind_ids
	  FROM APPROVAL_STEP_IND      
	 WHERE approval_step_id = m_approval_step_id;
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

PROCEDURE AddIndicator(
	in_ind_id IN	PENDING_IND.PENDING_IND_ID%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;	
	
	-- check it's valid
	SELECT count(*) 
	  INTO v_cnt
	  FROM approval_step_ind
	 WHERE approval_step_id = m_approval_step_id
	   AND pending_ind_id = in_ind_id;

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid ind id ('||in_ind_id||') for approval step ('||m_approval_step_id||')');
	END IF;

	
	m_ind_ids.EXTEND();
	m_ind_ids(m_ind_ids.COUNT) := in_ind_id;
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

PROCEDURE RemoveIndicator(
	in_ind_id IN	PENDING_IND.PENDING_IND_ID%TYPE	
)
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;	
	
	FOR indx IN m_ind_ids.FIRST .. m_ind_ids.LAST
    LOOP
	    IF m_ind_ids.EXISTS(indx) AND m_ind_ids(indx) = in_ind_id THEN
        	m_ind_ids.DELETE(indx);
            EXIT;
        END IF;
    END LOOP;
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

PROCEDURE AddIndicatorAndChildren(
	in_ind_root_id	IN	PENDING_IND.PENDING_IND_ID%TYPE
)
AS
	-- we have to BULK COLLECT into a new collection as
	-- Oracle seems to clear the old collection down before
	-- the statement is executed
	m_temp_ids		security.T_SID_TABLE;
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	SELECT pending_ind_id
	  BULK COLLECT INTO m_temp_ids
	  FROM ( 
	  		 (
		SELECT pending_ind_id
		  FROM APPROVAL_STEP_IND
		 WHERE approval_step_id = m_approval_step_id
	 INTERSECT
	    SELECT pending_ind_id
	      FROM PENDING_IND
	   CONNECT BY PRIOR pending_ind_id = parent_ind_id
	     START WITH pending_ind_id = in_ind_root_id 
	  		 )
	  	 UNION 
	  	SELECT column_value
	  	  FROM TABLE(m_ind_ids)
	 ); 
	 
	 m_ind_ids := m_temp_ids;
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

-- regions
PROCEDURE AddAllRegions
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	-- we can safely overwrite as we're adding all of them
    SELECT DISTINCT pending_region_id
	  BULK COLLECT INTO m_region_ids
      FROM (
        SELECT pending_region_id, parent_region_Id
	      FROM PENDING_REGION
	     START WITH pending_region_id IN (
	     	SELECT pending_region_id FROM APPROVAL_STEP_REGION WHERE approval_step_id = m_approval_step_id
	     )
	CONNECT BY PRIOR pending_region_id = parent_region_id                
     );
	   
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

PROCEDURE AddRegion(
	in_region_id 	IN	PENDING_REGION.PENDING_REGION_ID%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	
	-- check it's valid, i.e. a parent of this region is in the approval_step_region table
	SELECT count(*) 
	  INTO v_cnt
	  FROM approval_step_region
	 WHERE approval_step_id = m_approval_step_id
	   AND pending_region_id IN (
		SELECT pending_region_id
		  FROM pending_region
		 START WITH pending_region_id = in_region_id
		CONNECT BY PRIOR parent_region_id = pending_region_id
    );

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid region id ('||in_region_id||') for approval step ('||m_approval_step_id||')');
	END IF;

	
	m_region_ids.EXTEND();
	m_region_ids(m_region_ids.COUNT) := in_region_id;
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;

END;

PROCEDURE RemoveRegion(
	in_region_id IN	PENDING_REGION.PENDING_REGION_ID%TYPE	
)
AS
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;	
	
	FOR regionx IN m_region_ids.FIRST .. m_region_ids.LAST
    LOOP
	    IF m_region_ids.EXISTS(regionx) AND m_region_ids(regionx) = in_region_id THEN
        	m_region_ids.DELETE(regionx);
            EXIT;
        END IF;
    END LOOP;
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

PROCEDURE AddRegionAndChildren(
	in_region_root_id	IN	PENDING_REGION.PENDING_REGION_ID%TYPE
)
AS
	-- we have to BULK COLLECT into a new collection as
	-- Oracle seems to clear the old collection down before
	-- the statement is executed
	m_temp_ids		security.T_SID_TABLE;
BEGIN
	IF NOT m_is_initialised THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call Init before this procedure');
	END IF;
	 
	SELECT pending_region_id
	  BULK COLLECT INTO m_temp_ids
	  FROM ( 
	         (
	    SELECT DISTINCT pending_region_id
	      FROM (
	        SELECT pending_region_id, parent_region_Id
		      FROM PENDING_REGION
		     START WITH pending_region_id IN (
		     	SELECT pending_region_id FROM APPROVAL_STEP_REGION WHERE approval_step_id = m_approval_step_id
		     )
		CONNECT BY PRIOR pending_region_id = parent_region_id                
	     )
	 INTERSECT
	    SELECT pending_region_id
	      FROM PENDING_REGION
	   CONNECT BY PRIOR pending_region_id = parent_region_id
	     START WITH pending_region_id = in_region_root_id	 
	  		 )
	  	 UNION 
	  	SELECT column_value
	  	  FROM TABLE(m_region_ids)
	 ); 
	 
	 m_region_ids := m_temp_ids;
	   
	-- we'll need to reselect
	m_pending_vals_selected := FALSE;
END;

PROCEDURE InitDataSource(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_start_dtm			IN	pending_period.start_dtm%TYPE,
	in_end_dtm				IN	pending_period.end_dtm%TYPE,
	in_interval_months		IN	NUMBER, -- number of months in the interval (3 = quarterly)
	in_include_stored_calcs	IN	NUMBER,
	out_inds_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_aggr_children_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_ind_depends_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_values_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_dates_cur			OUT	security_pkg.T_OUTPUT_CUR, -- we use a cursor as it's easier to call from C#
	out_pending_inds_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_pending_val_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_variance_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_pending_dataset_id	pending_dataset.pending_dataset_id%TYPE;
	v_pending_ind_ids		security_pkg.T_SID_IDS;
	v_pending_region_ids	security_pkg.T_SID_IDS;
BEGIN
	SELECT pending_dataset_id
	  INTO v_pending_dataset_id
	  FROM approval_step
	 WHERE approval_step_id = m_approval_step_id;
	
	-- put whatever we've got selected into the collection to pass to InitDataSource
	SELECT column_value
	  BULK COLLECT INTO v_pending_ind_ids
	  FROM TABLE(m_ind_ids);
	  
	SELECT column_value
	  BULK COLLECT INTO v_pending_region_ids
	  FROM TABLE(m_region_ids);
	   
	pending_datasource_pkg.InitDataSource(
		m_act_id, 
		v_pending_dataset_id, 
		v_pending_ind_ids, 
		v_pending_region_ids,
		in_start_dtm, 
		in_end_dtm,
		in_interval_months,
		in_include_stored_calcs,	
		out_inds_cur,
		out_regions_cur,
		out_aggr_children_cur,
		out_ind_depends_cur,
		out_values_cur,
		out_dates_cur,
		out_pending_inds_cur,
		out_pending_val_cur,
		out_variance_cur
	);
END;



PROCEDURE Dispose
AS
BEGIN
	-- tidy up 
	SELECT null
	  BULK COLLECT INTO m_ind_ids
	  FROM DUAL
	 WHERE 1 = 0;
	 
	SELECT null
	  BULK COLLECT INTO m_region_ids
	  FROM DUAL
	 WHERE 1 = 0;
	 
	SELECT null
	  BULK COLLECT INTO m_period_ids
	  FROM DUAL
	 WHERE 1 = 0;
	
	-- mark as not initialised
	m_is_initialised := FALSE;
	m_pending_vals_selected := FALSE;
	m_sheet_key := NULL;
END;


-- specific_region_id and specific_ind_root_id are (literally!) rather
-- specific and migth not make sense with all sheet_keys - not sure of
-- the best thing to do, but better to plough on and make progress
PROCEDURE InitWithKey(
	in_act_id			 	IN	security_pkg.T_ACT_ID,
	in_approval_step_id	 	IN	approval_step.approval_step_id%TYPE,
	in_sheet_key			IN	approval_step_sheet.sheet_key%TYPE,
	in_specific_ind_root_id	IN	pending_region.pending_region_id%TYPE DEFAULT NULL,
	in_specific_region_id	IN	pending_region.pending_region_id%TYPE DEFAULT NULL
)
AS
	v_pending_ind_id		pending_ind.pending_ind_id%TYPE;
	v_pending_region_id		pending_region.pending_region_id%TYPE;
	v_pending_period_id		pending_period.pending_period_id%TYPE;
BEGIN
    
	Init(in_act_id, in_approval_step_id);
	m_sheet_key := in_sheet_key;

	SELECT pending_ind_id, pending_region_id, pending_period_id
	  INTO v_pending_ind_id, v_pending_region_id, v_pending_period_id
	  FROM approval_step_sheet
	 WHERE approval_step_id = in_approval_step_id
	   AND sheet_key = in_sheet_key;
	-- add indicators   
	IF in_specific_ind_root_id IS NOT NULL THEN
		AddIndicatorAndChildren(in_specific_ind_root_id);
	ELSIF v_pending_ind_id IS NULL THEN
		AddAllIndicators();
	ELSE
		AddIndicatorAndChildren(v_pending_ind_id);
	END IF;	   	   
	-- add regions
	IF in_specific_region_id IS NOT NULL THEN
		AddRegion(in_specific_region_id);
	ELSIF v_pending_region_id IS NULL THEN
		AddAllRegions();
	ELSE
		AddRegionAndChildren(v_pending_region_id);
	END IF;	   
	-- add periods
	IF v_pending_period_id IS NULL THEN
		AddAllPeriods();
	ELSE
		AddPeriodId(v_pending_period_id);
	END IF;	   
END;


PROCEDURE Init(
	in_act_id			 IN	security_pkg.T_ACT_ID,
	in_approval_step_id	 IN	approval_step.approval_step_id%TYPE
)
AS
BEGIN
    
	m_is_initialised := TRUE;
	
	m_act_id := in_act_id;
	m_approval_Step_Id := in_approval_step_id;
	m_sheet_key := NULL;
	
	m_ind_ids := security.T_SID_TABLE();
	m_region_ids := security.T_SID_TABLE();
	m_period_ids := security.T_SID_TABLE();

END;

END approval_step_range_pkg;
/
