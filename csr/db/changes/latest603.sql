-- Please update version.sql too -- this keeps clean builds in sync
define version=603
@update_header

create or replace procedure csr.tryInsertParam(
	in_alert_type_id				in	alert_type_param.alert_type_id%type,
	in_repeats						in	alert_type_param.repeats%type,
	in_field_name					in	alert_type_param.field_name%type,
	in_description					in	alert_type_param.description%type,
	in_help_text					in	alert_type_param.help_text%type,
	in_display_pos					in	alert_type_param.display_pos%type
)
as
	v_display_pos					number;
begin
	select min(display_pos)
	  into v_display_pos
	  from alert_type_param
	 where alert_type_id = in_alert_type_id
	   and field_name = in_field_name;
	   
	if v_display_pos is not null then
		-- delete the old row and shuffle pos
		delete from alert_type_param
		 where alert_type_id = in_alert_type_id
		   and field_name = in_field_name;
		update alert_type_param
		   set display_pos = display_pos - 1
		 where display_pos > v_display_pos;
	end if;
	
	-- make a gap
	update alert_type_param
	   set display_pos = display_pos + 1
	 where alert_type_id = in_alert_type_id
	   and display_pos >= in_display_pos;

	-- stuff the new row in
	insert into alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	values (in_alert_type_id, in_repeats, in_field_name, in_description, in_help_text, in_display_pos);
end;
/

begin
	csr.tryInsertParam(1, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(2, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(3, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(4, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
	csr.tryInsertParam(5, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(7, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(9, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(10, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 10);
	csr.tryInsertParam(11, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(12, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(13, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(14, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(15, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(16, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(17, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(18, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(19, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(20, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	csr.tryInsertParam(21, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(22, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 4);
	csr.tryInsertParam(23, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(24, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(25, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(26, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
	csr.tryInsertParam(27, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	csr.tryInsertParam(28, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
end;
/

drop procedure csr.tryInsertParam;

@update_tail
