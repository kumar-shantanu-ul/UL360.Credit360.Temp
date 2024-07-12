-- TODO: what if they've got sub delegations?
DECLARE
	in_delegation_sid		security_pkg.T_SID_ID := 111030;
    CURSOR d_c IS
    	SELECT delegation_sid, name, start_dtm, end_dtm, interval, allocate_users_to, app_sid, note, 
	    	group_by, submission_schedule_id, reminder_offset, is_note_mandatory, created_by_sid , parent_sid
          FROM delegation 
         WHERE delegation_sid = in_delegation_sid;
    d						d_c%ROWTYPE;
    v_new_name				VARCHAR2(1024);
    v_new_delegation_sid	security_pkg.T_SID_ID;
    v_act					security_pkg.T_ACT_ID;
    v_sheet_id				csr_data_pkg.T_SHEET_ID;
    v_end_dtm				DATE;
    v_changed_cnt			INTEGER :=0;
    v_sub_delegations		NUMBER(10);
BEGIN
	SELECT COUNT(*) INTO v_sub_delegations
      FROM delegation
     WHERE parent_sid = in_delegation_sid;
    IF v_sub_delegations > 0 THEN
    	RAISE_APPLICATION_ERROR(-20001, 'Delegation has sub-delegations');
    END IF;
	-- get delegation details
    OPEN d_c;
    FETCH d_c INTO d;
    --
	FOR r IN 
    	(select region_sid, mandatory, description from
			(select region_sid, mandatory, description, rownum rn 
			   from delegation_region 
			  where delegation_sid = in_delegation_sid
			  order by pos)
			 where rn > 1)
	LOOP
    	-- copy delegation
		user_pkg.logonauthenticated(d.created_by_sid,500,v_act);
       	-- create non top level delegation
        v_new_name := d.name||' - '||r.description;
        IF d.app_sid = d.parent_sid THEN
        	-- top level
			delegation_pkg.CreateTopLevelDelegation(v_act, v_new_name, d.start_dtm, d.end_dtm, d.interval, d.allocate_users_to, d.app_sid, d.note, 
	    		d.group_by, d.submission_schedule_id, d.reminder_offset, d.is_note_mandatory, v_new_delegation_sid);
		ELSE
        	-- non top level
	        delegation_pkg.CreateNonTopLevelDelegation(v_act, d.parent_sid, d.app_sid, v_new_name, null, null, null, null,
	           	d.interval, d.submission_schedule_id, d.note, v_new_delegation_sid);
			-- insert users
			FOR u IN 
				(SELECT delegation_sid, user_sid 
				   FROM DELEGATION_USER
				  WHERE delegation_sid = in_delegation_sid) 
			LOOP    
				INSERT INTO DELEGATION_USER (delegation_sid, user_sid)
					VALUES (v_new_delegation_sid, u.user_sid);
				group_pkg.AddMember(v_act, u.user_sid, v_new_delegation_sid);
			END LOOP;   
        END IF;        
        -- copy indicators
         INSERT INTO delegation_ind
	        	(delegation_sid, ind_sid, mandatory, description, pos, section_Key)
         	SELECT v_new_delegation_sid, ind_sid, mandatory, description, pos, section_key
		      FROM delegation_ind
			 WHERE delegation_sid = in_delegation_sid;        
        -- insert this region (aggregating to self)
        INSERT INTO DELEGATION_REGION
        	(delegation_sid, region_sid, mandatory, description, pos, aggregate_to_region_sid)
        VALUES
        	(v_new_delegation_sid, r.region_sid, r.mandatory, r.description, 1, r.region_sid);    
        -- insert some sheets
        FOR s IN 
        	(SELECT sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm 
               FROM sheet
              WHERE delegation_sid = in_delegation_sid)
        LOOP
	        sheet_pkg.CreateSheet(v_act, v_new_delegation_sid, s.start_dtm, s.submission_dtm, v_sheet_id, v_end_dtm);
            UPDATE sheet_value
			   SET sheet_id = v_sheet_id
			 WHERE sheet_id = s.sheet_id
			   AND region_sid = r.region_sid;
        END LOOP;        
    	-- remove from old delegation
    	DELETE FROM DELEGATION_REGION
        	  WHERE region_sid = r.region_sid
                AND delegation_sid = in_delegation_sid;
		v_changed_cnt := v_changed_cnt + 1;
    END LOOP;	
    dbms_output.put_line(v_changed_cnt||' thigns changed');
    IF v_changed_cnt > 0 THEN
	    -- fix up aggregate_to_region_sid on first region just in case
	    UPDATE DELEGATION_REGION
	       SET AGGREGATE_TO_REGION_SID = REGION_SID
	     WHERE DELEGATION_SID = in_delegation_sid;
	   	-- rename
	    UPDATE DELEGATION 
	       SET name = name||' - '|| (SELECT description FROM DELEGATION_REGION WHERE DELEGATION_SID = in_delegation_sid)
         WHERE DELEGATION_SID = in_delegation_sid;
	END IF;
END;
