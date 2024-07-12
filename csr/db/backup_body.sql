CREATE OR REPLACE PACKAGE BODY csr.backup_pkg AS

TYPE t_ddl IS TABLE OF CLOB;
TYPE t_tables IS TABLE OF VARCHAR2(30) INDEX BY VARCHAR2(61);
TYPE t_flat_tables IS TABLE OF BOOLEAN INDEX BY VARCHAR2(61);
TYPE t_constraints IS TABLE OF BOOLEAN INDEX BY VARCHAR2(61);
	
m_trace 							BOOLEAN DEFAULT FALSE;
m_trace_only 						BOOLEAN DEFAULT FALSE;
m_flat_tables 						t_flat_tables;
m_tables 							t_tables;
m_existing_tables					t_tables;
m_backup_name						VARCHAR2(30);
m_root_owner						VARCHAR2(30);
m_ddl								t_ddl;

FUNCTION q( 
	s 							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
    RETURN '"'||s||'"';
END;

FUNCTION dq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
	v_r		VARCHAR2(30);
BEGIN
	IF SUBSTR(s, 1, 1) = '"' THEN
		IF SUBSTR(s, -1, 1) <> '"' THEN
			RAISE_APPLICATION_ERROR(-20001, 'Missing quote in identifier '||s);
		END IF;
		v_r := SUBSTR(s, 2, LENGTH(s) - 2);
		IF INSTR(v_r, '"') <> 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Embedded quote in quoted identifier '||s);
		END IF;
		RETURN v_r;
	END IF;
	RETURN UPPER(s);
END;

FUNCTION sq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
    RETURN ''''||REPLACE(s,'''','''''')||'''';
END;

PROCEDURE GetUniqueTableName(
	in_owner						IN	VARCHAR2,
	in_table_name					IN	VARCHAR2,
	out_table_name					OUT	VARCHAR2,
	out_exists						OUT	BOOLEAN
)
IS
	v_full_name						VARCHAR2(61);
	v_name							VARCHAR2(30);
	v_num_name						VARCHAR2(30);
	v_i								NUMBER;
	v_num_suffix					VARCHAR2(30);
BEGIN
	v_full_name := in_owner||'.'||in_table_name;
	IF m_tables.EXISTS(v_full_name) THEN
		out_exists := TRUE;
		out_table_name := m_tables(v_full_name);
		RETURN;
	END IF;
	
	-- try to keep the name of the table if it was in the same schema as the root table
	IF m_root_owner = in_owner AND NOT m_flat_tables.EXISTS(in_table_name) THEN
		m_flat_tables(in_table_name) := TRUE;
		m_tables(v_full_name) := in_table_name;		
		out_exists := FALSE;
		out_table_name := in_table_name;
		RETURN;
	END IF;
	
	-- try schema_table
	v_name := SUBSTR(in_owner, 1, 15) || '_';
	v_name := v_name || SUBSTR(in_table_name, 1, 30 - LENGTH(v_name));
	v_num_name := v_name;

	-- use _2, _3, etc		
	v_i := 2;
	WHILE m_flat_tables.EXISTS(v_num_name) LOOP
		v_num_suffix := '_' || TO_CHAR(v_i);
		v_num_name := SUBSTR(v_name, 1, 30 - LENGTH(v_num_suffix)) || v_num_suffix;
		v_i := v_i + 1;
	END LOOP;
	
	m_tables(v_full_name) := v_num_name;
	m_flat_tables(v_num_name) := TRUE;
	out_exists := FALSE;
	out_table_name := v_num_name;
END;

PROCEDURE EnableTrace
AS
BEGIN
	m_trace := TRUE;
END;

PROCEDURE DisableTrace
AS
BEGIN
	m_trace := FALSE;
END;

PROCEDURE EnableTraceOnly
AS
BEGIN
	m_trace := TRUE;
	m_trace_only := TRUE;
END;

PROCEDURE DisableTraceOnly
AS
BEGIN
	m_trace := FALSE;
	m_trace_only := FALSE;
END;

PROCEDURE TraceClob(
	in_sql			CLOB
)
AS
	v_sql			DBMS_SQL.VARCHAR2S;
	v_chunk			VARCHAR2(32767);
	v_upperbound	NUMBER;
	v_cur			INTEGER;
	v_ret			NUMBER;
BEGIN
	v_upperbound := ceil(dbms_lob.getlength(in_sql) / 32767);
	FOR i IN 1..v_upperbound
	LOOP
		v_chunk := dbms_lob.substr(in_sql, 32767, ((i - 1) * 32767) + 1);
		dbms_output.put(v_chunk);
	END LOOP;
	dbms_output.put_line('');
	IF SUBSTR(v_chunk, -1) = ';' THEN
		dbms_output.put_line('/');
	ELSE
		dbms_output.put_line(';');
	END IF;
END;

PROCEDURE ExecuteClob(
	in_sql							IN	CLOB
)
AS
	v_sql							DBMS_SQL.VARCHAR2S;
	v_upperbound					NUMBER;
	v_cur							INTEGER;
	v_ret							NUMBER;
BEGIN
	-- Split the SQL statement into chunks of 256 characters (one varchar2s entry)
	v_upperbound := ceil(dbms_lob.getlength(in_sql) / 256);
	FOR i IN 1..v_upperbound
	LOOP
		-- TODO: this is screwed with UTF8, i.e. creates the wrong size chunk
		v_sql(i) := dbms_lob.substr(in_sql, 256, ((i - 1) * 256) + 1);	
	END LOOP;
	
	-- Now parse and execute the SQL statement
	v_cur := dbms_sql.open_cursor;
	dbms_sql.parse(v_cur, v_sql, 1, v_upperbound, false, dbms_sql.native);
	v_ret := dbms_sql.execute(v_cur);
	dbms_sql.close_cursor(v_cur);
END;

PROCEDURE ExecuteDDL
AS
BEGIN
	IF m_ddl.count = 0 THEN
		RETURN;
	END IF;
	FOR i in m_ddl.first .. m_ddl.last LOOP
		IF m_trace THEN
			TraceClob(m_ddl(i));
		END IF;
		IF NOT m_trace_only THEN
			ExecuteClob(m_ddl(i));
		END IF;
	END LOOP;
END;

PROCEDURE WriteAppend(
	in_clob						IN OUT NOCOPY	CLOB,
	in_str						IN				VARCHAR2
)
AS
BEGIN
	dbms_lob.writeappend(in_clob, LENGTH(in_str), in_str);
END;

PROCEDURE Backup_(
	in_owner						IN	VARCHAR2,
	in_table_name					IN	VARCHAR2,
	in_where						IN	VARCHAR2 DEFAULT NULL,
	in_constraint_name				IN	VARCHAR2 DEFAULT NULL,
	in_parent_table_name			IN	VARCHAR2 DEFAULT NULL,
	in_parent_owner					IN	VARCHAR2 DEFAULT NULL,
	in_parent_constraint_name		IN	VARCHAR2 DEFAULT NULL,
	in_parent_view					IN	CLOB DEFAULT NULL,
	in_followed_constraints			IN	t_constraints -- since this can't be constructed, and can't be null, it can't have a default value.  Poo.
)
AS
	v_sql							CLOB;
	v_first							BOOLEAN;
	v_to_table_name					VARCHAR2(30);
	v_exists						BOOLEAN;
	v_full_child_cons_name 			VARCHAR2(61);
	v_parent_view					CLOB;
	v_first_cons					BOOLEAN;
	v_cols							CLOB;
	v_followed_constraints			t_constraints := in_followed_constraints;
BEGIN
	GetUniqueTableName(in_owner, in_table_name, v_to_table_name, v_exists);
	--dbms_output.put_line(in_owner||'.'	||in_table_name||'  to ' ||v_to_table_name|| CASE WHEN v_exists THEN ' exists ' else ' not exists' end);
	IF v_exists THEN
		v_sql := 'INSERT INTO '||q(m_backup_name)||'.'||q(v_to_table_name)||' ';
	ELSE
		v_sql := 'CREATE TABLE '||q(m_backup_name)||'.'||q(v_to_table_name)||' AS ';
	END IF;
	
	v_parent_view := 'SELECT * FROM '||q(in_owner)||'.'||q(in_table_name);

	IF in_parent_constraint_name IS NOT NULL THEN
		-- self join, so do a connect by
		IF in_parent_table_name = in_table_name THEN
			WriteAppend(v_parent_view, ' START WITH (');
		ELSE
			WriteAppend(v_parent_view, ' WHERE (');
		END IF;
			
		v_first := TRUE;
		FOR s IN (SELECT column_name
					FROM all_cons_columns
				   WHERE owner = in_owner
				     AND constraint_name = in_constraint_name
				   ORDER BY position) LOOP			
			IF NOT v_first THEN
				WriteAppend(v_parent_view, ', ');
			END IF;		   	
			v_first := FALSE;
			WriteAppend(v_parent_view, q(s.column_name));
		END LOOP;
		
		WriteAppend(v_parent_view, ') IN (SELECT ');
			
		v_first := TRUE;
		FOR s IN (SELECT column_name
					FROM all_cons_columns
				   WHERE owner = in_parent_owner
				     AND constraint_name = in_parent_constraint_name
				   ORDER BY position) LOOP
			IF NOT v_first THEN
				WriteAppend(v_parent_view, ', ');
			END IF;		   	
			v_first := FALSE;
			WriteAppend(v_parent_view, q(s.column_name));
		END LOOP;
		WriteAppend(v_parent_view, ' FROM (');
		dbms_lob.append(v_parent_view, in_parent_view);
		WriteAppend(v_parent_view, ')');
		
		IF in_parent_table_name = in_table_name THEN
			WriteAppend(v_parent_view, ') CONNECT BY ');
			v_first := TRUE;
			FOR s IN (SELECT acp.column_name parent_column_name, acc.column_name child_column_name
						FROM all_cons_columns acc, all_cons_columns acp
					   WHERE acp.owner = in_parent_owner 
					     AND acp.constraint_name = in_parent_constraint_name
					     AND acc.owner = in_owner
					     AND acc.constraint_name = in_constraint_name
					     AND acc.position = acp.position
					   ORDER BY acc.position) LOOP
				IF NOT v_first THEN
					WriteAppend(v_parent_view, ' AND ');
				END IF;
				v_first := FALSE;
				WriteAppend(v_parent_view, ' PRIOR '||q(s.parent_column_name)||' = '||q(s.child_column_name));
			END LOOP;
		END IF;
		
		IF in_where IS NOT NULL THEN
			WriteAppend(v_parent_view, ' AND (');
			WriteAppend(v_parent_view, in_where);
			WriteAppend(v_parent_view, ')');
		END IF;
		
		IF in_parent_table_name != in_table_name THEN
			WriteAppend(v_parent_view, ')');			
		END IF;			
	ELSIF in_where IS NOT NULL THEN
		WriteAppend(v_parent_view, ' WHERE (');
		WriteAppend(v_parent_view, in_where);
		WriteAppend(v_parent_view, ')');
	END IF;

	v_first_cons := TRUE;
	IF v_exists THEN
		FOR r IN (SELECT constraint_name
					FROM all_constraints
				   WHERE constraint_type IN ('U', 'P')
				     AND owner = in_owner
				     AND table_name = in_table_name) LOOP
			IF v_first_cons THEN
				WriteAppend(v_sql, 'SELECT * FROM (');
				dbms_lob.append(v_sql, v_parent_view);
				WriteAppend(v_sql, ') WHERE ');
			ELSE
				WriteAppend(v_sql, ' AND ');
			END IF;
			v_first_cons := FALSE;
			WriteAppend(v_sql, '(');
			
			v_cols := NULL;
			v_first := TRUE;
			FOR s IN (SELECT column_name
						FROM all_cons_columns
					   WHERE owner = in_owner
					     AND constraint_name = r.constraint_name) LOOP
				IF NOT v_first THEN
					WriteAppend(v_cols, ',');
				END IF;
				v_first := FALSE;
				IF v_cols IS NOT NULL THEN
					WriteAppend(v_cols, q(s.column_name));
				ELSE
					v_cols := q(s.column_name); -- Oracle oddity with empty_clob() or null: you can assign, but not append
				END IF;
			END LOOP;
			dbms_lob.append(v_sql, v_cols);
			WriteAppend(v_sql, ') NOT IN (SELECT ');
			dbms_lob.append(v_sql, v_cols);
			WriteAppend(v_sql, ' FROM '||q(m_backup_name)||'.'||q(v_to_table_name)||')');			
		END LOOP;
	END IF;		
	IF v_first_cons THEN
		dbms_lob.append(v_sql, v_parent_view);
	END IF;
	
	m_ddl.extend(1);
	m_ddl(m_ddl.count) := v_sql;
	IF NOT v_exists AND NOT m_existing_tables.EXISTS(in_owner||'.'||in_table_name) THEN
		m_ddl.extend(1);
		m_ddl(m_ddl.count) := 
		'BEGIN'||CHR(10)||
		'    INSERT INTO '||q(m_backup_name)||'."BACKUP_TABLE_MAP" ("TABLE_NAME", "MAP_TO_TABLE_NAME")'||CHR(10)||
		'    VALUES ('||sq(in_owner||'.'||in_table_name)||', '||sq(v_to_table_name)||');'||CHR(10)||
		'    COMMIT;'||CHR(10)||
		'END;';
	END IF;

	-- do all child tables
	FOR r IN (SELECT acp.owner parent_owner, acp.constraint_name parent_constraint_name,
					 acc.owner child_owner, acc.constraint_name child_constraint_name,
					 acc.table_name child_table_name
				FROM all_constraints acp, all_constraints acc
			   WHERE acp.owner = in_owner AND acp.table_name = in_table_name
			     AND acp.constraint_type IN ('U', 'P')
			     AND acc.r_owner = acp.owner
			     AND acc.r_constraint_name = acp.constraint_name
			     AND acc.constraint_type = 'R') LOOP

		v_full_child_cons_name := r.child_owner || '.' || r.child_table_name;
		--dbms_output.put_line('following ' ||r.parent_owner||'.'||in_table_name||'.'||r.parent_constraint_name||' to '||r.child_owner||'.'||r.child_table_name||'.'||r.child_constraint_name||
		--	(CASE WHEN v_followed_constraints.EXISTS(v_full_child_cons_name) THEN ' - no' ELSE ' - yes' END));
		IF NOT v_followed_constraints.EXISTS(v_full_child_cons_name) THEN
			v_followed_constraints(v_full_child_cons_name) := TRUE;
			Backup_(r.child_owner, r.child_table_name, NULL, r.child_constraint_name, in_table_name, r.parent_owner, r.parent_constraint_name, v_parent_view,
				v_followed_constraints);
		END IF;
	END LOOP;	
END;

PROCEDURE Backup(
	in_backup_name					IN	VARCHAR2,
	in_owner						IN	VARCHAR2,
	in_table_name					IN	VARCHAR2,
	in_where						IN	VARCHAR2
)
AS
	v_constraints					t_constraints;
	v_cnt	 						NUMBER;
	v_cur							SYS_REFCURSOR;
	v_table_name					VARCHAR2(30);
	v_map_to_table_name				VARCHAR2(61);
	v_owner							VARCHAR2(30);
BEGIN
	v_owner := dq(in_owner);
	m_root_owner := v_owner;
	m_flat_tables.delete;
	m_tables.delete;
	m_existing_tables.delete;
	m_backup_name := dq(in_backup_name);
	m_ddl := t_ddl();
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_users
	 WHERE username = m_backup_name;
	IF v_cnt != 0 THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM all_tables
		 WHERE table_name = 'BACKUP_TABLE_MAP';
		IF v_cnt = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The user '||in_backup_name||' already exists, but does not possess the mapping table BACKUP_TABLE_MAP');
		END IF;
		
		EXECUTE IMMEDIATE 
			'BEGIN'||CHR(10)||
				'OPEN :1 FOR'||CHR(10)||
					'SELECT table_name, map_to_table_name'||CHR(10)||
					  'FROM '||q(m_backup_name)||'."BACKUP_TABLE_MAP";'||CHR(10)||
			'END;'
		USING v_cur;
			   
		LOOP
			FETCH v_cur INTO v_table_name, v_map_to_table_name;
			EXIT WHEN v_cur%NOTFOUND;
			m_flat_tables(v_map_to_table_name) := TRUE;
			m_tables(v_table_name) := v_map_to_table_name;
			m_existing_tables(v_table_name) := v_map_to_table_name;
			dbms_output.put_line('put ' ||v_map_to_table_name||' to '||v_table_name||' into stuff');
		END LOOP;
	ELSE
		m_ddl.extend(1);
		m_ddl(m_ddl.count) := 'CREATE USER '||q(m_backup_name)||' IDENTIFIED EXTERNALLY QUOTA UNLIMITED ON USERS';
		m_ddl.extend(1);
		m_ddl(m_ddl.count) := 
			'CREATE TABLE '||q(m_backup_name)||'.BACKUP_TABLE_MAP ('||CHR(10)||
				'TABLE_NAME         VARCHAR2(30),'||CHR(10)||
				'MAP_TO_TABLE_NAMe  VARCHAR2(61)'||CHR(10)||
			')';		
	END IF;

	Backup_(
		in_owner 				=> v_owner,
		in_table_name 			=> dq(in_table_name), 
		in_where				=> in_where,
		in_followed_constraints	=> v_constraints
	);

m_trace:=TRUE;
	ExecuteDDL;
END;

END backup_pkg;
/
