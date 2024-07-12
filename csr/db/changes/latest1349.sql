-- Please update version.sql too -- this keeps clean builds in sync
define version=1349
@update_header

--Fixes mismatch on column between live and create_schema.sql
begin
  UPDATE csr.pending_ind SET pct_upper_tolerance = 1 WHERE pct_upper_tolerance is null;
end;
/

begin
 for r in (select 1 from all_tab_columns where owner='CSR' and table_name='PENDING_IND' and column_name='PCT_UPPER_TOLERANCE' and nullable='Y') LOOP 
    execute immediate 'ALTER TABLE csr.pending_ind MODIFY pct_upper_tolerance default 1 not null'; 
 end loop; 
end;
/

@update_tail
