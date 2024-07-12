PROMPT please enter: host

declare
	v_xml							varchar2(4000);
	v_path							varchar2(4000);
begin
	dbms_output.enable(NULL);
	security.user_pkg.logonadmin('&&1');

	for r in (select i.*
	  			from csr.ind i
	  		   where i.ind_sid in (select master_ind_sid
	  		   						 from csr.ind_selection_group)) loop
		v_xml := null;
		for s in (select ind_sid 
					from csr.ind_selection_group_member isg
				   where master_ind_sid = r.ind_sid
				   order by pos) loop
				   	
			v_path := '<path sid="' || s.ind_sid || '" />';
			if v_xml is null then
				v_xml := v_path;
			else
				v_xml := '<add><left>' || v_xml || '</left><right>' || v_path || '</right></add>';
			end if;
		end loop;
		
		dbms_output.put_line('set calc for '||r.ind_sid||' ('||r.description||') to '||v_xml);
		csr.calc_pkg.SetCalcXMLAndDeps(
			SYS_CONTEXT('SECURITY', 'ACT'),
			r.ind_sid,
			sys.xmltype.createXML(v_xml),
			0,
			r.default_interval,
			0,
			NULL
		);
		
		if r.factor_type_id is not null then
			csr.indicator_pkg.CreateGasIndicators(r.ind_sid);
		end if;
	end loop;
end;
/
