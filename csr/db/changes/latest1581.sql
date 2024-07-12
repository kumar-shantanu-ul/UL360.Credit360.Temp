-- Please update version.sql too -- this keeps clean builds in sync
define version=1581
@update_header

DECLARE
	v_count		number := 0;
BEGIN
	select count(*)
	  into v_count
	  from all_constraints 
	 where constraint_name = UPPER('uk_as2_ir_omi')
	   and owner = 'CSR';
	
	if v_count > 0 then
		execute immediate 'alter table csr.as2_inbound_receipt drop constraint uk_as2_ir_omi';
	end if;
END;
/

@update_tail