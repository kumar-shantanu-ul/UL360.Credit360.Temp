-- Please update version.sql too -- this keeps clean builds in sync
define version=1124
@update_header

alter table csr.axis add (
  HELPER_PKG VARCHAR2(255)
);

@..\strategy_pkg
@..\strategy_body

@update_tail