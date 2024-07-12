
begin
	for d in (
    	        select delegation_sid from delegation 
        connect by prior delegation_sid = parent_sid
        start with delegation_sid in  (1456356, 1456357,  1456358)
	       order by level)
    loop    
    	dbms_output.put_line('doing delegation '||d.delegation_sid);
	    insert into security.securable_object@live
	    	select * from security.securable_object where sid_id = d.delegation_sid;
	    insert into security.group_table@live
	    	select * from security.group_table where sid_id = d.delegation_sid;
	    insert into security.group_members@live
	    	select * from security.group_members where member_sid_id = d.delegation_sid OR group_sid_id =d.delegation_sid;
	    insert into security.acl@live
	    	select * from security.acl where sid_id = d.delegation_sid;
	    for r in (SELECT ac.* FROM security.SECURABLE_OBJECT so, security.acl ac WHERE so.sid_id = d.delegation_sid and so.dacl_id = ac.acl_id)
        loop   
        	begin
				insert into security.acl@live (acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set) 
			    	values (r.acl_id, r.acl_index, r.ace_type, r.ace_flags, r.sid_id, r.permission_set);
		    exception
		    	when dup_val_on_index then null;
		    end;
		end loop;
		insert into delegation@live
			select * from delegation where delegation_sid = d.delegation_sid;
		insert into delegation_user@live
			select * from delegation_user where delegation_sid = d.delegation_sid;
		insert into delegation_region@live
			select * from delegation_region where delegation_sid = d.delegation_sid and region_sid = 1421846;
		insert into delegation_ind@live
			select * from delegation_ind where delegation_sid = d.delegation_sid;
		insert into sheet@live (sheet_id, delegation_sid, start_dtm, end_dtm ,submission_dtm, reminder_dtm, last_sheet_history_Id, last_reminded_dtm)
			select sheet_id, delegation_sid, start_dtm, end_dtm ,submission_dtm, reminder_dtm, null, last_reminded_dtm from sheet where delegation_sid = d.delegation_sid; 
		insert into sheet_history@live
			select * from sheet_history where sheet_id in (select sheet_id from sheet where delegation_sid = d.delegation_sid);
		for r in (
			select sheet_id, max(sheet_history_id) msh from sheet_history where sheet_id in (select sheet_id from sheet where delegation_sid = d.delegation_sid) group by sheet_id
		    )
		Loop
			update sheet@live set last_sheet_history_id = r.msh where sheet_id = r.sheet_id;
		end loop;    
		for r in (
			SELECT SHEET_VALUE_ID FROM SHEET_VALUE WHERE SHEET_ID in (select sheet_id from sheet where delegation_sid = d.delegation_sid)
		    )
		loop
			insert into sheet_value@live (SHEET_VALUE_ID, SHEET_ID, IND_SID, REGION_SID, VAL_NUMBER, SET_BY_USER_SID, SET_DTM, NOTE, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, IS_INHERITED, STATUS, LAST_SHEET_VALUE_CHANGE_ID, ALERT, FILE_UPLOAD_SID, FLAG)
		    	select SHEET_VALUE_ID, SHEET_ID, IND_SID, REGION_SID, VAL_NUMBER, SET_BY_USER_SID, SET_DTM, NOTE, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, IS_INHERITED, STATUS, NULL, ALERT, null, FLAG from sheet_value where sheet_value_Id = r.sheet_value_Id;
			insert into sheet_value_change@live (SHEET_VALUE_CHANGE_ID, SHEET_VALUE_ID, IND_SID, REGION_SID, VAL_NUMBER, REASON, CHANGED_BY_SID, CHANGED_DTM, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, NOTE, FILE_UPLOAD_SID, FLAG)
		    	select SHEET_VALUE_CHANGE_ID, SHEET_VALUE_ID, IND_SID, REGION_SID, VAL_NUMBER, REASON, CHANGED_BY_SID, CHANGED_DTM, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, NOTE, null, FLAG from sheet_value_change where sheet_value_Id = r.sheet_value_Id;
		    for f in (
			    select sheet_value_id, max(sheet_value_change_id) msh from sheet_value_change where sheet_value_id = r.sheet_value_Id group by sheet_value_id 
		    )
		    loop
		            update sheet_value@live set last_sheet_value_change_id = f.msh where sheet_value_id = f.sheet_Value_id; 
		    end loop;
		    /*insert into sheet_inherited_value@live
		    	select * from sheet_inherited_value where inherited_value_id = r.sheet_value_id;        
		    insert into sheet_inherited_value@live
		    	select * from sheet_inherited_value where sheet_value_id = r.sheet_value_id;*/
		end loop;
	end loop;
end;
