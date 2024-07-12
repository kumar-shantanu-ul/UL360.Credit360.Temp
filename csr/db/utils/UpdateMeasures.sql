-- Currently only supports batch update of scale and format mask; update variables and "description not in('%')" predicate as necessary.
declare
v_new_scale number(10) := 2;
v_new_format_mask varchar2(255) := '#,##0.##';
v_dtm date := sysdate;
v_audit_msg varchar(1024);
begin
for r in (
select measure_sid, name, description, scale, format_mask, custom_field, std_measure_conversion_id, pct_ownership_applies, divisibility, option_set_id, lookup_key
from csr.measure
where custom_field is null
and description not in ('%')
)
loop
dbms_output.put_line('Processing ' || r.description || ' (' || r.measure_sid || ')');
csr.measure_pkg.AmendMeasure(security_pkg.GetACT, r.measure_sid, r.name, r.description, nvl(v_new_scale, r.scale), nvl(v_new_format_mask, r.format_mask), r.custom_field, r.std_measure_conversion_id, r.pct_ownership_applies, r.divisibility, r.option_set_id, r.lookup_key);
begin
select description into v_audit_msg
from csr.audit_log
where object_sid = r.measure_sid and audit_date >= v_dtm and rownum = 1;
exception
when no_data_found then
v_audit_msg := null;
end;
if v_audit_msg is null then
dbms_output.put_line('No changes made.');
else
dbms_output.put_line(v_audit_msg);
end if;
end loop;
end;
/
PROMPT Now commit or rollback.
 