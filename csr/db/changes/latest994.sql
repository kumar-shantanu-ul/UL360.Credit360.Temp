-- Please update version.sql too -- this keeps clean builds in sync
define version=994
@update_header

update csr.delegation
    set master_delegation_sid = null
  where delegation_sid in (
	select delegation_sid from csr.master_deleg
  );

@..\deleg_plan_pkg
@..\deleg_plan_body

@update_tail
