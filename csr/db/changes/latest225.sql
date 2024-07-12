-- Please update version.sql too -- this keeps clean builds in sync
define version=225
@update_header

DECLARE
	v_version	NUMBER;
BEGIN
	SELECT db_version INTO v_version FROM aspen2.version;
	IF v_version < 10 THEN
		RAISE_APPLICATION_ERROR(-20001, 'aspen2 must be at version 10 or greater before running this');
	END IF;
END;
/

drop type t_split_table;
drop type t_split_row;
drop type t_split_numeric_table;
drop type t_split_numeric_row;
drop package utils_pkg;

PROMPT Enter connection name (e.g. ASPEN)
connect aspen2/aspen2@&&1
BEGIN
	FOR r IN (SELECT username FROM all_users WHERE username in ('CSR','ACTIONS','DONATIONS','SUPPLIER','INDIGOWEB','MAIL')) LOOP
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON utils_pkg TO '||r.username;
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON t_split_row TO '||r.username;
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON t_split_table TO '||r.username;
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON t_split_numeric_row TO '||r.username;
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON t_split_numeric_table TO '||r.username;
		EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM '||r.username||'.t_split_row FOR aspen2.t_split_row';
		EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM '||r.username||'.t_split_table FOR aspen2.t_split_table';
		EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM '||r.username||'.t_split_numeric_row FOR aspen2.t_split_numeric_row';
		EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM '||r.username||'.t_split_numeric_table FOR aspen2.t_split_numeric_table';
		EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM '||r.username||'.utils_pkg FOR aspen2.utils_pkg';		
	END LOOP;
END;
/

connect csr/csr@&&1
@..\..\..\aspen2\tools\recompile_packages

@update_tail
