-- Please update version.sql too -- this keeps clean builds in sync
define version=1005
@update_header

begin
	update csr.measure 
	   set format_mask=format_mask||'%' 
	 where std_measure_conversion_id=21453 and instr(format_mask, '%')<=0;
	update csr.measure
	   set std_measure_conversion_id=1
	 where std_measure_conversion_id=21453;
	delete from csr.std_measure_conversion where std_measure_conversion_id=21453;
end;
/

@update_tail
