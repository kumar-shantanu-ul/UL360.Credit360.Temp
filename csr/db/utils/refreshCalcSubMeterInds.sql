DECLARE
	v_id	NUMBER(10);
BEGIN
	security.user_pkg.logonadmin('&&host');
	
	v_id := csr.aggregate_ind_pkg.SetGroup('CalculatedSubMeter', 'csr.meter_pkg.GetCalcSubMeterAggr');
	
	DELETE FROM csr.aggregate_ind_group_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND aggregate_ind_group_id = v_id;
	   
	INSERT INTO csr.aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
        SELECT DISTINCT v_id, m.primary_ind_sid
          FROM csr.all_meter m
          JOIN csr.meter_source_type mst ON m.meter_source_type_id = mst.meter_source_type_id AND m.app_sid = mst.app_sid
         WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND mst.is_calculated_sub_meter = 1;
           
    csr.aggregate_ind_pkg.RefreshGroup(v_id);
    COMMIT;
END;
/

EXIT
