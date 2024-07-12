-- Please update version.sql too -- this keeps clean builds in sync
define version=1314
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

alter table csrimp.home_page drop primary key drop index;
alter table csrimp.home_page drop column app_sid;
alter table csrimp.home_page add constraint pk_home_page primary key (sid_id);

grant insert,select,update,delete on csrimp.sheet_value_var_expl to web_user;

update csr.imp_session set owner_sid=3 where (app_sid, owner_sid) not in (
	select app_sid, csr_user_sid
	  from csr.csr_user);
alter table csr.imp_session add constraint fk_imp_session_csr_user foreign key (app_sid, owner_sid) references csr.csr_user(app_sid, csr_user_sid);

declare
	v_vc number := 0;
	v_mc number := 0;
begin
	for r in (
	  select distinct app_sid, imp_measure_id, imp_ind_id
		from csr.imp_val 
	   where (app_sid, imp_measure_id, imp_ind_id) not in (
	   			select app_sid, imp_measure_id, imp_ind_id 
	   			  from csr.imp_measure)
		 and imp_measure_id is not null) loop
		 
		insert into csr.imp_measure (imp_measure_id, description, maps_to_measure_conversion_id, maps_to_measure_sid, imp_ind_id, app_sid)
			select csr.imp_measure_id_seq.nextval, im.description||'_'||csr.imp_measure_id_seq.currval, 
				   im.maps_to_measure_conversion_id, im.maps_to_measure_sid, r.imp_ind_id, r.app_sid
			  from csr.imp_measure im
			 where im.app_sid = r.app_sid and im.imp_measure_id = r.imp_measure_id;
		v_mc := v_mc + sql%rowcount;
		
		update csr.imp_val
		   set imp_measure_id = csr.imp_measure_id_seq.currval
		 where app_sid = r.app_sid and imp_measure_id = r.imp_measure_id and imp_ind_id = r.imp_ind_id;
		v_vc := v_vc + sql%rowcount;
	end loop;
	-- security.security_pkg.debugmsg('created '||v_mc||' measures, updated '||v_vc||' vals');
end;
/

alter table csr.imp_measure drop primary key cascade drop index;
alter table csr.imp_measure add constraint pk_imp_measure primary key (app_sid, imp_measure_id);
alter table csr.imp_measure add constraint uk_imp_measure_measure_ind unique (app_sid, imp_measure_id, imp_ind_id);
alter table csr.imp_val add constraint fk_imp_val_imp_measure foreign key
(app_sid, imp_measure_id, imp_ind_id) references csr.imp_measure (app_sid, imp_measure_id, imp_ind_id);

@../csrimp/imp_body

@update_tail
