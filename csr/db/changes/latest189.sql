-- Please update version.sql too -- this keeps clean builds in sync
define version=189
@update_header

declare
	v_val_change_id val_change.val_change_id%TYPE;
begin
	for r in (select * from val where last_val_change_id is null) loop
		-- create a fake change for the value
		INSERT INTO VAL_CHANGE
		 	(val_change_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, status, 
		 	 source_id, entry_measure_conversion_id, entry_val_number, note, source_type_id, changed_by_sid,
		 	 changed_dtm, reason, val_id)
		VALUES
			(val_change_id_seq.nextval, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, r.val_number, r.status, 
		  	 r.source_id, r.entry_measure_conversion_id, r.entry_val_number, null, r.source_type_id, 3,
		  	 sysdate, 'New value', r.val_id)
		 RETURNING val_change_id INTO v_val_change_id;
		update val
		   set last_val_change_id = v_val_change_id
		 where val_id = r.val_id;
	end loop;
end;
/

alter table val modify last_val_change_id not null;
alter table val drop constraint fk_val_1;
ALTER TABLE VAL ADD CONSTRAINT FK_VAL_1
     FOREIGN KEY (LAST_VAL_CHANGE_ID)
    REFERENCES VAL_CHANGE(VAL_CHANGE_ID)  DEFERRABLE INITIALLY DEFERRED
 ;

@update_tail
