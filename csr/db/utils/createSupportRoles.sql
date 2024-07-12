begin
begin
execute immediate 'create role first_line_support';
exception
when others then
if sqlcode <> -01921 then
raise;
end if;
end;
execute immediate '
grant
create session,
select any table,
select any dictionary
to first_line_support
';
end;
/
