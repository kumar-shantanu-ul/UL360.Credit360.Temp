-- Please update version.sql too -- this keeps clean builds in sync
define version=642
@update_header

declare
	v_cnt		number(10) := 0;
	v_new_name	tag_group.name%TYPE;
begin
	-- disambiguate tag group names
	for r in (
		select tag_group_id, tg.app_sid, tg.name, row_number() over (partition by tg.app_sid, upper(tg.name) order by tag_group_id) rn, c.host
		  from csr.tag_group tg
			join csr.customer c on tg.app_sid = c.app_sid
	)
	loop
		if r.rn > 1 then
			v_new_name := r.name ||' ('||r.rn||')';
			dbms_output.put_line(r.host||' - changing "'||r.name||'" to "'||v_new_name||'"');
			update csr.tag_group set name = v_new_name where tag_group_id = r.tag_group_id and app_sid = r.app_sid;
			v_cnt := v_cnt + 1;
		end if;
	end loop;
	dbms_output.put_line(v_cnt||' tag group names disambiguated');
end;
/

CREATE UNIQUE INDEX csr.UK_TAG_GROUP_NAME ON csr.TAG_GROUP(APP_SID, UPPER(NAME));

@update_tail
