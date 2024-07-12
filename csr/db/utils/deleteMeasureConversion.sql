-- assumes pct ownership isn't in use
declare
	in_measure_conversion_id	measure_conversion.measure_conversion_id%TYPE := xxxx;
begin
	update val
	   set entry_measure_conversion_id = null,
		entry_val_number = val_number
	 where entry_measure_conversion_id =  in_measure_conversion_id;
	 
	update val_change
	   set entry_measure_conversion_id = null,
		entry_val_number = val_number
	 where entry_measure_conversion_id =  in_measure_conversion_id;
	 
	update sheet_value
	   set entry_measure_conversion_id = null,
		entry_val_number = val_number
	 where entry_measure_conversion_id =  in_measure_conversion_id;
	 
	update sheet_value_change
	   set entry_measure_conversion_id = null,
		entry_val_number = val_number
	 where entry_measure_conversion_id =  in_measure_conversion_id;
	 
	 
	update imp_measure 
	  set maps_to_measure_conversion_id = null
	 where maps_to_measure_conversion_id =  in_measure_conversion_id;
	 
	 
	update range_ind_member 
	  set measure_conversion_id = null
	 where measure_conversion_id =  in_measure_conversion_id;
	 
	update dataview_ind_member 
	  set measure_conversion_id = null
	 where measure_conversion_id =  in_measure_conversion_id;
	 
	 update scenario_rule
	  set measure_conversion_id = null
	 where measure_conversion_id =  in_measure_conversion_id;
	 
	 delete from measure_conversion where measure_conversion_id =  in_measure_conversion_id;
end;
/
