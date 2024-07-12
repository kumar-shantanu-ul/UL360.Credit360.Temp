-- Please update version.sql too -- this keeps clean builds in sync
define version=2685
@update_header

@latest2685_packages

GRANT SELECT ON chem.v$substance_region TO csr;
GRANT EXECUTE ON cms.tmp_tab_pkg TO csr;

--migrate old unprocessed flow_item_alerts to flow_item_generated_alert
DECLARE 
	v_host VARCHAR2(255);
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT DISTINCT c.host, fia.flow_item_id, fsl.set_by_user_sid, fia.flow_state_log_id, fsta.flow_state_transition_id
		  FROM csr.XX_FLOW_ITEM_ALERT fia
		  JOIN csr.flow_transition_alert fsta ON fsta.flow_transition_alert_id = fia.flow_transition_alert_id AND fsta.app_sid = fia.app_sid
		  JOIN csr.flow_state_log fsl ON fia.flow_state_log_id = fsl.flow_state_log_id AND fia.app_sid = fsl.app_sid
		  JOIN csr.customer c ON c.app_sid = fia.app_sid
		 WHERE processed_dtm IS NULL
		   AND NOT EXISTS( --ok, if 1 exists dont bother with this flow_item_alert
			SELECT 1
			  FROM csr.flow_item_generated_alert figa
			 WHERE figa.app_sid = fia.app_sid
			   AND figa.xx_flow_item_alert = fia.flow_item_alert_id
		 )
		 ORDER BY c.host, fia.flow_item_id
	)
	LOOP
		IF NVL(v_host, ' ') <> r.host THEN
			security.user_pkg.logonadmin(r.host);
			v_host := r.host;
		END IF;
		--dbms_output.put_line('Generating alerts for host:'||r.host||' and flow state log id:' || r.flow_state_log_id);
		csr.tmp_transition_alert_pkg.tmp_generateTransEntries(r.flow_item_id, r.set_by_user_sid, r.flow_state_log_id, r.flow_state_transition_id);
		
		UPDATE csr.XX_FLOW_ITEM_ALERT 
		   SET processed_dtm = SYSDATE
		 WHERE app_sid = security.security_pkg.getapp
		   AND flow_item_id = r.flow_item_id
		   AND flow_state_log_id = r.flow_state_log_id;
		 
		 commit;
	END LOOP;
	
	security.user_pkg.logonadmin;
END;
/

DROP PACKAGE csr.tmp_transition_alert_pkg;
DROP PACKAGE cms.tmp_tab_pkg;


@update_tail
