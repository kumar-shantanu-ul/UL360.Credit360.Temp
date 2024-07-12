variable dataset_id number

BEGIN
	:dataset_id := &1;
END;
/

	SELECT
		(SELECT COUNT(*) FROM pvc_region_recalc_job WHERE pending_dataset_id = :dataset_id) pvc_region_recalc_job
	,	(SELECT COUNT(*) FROM pvc_stored_calc_job WHERE pending_dataset_id = :dataset_id) pvc_stored_calc_job
	,	(SELECT COUNT(*) FROM pending_val_log WHERE pending_val_id IN (SELECT pending_val_id FROM pending_val WHERE pending_ind_id IN (SELECT pending_ind_id FROM pending_ind WHERE pending_dataset_id = :dataset_id))) pending_val_log
	,	(SELECT COUNT(*) FROM pending_val WHERE pending_ind_id IN (SELECT pending_ind_id FROM pending_ind WHERE pending_dataset_id = :dataset_id)) pending_val
	,	(SELECT COUNT(*) FROM approval_step_model WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id)) approval_step_model
	,	(SELECT COUNT(*) FROM approval_step_user WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id)) approval_step_user
	,	(SELECT COUNT(*) FROM approval_step_sheet_log WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id)) approval_step_sheet_log
	,	(SELECT COUNT(*) FROM approval_step_sheet WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id)) approval_step_sheet
	,	(SELECT COUNT(*) FROM approval_step_ind WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id)) approval_step_ind
	,	(SELECT COUNT(*) FROM approval_step_region WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id)) approval_step_region
	,	(SELECT COUNT(*) FROM approval_step WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id)) approval_step
	,	(SELECT COUNT(*) FROM pending_ind WHERE pending_dataset_id = :dataset_id) pending_ind
	,	(SELECT COUNT(*) FROM pending_period WHERE pending_dataset_id = :dataset_id) pending_period
	,	(SELECT COUNT(*) FROM pending_region WHERE pending_dataset_id = :dataset_id) pending_region
	,	(SELECT COUNT(*) FROM pending_dataset WHERE pending_dataset_id = :dataset_id) pending_dataset
	FROM dual;

DECLARE
	v_act security_pkg.t_act_id;
	v_count number;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	SELECT COUNT(*) INTO v_count FROM security.securable_object WHERE sid_id = :dataset_id AND class_id = class_pkg.GetClassId('CSRDataset');

	IF v_count <> 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Pending dataset ' || :dataset_id || ' not found.');
	END IF;

	DELETE FROM pvc_region_recalc_job WHERE pending_dataset_id = :dataset_id;
	DELETE FROM pvc_stored_calc_job WHERE pending_dataset_id = :dataset_id;
	DELETE FROM pending_val_log WHERE pending_val_id IN (SELECT pending_val_id FROM pending_val WHERE pending_ind_id IN (SELECT pending_ind_id FROM pending_ind WHERE pending_dataset_id = :dataset_id));
	DELETE FROM pending_val WHERE pending_ind_id IN (SELECT pending_ind_id FROM pending_ind WHERE pending_dataset_id = :dataset_id);
	DELETE FROM approval_step_model WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id);
	DELETE FROM approval_step_user WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id);
	DELETE FROM approval_step_sheet_log WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id);
	DELETE FROM approval_step_sheet WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id);
	DELETE FROM approval_step_ind WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id);
	DELETE FROM approval_step_region WHERE approval_step_id IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id);
	DELETE FROM pending_ind WHERE pending_dataset_id = :dataset_id;
	DELETE FROM pending_period WHERE pending_dataset_id = :dataset_id;
	DELETE FROM pending_region WHERE pending_dataset_id = :dataset_id;

	FOR step IN (SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = :dataset_id)
	LOOP
		securableobject_pkg.DeleteSO(v_act, step.approval_step_id);
	END LOOP;
	DELETE FROM approval_step WHERE pending_dataset_id = :dataset_id;

	securableobject_pkg.DeleteSO(v_act, :dataset_id);
	DELETE FROM pending_dataset WHERE pending_dataset_id = :dataset_id;

	dbms_output.put_line('Dataset deleted. Commit or rollback.');
END;
/
