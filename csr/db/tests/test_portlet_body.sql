CREATE OR REPLACE PACKAGE BODY csr.test_portlet_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_customer_portlet_sid NUMBER(10);
	v_tab_id			   NUMBER(10);
BEGIN
	v_site_name	:= in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	SELECT customer_portlet_sid 
	  INTO v_customer_portlet_sid
	  FROM csr.customer_portlet
	 WHERE portlet_id = 1 
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT MIN(tab_id) 
	  INTO v_tab_id
	  FROM csr.tab
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	INSERT INTO csr.tab_portlet (app_sid, tab_portlet_id, tab_id, column_num, pos, state, customer_portlet_sid, added_by_user_sid, added_dtm)
	VALUES (SYS_CONTEXT('SECURITY', 'APP'), 999999999, v_tab_id, 0, 0, '{}', v_customer_portlet_sid, 3, SYSDATE);
END;

PROCEDURE SetUp
AS
BEGIN
	NULL;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	security.user_pkg.logonadmin(v_site_name);
	DELETE FROM csr.tab_portlet WHERE tab_portlet_id = 999999999;
END;

PROCEDURE TearDown AS
BEGIN
	NULL;
END;

PROCEDURE TestAuditPortletState AS
	v_portlet_id	NUMBER;
	v_test_string 	CLOB;
BEGIN
	v_test_string := '{"id":15,"method":"saveState","params":[233562,{"portletHeight":100,"translations":[{"lang":"en","description":"Region picker"}],
	"pickerName":"site","selectedRegionList":[{"id":"ext-comp-1534","sid":39013686,"description":"1. Health Tech Industrial",
	"uniqueId":39013686,"level":0},{"id":"ext-comp-1534","sid":48614797,"description":"Connected Care and Health Informatics",
	"uniqueId":48614797,"level":1},{"id":"ext-comp-1534","sid":63114550,"description":"BG Monitoring and Analytics  ",
	"uniqueId":63114550,"level":2},{"id":"ext-comp-1534","sid":"11403789","description":"X686 - Andover  ",
	"uniqueId":"11403789","level":3},{"id":"ext-comp-1534","sid":"11403800","description":"X693 - Boeblingen  ",
	"uniqueId":"11403800","level":3},{"id":"ext-comp-1534","sid":"11404235","description":"X848 - Shenzhen Goldway  ",
	"uniqueId":"11404235","level":3},{"id":"ext-comp-1534","sid":63114537,"description":"BG Therapeutic Care (TC)",
	"uniqueId":63114537,"level":2},{"id":"ext-comp-1534","sid":"11422723","description":"X627 - Carlsbad (TC)",
	"uniqueId":"11422723","level":3},{"id":"ext-comp-1534","sid":"11404227","description":"X030 - Wallingford (TC)",
	"uniqueId":"11404227","level":3},{"id":"ext-comp-1534","sid":48614796,"description":"Diagnosis and Treatment",
	"uniqueId":48614796,"level":1},{"id":"ext-comp-1534","sid":39013693,"description":"BG Diagnostic Imaging X",
	"uniqueId":39013693,"level":2},{"id":"ext-comp-1534","sid":"11402978","description":"X413 - Hamburg X",
	"uniqueId":"11402978","level":3},{"id":"ext-comp-1534","sid":"11403251","description":"X690 - Haifa X",
	"uniqueId":"11403251","level":3},{"id":"ext-comp-1534","sid":"11402643","description":"X691 - Cleveland X",
	"uniqueId":"11402643","level":3},{"id":"ext-comp-1534","sid":"11404124","description":"X074 - Gainesville X",
	"uniqueId":"11404124","level":3},{"id":"ext-comp-1534","sid":"11407568","description":"X075 – Latham X",
	"uniqueId":"11407568","level":3},{"id":"ext-comp-1534","sid":"11406797","description":"X843 - Varginha (ex Lagoa Santa) X",
	"uniqueId":"11406797","level":3},{"id":"ext-comp-1534","sid":"11422718","description":"X045 - Suzhou X",
	"uniqueId":"11422718","level":3},{"id":"ext-comp-1534","sid":40288095,"description":"BG Image Guided Therapy (IGT)",
	"uniqueId":40288095,"level":2},{"id":"ext-comp-1534","sid":"12191435","description":"X716 - Best (IGT)",
	"uniqueId":"12191435","level":3},{"id":"ext-comp-1534","sid":"11405196","description":"X850 - Pune (IGT)",
	"uniqueId":"11405196","level":3},{"id":"ext-comp-1534","sid":"11404103","description":"X858 - Best PMSN (IGT)",
	"uniqueId":"11404103","level":3},{"id":"ext-comp-1534","sid":"41250901","description":"H3105 - Rancho Cordova, CA (IGT)",
	"uniqueId":"41250901","level":3},{"id":"ext-comp-1534","sid":"41250904","description":"H3106 - Coyol (IGT)",
	"uniqueId":"41250904","level":3},{"id":"ext-comp-1534","sid":"57929052","description":"H3117 - Colorado Springs, CO (IGT)",
	"uniqueId":"57929052","level":3},{"id":"ext-comp-1534","sid":"57929055","description":"H3119 - Fremont, CA North (IGT)",
	"uniqueId":"57929055","level":3},{"id":"ext-comp-1534","sid":"57929057","description":"H3120 - Fremont, CA South (IGT)",
	"uniqueId":"57929057","level":3},{"id":"ext-comp-1534","sid":39013724,"description":"BG Ultrasound (US)","uniqueId":39013724,"level":2},
	{"id":"ext-comp-1534","sid":"11405969","description":"X407 - Bothell (US)","uniqueId":"11405969","level":3},
	{"id":"ext-comp-1534","sid":"12191460","description":"X408 - Reedsville (US)","uniqueId":"12191460","level":3},
	{"id":"ext-comp-1534","sid":"12631794","description":"H3032 - Shanghai (US)","uniqueId":"12631794","level":3},
	{"id":"ext-comp-1534","sid":39013687,"description":"Personal Health","uniqueId":39013687,"level":1},
	{"id":"ext-comp-1534","sid":39013690,"description":"BG Domestic Appliances (DA)","uniqueId":39013690,"level":2},
	{"id":"ext-comp-1534","sid":"11404329","description":"X424 - Varginha (DA)","uniqueId":"11404329","level":3},
	{"id":"ext-comp-1534","sid":11406541,"description":"X503 - Batam (DA)","uniqueId":11406541,"level":3}],"showInactive":false,"type":6,"pickerMode":1,"portletTitle":"Region picker"}]}';

	BEGIN
		csr.portlet_pkg.UNSEC_AuditPortletState(999999999, 'mame', v_test_string, v_test_string);
	EXCEPTION
		WHEN OTHERS THEN 
			unit_test_pkg.TestFail('Can create portlet audit entries when string is > 4k chars.', 'Exception thrown.');
	END;
END;

END test_portlet_pkg;
/
