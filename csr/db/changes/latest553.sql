-- Please update version.sql too -- this keeps clean builds in sync
define version=553
@update_header

begin
insert into std_factor_set (std_factor_set_id, name) values (3, 'GHG Protocol');
	begin
		insert into std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
		values (13, 'm^-1', 'm^-1', -1, 0, 0, 0, 0, 0, 0);
		insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
		values (56, 13, 'g/tkm', 1e9, 1, 0);
	exception
		when dup_val_on_index then null;
	end;
	begin
		insert into std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
		values (14, 'mole', 'mole', 0, 0, 0, 0, 0, 1, 0);
		insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
		values (52, 14, 'scf', 0.834696671, 1, 0);
	exception
		when dup_val_on_index then null;
	end;
	begin
		insert into std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
		values (15, 'kg/mole', 'kg/mole', 0, 1, 0, 0, 0, -1, 0);
	insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	values (53, 15, 'kg/scf', 1.19804, 1, 0);
	exception
		when dup_val_on_index then null;
	end;
	insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	values (50, 4, 'TJ', 1e-12, 1, 0);
	insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	values (51, 9, 'kg/TJ', 1e12, 1, 0);
	insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	values (54, 8, 'kg/gallon (US)', 0.003785411784, 1, 0);
	insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	values (55, 8, 'g/gallon (US)', 3.785411784, 1, 0);
	insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	values (57, 10, 'g/mile', 1609344, 1, 0);
	insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	values (58, 10, 'g/pkm', 1000000, 1, 0);
	commit;
end;
/

@update_tail
