-- Please update version.sql too -- this keeps clean builds in sync
define version=1171
@update_header

alter table csr.backup_delegation_ind add constraint
pk_backup_delegation_ind primary key (app_sid,delegation_sid,ind_sid);

begin
	delete from csr.delegation_ind_description;
	insert into csr.delegation_ind_description (app_sid, delegation_sid, ind_sid, lang, description)
		select di.app_sid, di.delegation_sid, di.ind_sid, ts.lang, COALESCE(tr.translated, di.description, id.description) description
		  from csr.backup_delegation_ind di
		  join aspen2.translation_set ts on ts.application_sid = di.app_sid
		  left join (
			select t.application_sid, t.original, tr.lang, tr.translated
			  from aspen2.translated tr, aspen2.translation t
			where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
		  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and di.description = tr.original
		  left join csr.ind_description id on di.app_sid = id.app_sid and di.ind_sid = id.ind_sid and ts.lang = id.lang
		  where COALESCE(tr.translated, di.description, id.description) IS NOT NULL
		 minus 
		 select id.app_sid, di.delegation_sid, di.ind_sid, id.lang, id.description
		   from csr.ind_description id, csr.delegation_ind di
		  where di.app_sid = id.app_sid and di.ind_sid = id.ind_sid
		  ;
/*
This is the version I actually ended up using for speed:
	
truncate table csr.delegation_ind_description;
	
begin
	security.user_pkg.logonadmin;
	for r in (select distinct app_sid from csr.backup_delegation_ind) loop
		security.security_pkg.setapp(r.app_sid);
		security_pkg.debugmsg('doing '||r.app_sid);
				
		insert into csr.delegation_ind_description (app_sid, delegation_sid, ind_sid, lang, description)
			select di.app_sid, di.delegation_sid, di.ind_sid, ts.lang, COALESCE(tr.translated, di.description, id.description) description
			  from csr.backup_delegation_ind di
			  join csr.delegation_ind die on di.app_sid = die.app_sid and di.delegation_sid = die.delegation_sid and di.ind_sid = die.ind_sid
			  join aspen2.translation_set ts on ts.application_sid = di.app_sid
			  left join (
				select t.application_sid, t.original, tr.lang, tr.translated
				  from aspen2.translated tr, aspen2.translation t
				where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
			  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and di.description = tr.original
			  left join csr.ind_description id on di.app_sid = id.app_sid and di.ind_sid = id.ind_sid and ts.lang = id.lang
			 where COALESCE(tr.translated, di.description, id.description) IS NOT NULL
			   and di.app_sid = r.app_sid
			 minus 
			 select id.app_sid, di.delegation_sid, di.ind_sid, id.lang, id.description
			   from csr.ind_description id, csr.delegation_ind di
			  where di.app_sid = id.app_sid and di.ind_sid = id.ind_sid
			    and id.app_sid = r.app_sid
			  ;
			  
		security_pkg.debugmsg('added '||sql%rowcount||' for '||r.app_sid);
		commit;
	end loop;
end;

*/
end;
/

@update_tail
