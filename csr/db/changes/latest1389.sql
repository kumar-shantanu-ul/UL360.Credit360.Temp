-- Please update version.sql too -- this keeps clean builds in sync
define version=1389
@update_header

begin
	for r in (select 1 from all_indexes where owner='CSR' and index_name='UK_FACTOR_1') loop
		execute immediate 'drop index csr.UK_FACTOR_1';
	end loop;
end;
/

-- delete dupe guff
delete from csr.factor where factor_id in (
  select factor_Id 
    from (
      select 
        row_number()  over (
          partition by APP_SID, FACTOR_TYPE_ID, NVL(GEO_COUNTRY, 'XX'), NVL(GEO_REGION, 'XX'), NVL(EGRID_REF, 'XX'), NVL(REGION_SID, -1), START_DTM, END_DTM, GAS_TYPE_ID,
          NVL(std_factor_id, -is_selected) order by factor_id desc
        ) rn,
        f.* 
     from csr.factor f
  ) where rn > 1
);

-- bit weird but this allows for bespoke factors (null std_factor_id) to be stored alongside standard factors. We might want to tighten this later
-- but would result in deleting a lot of rows -- would need to check impact of this before doing it.
CREATE UNIQUE INDEX CSR.UK_FACTOR_1 ON CSR.FACTOR (
 APP_SID, FACTOR_TYPE_ID, NVL(GEO_COUNTRY, 'XX'), NVL(GEO_REGION, 'XX'), NVL(EGRID_REF, 'XX'), NVL(REGION_SID, -1), START_DTM, END_DTM, GAS_TYPE_ID,
  NVL(std_factor_id, -is_selected)
);
  

@update_tail