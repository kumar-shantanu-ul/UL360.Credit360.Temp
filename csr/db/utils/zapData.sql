alter session set ddl_lock_timeout=180;
ALTER SESSION SET CONSTRAINTS = DEFERRED;

/
declare
	v_app_sid	csr.customer.app_sid%TYPE;
	
	type t_array is varray(5) of varchar2(30);
	schemas t_array := t_array('SURVEYS', 'FILESHARING', 'FILESTORE', 'FILTERS', 'SUGGESTIONS');
	
	v_nulled_constraints aspen2.T_VARCHAR2_TABLE := aspen2.T_VARCHAR2_TABLE();
	
	v_table_name		varchar2(4000);
	v_columns			varchar2(4000);
	v_constraint_name	varchar2(4000);
	v_sql				varchar2(4000);
begin
	begin
		security.user_pkg.logonadmin('&&1');
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	exception
		when security.security_pkg.object_not_found then
			-- hmm, ok -- the row in website is missing.  let's try looking in csr.customer
			begin
				select app_sid
				  into v_app_sid
				  from csr.customer
				 where lower(host) = lower('&&1');
				 
				 security.user_pkg.logonAdmin;
				 security.security_pkg.setapp(v_app_sid);
			exception
				when no_data_found then
					DBMS_OUTPUT.PUT_LINE('Host not found. Nothing to do.');
					return;
			end;			 
	end;
	
	IF security.security_pkg.GetApp IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Assertion failed, should have an APP_SID by this point in the session');
	END IF;

	for i in 1..schemas.count loop
		-- Null out any nullable columns involved in a circular FK constraint
		v_constraint_name := NULL;
		v_table_name := NULL;
		v_columns := NULL;

		FOR rec IN (
			WITH tables_to_empty AS (
				SELECT distinct tc.table_name
				  FROM all_tab_columns tc
				  JOIN dba_tables t ON tc.owner = t.owner AND tc.table_name = t.table_name
				 WHERE tc.owner = UPPER(schemas(i))
				   AND tc.column_name='APP_SID'
			)
			SELECT distinct tc.table_name, tc.column_name, cc.constraint_name
			  FROM all_tab_columns tc
			  JOIN dba_cons_columns cc ON tc.column_name = cc.column_name AND tc.table_name = cc.table_name AND cc.owner = UPPER(schemas(i))
			  JOIN dba_constraints c1 ON cc.constraint_name = c1.constraint_name AND c1.owner = cc.owner
			  JOIN dba_constraints c2 ON c2.owner = c1.r_owner AND c2.constraint_name = c1.r_constraint_name
			  JOIN dba_constraints c3 ON c3.owner = c2.owner AND c3.table_name = c2.table_name
			  JOIN dba_constraints c4 ON c4.owner = c3.r_owner AND c4.constraint_name = c3.r_constraint_name
			 WHERE tc.owner = UPPER(schemas(i))
			   AND tc.table_name IN (SELECT table_name from tables_to_empty)
			   AND nullable='Y'
			   AND c1.r_owner = UPPER(schemas(i))
			   AND c1.table_name = c4.table_name
		  ORDER BY tc.table_name
		) LOOP
			-- Each row in the cursor is for a single column.  We have to update all columns for an individual constraint in a single
			-- UPDATE statement so that constraints that require all columns to be NULL or NOT NULL are not violated, which is what
			-- would happen if we try to update each column individually.
			IF v_table_name IS NOT NULL AND v_table_name = rec.table_name THEN
				-- Current column belongs to the same table as the previous column so just add it to the list of columns that need updating
				v_columns := v_columns || ', ' || rec.column_name || ' = NULL';
			ELSE
				IF v_table_name IS NOT NULL THEN
					-- Update column(s) from previous table
					v_sql := 'UPDATE ' || schemas(i) || '.' || v_table_name || ' SET ' || v_columns || ' WHERE APP_SID = ' || v_app_sid;
					-- dbms_output.put_line(v_sql);
					EXECUTE IMMEDIATE(v_sql);
				END IF;
				
				-- Put the column for the current table into the variables
				v_constraint_name := rec.constraint_name;
				v_table_name := rec.table_name;
				v_columns := rec.column_name || ' = NULL';
			END IF;

			v_nulled_constraints.extend;
			v_nulled_constraints(v_nulled_constraints.COUNT) := rec.constraint_name;
		END LOOP;

		if v_columns IS NOT NULL then
			-- Ensure the final table is updated
			v_sql := 'UPDATE ' || schemas(i) || '.' || v_table_name || ' SET ' || v_columns || ' WHERE APP_SID = ' || v_app_sid;
			-- dbms_output.put_line(v_sql);
			EXECUTE IMMEDIATE(v_sql);
		end if;
		
		-- Clear every table for the given app_sid
		DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'HH24:MI:SS') || ' - ' || schemas(i) || ' - Deleting data');
		FOR rec IN (
			WITH tables_to_empty AS (
				SELECT tc.table_name
				  FROM all_tab_columns tc
				  JOIN dba_tables t ON tc.owner = t.owner AND tc.table_name = t.table_name
				 WHERE tc.owner = UPPER(schemas(i))
				   AND tc.column_name='APP_SID'
			)
			SELECT table_name, lvl
			  FROM (
				SELECT table_name, max(lvl) lvl
				  FROM (
					SELECT table_name, fk_table_name, level lvl
					  FROM (
						SELECT t.table_name, CASE WHEN nc.column_value IS NULL AND fk.deferrable != 'DEFERRABLE' THEN fk.table_name END fk_table_name
						  FROM tables_to_empty t
						  LEFT JOIN dba_constraints uk ON t.table_name = uk.table_name AND uk.owner = UPPER(schemas(i))
						  LEFT JOIN dba_constraints fk ON uk.constraint_name = fk.r_constraint_name AND fk.owner = UPPER(schemas(i))
						  LEFT JOIN TABLE(v_nulled_constraints) nc ON fk.constraint_name = nc.column_value
					  )
					  START WITH fk_table_name IS NULL
					  CONNECT BY NOCYCLE PRIOR table_name = fk_table_name
				  )
				 GROUP BY table_name
			  )
			ORDER BY lvl ASC)
		LOOP
			-- dbms_output.put_line('DELETE FROM ' || schemas(i) || '.' || rec.table_name || ' WHERE APP_SID = ' || v_app_sid || '; --' || rec.lvl);
			EXECUTE IMMEDIATE('DELETE FROM ' || schemas(i) || '.' || rec.table_name || ' WHERE APP_SID = ' || v_app_sid);
		END LOOP;
	
		commit;
	end loop;
end;
/
exit;
/
