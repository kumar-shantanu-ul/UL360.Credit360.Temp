CREATE OR REPLACE PACKAGE BODY ct.snapshot_pkg AS

FUNCTION SnapshotTaken RETURN customer_options.snapshot_taken%TYPE
AS
	v_snapshot_taken		customer_options.snapshot_taken%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	SELECT snapshot_taken
	  INTO v_snapshot_taken
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;
	   
	RETURN v_snapshot_taken;
END;

PROCEDURE CopyBreakdownRegionEios (
	in_old_breakdown_id				IN  breakdown_region_eio.breakdown_id%TYPE,
	in_new_breakdown_id				IN  breakdown_region_eio.breakdown_id%TYPE
)
AS
BEGIN
	FOR bre IN (
		SELECT app_sid, breakdown_id, region_id, eio_id, fte, turnover, pct
		  FROM breakdown_region_eio
		 WHERE app_sid = security_pkg.getApp
		   AND breakdown_id = in_old_breakdown_id
	) LOOP 		
		-- Copy breakdown region eio
		INSERT INTO breakdown_region_eio (app_sid, breakdown_id, region_id, eio_id, fte, turnover, pct)
		     VALUES (bre.app_sid, in_new_breakdown_id, bre.region_id, bre.eio_id, bre.fte, bre.turnover, bre.pct);
	END LOOP;
END;

PROCEDURE CopyBreakdownRegions (
	in_old_breakdown_id				IN  breakdown_region.breakdown_id%TYPE,
	in_new_breakdown_id				IN  breakdown_region.breakdown_id%TYPE
)
AS
BEGIN
	FOR br IN (
		SELECT app_sid, breakdown_id, region_id, fte_travel, pct
		  FROM breakdown_region
		 WHERE app_sid = security_pkg.getApp
		   AND breakdown_id = in_old_breakdown_id
	) LOOP 		
		-- Copy breakdown region
		INSERT INTO breakdown_region (app_sid, breakdown_id, region_id, fte_travel, pct)
		     VALUES (br.app_sid, in_new_breakdown_id, br.region_id, br.fte_travel, br.pct);
	END LOOP;	
	
	-- Copy breakdown region eios
	CopyBreakdownRegionEios(in_old_breakdown_id, in_new_breakdown_id);
END;

PROCEDURE CopyBreakdowns (
	in_old_breakdown_type_id		IN  breakdown.breakdown_type_id%TYPE,
	in_new_breakdown_type_id		IN  breakdown.breakdown_type_id%TYPE
)
AS
	v_new_breakdown_id				breakdown.breakdown_id%TYPE;
BEGIN
	FOR b IN (
		SELECT app_sid, company_sid, breakdown_id, breakdown_type_id, description, fte, turnover, fte_travel, is_remainder, region_id
		  FROM breakdown
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_type_id = in_old_breakdown_type_id
	) LOOP 		
		-- Copy breakdown
		INSERT INTO breakdown (app_sid, company_sid, breakdown_id, breakdown_type_id, description, fte, turnover, fte_travel, is_remainder, region_id)
		     VALUES (b.app_sid, b.company_sid, breakdown_id_seq.NEXTVAL, in_new_breakdown_type_id, b.description, b.fte, b.turnover, b.fte_travel, b.is_remainder, b.region_id)
		  RETURNING breakdown_id INTO v_new_breakdown_id;
			 
		-- Copy breakdowns regions + children
		CopyBreakdownRegions(b.breakdown_id, v_new_breakdown_id);
	END LOOP;	
END;

PROCEDURE CopyBreakdownTypes
AS
	v_new_breakdown_type_id			breakdown_type.breakdown_type_id%TYPE;
BEGIN
	FOR bt IN (
		SELECT app_sid, company_sid, breakdown_type_id, singular, plural, by_turnover, by_fte, is_region, rest_of, is_hotspot
		  FROM breakdown_type
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND is_hotspot = 1
	) LOOP 		
		-- Copy breakdown type
		INSERT INTO breakdown_type (app_sid, company_sid, breakdown_type_id, singular, plural, by_turnover, by_fte, is_region, rest_of, is_hotspot)
		     VALUES (bt.app_sid, bt.company_sid, breakdown_type_id_seq.NEXTVAL, bt.singular, bt.plural, bt.by_turnover, bt.by_fte, bt.is_region, bt.rest_of, 0)
		  RETURNING breakdown_type_id INTO v_new_breakdown_type_id;
			 
		-- Copy breakdowns + children
		CopyBreakdowns(bt.breakdown_type_id, v_new_breakdown_type_id);
	END LOOP;	
END;

PROCEDURE DeleteVCBreakdownTypes
AS
BEGIN
	FOR bt IN (
		SELECT app_sid, company_sid, breakdown_type_id, singular, plural, by_turnover, by_fte, is_region, rest_of, is_hotspot
		  FROM breakdown_type
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND is_hotspot = 0
	) LOOP 		
		breakdown_type_pkg.DeleteBreakdownType(bt.breakdown_type_id);
	END LOOP;	
END;

PROCEDURE CreateQuestionnaires
AS
BEGIN
	FOR br IN (
		SELECT br.breakdown_id, br.region_id
		  FROM breakdown_region br, breakdown b, breakdown_type bt
		 WHERE br.app_sid = security_pkg.getApp
		   AND br.breakdown_id = b.breakdown_id
		   AND b.breakdown_type_id = bt.breakdown_type_id
		   AND b.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND bt.is_hotspot = 0
	) LOOP 
		INSERT INTO ec_questionnaire (app_sid, company_sid, ec_questionnaire_id, 
		                                 guid, breakdown_id, region_id)
			 VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), 
			         ec_questionnaire_id_seq.NEXTVAL, security.user_pkg.RawAct,
			         br.breakdown_id, br.region_id);
	END LOOP;
END;

PROCEDURE SnapshotData
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	DeleteVCBreakdownTypes();
	CopyBreakdownTypes();
	CreateQuestionnaires();
	
	UPDATE customer_options
	   SET snapshot_taken = 1
	 WHERE app_sid = security_pkg.getApp;
END;

END snapshot_pkg;
/
