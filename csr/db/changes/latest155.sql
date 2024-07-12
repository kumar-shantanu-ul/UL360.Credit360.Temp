-- Please update version.sql too -- this keeps clean builds in sync
define version=155
@update_header

alter table section add (checked_out_version_number number(10));

ALTER TABLE SECTION ADD CONSTRAINT RefSECTION_VERSION20 
    FOREIGN KEY (SECTION_SID, CHECKED_OUT_VERSION_NUMBER)
    REFERENCES SECTION_VERSION(SECTION_SID, VERSION_NUMBER)
;

@..\text\section_body

UPDATE section SET visible_version_number = NVL(section_pkg.GetLatestCheckedInVersion(section_sid),1);

ALTER TABLE SECTION ADD CONSTRAINT RefSECTION_VERSION21 
    FOREIGN KEY (SECTION_SID, VISIBLE_VERSION_NUMBER)
    REFERENCES SECTION_VERSION(SECTION_SID, VERSION_NUMBER)
    DEFERRABLE INITIALLY DEFERRED
;

update section
   set checked_out_version_number = section_pkg.GetLatestVersion(section_sid) 
 where checked_out_to_sid is not null;
 
 commit;


	  
@update_tail


/*
-- I had a load of duff data where there was no section_version entry - this doesn't
-- appear to be the case on live, but if you have this issue locally, then you can
-- run this script (at your own risk!! :)). The foul when others then null is because
-- it deletes bits of the tree top down sometimes, so has already deleted child nodes
-- and I can't be bothered to rectify this for a throw-away query not destined for live.
DECLARE
	v_act				security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	for r in (
		select s.section_sid
		  from section s, section_version sv 
		 where s.section_sid = sv.section_sid(+)
		 group by s.section_sid
		having count(sv.section_sid) =0
	)
	loop
		begin
			securableobject_pkg.deleteso(v_act, r.section_sid);
		exception
			when others then null;
		end;	
	end loop;
end;
*/
