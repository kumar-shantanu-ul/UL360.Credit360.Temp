-- Please update version.sql too -- this keeps clean builds in sync
define version=2805
define minor_version=0
define is_combined=0
@update_header

@../csr_data_pkg
@../tag_pkg
@../supplier_body

@update_tail
