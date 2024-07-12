-- Please update version.sql too -- this keeps clean builds in sync
define version=1444
@update_header

INSERT INTO csr.std_measure (std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd)
VALUES(34, 'm.s^-2', 'm.s^-2', 0, '#,##0', 'sum', NULl, 0, 1,0,-2,0,0,0,0);

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES(26169, 34, 'MJ/t.km', 0.9842, 1, 0);

@update_tail
