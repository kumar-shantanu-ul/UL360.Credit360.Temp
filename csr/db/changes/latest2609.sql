--Please update version.sql too -- this keeps clean builds in sync
define version=2609
@update_header

-- CO2 / CO2e back to front
update csr.std_factor set value = 2.6769 where std_factor_id = 184332957;
update csr.std_factor set value = 2.6569 where std_factor_id = 184332909;
update csr.std_factor set value = 2.6705 where std_factor_id = 184324792;
update csr.std_factor set value = 2.6502 where std_factor_id = 184324208;
update csr.std_factor set value = 2.6769 where std_factor_id = 184369389;
update csr.std_factor set value = 2.6569 where std_factor_id = 184369388;
update csr.std_factor set value = 2.6705 where std_factor_id = 184369393;
update csr.std_factor set value = 2.6502 where std_factor_id = 184369392;

@update_tail
