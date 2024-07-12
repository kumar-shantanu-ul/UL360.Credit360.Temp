-- Please update version.sql too -- this keeps clean builds in sync
define version=2174
@update_header


create or replace function get_constraintname_text( p_cons_name in varchar2 ) 
return varchar2
  authid current_user
   is
       l_search_condition all_constraints.search_condition%type;
   begin
       select search_condition into l_search_condition
          from all_constraints
         where constraint_name = p_cons_name;
  
       return l_search_condition;
   end;
   /

begin
for r in (
  select constraint_name, table_name, owner from (
  SELECT constraint_name, table_name, get_constraintname_text(constraint_name), owner
    FROM all_constraints
   WHERE table_name LIKE UPPER('TPL_REPORT_TAG_EVAL')
     AND owner LIKE UPPER('CSR')
     AND constraint_name like 'SYS_%'
     AND (get_constraintname_text(constraint_name) like '"IF_TRUE" IS NOT NULL' OR get_constraintname_text(constraint_name) like '"IF_FALSE" IS NOT NULL')
  )
)
loop
  execute immediate ('ALTER TABLE CSR.TPL_REPORT_TAG_EVAL DROP CONSTRAINT ' || r.constraint_name);
end loop;


for r in (
  select constraint_name, table_name, owner from (
  SELECT constraint_name, table_name, get_constraintname_text(constraint_name), owner
    FROM all_constraints
   WHERE table_name LIKE UPPER('TPL_REPORT_TAG_EVAL')
     AND owner LIKE UPPER('CSRIMP')
     AND constraint_name like 'SYS_%'
     AND (get_constraintname_text(constraint_name) like '"IF_TRUE" IS NOT NULL' OR get_constraintname_text(constraint_name) like '"IF_FALSE" IS NOT NULL')
  )
)
loop
  execute immediate ('ALTER TABLE CSRIMP.TPL_REPORT_TAG_EVAL DROP CONSTRAINT ' || r.constraint_name);
end loop;

end;
/
 
ALTER TABLE CSR.TPL_REPORT_TAG_EVAL ADD(
	CONSTRAINT CHK_TPL_REP_TAG_EVA_TFSET
	CHECK ((IF_TRUE IS NOT NULL) OR (IF_FALSE IS NOT NULL)) enable);

ALTER TABLE CSRIMP.TPL_REPORT_TAG_EVAL ADD(
	CONSTRAINT CHK_TPL_REP_TAG_EVA_TFSET
	CHECK ((IF_TRUE IS NOT NULL) OR (IF_FALSE IS NOT NULL)) enable);
	
drop function get_constraintname_text;

@update_tail