-- Please update version.sql too -- this keeps clean builds in sync
define version=368
@update_header

-- add missing region tag data for existing templated reports
insert into tpl_report_tag_dv_region (app_sid, tpl_report_sid, tag, dataview_sid, region_sid, tpl_region_type_id)
    select app_sid, tpl_report_sid, tag, dataview_sid, region_sid, 1 tpl_region_type_id
      from (select dv.app_sid, dv.tpl_report_sid, dv.tag, dv.dataview_sid, rrm.region_sid
              from tpl_report_tag_dataview dv, range_region_member rrm
             where dv.dataview_sid = rrm.range_sid
             minus
            select app_sid, tpl_report_sid, tag, dataview_sid, region_sid
              from tpl_report_tag_dv_region);

@update_tail
