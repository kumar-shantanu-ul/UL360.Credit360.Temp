define host='&&1'
begin
	security.user_pkg.logonadmin('&&host');
	for rc in (select host from csr.customer where use_carbon_emission = 1) loop
		dbms_output.put_line('doing '||rc.host);
		security.user_pkg.logonadmin(rc.host);
		for r in (select ind_sid, description 
					from csr.v$ind 
				   where parent_sid = security.securableobject_pkg.getsidfrompath(sys_context('security','act'), sys_context('security','app'), 'Trash') and gas_type_id is not null
				   order by ind_sid desc) loop
			dbms_output.put_line('deleting trashed ind '||r.description||' ('||r.ind_sid||')');
			security.securableobject_pkg.deleteso(sys_context('security','act'), r.ind_sid);
		end loop;
		for r in (select * 
		  			from (select parent_sid,ind_sid,map_to_ind_sid,gas_type_id,description,calc_xml,to_number(extract(calc_xml,'//gasfactor/@sid').getstringval()) gf_sid,
		  						 to_number(extract(calc_xml,'//path/@sid').getstringval()) base_sid, extract(calc_xml, '//gasfactor/@gasType').getstringval() gas_type,
		  						 case extract(calc_xml, '//gasfactor/@gasType').getstringval()
		  						 when 'CO2' then 1 when 'CO2e' then 2 when 'CH4' then 3 when 'N2O' then 4 else -2 end gf_gas_type
				    		from csr.v$ind 
				   		   where dbms_lob.instr(extract(calc_xml,'/').getclobval(), '<gasfactor') > 0)
				   where gf_gas_type != -2 and (base_sid != parent_sid /*or ind_sid != nvl(gf_sid,-1)*/ or nvl(gas_type_id,-1)!=gf_gas_type							
				   	  or nvl(map_to_ind_sid,-1) != base_sid)) loop
			dbms_output.put_line('ind '||r.description||' ('||r.ind_sid||') has messed up properties:');
			if r.base_sid != r.parent_sid then
				dbms_output.put_line('  it is calculating for '||r.base_sid||' but the parent is '||r.parent_sid);
				-- this hasn't happened so no fix code
				raise_application_error(-20001,'I can''t fix '||r.ind_sid);
			end if;
			if nvl(r.gas_type_id,-1)!=r.gf_gas_type and r.gf_gas_type != -2 then
				dbms_output.put_line('  the gas type is '||r.gas_type_id||' but the embedded gas type is '||r.gf_gas_type);
				update csr.ind set gas_type_id = r.gf_gas_type where ind_sid = r.ind_sid;
			end if;
			if nvl(r.map_to_ind_sid,-1)!=r.base_sid then
				dbms_output.put_line('  the base sid is '||r.base_sid||' but the map_to_ind_sid is '||r.map_to_ind_sid);
				update csr.ind set map_to_ind_sid = r.base_sid where ind_sid = r.ind_sid;
			end if;
			/*if r.ind_sid != nvl(r.gf_sid,-1) then
				dbms_output.put_line('  the gasfactor sid is '||r.gf_sid||' but should be '||r.ind_sid||' (now ignored)');
			end if;*/
			insert into csr.val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
				select DISTINCT c.app_sid, r.ind_sid, c.calc_start_dtm, c.calc_end_dtm
				  from customer c;
		end loop;
	end loop;
end;
/