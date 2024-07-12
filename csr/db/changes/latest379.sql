-- Please update version.sql too -- this keeps clean builds in sync
define version=379
@update_header

declare
  v_nullable varchar2(1);
begin
  select nullable into v_nullable
  from user_tab_columns
  where table_name = 'MODEL'
  and column_name = 'EXCEL_DOC';

  if v_nullable = 'N' then
    execute immediate 'alter table csr.model modify (excel_doc null)';
  end if;

  select nullable into v_nullable
  from user_tab_columns
  where table_name = 'MODEL'
  and column_name = 'FILENAME';

  if v_nullable = 'N' then
    execute immediate 'alter table csr.model modify (filename null)';
  end if;
end;
/

@update_tail
