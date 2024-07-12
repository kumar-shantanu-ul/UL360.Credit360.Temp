define old_feedback=&&feedback
define feedback=0
set feedback &&feedback

variable approval_step_id number
exec :approval_step_id := &1

@@print ''
@@print '************************************************************************************************************************************************'
@@print '************************************************************************************************************************************************'
@@print '************************************************************************************************************************************************'

@@print ''
@@print 'approval_step'
select * from approval_step where approval_step_id = :approval_step_id;

@@print ''
@@print 'approval_step_sheet'
select sheet_key, label, pending_period_id, pending_ind_id, pending_region_id, visible, due_dtm, reminder_dtm from approval_step_sheet where approval_step_id = :approval_step_id;

@@print ''
@@print 'approval_step_model'
select a.link_description, a.icon_cls, m.model_sid, m.name from model m inner join approval_step_model a on m.model_sid = a.model_sid where a.approval_step_id = :approval_step_id;

@@print ''
@@print 'pending_region (approval_step_region)'
select pending_region.*, approval_step_region.rolls_up_to_region_id from approval_step_region left join pending_region on pending_region.pending_region_id = approval_step_region.pending_region_id where approval_step_region.approval_step_id = :approval_step_id;

@@print ''
@@print 'pending_period'
select * from pending_period where pending_dataset_id = (select pending_dataset_id from approval_step where approval_step_id = :approval_step_id) order by start_dtm, end_dtm;

@@print ''
@@print 'approval_step_user'
select user_sid, full_name from approval_step_user left join csr_user on csr_user.csr_user_sid = approval_step_user.user_sid and approval_step_user.app_sid = csr_user.app_sid where approval_step_id = :approval_step_id;

@@print ''
@@print 'approval_step_ind'
select count(*), sum(case when pending_element_type.is_number = 1 or pending_element_type.is_string = 1 then 1 else 0 end) editable, sum(case when (pending_element_type.is_number = 1 or pending_element_type.is_string = 1) and ind.ind_type = 0 then 1 else 0 end) editable_and_ind_type_normal from approval_step_ind
inner join pending_ind on approval_step_ind.pending_ind_id = pending_ind.pending_ind_id
inner join pending_element_type on pending_element_type.element_type = pending_ind.element_type
left join ind on ind.ind_sid = pending_ind.maps_to_ind_sid
where approval_step_id = :approval_step_id;

@@print ''
@@print 'pending_val'
select count(*) from pending_val where approval_step_id = :approval_step_id;

@@print ''
@@print 'approval_step (children)'
select * from approval_step where parent_step_id = :approval_step_id;

define feedback=&&old_feedback
set feedback &&feedback
