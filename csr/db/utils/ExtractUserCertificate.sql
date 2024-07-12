declare
v_i number(10);
v_s number(10);
v_id number(10);
v_t raw(64);
begin
v_id := &1;
for r in (
select sid_id, dbms_lob.getlength(cert) cert_length, cert, rownum rn

from security.user_certificates
where sid_id = v_id
order by cert_hash
)
loop
v_i := 1;
v_s := 64;
dbms_output.put_line('Cert #' || r.rn);
loop
select dbms_lob.substr(r.cert, v_s, v_i) into v_t
from dual;
dbms_output.put_line(v_t);
exit when v_i + v_s >= r.cert_length;
v_i := v_i + v_s;
end loop;
end loop;
end;
/
