-- Please update version.sql too -- this keeps clean builds in sync
define version=2948
define minor_version=0
@update_header

UPDATE csr.std_measure_conversion
   SET A = 1000
 WHERE std_measure_conversion_id = 28180;
 
INSERT INTO csr.std_measure (std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd)
VALUES (39,'l/mol','l/mol',0,'#,##0','sum',null,0,3,0,0,0,0,-1,0);
 
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible)
VALUES (28183,39,'l/mol',1000,1,0,1);

@update_tail
