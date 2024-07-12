-- Please update version.sql too -- this keeps clean builds in sync
define version=629
@update_header

insert into csr.std_measure (std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd)
values (18, 'J/m^2', 'J/m^2', 0, '#,##0', 'sum', null, 0, 0, 1, -2, 0, 0, 0, 0);
insert into csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
values (66, 18, 'BTU (US)/ft^2', 0.00008807611664994907426951454371080606542396, 1, 0);
insert into csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
values (67, 18, 'million BTU (US)/ft^2', 0.00000000008807611664994907426951454371080606542396, 1, 0);

@update_tail
