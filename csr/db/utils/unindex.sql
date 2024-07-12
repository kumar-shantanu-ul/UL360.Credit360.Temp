column columns format a20 word_wrapped
column table_name format a30 word_wrapped

select 
'create index '||lower(a.owner)||'.ix_'||substr(lower(a.table_name), 1, 13)||'_'||substr(replace(replace(lower(a.columns),', ','_'), 'app_sid_', ''), 1, 13)||' on '||lower(a.owner)||'.'||lower(a.table_name)||' ('||lower(a.columns)||');'
--'alter table '||lower(a.owner)||'.'||lower(a.table_name)||' disable constraint '||a.constraint_name||';'
from 
( select a.owner, a.table_name, a.constraint_name,
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
	     max(decode(position,16,', '||column_name,NULL)) columns
    from all_cons_columns a, all_constraints b
   where a.owner = b.owner
     and a.constraint_name = b.constraint_name
     and b.constraint_type = 'R'
     and b.status = 'ENABLED'
  	 and b.r_owner in ('CSR','CHAIN','SUPPLIER','ACTIONS','DONATIONS','ASPEN2','CMS','MAIL', 'SURVEYS')
   group by a.owner, a.table_name, a.constraint_name ) a, 
( select table_owner owner, table_name, index_name, 
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
    from all_ind_columns 
   group by table_owner, table_name, index_name ) b
where a.owner = b.owner (+)
  and a.table_name = b.table_name (+)
  and b.columns (+) like a.columns || '%'
  and b.table_name is null
--  and a.r_owner in ('CSR','CHAIN','SUPPLIER','ACTIONS','DONATIONS','ASPEN2','CMS','MAIL')
  order by a.owner, a.table_name
/
