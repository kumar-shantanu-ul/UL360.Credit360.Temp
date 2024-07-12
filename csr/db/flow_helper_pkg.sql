CREATE OR REPLACE PACKAGE csr.flow_helper_pkg AS

FUNCTION GetFlowRegionSids(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

END flow_helper_pkg;
/
