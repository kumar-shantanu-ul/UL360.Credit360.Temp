-- Please update version.sql too -- this keeps clean builds in sync
define version=456
@update_header

ALTER TABLE csr.measure_conversion
ADD A NUMBER(10, 0);
ALTER TABLE csr.measure_conversion
ADD B NUMBER(10, 0);
ALTER TABLE csr.measure_conversion
ADD C NUMBER(10, 0);

ALTER TABLE measure_conversion_period
ADD A NUMBER(10, 0);
ALTER TABLE measure_conversion_period
ADD B NUMBER(10, 0);
ALTER TABLE measure_conversion_period
ADD C NUMBER(10, 0);

@update_tail
