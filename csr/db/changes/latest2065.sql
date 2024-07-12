-- Please update version.sql too -- this keeps clean builds in sync
define version=2065
@update_header

-- XXX: dodgy old style script
-- there's no way of granting this grant from UPD as it
-- doesn't have permission to do so.
connect sys/oracle@&_CONNECT_IDENTIFIER AS SYSDBA
grant execute on sys.dbms_lock to csr;

connect upd/upd@&_CONNECT_IDENTIFIER

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail
