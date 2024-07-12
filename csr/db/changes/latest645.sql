-- Please update version.sql too -- this keeps clean builds in sync
define version=645
@update_header

-- This script will fail because deleg_manage_pkg was renamed: ignore it
whenever oserror continue
whenever sqlerror continue

@../delegation_pkg
@../deleg_manage_pkg
@../delegation_body
@../deleg_manage_body
@../role_body

grant execute on csr.deleg_manage_pkg to web_user;

@update_tail
