declare
    v_host  customer.host%TYPE := '&&1';
    v_s     VARCHAR2(255);
begin
	for r in (
		select i.rowid rid, 
			i.description, m.description measure_description,
		    case 
				when m.custom_field = 'x' then 'SUM' -- DO aggregate checkboxes
				when m.custom_field = '|' then 'NONE' -- don't aggregate text
				when length(m.custom_field) > 1 then 'NONE' -- don't aggregate lists
				when LOWER(m.description) like '%pct%' OR
					LOWER(m.description) like '%percent%' OR
					REPLACE(m.description,'%',CHR(0)) like '%'||chr(0)||'%'
					then 'NONE' -- don't aggregate percentages
				else 'SUM' -- DO aggregate everything else
			end new_aggregate,
			aggregate,
			case 
				when m.custom_field is not null then csr_data_pkg.DIVISIBILITY_LAST_PERIOD
				when LOWER(m.description) like '%pct%' OR
					LOWER(m.description) like '%percent%' OR
					REPLACE(m.description,'%',CHR(0)) like '%'||chr(0)||'%'
					then csr_data_pkg.DIVISIBILITY_AVERAGE
				when LOWER(m.description) like '%employee%' OR
					LOWER(m.description) like '%people%' OR
					LOWER(m.description) like 'fte%' OR
					LOWER(m.description) like '%participants%' OR -- bit mcondalds specific
					LOWER(m.description) like 'crew%'  -- bit mcondalds specific
					then csr_data_pkg.DIVISIBILITY_AVERAGE
				else csr_data_pkg.DIVISIBILITY_DIVISIBLE
			end new_divisible,
			divisible
		  from ind i, customer c, measure m
		 where i.app_sid = c.app_sid
		   and host = v_host
		   and i.measure_sid = m.measure_sid
	)
	loop
		if r.new_aggregate != r.aggregate or r.new_divisible != r.divisible then
			DBMS_OUTPUT.PUT_LINE('Setting '||r.description||' ('||r.measure_description||')');
			DBMS_OUTPUT.PUT_LINE('    aggregate = '||r.new_aggregate);
			SELECT DECODE(r.new_divisible,2,'LAST_PERIOD',1,'DIVISIBLE',0,'AVERAGE','?') INTO v_s FROM DUAL;
			DBMS_OUTPUT.PUT_LINE('    divisible = '||v_s);
			update ind 
				set aggregate = r.new_aggregate,
					divisible = r.new_divisible 
			  where rowid =r.rid;
		end if;
	end loop;
end;
/
