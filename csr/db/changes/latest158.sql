-- Please update version.sql too -- this keeps clean builds in sync
define version=158
@update_header

alter table customer add
(
	region_root_sid		number(10),
	ind_root_sid		number(10)
);

set serveroutput on
declare
	v_act_id			security_pkg.t_act_id;
	v_region_root_sid	security_pkg.t_sid_id;
	v_ind_root_sid		security_pkg.t_sid_id;
begin
	user_pkg.logonauthenticated(security_pkg.sid_builtin_administrator, 86400, v_act_id);
	for r in (select * from customer) loop
		dbms_output.put_line('updating '||r.host);
		if r.host = 'SuperAdmins' then
			securableobject_pkg.createso(v_act_id, r.csr_root_sid, security_pkg.so_container, 'Regions', v_region_root_sid);
			securableobject_pkg.createso(v_act_id, r.csr_root_sid, security_pkg.so_container, 'Indicators', v_ind_root_sid);
			INSERT INTO REGION (region_sid, parent_sid, csr_root_sid, name, description, active, pos, info_xml, link_to_region_sid)
				VALUES (v_region_root_sid, r.csr_root_sid, r.csr_root_sid, 'regions', 'Regions', 1, 1, null, null);
			INSERT INTO IND (ind_sid, parent_sid, name, description, csr_root_sid)
				VALUES (v_ind_root_sid, r.csr_root_sid, 'indicators', 'Indicators', r.csr_root_sid);			
			update customer
			   set region_root_sid = v_region_root_sid,
			       ind_root_sid = v_ind_root_sid
			 where csr_root_sid = r.csr_root_sid;
		else
			update customer
			   set region_root_sid = securableobject_pkg.getsidfrompath(null, 0, '//aspen/applications/'||host||'/csr/regions'),
			       ind_root_sid = securableobject_pkg.getsidfrompath(null, 0, '//aspen/applications/'||host||'/csr/indicators')
			 where csr_root_sid = r.csr_root_sid;
		end if;
	end loop;
end;
/

alter table customer modify region_root_sid not null;
alter table customer modify ind_root_sid not null;
alter table customer add constraint fk_cust_reg_root_region
foreign key (region_root_sid) references region(region_sid) deferrable initially deferred;
alter table customer add constraint fk_cust_ind_root_ind
foreign key (ind_root_sid) references ind(ind_sid) deferrable initially deferred;

	  
@update_tail
