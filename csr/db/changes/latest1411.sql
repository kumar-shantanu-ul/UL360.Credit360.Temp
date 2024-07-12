-- Please update version.sql too -- this keeps clean builds in sync
define version=1411
@update_header

begin
	begin
		Insert into CSR.STD_MEASURE (STD_MEASURE_ID, NAME, DESCRIPTION, SCALE, FORMAT_MASK, REGIONAL_AGGREGATION, CUSTOM_FIELD, PCT_OWNERSHIP_APPLIES, M, KG, S, A, K, MOL, CD) values (32,'m.kg.s^-2','m.kg.s^-2',0,'#,##0','sum',NULL,0,1,1,-2,0,0,0,0);
	exception
		when dup_val_on_index then
			null;			
	end;
	begin
		Insert into CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C) values (25989,32,'GJ/km',.000001,1,0);
	exception
		when dup_val_on_index then
			null;			
	end;
	begin
		INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
		VALUES(26164, 32, 'MJ/km', 0.001, 1, 0);
	exception
		when dup_val_on_index then
			null;			
	end;
end;
/

@update_tail
