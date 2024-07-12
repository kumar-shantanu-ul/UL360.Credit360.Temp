-- Please update version.sql too -- this keeps clean builds in sync
define version=3309
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
delete from csr.deleg_plan_deleg_region_deleg where (applied_to_region_sid, maps_to_root_deleg_sid) in (
	with master_delegs as (
    select dp.deleg_plan_sid, dp.last_applied_dtm, dpc.deleg_plan_col_id, d.delegation_sid, d.name
      from csr.deleg_plan dp
      join csr.deleg_plan_col dpc on dp.deleg_plan_sid = dpc.deleg_plan_sid
      join csr.deleg_plan_col_deleg dpcd on dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
      join csr.delegation d on d.delegation_sid = dpcd.delegation_sid
      join csr.deleg_plan_deleg_region dpdr on dpcd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
     where dp.last_applied_dtm > '25-JUN-20'
       and dpdr.region_selection in ('PT', 'P')
  )
  select r.region_sid, dr.delegation_sid
	  from csr.delegation_region dr
	  join csr.region r on dr.region_sid = r.region_sid
	 where r.region_type != 3
	   and dr.delegation_sid in (
			select delegation_sid from csr.delegation where master_delegation_sid in (
				select delegation_sid from master_delegs
		)
	)
);

delete from csr.delegation_region where (region_sid, delegation_sid) in (
	with master_delegs as (
    select dp.deleg_plan_sid, dp.last_applied_dtm, dpc.deleg_plan_col_id, d.delegation_sid, d.name
      from csr.deleg_plan dp
      join csr.deleg_plan_col dpc on dp.deleg_plan_sid = dpc.deleg_plan_sid
      join csr.deleg_plan_col_deleg dpcd on dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
      join csr.delegation d on d.delegation_sid = dpcd.delegation_sid
      join csr.deleg_plan_deleg_region dpdr on dpcd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
     where dp.last_applied_dtm > '25-JUN-20'
       and dpdr.region_selection in ('PT', 'P')
  )
  select r.region_sid, dr.delegation_sid
	  from csr.delegation_region dr
	  join csr.region r on dr.region_sid = r.region_sid
	 where r.region_type != 3
	   and dr.delegation_sid in (
			select delegation_sid from csr.delegation where master_delegation_sid in (
				select delegation_sid from master_delegs
		)
	)
);
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
