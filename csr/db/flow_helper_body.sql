CREATE OR REPLACE PACKAGE BODY csr.flow_helper_pkg AS

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT fir.region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM flow_item_region fir
	 WHERE fir.flow_item_id = in_flow_item_id;

	RETURN v_region_sids_t;
END;

END flow_helper_pkg;
/
