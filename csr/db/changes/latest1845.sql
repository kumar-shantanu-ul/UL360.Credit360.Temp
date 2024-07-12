-- Please update version.sql too -- this keeps clean builds in sync
define version=1845
@update_header

begin 
    for r in (
        select constraint_name, search_condition, owner, table_name
          from all_constraints 
         where table_name = 'TAB_COLUMN_ROLE_PERMISSION' and owner='CMS' and constraint_type = 'C'
    ) 
    loop 
        if r.search_condition like 'permission in (0, 1, 2)%' then 
            EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
        end if; 
    end loop; 
end;
/

-- make space for the new permission
UPDATE cms.tab_column_role_permission 
   SET permission = permission + 1
 WHERE permission > 0;

ALTER TABLE CMS.TAB_COLUMN_ROLE_PERMISSION ADD (
    POLICY_FUNCTION VARCHAR2(100),
    CONSTRAINT CHK_TCRP_POLICY_FN CHECK (permission = 1 AND policy_function IS NOT NULL OR permission IN (0,2,3))
);

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail