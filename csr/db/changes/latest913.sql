-- Please update version.sql too -- this keeps clean builds in sync
define version=913
@update_header

ALTER TABLE csr.measure_conversion
	ADD STD_MEASURE_CONVERSION_ID NUMBER(10, 0);

@..\measure_pkg
@..\csr_data_pkg

@..\measure_body

@update_tail
