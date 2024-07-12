update region 
   set link_to_region_sid = null 
 where region_sid in (
    select region_sid 
      from (
        select region_sid,lpad(' ', (level-1)*2)||description description, connect_by_iscycle cycle 
          from region
         start with parent_sid in (
            select region_tree_root_sid 
              from region_tree 
             where app_sid = (
                select app_sid
                  from customer
                 where host='&&host'
            )
         )
   connect by nocycle prior region_pkg.ParseLink(region_sid) = parent_sid
      ) 
    where cycle = 1
);