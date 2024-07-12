declare
	type t_ind_map is table of number(10) index by binary_integer;
	v_ind_map	t_ind_map;
	v_xml 		varchar2(32767);
	v_new_xml 	varchar2(32767);
	v_num 		varchar2(32767);
	v_pos 		binary_integer;
	v_last_pos 	binary_integer;
	v_sid		number(10);
	v_new_sid	number(10);
begin
	for r in (select extract(calc_xml,'/').getclobval() calc, ind_Sid from csr.v$ind where dbms_lob.instr(extract(calc_xml,'/').getclobval(),'<script>')>0) loop
		v_xml := r.calc;
		v_new_xml := '';
		v_last_pos := 1;
		v_pos := 1;
		loop
			v_pos := regexp_instr(v_xml, '\d+', v_pos);
			if v_pos = 0 then
				exit;
			end if;
			--dbms_output.put_line('pos = ' ||v_pos);
			v_new_xml := v_new_xml || substr(v_xml, v_last_pos, v_pos - v_last_pos);
			--dbms_output.put_line('copy = ' ||v_last_pos || ' to ' || v_pos);
			v_num := regexp_substr(v_xml, '\d+', v_pos);
			--dbms_output.put_line('num = ' ||v_num);
			v_pos := v_pos + length(v_num);
			v_last_pos := v_pos;
			
			if length(v_num) <= 10 then -- <10bn
				v_sid := to_number(v_num);
				if v_sid >= 100000 then
					if v_ind_map.exists(v_sid) then
						v_num := v_ind_map(v_sid);
					else
						select min(new_sid)
						  into v_new_sid
						  from csrimp.map_sid
						 where old_sid = v_sid;
						if v_new_sid is not null then
							v_ind_map(v_sid) := v_new_sid;
							v_num := to_char(v_new_sid);
						end if;
					end if;
					--dbms_output.put_line('mapped '||v_sid||' to '||v_num);
				end if;
			end if;
			v_new_xml := v_new_xml || v_num;
		end loop;
		v_new_xml := v_new_xml || substr(v_xml, v_last_pos, 1 + length(v_xml) - v_last_pos);
		--dbms_output.put_line(v_new_xml);
		--exit;
		if v_new_xml != v_xml then
			update csr.ind
			   set calc_xml = v_new_xml
			 where ind_sid = r.ind_sid;
		end if;
	end loop;
end;
/
