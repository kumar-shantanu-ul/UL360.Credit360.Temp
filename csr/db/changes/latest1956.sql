-- Please update version.sql too -- this keeps clean builds in sync
define version=1956
@update_header


alter table chem.cas add (category varchar2(20));

BEGIN
    for r in (
        select distinct category, cas_code from chem.cas_restricted
    )
    LOOP
        update chem.cas set category = r.category where cas_code = r.cas_code; 
    END LOOP;
END;
/

alter table chem.cas_restricted drop column category;

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail