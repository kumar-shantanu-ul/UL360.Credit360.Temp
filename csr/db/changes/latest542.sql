-- Please update version.sql too -- this keeps clean builds in sync
define version=542
@update_header

begin
	insert into default_alert_frame_body
	select default_alert_frame_id, wanted_lang.lang lang, (select html from csr.default_alert_frame_body where default_alert_frame_id = default_alert_frame.default_alert_frame_id and lang = 'en-gb') html from default_alert_frame, (select 'en' lang from dual union select 'en-us' lang from dual) wanted_lang;
exception
	when dup_val_on_index then
		null;
end;
/

@update_tail
