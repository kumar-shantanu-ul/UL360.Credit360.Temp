-- Please update version.sql too -- this keeps clean builds in sync
define version=2356
@update_header

insert into CSR.STD_MEASURE_CONVERSION 
values (28133, 9, 't/TJ', 1000000, 1, 0, 0);

@update_tail
