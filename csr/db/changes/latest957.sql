-- Please update version.sql too -- this keeps clean builds in sync
define version=957
@update_header

begin
	for r in (select * 
				from (select rowid, dataview_sid, pos, row_number() over (partition by app_sid, dataview_sid order by pos) rn
					    from csr.dataview_ind_member) 
			    where rn != pos) loop
		update csr.dataview_ind_member
		   set pos = r.rn
		 where rowid = r.rowid;
	end loop;
	for r in (select * 
				from (select rowid, dataview_sid, pos, row_number() over (partition by app_sid, dataview_sid order by pos) rn
					    from csr.dataview_region_member) 
			    where rn != pos) loop
		update csr.dataview_region_member
		   set pos = r.rn
		 where rowid = r.rowid;
	end loop;
end;
/

ALTER TABLE CSR.DATAVIEW_IND_MEMBER ADD CONSTRAINT UK_DATAVIEW_IND_POS  UNIQUE (APP_SID, DATAVIEW_SID, POS);
ALTER TABLE CSR.DATAVIEW_REGION_MEMBER ADD CONSTRAINT UK_DATAVIEW_REGION_POS  UNIQUE (APP_SID, DATAVIEW_SID, POS);

grant select on aspen2.translation to csr;

@../dataview_pkg
@../dataview_body

@update_tail
