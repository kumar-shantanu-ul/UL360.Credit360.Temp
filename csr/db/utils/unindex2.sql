select a.create_sql 
from 
( select a.table_name, a.constraint_name, 
	     max(decode(position, 1,     column_name,NULL)) || 
	     max(decode(position, 2,', '||column_name,NULL)) || 
	     max(decode(position, 3,', '||column_name,NULL)) || 
	     max(decode(position, 4,', '||column_name,NULL)) || 
	     max(decode(position, 5,', '||column_name,NULL)) || 
	     max(decode(position, 6,', '||column_name,NULL)) || 
	     max(decode(position, 7,', '||column_name,NULL)) || 
	     max(decode(position, 8,', '||column_name,NULL)) || 
	     max(decode(position, 9,', '||column_name,NULL)) || 
	     max(decode(position,10,', '||column_name,NULL)) || 
	     max(decode(position,11,', '||column_name,NULL)) || 
	     max(decode(position,12,', '||column_name,NULL)) || 
	     max(decode(position,13,', '||column_name,NULL)) || 
	     max(decode(position,14,', '||column_name,NULL)) || 
	     max(decode(position,15,', '||column_name,NULL)) || 
	     max(decode(position,16,', '||column_name,NULL)) columns,
	     'create index ix_**** on '||a.table_name||'('||
	     max(decode(position, 1,     column_name,NULL)) || 
	     max(decode(position, 2,', '||column_name,NULL)) || 
	     max(decode(position, 3,', '||column_name,NULL)) || 
	     max(decode(position, 4,', '||column_name,NULL)) || 
	     max(decode(position, 5,', '||column_name,NULL)) || 
	     max(decode(position, 6,', '||column_name,NULL)) || 
	     max(decode(position, 7,', '||column_name,NULL)) || 
	     max(decode(position, 8,', '||column_name,NULL)) || 
	     max(decode(position, 9,', '||column_name,NULL)) || 
	     max(decode(position,10,', '||column_name,NULL)) || 
	     max(decode(position,11,', '||column_name,NULL)) || 
	     max(decode(position,12,', '||column_name,NULL)) || 
	     max(decode(position,13,', '||column_name,NULL)) || 
	     max(decode(position,14,', '||column_name,NULL)) || 
	     max(decode(position,15,', '||column_name,NULL)) || 
	     max(decode(position,16,', '||column_name,NULL)) ||') tablespace indx;' create_sql	     
    from user_cons_columns a, user_constraints b
   where a.constraint_name = b.constraint_name
     and b.constraint_type = 'R'
   group by a.table_name, a.constraint_name ) a, 
( select table_name, index_name, 
	     max(decode(column_position, 1,     column_name,NULL)) || 
	     max(decode(column_position, 2,', '||column_name,NULL)) || 
	     max(decode(column_position, 3,', '||column_name,NULL)) || 
	     max(decode(column_position, 4,', '||column_name,NULL)) || 
	     max(decode(column_position, 5,', '||column_name,NULL)) || 
	     max(decode(column_position, 6,', '||column_name,NULL)) || 
	     max(decode(column_position, 7,', '||column_name,NULL)) || 
	     max(decode(column_position, 8,', '||column_name,NULL)) || 
	     max(decode(column_position, 9,', '||column_name,NULL)) || 
	     max(decode(column_position,10,', '||column_name,NULL)) || 
	     max(decode(column_position,11,', '||column_name,NULL)) || 
	     max(decode(column_position,12,', '||column_name,NULL)) || 
	     max(decode(column_position,13,', '||column_name,NULL)) || 
	     max(decode(column_position,14,', '||column_name,NULL)) || 
	     max(decode(column_position,15,', '||column_name,NULL)) || 
	     max(decode(column_position,16,', '||column_name,NULL)) columns
    from user_ind_columns 
   group by table_name, index_name ) b
where a.table_name = b.table_name (+)
  and b.columns (+) like a.columns || '%'
  and b.table_name is null
/
