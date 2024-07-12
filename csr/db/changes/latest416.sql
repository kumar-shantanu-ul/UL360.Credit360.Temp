-- Please update version.sql too -- this keeps clean builds in sync
define version=416
@update_header

create table old_stored_calc_job as
		 SELECT /*+ALL_ROWS*/ DISTINCT cirj.app_sid, cirj.calc_ind_sid,
				v.region_sid, v.period_start_dtm, v.period_end_dtm, i.start_month, i.default_interval, i.calc_start_dtm_adjustment,
            	MAX(cirj.lev) max_lev, c.aggregation_engine_version
		   FROM stored_calc_job cirj, val_change v, ind i, customer c
		  WHERE cirj.app_sid = v.app_sid AND cirj.trigger_val_change_id = v.val_change_id
            AND cirj.app_sid = i.app_sid AND cirj.calc_ind_sid = i.ind_sid
		    AND c.app_sid = cirj.app_sid
       GROUP BY cirj.app_sid, cirj.calc_ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm, i.start_month, i.default_interval, i.calc_start_dtm_adjustment, 
       	 		c.aggregation_engine_version
       ORDER BY cirj.app_sid, max_lev, calc_ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm;

drop table stored_calc_job;

create table calc_job_lock
(
	app_sid		number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	dummy		number(1) default 0 not null,
	constraint pk_calc_job_lock primary key (app_sid)
	using index tablespace indx
);

alter table calc_job_lock add constraint fk_calc_job_lock_customer
foreign key (app_sid) references customer(app_sid);

create table stored_calc_job
(
	app_sid		number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	ind_sid		number(10) not null,
	region_sid	number(10) not null,
	start_dtm	date not null,
	end_dtm		date not null,
	processing	number(1) default 0 not null,
	constraint pk_stored_calc_job primary key (app_sid, ind_sid, region_sid, processing)
	using index tablespace indx
);

alter table stored_calc_job add constraint fk_stored_calc_job_ind 
foreign key (app_sid, ind_sid) references ind (app_sid, ind_sid);

alter table stored_calc_job add constraint fk_stored_calc_job_region
foreign key (app_sid, region_sid) references region (app_sid, region_sid);

create index idx_scj_app_ind on stored_calc_job (app_sid, ind_sid);
create index idx_scj_app_region on stored_calc_job (app_sid, region_sid);

alter table stored_calc_job add constraint ck_stored_calc_job_processing check (processing in (0,1));
alter table stored_calc_job add constraint ck_stored_calc_job_dates check (end_dtm > start_dtm);

insert into calc_job_lock (app_sid)
	select app_sid from customer;

insert into stored_calc_job (app_sid, ind_sid, region_sid, start_dtm, end_dtm)
	select app_sid, calc_ind_sid, region_sid, min(period_start_dtm), max(period_end_dtm)
	  from old_stored_calc_job
	 group by app_sid, calc_ind_sid, region_sid;

drop table old_stored_calc_job;

@..\calc_pkg
@..\calc_body
@..\indicator_body
@..\region_body
@..\rag_body
@..\csr_data_body
@..\system_status_body
@..\val_body

@update_tail
