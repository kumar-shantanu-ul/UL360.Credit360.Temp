whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

define host='&&1'
define region_tree_sid='&&2'

PROMPT WARNING: This will completely remove the tree and all children
PROMPT Type Y to accept and continue

set serveroutput on

DECLARE
	v_prompt 		varchar2(1) := UPPER('&&3');
	v_check		NUMBER(10);
BEGIN
	IF v_prompt = 'Y' THEN
		security.user_pkg.logonadmin('&&host');
		
		SELECT COUNT(*)
		  INTO v_check
		  FROM csr.region_tree
		 WHERE region_tree_root_sid = &&region_tree_sid;
		 
		IF v_check < 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Invalid region tree sid');
		END IF;
		
		SELECT COUNT(*)
		  INTO v_check
		  FROM csr.region_tree
		 WHERE region_tree_root_sid = &&region_tree_sid
		   AND is_primary = 1;
		 
		IF v_check > 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Region tree is a primary');
		END IF;
		
		security.securableobject_pkg.DeleteSo(SYS_CONTEXT('SECURITY', 'ACT'), &&region_tree_sid);
		csr.region_tree_pkg.DeleteObject(SYS_CONTEXT('SECURITY', 'ACT'), &&region_tree_sid);
		COMMIT;
	END IF;
END;
/
