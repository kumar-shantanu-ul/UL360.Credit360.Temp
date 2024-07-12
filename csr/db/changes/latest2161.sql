-- Please update version.sql too -- this keeps clean builds in sync
define version=2161
@update_header

update csr.std_factor
   set value=2.6769, note='DEFRA 2013 (2012 Figures)'
 where std_factor_id = (
	select std_factor_id from csr.std_factor where factor_type_id = 8063 and gas_type_id = 1 and start_dtm = date '1990-01-01' and std_factor_set_id = 35
);

update csr.std_factor
   set value=2.6569, note='DEFRA 2013 (2012 Figures)'
 where std_factor_id = (
	select std_factor_id from csr.std_factor where factor_type_id = 8063 and gas_type_id = 2 and start_dtm = date '1990-01-01' and std_factor_set_id = 35
);

update csr.std_factor
   set value=0.0009, note='DEFRA 2013 (2012 Figures)'
 where std_factor_id = (
	select std_factor_id from csr.std_factor where factor_type_id = 8063 and gas_type_id = 3 and start_dtm = date '1990-01-01' and std_factor_set_id = 35
);

update csr.std_factor
   set value=0.0191, note='DEFRA 2013 (2012 Figures)'
 where std_factor_id = (
	select std_factor_id from csr.std_factor where factor_type_id = 8063 and gas_type_id = 4 and start_dtm = date '1990-01-01' and std_factor_set_id = 35
);

update csr.std_factor
   set value=2.6705, note='DEFRA 2013'
 where std_factor_id = (
	select std_factor_id from csr.std_factor where factor_type_id = 8063 and gas_type_id = 1 and start_dtm = date '2013-01-01' and std_factor_set_id = 35
);

update csr.std_factor
   set value=2.6502, note='DEFRA 2013'
 where std_factor_id = (
	select std_factor_id from csr.std_factor where factor_type_id = 8063 and gas_type_id = 2 and start_dtm = date '2013-01-01' and std_factor_set_id = 35
);

update csr.std_factor
   set value=0.0008, note='DEFRA 2013'
 where std_factor_id = (
	select std_factor_id from csr.std_factor where factor_type_id = 8063 and gas_type_id = 3 and start_dtm = date '2013-01-01' and std_factor_set_id = 35
);

update csr.std_factor
   set value=0.0195, note='DEFRA 2013'
 where std_factor_id = (
	select std_factor_id from csr.std_factor where factor_type_id = 8063 and gas_type_id = 4 and start_dtm = date '2013-01-01' and std_factor_set_id = 35
);

BEGIN
FOR r IN (
		SELECT host
		  FROM csr.customer
		 WHERE use_carbon_emission = 1
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		csr.calc_pkg.AddJobsForFactorType(8063);
	END LOOP;
END;
/

@update_tail
