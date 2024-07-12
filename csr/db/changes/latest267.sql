-- Please update version.sql too -- this keeps clean builds in sync
define version=267
@update_header

-- fully link region tree
begin
    for c in (
        select app_sid, region_root_sid
          from customer) loop
        for r in (
            select lvl, parent_sid_id, sid_id, name from (
                select level lvl, so.parent_sid_id, so.sid_id, so.name, r.region_sid from security.securable_object so, region r
                 where so.sid_id = r.region_sid(+)
                       start with sid_id=c.region_root_sid connect by prior nvl(r.link_to_region_sid, so.sid_id) = so.parent_sid_id) 
             where region_sid is null) loop
            insert into region (region_sid, parent_sid, name, description, active, pos, link_to_region_sid, region_type, app_sid)
                select r.sid_id, r.parent_sid_id, r.name, r.name, 1, count(*) + 1, null, 2, c.app_sid
                  from region 
                 where parent_sid = r.parent_sid_id;
        end loop;
    end loop;
end;
/

@update_tail

