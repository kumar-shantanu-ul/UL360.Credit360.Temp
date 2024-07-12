 -- fix up import session ids
 begin 
 for r in ( 
   select v.val_id, iv.imp_val_id, iv.set_val_id
	 from val v
		join ind i on v.ind_sid = i.ind_sid
		join region r on v.region_sid = r.region_sid
		join imp_ind ii on i.ind_sid = ii.maps_to_ind_sid
		join imp_region ir on r.region_sid = ir.maps_to_region_sid
		join imp_val iv 
			on ii.imp_ind_id = iv.imp_ind_id
			and ir.imp_region_id = iv.imp_region_id
			and v.period_start_dtm = iv.start_dtm
			and v.period_end_dtm = iv.end_dtm		
	where source_type_id =2 
	  and source_id is null
	  and v.entry_val_number = iv.val
	  and iv.set_val_Id = v.val_id
  )
  loop
	update val set source_Id = r.imp_val_id where val_id = r.val_id;
  end loop;
 end;
 /
 
 -- list orphans
 select description, x.* 
   from (
		select ind_sid, min(period_start_dtm), max(period_end_dtm), count(*) 
		  from val 
		 where source_type_id =2 
		   and source_id is null 
		 group by ind_sid
	)x join ind i on x.ind_sid = i.ind_sid 
 order by x.ind_sid;


-- zap orphans remaining
begin
	for r in (
		select val_id 
		  from val
		 where source_type_id =2 
		   and source_id is null
	)
	loop
		indicator_pkg.deleteval(security_pkg.getact, r.val_id, 'orphan import value');
	end loop;
end;
/
