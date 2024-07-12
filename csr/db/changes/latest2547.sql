-- Please update version.sql too -- this keeps clean builds in sync
define version=2547
@update_header

update CSR.factor_type set std_measure_id = 1 where factor_type_id  in (select factor_type_id from CSR.factor_type where parent_id = 15235);

@update_tail