BEGIN
	-- Audit Types
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (1,'Logon',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (2,'Logoff',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (3,'Super user logon',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (4,'Change schema',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (5,'Change user',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (6,'Value change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (7,'Logon failed',1);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (10,'Delegation change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (11,'Action change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (12,'Action progress update',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (13,'Issues',6);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (14,'Action status change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (15,'Meter reading',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (16,'Client specific',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (17,'Suspicious access',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (18,'Feed',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (19,'SSO logon',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (20,'Group change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (21,'Survey change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (22,'Audit Document Update',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (23,'Initiatives',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (24,'Meter patch updated',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (25,'Portlet',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (26,'Dashboard',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (27,'Batch logon',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (28,'Factor',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (29,'Anonymised',1);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (50,'Product created',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (51,'Product details updated',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (52,'Product supplier changed',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (53,'Product data approver changed',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (54,'Product data provider changed',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (55,'Product deleted',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (56,'Product tag changed',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (57,'Product volume changed',2);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (60,'Supplier created',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (61,'Supplier details updated',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (62,'Assigned user to company',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (63,'Unassigned user from company',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (64,'Supplier deleted',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (65,'Supplier tag changed',1);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (70,'Product status change',3);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (71,'Questionaire saved',3);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (72,'Questionaire status change',3);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (73,'Questionaire linked',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (74,'Questionaire unlinked',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (75,'GT value saved',3);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (76,'GT score changed',3);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (77,'GT questionnaire copied',3);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (80,'Donation',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (81,'Budget',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (82,'Scheme',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (83,'Status',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (84,'Category',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (85,'Recipient',1);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (90,'Internal audit change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (91,'Finding change',1);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (100,'Region role change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (101,'User role change',1);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (110,'Region category change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (111,'Indicator category change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (112,'Category description changed',1);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (120,'Module enabled',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (121,'Capability enabled',1);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (200,'Business relationships',4);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (201,'Product Type',4);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (202,'Company product changes',2);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (203,'Chain Filter',4);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (300,'Automated import mailbox change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (301,'Automated import change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (303,'Automated export change',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (304,'Credential Management',6);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (305,'IQA',6);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (306,'Landing Page',6);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (307,'Period Set',6);

	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (500,'Region metric change',5);

END;
/

