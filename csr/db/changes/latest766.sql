-- Please update version.sql too -- this keeps clean builds in sync
define version=766
@update_header

UPDATE csr.std_measure SET name = 'm^-2.s^2', description = 'm^-2.s^2' WHERE std_measure_id = 9;
UPDATE csr.std_measure SET name = 'm^2.s^-2', description = 'm^2.s^-2' WHERE std_measure_id = 17;
UPDATE csr.std_measure SET name = 'kg/s^2', description = 'kg/s^2' WHERE std_measure_id = 18;

INSERT INTO csr.std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
	VALUES (24, 'm^-3', 'm^-3', -3, 0, 0, 0, 0, 0, 0);

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (85, 24, '1/Gallon (UK)', 0.00454609189, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (86, 24, 'l/Gallon (US)', 0.00378541179, 1, 0);

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (87, 4, 'MBTU (US)', 0.000000948043428, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (88, 4, 'MBTU (UK)', 0.00000094781712, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (89, 4, 'MBTU (EC)', 0.000000947813394, 1, 0);

UPDATE csr.std_measure_conversion SET description = 'MMBTU (US)' WHERE description = 'million BTU (US)';
UPDATE csr.std_measure_conversion SET description = 'MMBTU (UK)' WHERE description = 'million BTU (UK)';
UPDATE csr.std_measure_conversion SET description = 'MMBTU (EC)' WHERE description = 'million BTU (EC)';

INSERT INTO csr.std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
	VALUES (25, 'm^2.s^-2', 'm^2.s^-2', 2, 0, -2, 0, 0, 0, 0);

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (90, 25, 'BTU (US)/lb', 0.000430025266, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (91, 25, 'BTU (UK)/lb', 0.000429922614, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (92, 25, 'BTU (EC)/lb', 0.000429920924, 1, 0);

INSERT INTO csr.std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
	VALUES (26, 'm^-1.kg.s^-2', 'm^-1.kg.s^-2', -1, 1, -2, 0, 0, 0, 0);

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (93, 26, 'BTU (US)/Gallon (US)', 3.58873477e-6, 1, 0);

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (94, 18, 'MBTU (US)/ft^2', 8.80761166e-8, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (95, 18, 'MBTU (UK)/ft^2', 8.80550919e-8, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (96, 18, 'MBTU (EC)/ft^2', 8.80547458e-8, 1, 0);

UPDATE csr.std_measure_conversion SET description = 'MMBTU (US)/ft^2' WHERE std_measure_conversion_id = 67;

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (97, 18, 'kWh/ft^2', 2.58064e-8, 1, 0);

INSERT INTO csr.std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
	VALUES (27, 'kg/m^2', 'kg/m^2', -2, 1, 0, 0, 0, 0, 0);

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (98, 27, 'metric ton/ft^2', 9.29030401e-5, 1, 0);


-- Copied these from live as I was missing them locally
BEGIN
	insert into csr.std_measure (std_measure_id, name, description, scale, format_mask, regional_aggregation, pct_ownership_applies, m, kg, s, a, k, mol, cd) values (19, '1/J', '1/J', 0, '#,##0', 'sum', 0, -2, -1, 2, 0, 0, 0, 0);
	insert into csr.std_measure (std_measure_id, name, description, scale, format_mask, regional_aggregation, pct_ownership_applies, m, kg, s, a, k, mol, cd) values (20, 'kg.s', 'kg.s', 0, '#,##0', 'sum', 0, 0, 1, 1, 0, 0, 0, 0);
	insert into csr.std_measure (std_measure_id, name, description, scale, format_mask, regional_aggregation, pct_ownership_applies, m, kg, s, a, k, mol, cd) values (21, 's^-1', 's^-1', 0, '#,##0', 'sum', 0, 0, 0, -1, 0, 0, 0, 0);
	insert into csr.std_measure (std_measure_id, name, description, scale, format_mask, regional_aggregation, pct_ownership_applies, m, kg, s, a, k, mol, cd) values (22, 's', 's', 0, '#,##0', 'sum', 0, 0, 0, 1, 0, 0, 0, 0);
	insert into csr.std_measure (std_measure_id, name, description, scale, format_mask, regional_aggregation, pct_ownership_applies, m, kg, s, a, k, mol, cd) values (23, 'kg^-1.s^-1', 'kg^-1.s^-1', 0, '#,##0', 'sum', 0, 0, -1, -1, 0, 0, 0, 0);
EXCEPTION WHEN dup_val_on_index THEN NULL;
END;
/

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (99, 20, 'ton.hour', 2.77777778e-7, 1, 0);

@update_tail
