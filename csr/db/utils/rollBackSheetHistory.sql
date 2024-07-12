DECLARE
	in_sheet_id					number(10) := &&1;
	v_last_sheet_history_id 	number(10);
    CURSOR c IS
        select sheet_history_id 
		  from csr.sheet_history 
		 where sheet_id = in_sheet_id 
		   and sheet_history_id < v_last_sheet_history_id
		 order by sheet_history_id desc;
    r	c%ROWTYPE;
BEGIN 
	select last_sheet_history_id into v_last_sheet_history_id 
	  from csr.sheet 
	 where sheet_id = in_sheet_id;
	--     
	OPEN c;
    FETCH c INTO r;
    IF c%NOTFOUND THEN
    	RAISE_APPLICATION_ERROR(-20001, 'Already at start of history');
    END IF;
    --
    UPDATE csr.sheet 
       SET last_sheet_history_id = r.sheet_history_id
     WHERE sheet_id = in_sheet_id;
    --
    DELETE FROM csr.SHEET_HISTORY
     WHERE sheet_history_id = v_last_sheet_history_id;
END;
/

PROMPT Now commit the changes
-- commit;


/*

-- rollback a bunch of sheets that match certain criteria
begin
	for r in (
		select s.sheet_id, sh.sheet_history_id, sh.prev_sheet_history_id
		 from sheet s
			join delegation d on s.delegation_sid = d.delegation_sid
			join (
				select * from (
					select sheet_id, sheet_history_id, prev_sheet_history_Id
					  from (
						select sheet_history_id, sheet_id, row_number() over (partition by sheet_Id order by sheet_history_id desc) rn,
							lead(sheet_history_id) over (partition by sheet_id order by sheet_history_id desc) prev_sheet_history_id
						  from sheet_history
						) where rn = 1
					)
			) sh on s.sheet_id = sh.sheet_id
		 where prev_sheet_history_id is not null
		   and s.start_dtm = '1 Jan 2012'  and s.end_dtm = '1 jan 2013'         -- condition to rollback
	)
	loop		
		UPDATE sheet 
		   SET last_sheet_history_id = r.prev_sheet_history_id
		 WHERE sheet_id = r.sheet_id;
		--
		DELETE FROM SHEET_HISTORY
		 WHERE sheet_history_id = r.sheet_history_id;
	end loop;
end;
/

*/
