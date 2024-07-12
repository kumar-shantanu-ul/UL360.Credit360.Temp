-- Please update version.sql too -- this keeps clean builds in sync
define version=1574
@update_header

ALTER TABLE csr.customer ADD (incl_inactive_regions NUMBER(1) DEFAULT 0);

@../csr_data_pkg

@../csr_data_body
@../region_body

@update_tail
