exec user_pkg.logonadmin('spm.credit360.com');
-- relies on all tpl reports having been deleted
CREATE table xx_hei_report_tag_eval_cond as select * from tpl_report_tag_eval_cond as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');
CREATE table xx_hei_report_tag_eval as select * from tpl_report_tag_eval as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');
CREATE table xx_hei_report_tag_dv_region as select * from tpl_report_tag_dv_region as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');
CREATE table xx_hei_report_tag_dataview as select * from tpl_report_tag_dataview as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');
CREATE table xx_hei_report_Tag_logging_form as select * from tpl_report_Tag_logging_form as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');
CREATE table xx_hei_report_tag_ind as select * from tpl_report_tag_ind as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');
CREATE table xx_hei_report_tag_text as select * from tpl_report_tag_text as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');
CREATE table xx_hei_REPORT_TAG as select * from TPL_REPORT_TAG as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');
CREATE table xx_hei_REPORT as select * from TPL_REPORT as of timestamp to_date('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi');

insert into TPL_REPORT select * from xx_hei_REPORT;
insert into TPL_REPORT_TAG select * from xx_hei_REPORT_TAG;
insert into tpl_report_tag_text select * from xx_hei_report_tag_text;
insert into tpl_report_tag_ind select * from xx_hei_report_tag_ind;
insert into tpl_report_Tag_logging_form select * from xx_hei_report_Tag_logging_form;
insert into tpl_report_tag_dataview select * from xx_hei_report_tag_dataview;
insert into tpl_report_tag_dv_region select * from xx_hei_report_tag_dv_region;
insert into tpl_report_tag_eval select * from xx_hei_report_tag_eval;
insert into tpl_report_tag_eval_cond select * from xx_hei_report_tag_eval_cond;



-- securable objects
create  table xx_hei_so as 
	select * from security.securable_object as of timestamp to_timestamp('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi')
	 where sid_id in (select tpl_report_sid from xx_hei_report);

create  table xx_hei_acl as
	select * 
	  from security.acl as of timestamp to_timestamp('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi')
	 where acl_id in (select dacl_id from xx_hei_so)
	 union
	select * 
	  from security.acl as of timestamp to_timestamp('28 Jan 2014 11:45', 'dd mon yyyy hh24:mi')
	 where sid_id in (select sid_id from xx_hei_so)
	 ;
	    


insert into security.securable_object
	select * from xx_hei_so;
	
insert into security.acl
	select * from xx_hei_acl where acl_id not in (select acl_id from security.acl);


