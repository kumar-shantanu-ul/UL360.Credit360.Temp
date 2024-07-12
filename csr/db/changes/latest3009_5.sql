-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.issue_scheduled_task add raised_by_user_sid number(10);
update csr.issue_scheduled_task set raised_by_user_sid = 3;
alter table csr.issue_scheduled_task modify raised_by_user_sid not null;
create index csr.ix_iss_sched_task_raised_user on csr.issue_scheduled_task (app_sid, raised_by_user_sid);
alter table csr.issue_scheduled_task add constraint fk_iss_sched_task_raised_user
foreign key (app_sid, raised_by_user_sid) references csr.csr_user (app_sid, csr_user_sid);

alter table csrimp.issue_scheduled_task add raised_by_user_sid number(10);
update csrimp.issue_scheduled_task set raised_by_user_sid = 3;
alter table csrimp.issue_scheduled_task modify raised_by_user_sid not null;

create table csr.issue_raise_alert (
	app_sid							number(10) default sys_context('SECURITY', 'APP') not null,
	issue_id						number(10) not null,
	raised_by_user_sid				number(10) not null,
	issue_comment					varchar2(4000),
	constraint pk_issue_raise_alert primary key (app_sid, issue_id)
);

alter table csr.issue_raise_alert add constraint fk_issue_raise_alert_issue
foreign key (app_sid, issue_id) references csr.issue (app_sid, issue_id);
alter table csr.issue_raise_alert add constraint fk_issue_raise_alert_raise_by
foreign key (app_sid, raised_by_user_sid) references csr.csr_user (app_sid, csr_user_sid);
create index csr.issue_raise_alert_raised_by on csr.issue_raise_alert (app_sid, raised_by_user_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- c:\cvs\csr\db\create_views.sql
create or replace view csr.v$scrag_usage as
select c.app_sid, c.host, case when msr.scenario_run_sid is null then 'val' when ms.file_based = 1 then 'scrag++' else 'scenario_run_val' end merged,
	   case when usr.scenario_run_sid is null then 'on the fly' when us.file_based = 1 then 'scrag++' else 'scenario_run_val' end unmerged,
	   nvl(spp_scenarios, 0) other_spp_scenarios, nvl(scenarios, 0) - nvl(spp_scenarios, 0) other_old_scenarios
  from csr.customer c
  left join csr.scenario_run msr on c.app_sid = msr.app_sid and c.merged_scenario_run_sid = msr.scenario_run_sid
  left join csr.scenario ms on ms.app_sid = msr.app_sid and ms.scenario_sid = msr.scenario_sid
  left join csr.scenario_run usr on c.app_sid = usr.app_sid and c.unmerged_scenario_run_sid = usr.scenario_run_sid
  left join csr.scenario us on us.app_sid = usr.app_sid and us.scenario_sid = usr.scenario_sid
  left join (select s.app_sid, sum(s.file_based) spp_scenarios, count(*) scenarios
			   from csr.scenario s
			  where (s.app_sid, s.scenario_sid) not in (
					select s.app_sid, s.scenario_sid
					  from csr.customer c
					  join csr.scenario_run sr on c.app_sid = sr.app_sid and c.merged_scenario_run_sid = sr.scenario_run_sid
					  join csr.scenario s on sr.app_sid = s.app_sid and sr.scenario_sid = s.scenario_sid
					 union all
					select s.app_sid, s.scenario_sid
					  from csr.customer c
					  join csr.scenario_run sr on c.app_sid = sr.app_sid and c.unmerged_scenario_run_sid = sr.scenario_run_sid
					  join csr.scenario s on sr.app_sid = s.app_sid and sr.scenario_sid = s.scenario_sid)
			  group by s.app_sid) o on c.app_sid = o.app_sid;

-- *** Data changes ***
-- RLS

-- Data
begin
	-- missing from some sites
	INSERT INTO csr.issue_type (app_sid, issue_type_id, label)
		SELECT app_sid, 20 /*csr_data_pkg.ISSUE_METER*/, 'Meter'
		  FROM (SELECT app_sid
				  FROM csr.customer_region_type
				 WHERE region_type = 1
				 MINUS
				SELECT app_sid
				  FROM csr.issue_type
				 WHERE issue_type_id = 20);

	-- fix up plugins
	update csr.plugin set cs_class='Credit360.Chain.Plugins.IssuesPanel' where js_class='Chain.ManageCompany.IssuesPanel';
	update csr.plugin set cs_class='Credit360.Metering.Plugins.IssuesTab' where js_class='Credit360.Metering.IssuesTab';
	update csr.plugin set cs_class='Credit360.Teamroom.IssuesPanel' where js_class='Teamroom.IssuesPanel';
	update csr.plugin set cs_class='Credit360.Initiatives.IssuesPanel' where js_class='Credit360.Initiatives.IssuesPanel';
	update csr.plugin set cs_class='Credit360.Property.Plugins.IssuesPanel' where js_class='Controls.IssuesPanel';
	commit;
end;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../audit_body
@../teamroom_pkg
@../teamroom_body
@../issue_pkg
@../issue_body
@../schema_body
@../initiative_pkg
@../initiative_body
@../property_pkg
@../property_body
@../meter_pkg
@../meter_body
@../meter_monitor_pkg
@../meter_monitor_body
@../quick_survey_pkg
@../quick_survey_body
@../supplier_pkg
@../supplier_body
@../enhesa_body
@../csrimp/imp_body

@update_tail
