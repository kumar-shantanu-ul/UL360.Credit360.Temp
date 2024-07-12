-- Please update version.sql too -- this keeps clean builds in sync
define version=258
@update_header

PROMPT Enter connection string (e.g. aspen)
connect aspen2/aspen2@&&1
grant select, references on translated to csr;

connect csr/csr@&&1

-- can we do a schema so that we enforce one start point minimum per user? 
alter table ind_owner rename to ind_start_point;
alter table ind_start_point drop column inherited;

delete from ind_start_point;

insert into ind_start_point (ind_sid, user_sid, app_sid) 
    select indicator_mount_point_sid, csr_user_sid, app_sid
      from csr_user 
     where indicator_mount_point_sid is not null;

-- fill in missing bits if any
INSERT INTO IND_START_POINT (user_sid, ind_sid, app_sid)
    SELECT csr_user_sid, ind_root_sid, c.app_sid
      FROM customer c, csr_user cu
     WHERE cu.app_sid = c.app_sid
       AND csr_user_sid NOT IN (
        SELECT DISTINCT user_sid FROM IND_START_POINT
     );

alter table csr_user drop column indicator_mount_point_sid;



@update_tail
