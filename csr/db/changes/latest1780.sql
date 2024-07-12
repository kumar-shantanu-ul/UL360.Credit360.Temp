-- Please update version.sql too -- this keeps clean builds in sync
define version=1780
@update_header

ALTER TABLE CHEM.SUBSTANCE_REGION ADD (
    FIRST_USED_DTM DATE,
    LOCAL_REF VARCHAR2(40)
);

ALTER TABLE CHEM.PROCESS_DESTINATION ADD (
    FIRST_USED_DTM DATE
);

begin
	for r in (
		select sr.substance_id, max(sr.region_sid) region_sid, app_sid
		from chem.substance_region sr
		group by sr.substance_id, sr.app_sid
		having count(*) = 1
	) loop
		update chem.substance s
		set region_sid = r.region_sid
		where s.substance_id = r.substance_id
		and s.app_sid = r.app_sid;
	end loop;

	for r in (
		select su.process_destination_id, min(su.start_dtm) start_dtm, app_sid
		from chem.substance_use su
		group by su.substance_id, su.region_sid, su.process_destination_id, su.app_sid
	) loop
		update chem.process_destination
		set first_used_dtm = r.start_dtm
		where process_destination_id = r.process_destination_id
		and app_sid = r.app_sid;
	end loop;
	
	update chem.process_destination
	set first_used_dtm = TO_DATE('01-JAN-12')
	where first_used_dtm is null;
end;
/

ALTER TABLE CHEM.PROCESS_DESTINATION MODIFY (
    FIRST_USED_DTM DATE NOT NULL
);

CREATE OR REPLACE VIEW CHEM.V$SUBSTANCE_USE AS
	SELECT su.app_sid, su.substance_use_id, su.substance_id, 
		   su.region_sid, su.process_destination_id, su.root_delegation_sid, 
		   su.mass_value, su.note, su.start_dtm, su.end_dtm, su.entry_std_measure_conv_id, 
		   su.entry_mass_Value, su.created_dtm, su.vers, su.changed_by
	  FROM substance_use su
	 WHERE su.retired_dtm IS NULL;

update chem.substance_use
set retired_dtm = sys_extract_utc(systimestamp)
where retired_dtm is null
and (substance_use_id, vers) not in (
	select substance_use_id, max(vers)
	from chem.substance_use
	where retired_dtm is null
	group by substance_use_id
);

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail
