set serveroutput on

variable approval_step_id number
exec :approval_step_id := &1

prompt pending_val_log
delete from csr.pending_val_log where pending_val_id in (select pending_val_id from csr.pending_val where approval_step_id = :approval_step_id);
prompt pending_val_variance
delete from csr.pending_val_variance where pending_val_id in (select pending_val_id from csr.pending_val where approval_step_id = :approval_step_id);
prompt pending_val_file_upload
delete from csr.pending_val_file_upload where pending_val_id in (select pending_val_id from csr.pending_val where approval_step_id = :approval_step_id);
prompt pending_val
delete from csr.pending_val where pending_ind_id in (select pending_ind_id from csr.pending_ind where approval_step_id = :approval_step_id);
prompt approval_step_model
delete from csr.approval_step_model where approval_step_id = :approval_step_id;
prompt approval_step_user
delete from csr.approval_step_user where approval_step_id = :approval_step_id;
prompt approval_step_sheet_log
delete from csr.approval_step_sheet_log where approval_step_id = :approval_step_id;
prompt approval_step_sheet_alert
delete from csr.approval_step_sheet_alert where approval_step_id = :approval_step_id;
prompt approval_step_sheet
delete from csr.approval_step_sheet where approval_step_id = :approval_step_id;
prompt approval_step_ind
delete from csr.approval_step_ind where approval_step_id = :approval_step_id;
prompt approval_step_region
delete from csr.approval_step_region where approval_step_id = :approval_step_id;
prompt approval_step
delete from csr.approval_step where approval_step_id = :approval_step_id;

exec dbms_output.put_line('Approval step deleted. Commit or rollback.');
