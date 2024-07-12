select pending_region_id, description,
(
select count(distinct pending_ind_id)
from approval_step_ind apsi
inner join approval_step_region apsr on apsr.approval_step_id = apsi.approval_step_id
where pending_region_id = pending_region.pending_region_id
) distinct_ind_count
from pending_region
where pending_dataset_id = &1
order by description;
