define old_feedback=&&feedback
define feedback=0
set feedback &&feedback

variable model_sid number
variable model_instance_sid number
exec :model_sid := &1
exec :model_instance_sid := &1

declare
	v_count number;
begin
	select count(*) into v_count
	  from model
	 where model_sid = :model_sid;

	if v_count = 0 then
		select base_model_sid into :model_sid
		  from model_instance
		 where model_instance_sid = :model_sid;
	else
		:model_instance_sid := null;
	end if;
end;
/

select :model_sid model_sid from dual;

@@print ''
@@print '************************************************************************************************************************************************'
@@print '************************************************************************************************************************************************'
@@print '************************************************************************************************************************************************'

@@print ''
@@print 'model'
select name, description, file_name, created_dtm, dbms_lob.getlength(thumb_img) thumbnail_length, dbms_lob.getlength(excel_doc) doc_length from model where model_sid = :model_sid;

@@print ''
@@print 'model_sheet'
select sheet_id, sheet_index, sheet_name, user_editable_boo, display_charts_boo, case when structure is null then 0 else 1 end has_structure from model_sheet where model_sid = :model_sid order by sheet_id;

@@print ''
@@print 'model_map'
select sheet_id, cell_name, (select map_type from model_map_type where model_map_type_id = model_map.model_map_type_id) model_map_type, map_to_indicator_sid, region_type_offset, region_offset_tag_id, period_offset, period_year_offset from model_map where model_sid = :model_sid order by sheet_id, cell_name;

@@print ''
@@print 'model_range'
select sheet_id, range_id,
(select stragg(cell_name) from model_range_cell where app_sid = model_range.app_sid and model_sid = model_range.model_sid and range_id = model_range.range_id) cells,
(select region_repeat_id from model_region_range where app_sid = model_range.app_sid and model_sid = model_range.model_sid and range_id = model_range.range_id) repeat
from model_range
where model_sid = :model_sid order by sheet_id, range_id;

@@print ''
@@print 'model_validation'
select sheet_id, cell_name, stragg(validation_text) validation_text
from model_validation
where model_sid = :model_sid
group by sheet_id, cell_name
order by sheet_id, cell_name;

@@print ''
@@print 'model_instance'
select model_instance_sid, description, start_dtm, end_dtm, dbms_lob.getlength(excel_doc) doc_length, (select stragg(description) from region where region_sid in (select region_sid from model_instance_region where model_instance_sid = model_instance.model_instance_sid)) regions from model_instance where base_model_sid = :model_sid and nvl(:model_instance_sid, model_instance_sid) = model_instance_sid order by created_dtm;

@@print ''
@@print 'model_instance_sheet'
select model_instance_sid, sheet_id, case when structure is null then 0 else 1 end has_structure from model_instance_sheet where base_model_sid = :model_sid and nvl(:model_instance_sid, model_instance_sid) = model_instance_sid order by model_instance_sid, sheet_id;

@@print ''
@@print 'model_instance_map'
select model_instance_sid, sheet_id, cell_name, source_cell_name, map_to_indicator_sid, map_to_region_sid, substr(cell_value, 0, 30) cell_value, period_year_offset, period_offset from model_instance_map where base_model_sid = :model_sid and nvl(:model_instance_sid, model_instance_sid) = model_instance_sid order by model_instance_sid, sheet_id, cell_name;

@@print ''
@@print 'model_instance_chart'
select model_instance_sid, sheet_id, chart_index, top, left, width, height, source_data from model_instance_chart where base_model_sid = :model_sid and nvl(:model_instance_sid, model_instance_sid) = model_instance_sid order by model_instance_sid, sheet_id, chart_index;

define feedback=&&old_feedback
set feedback &&feedback