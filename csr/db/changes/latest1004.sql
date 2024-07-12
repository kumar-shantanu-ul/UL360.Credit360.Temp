-- Please update version.sql too -- this keeps clean builds in sync
define version=1004
@update_header

update csr.std_measure_conversion set a=1 where std_measure_conversion_id=21453;

@update_tail
