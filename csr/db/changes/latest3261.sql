define version=3261
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/








DECLARE
	PROCEDURE DisableCapability (
		in_name                         VARCHAR2
	)
	AS
		v_act_id                        security.security_pkg.T_ACT_ID;
		v_app_sid                       security.security_pkg.T_SID_ID;
		v_capability_sid                security.security_pkg.T_SID_ID;
	BEGIN
		v_act_id := security.security_pkg.GetAct;
		v_app_sid := security.security_pkg.GetApp;
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, '/Capabilities/' || in_name);
		security.securableobject_pkg.DeleteSO(v_act_id, v_capability_sid);
	END;
BEGIN
	FOR r IN (SELECT host FROM csr.customer WHERE name = 'leighcarter-emissionfactors.credit360.com')
	LOOP
		security.user_pkg.logonadmin(r.host);
		DisableCapability('Can delete factor type');
		security.user_pkg.logonadmin();
	END LOOP;
END;
/




UPDATE csr.factor_type
   SET std_measure_id = (SELECT std_measure_id from csr.std_measure WHERE name = 'm^-1')
 WHERE name = 'Air Freight Distance - Domestic (+8% uplift) (Direct)';








@..\..\..\aspen2\db\tr_body



@update_tail
