-- sqlplus system/manager@aspen @traceUserData m.credit360.com casey@maersk.com
SET SERVEROUTPUT ON;


CREATE GLOBAL TEMPORARY TABLE chain.temp_user_finder_table (
	owner 			varchar2(30),
	table_name 		varchar2(30),
	column_name		varchar2(30),
	user_sid		number(10)
) ON COMMIT DELETE ROWS;


PROMPT >> Enter a site name to grep
EXEC user_pkg.logonadmin('&&1');

declare
	v_user_email	csr.csr_user.email%TYPE DEFAULT '&&2';
	t_users			security.T_SO_TABLE DEFAULT securableobject_pkg.GetChildrenAsTable(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Users'));
	v_user_list		varchar2(1000) default '';
	v_union			varchar2(20) default '';
	v_char			varchar2(2) default '';
	l_user_sids		varchar2(100) default '';
	v_select		CLOB default '';
	v_insert		CLOB default '';
	v_line			varchar2(500) default '';
	v_found_entry	BOOLEAN DEFAULT FALSE;
	v_len			NUMBER(10);
-- from tab_pkg
	v_sql			DBMS_SQL.VARCHAR2S;
	v_upperbound	NUMBER;
	v_cur			INTEGER;
	v_ret			NUMBER;
begin
  
	FOR r IN (SELECT csru.* FROM TABLE(t_users) u, csr.csr_user csru WHERE csru.csr_user_sid = u.sid_id AND LOWER(csru.email) = LOWER(v_user_email))
	LOOP
		v_user_list := v_user_list || RPAD(r.csr_user_sid, 8) || ' -> '||r.user_name||CHR(10);
		l_user_sids := l_user_sids || v_char || r.csr_user_sid;
		v_char := ', ';
	END LOOP;

	IF l_user_sids IS NULL THEN
		dbms_output.put_line('No users found with the email address '||v_user_email);
	ELSE  
		
		FOR R IN (
			SELECT acc.owner, acc.table_name, acc.column_name
			  FROM all_cons_columns acc, (
					SELECT level lvl,  ac.* 
					  FROM all_constraints ac 
				   CONNECT BY PRIOR constraint_name = r_constraint_name 
					 START WITH table_name = 'CHAIN_USER') ctree 
			 WHERE ctree.constraint_type = 'R' 
			   AND (ctree.owner = 'MAERSK' or ctree.owner = 'CHAIN') -- Add schema names here to see more results
			   AND ctree.owner = acc.owner
			   AND ctree.constraint_name = acc.constraint_name
			   AND acc.column_name NOT IN ('APP_SID', 'DEFAULT_COMPANY_SID') -- removes any columns names that we're not interested in
		) LOOP
			v_select := v_select || v_union || 'SELECT '''||r.owner||''' owner, '''||r.table_name||''' table_name, '''||r.column_name||''' column_name, '||r.column_name||' user_sid FROM '||r.owner||'.'||r.table_name||' WHERE '||r.column_name||' IN ('||l_user_sids||')'||CHR(10);
			v_union := ' UNION '||CHR(10);
		
		END LOOP;
		
		
		IF v_select IS NULL THEN
			dbms_output.put_line('No tables found');
		ELSE
			dbms_output.put(CHR(10)||CHR(10)||CHR(10));
			dbms_output.put_line(v_select);
			dbms_output.put(CHR(10)||CHR(10)||CHR(10));
		
			DELETE FROM chain.temp_user_finder_table;
			v_insert := 'INSERT INTO chain.temp_user_finder_table (owner, table_name, column_name, user_sid) '||v_select;
			
			-- Split the SQL statement into chunks of 256 characters (one varchar2s entry)
			v_upperbound := ceil(dbms_lob.getlength(v_insert) / 256);
			FOR i IN 1..v_upperbound
			LOOP
				v_sql(i) := dbms_lob.substr(v_insert, 256, ((i - 1) * 256) + 1);
			END LOOP;

			-- Now parse and execute the SQL statement
			v_cur := dbms_sql.open_cursor;
			dbms_sql.parse(v_cur, v_sql, 1, v_upperbound, false, dbms_sql.native);
			v_ret := dbms_sql.execute(v_cur);
			dbms_sql.close_cursor(v_cur);
			
			
			dbms_output.put_line('Users found (user_sdid -> user_name):');  
			dbms_output.put(CHR(10));
			dbms_output.put_line(v_user_list);
			
			dbms_output.put_line('References found in:');  
			dbms_output.put(CHR(10));
			FOR s IN (SELECT * FROM chain.temp_user_finder_table)
			LOOP
				v_found_entry := TRUE;
				v_line := s.owner||'.'||s.table_name||'.'||s.column_name;
				v_len := 45; -- the default padding val
				IF LENGTH(v_line) > v_len THEN -- don't allow rpad to trim data
					v_len := LENGTH(v_line);
				END IF;
				dbms_output.put_line(RPAD(v_line, v_len)||' = '||s.user_sid);
			END LOOP;
			
			IF NOT v_found_entry THEN
				dbms_output.put_line('No references found to users with email address '||v_user_email);
			END IF;
			
			dbms_output.put(CHR(10)||CHR(10)||CHR(10));
			dbms_output.put(CHR(10)||CHR(10)||CHR(10));
		END IF;	
	END IF;
END;
/

commit;
DROP TABLE chain.temp_user_finder_table;

exit
