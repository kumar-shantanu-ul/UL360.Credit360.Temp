CREATE OR REPLACE PACKAGE csr.test_common_pkg AS

ChainCompanySid						security.security_pkg.T_SID_ID;
ChainPropertyRegionSid				security.security_pkg.T_SID_ID;
ChainPropertyTypeId					security.security_pkg.T_SID_ID;
ChainPropertyFlowSid				security.security_pkg.T_SID_ID;

PROCEDURE SetupChainPropertyWorkflow;
PROCEDURE TeardownChainPropertyWorkflow;

PROCEDURE SetupChainProperty;
PROCEDURE TearDownChainProperty;

END test_common_pkg;
/
