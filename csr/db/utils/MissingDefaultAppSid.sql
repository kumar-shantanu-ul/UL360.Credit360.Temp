create or replace function  getlong( p_tname in varchar2,
                                       p_cname in varchar2,
                                       p_table in varchar2,
                                       p_column in varchar2) return varchar2
as
	l_cursor    integer default dbms_sql.open_cursor;
	l_n         number;
	l_long_val  varchar2(4000);
	l_long_len  number;
	l_buflen    number := 4000;
	l_curpos    number := 0;
begin
	dbms_sql.parse( l_cursor,
		'select ' || p_cname || ' from ' || p_tname ||
		' where table_name = :x and column_name = :y',
		dbms_sql.native );
	dbms_sql.bind_variable( l_cursor, ':x', p_table );
	dbms_sql.bind_variable( l_cursor, ':y', p_column );

	dbms_sql.define_column_long(l_cursor, 1);
	l_n := dbms_sql.execute(l_cursor);

	if (dbms_sql.fetch_rows(l_cursor)>0)
	then
		dbms_sql.column_value_long(l_cursor, 1, l_buflen, l_curpos ,
		l_long_val, l_long_len );
	end if;
	dbms_sql.close_cursor(l_cursor);
	return l_long_val;
end getlong;
/

select table_name,data_default from user_tab_columns where column_name='APP_SID' and (data_default is null or replace(upper(getlong('USER_TAB_COLUMNS','DATA_DEFAULT',table_name,column_name)),' ','') != 'SYS_CONTEXT(''SECURITY'',''APP'')')
and table_name not in (select view_name from user_views);

drop function getlong;
