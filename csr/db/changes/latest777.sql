-- Please update version.sql too -- this keeps clean builds in sync
define version=777
@update_header

begin
	update csr.factor_type set name = 'Small petrol motorbike (mopeds/scooters up to 125cc)' where factor_type_id = 155;
	update csr.factor_type set name = 'Medium petrol motorbike (125-500cc)' where factor_type_id = 156;
	update csr.factor_type set name = 'Large petrol motorbike (over 500cc)' where factor_type_id = 157;
	update csr.factor_type set name = 'Average petrol motorbike (unknown engine size)' where factor_type_id = 158;
	update csr.factor_type set name = 'Small petrol motorbike (mopeds/scooters up to 125cc)' where factor_type_id = 328;
	update csr.factor_type set name = 'Medium petrol motorbike (125-500cc)' where factor_type_id = 329;
	update csr.factor_type set name = 'Large petrol motorbike (over 500cc)' where factor_type_id = 330;
	update csr.factor_type set name = 'Average petrol motorbike (unknown engine size)' where factor_type_id = 331;
end;
/

@update_tail
