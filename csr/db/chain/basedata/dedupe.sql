BEGIN
	--company table
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (1, 'COMPANY', 'NAME', 'Company name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (2, 'COMPANY', 'PARENT_SID', 'Parent company');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (3, 'COMPANY', 'COMPANY_TYPE_ID', 'Company type');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (4, 'COMPANY', 'CREATED_DTM', 'Created date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (5, 'COMPANY', 'ACTIVATED_DTM', 'Activated date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (6, 'COMPANY', 'ACTIVE', 'Active');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (7, 'COMPANY', 'ADDRESS', 'Address');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (8, 'COMPANY', 'STATE', 'State');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (9, 'COMPANY', 'POSTCODE', 'Postcode');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (10, 'COMPANY', 'COUNTRY_CODE', 'Country');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (11, 'COMPANY', 'PHONE', 'Phone');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (12, 'COMPANY', 'FAX', 'Fax');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (13, 'COMPANY', 'WEBSITE', 'Website');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (14, 'COMPANY', 'EMAIL', 'Email');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (15, 'COMPANY', 'DELETED', 'Deleted');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (16, 'COMPANY', 'SECTOR_ID', 'Sector');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (17, 'COMPANY', 'CITY', 'City');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (18, 'COMPANY', 'DEACTIVATED_DTM', 'Deactivated date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (19, 'COMPANY', 'PURCHASER_COMPANY', 'Purchaser company');
	
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (101, 'USER', 'EMAIL', 'Email');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (102, 'USER', 'FULL_NAME', 'Full name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (103, 'USER', 'FIRST_NAME', 'First Name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (104, 'USER', 'LAST_NAME', 'Last name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (105, 'USER', 'USER_NAME', 'Username');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (106, 'USER', 'FRIENDLY_NAME', 'Friendly name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (107, 'USER', 'PHONE_NUMBER', 'Phone Number');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (108, 'USER', 'JOB_TITLE', 'Job title');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (109, 'USER', 'CREATED_DTM', 'Created date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (110, 'USER', 'PRIMARY_REGION', 'Primary region');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (111, 'USER', 'USER_REF', 'User reference');
	INSERT INTO chain.dedupe_field(dedupe_field_id, entity, field, description) VALUES (112, 'USER', 'ACTIVE', 'User is active');
END;
/

BEGIN
	INSERT INTO chain.dedupe_match_type (dedupe_match_type_id, label) VALUES (1, 'Automatic');
	INSERT INTO chain.dedupe_match_type (dedupe_match_type_id, label) VALUES (2, 'Manual');
END;
/

BEGIN
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) VALUES (1, 'Exact match (case insensitive)', 100);
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) VALUES (2, 'Levenshtein (distance match)', 50);
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) VALUES (3, 'Jaro-Winkler (distance match)', 70);
	INSERT INTO chain.dedupe_rule_type (dedupe_rule_type_id, description, threshold_default) VALUES (4, 'Contains match (case insensitive)', 100);
END;
/

BEGIN
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) VALUES (1, 'Auto create company');
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) VALUES (2, 'Mark record for manual review');
	INSERT INTO chain.dedupe_no_match_action (dedupe_no_match_action_id, description) VALUES (3, 'Park record');
END;
/