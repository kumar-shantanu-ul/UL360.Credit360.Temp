-- Please update version.sql too -- this keeps clean builds in sync
define version=563
@update_header

insert into std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
values(16, 'm^-2', 'm^-2', -2, 0, 0, 0, 0, 0, 0);

insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
values(60, 16, 'mile/gallon (US)', 2.35214584e-6, 1, 0);

@update_tail
