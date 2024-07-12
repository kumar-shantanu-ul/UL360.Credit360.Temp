DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_users
	 WHERE username = 'CHEM';
	IF v_exists <> 0 THEN
		EXECUTE IMMEDIATE 'DROP USER CHEM CASCADE';
	END IF;
END;
/

CREATE USER "CHEM" IDENTIFIED BY "CHEM" QUOTA UNLIMITED ON USERS;
-- USER SQL
ALTER USER "CHEM" 
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP"
ACCOUNT UNLOCK;

GRANT CREATE SESSION TO "CHEM";

@@object_grants

grant execute on security.security_pkg to chem;
grant execute on csr.csr_data_pkg to chem;
grant execute on csr.sheet_pkg to chem;
grant execute on csr.sqlreport_pkg to chem;
grant execute on csr.delegation_pkg to chem
grant execute on csr.region_pkg to chem
grant execute on csr.stragg to chem;

GRANT INSERT,SELECT ON csr.flow_item TO chem;
GRANT SELECT ON csr.customer TO chem;
GRANT SELECT ON csr.flow TO chem;
GRANT SELECT ON csr.flow_state_log TO chem;
GRANT SELECT ON csr.flow_item_id_seq to chem;
GRANT SELECT ON csr.role TO chem;
GRANT SELECT ON csr.region_role_member TO chem;
GRANT SELECT ON csr.flow_state_role TO chem;

@@create_schema
@@create_views

@@cross_schema_constraints

@@rls

@@build
@@package_grants

@@basedata

commit;

