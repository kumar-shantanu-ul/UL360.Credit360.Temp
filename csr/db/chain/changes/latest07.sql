define version=7
@update_header

-- revoke priviledge from version 6
begin
	execute immediate 'revoke select on questionnaire_type from web_user';
exception
	when others then
		null;
end;
/

begin
	INSERT INTO card_group
	(card_group_id, name, description, require_all_cards)
	VALUES
	(8, 'Dashboard Info', 'Allows informational messages on the dashboard', 0);
end;
/

@..\questionnaire_pkg
@..\questionnaire_body

@update_tail