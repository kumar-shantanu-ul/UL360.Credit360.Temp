PROMPT Enter host
exec user_pkg.logonadmin('&&1');

PROMPT Enter folder path (e.g. Dataviews) -- this will process descendants too
declare
	v_folder varchar2(255) := '&&2';
begin
    for r in (
        select dataview_sid,
            case 
                when add_months(start_dtm, 12) = end_dtm then add_months(start_dtm, 12)
                else start_dtm
            end start_dtm,
            case 
                when end_dtm > sysdate and end_dtm > add_months(start_dtm,12) then end_dtm
                else add_months(end_dtm, 12) 
            end end_dtm
          from dataview
         where parent_sid in (
            select sid_id
              from security.securable_object
             start with sid_id = securableobject_pkg.getsidfrompath(security_pkg.getact, security_pkg.getapp, v_folder)
            CONNECT by prior sid_id =parent_Sid_id
         )
    )
    loop
        update dataview
           set start_dtm = r.start_dtm, end_dtm = r.end_dtm
         where dataview_sid = r.dataview_sid;
    end loop;
end;
/
