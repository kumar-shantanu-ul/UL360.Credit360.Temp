-- Please update version.sql too -- this keeps clean builds in sync
define version=1485
@update_header

  Update csr.factor_type set parent_id = 421 where factor_type_id = 7043;

@update_tail
