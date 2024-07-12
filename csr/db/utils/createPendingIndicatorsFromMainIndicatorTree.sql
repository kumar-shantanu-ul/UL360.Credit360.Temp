PROMPT WARNING: This script was written to do a very specific copy. It probably won't work as you want it to. Consider it a starting point.

UNDEF host
UNDEF pending_dataset_id
UNDEF ind_sid

PROMPT Populates the pending_ind table with values taken from ind.
PROMPT You will be asked for:
PROMPT host: e.g. mcdonalds.credit360.com
PROMPT pending_dataset_id: The pending dataset to copy the indicators to. e.g. 11370387
PROMPT ind_sid: The indicator to copy (child indicators are copied as well) e.g. 11399237

set serveroutput on

begin

user_pkg.LogonAdmin('&&host');

for r in (
select
i.aggregate aggregate,
0 allow_file_upload, 
sys_context('SECURITY', 'APP') app_sid, 
null default_val_number, 
null default_val_string, 
i.description description,
null dp, 
case when i.measure_sid is null then 2 when m.custom_field is not null then 8 else 4 end element_type, 
0 file_upload_mandatory, 
null format_xml, 
null info_xml, 
null link_to_ind_id, 
null lookup_key, 
i.ind_sid maps_to_ind_sid,
i.measure_sid measure_sid,
0 note_mandatory, 
null parent_ind_id,
i.pct_lower_tolerance pct_lower_tolerance, 
i.pct_upper_tolerance pct_upper_tolerance, 
&&pending_dataset_id pending_dataset_id,
pending_ind_id_seq.nextval pending_ind_id, 
0 pos, 
0 read_only, 
i.tolerance_type tolerance_type, 
0 val_mandatory,
i.ind_sid ind_sid,
i.parent_sid parent_ind_sid
from ind i
left join measure m on i.measure_sid = m.measure_sid and i.app_sid = m.app_sid
start with i.ind_sid = &&ind_sid
connect by i.parent_sid = prior i.ind_sid and i.app_sid = prior i.app_sid
)
loop

insert into pending_ind (aggregate, allow_file_upload, app_sid, default_val_number, default_val_string, description, dp, element_type, file_upload_mandatory, format_xml, info_xml,
link_to_ind_id, lookup_key, maps_to_ind_sid, measure_sid, note_mandatory, parent_ind_id, pct_lower_tolerance, pct_upper_tolerance, pending_dataset_id, pending_ind_id, pos,
read_only, tolerance_type, val_mandatory)
values
(
r.aggregate,
r.allow_file_upload, 
r.app_sid, 
r.default_val_number, 
r.default_val_string, 
r.description,
r.dp, 
r.element_type, 
r.file_upload_mandatory, 
r.format_xml, 
r.info_xml, 
r.link_to_ind_id, 
r.lookup_key, 
r.maps_to_ind_sid,
r.measure_sid,
r.note_mandatory, 
case when r.ind_sid = &&ind_sid then null else (select pending_ind_id from pending_ind where pending_dataset_id = &&pending_dataset_id and maps_to_ind_sid = r.parent_ind_sid) end,
r.pct_lower_tolerance, 
r.pct_upper_tolerance, 
r.pending_dataset_id,
r.pending_ind_id, 
r.pos, 
r.read_only, 
r.tolerance_type, 
r.val_mandatory
);

end loop;

end;
/

select pending_ind_id
from pending_ind
start with maps_to_ind_sid = &&ind_sid and pending_dataset_id = &&pending_dataset_id
connect by parent_ind_id = prior pending_ind_id and app_sid = prior app_sid;

PROMPT Done. Issue commit or rollback.
