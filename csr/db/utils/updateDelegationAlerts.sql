DECLARE
BEGIN
  FOR r IN (
    SELECT ind_sid, region_sid, val_number, sheet_id FROM sheet_value WHERE sheet_id = &&sheet_id
  )
  LOOP
    begin delegation_pkg.UpdateAlerts(r.ind_sid, r.region_sid, r.val_number, r.sheet_id); end;
  END LOOP;
END;
/
