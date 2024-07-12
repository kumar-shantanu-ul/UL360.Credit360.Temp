-- Please update version.sql too -- this keeps clean builds in sync
define version=1668
@update_header

UPDATE CSR.STD_ALERT_TYPE 
   SET DESCRIPTION = 'Corporate Reporter question workflow state change',
   SEND_TRIGGER = 'The status of a question has changed in the workflow'
 WHERE STD_ALERT_TYPE_ID = 44;

UPDATE CSR.STD_ALERT_TYPE 
   SET DESCRIPTION = 'Corporate Reporter question reminder',
   SEND_TRIGGER ='The date the question reminder is due'
 WHERE STD_ALERT_TYPE_ID = 48;

UPDATE CSR.STD_ALERT_TYPE 
   SET DESCRIPTION = 'Corporate Reporter question overdue',
   SEND_TRIGGER = 'The date the question is due'
 WHERE STD_ALERT_TYPE_ID = 49;


UPDATE CSR.std_alert_type_param 
   SET description = 'Workflow status', 
    help_text = 'The current workflow status of the question'
 WHERE std_alert_type_id = 48 AND field_name = 'STATE_LABEL';

UPDATE CSR.std_alert_type_param 
   SET description = 'Workflow status', 
    help_text = 'The current workflow status of the question'
 WHERE std_alert_type_id = 49 AND field_name = 'STATE_LABEL';

UPDATE CSR.std_alert_type_param 
   SET description = 'Due date', 
    help_text = 'Date when the question is due'
 WHERE std_alert_type_id = 44 AND field_name = 'DUE_DTM';

UPDATE CSR.std_alert_type_param 
   SET description = 'From', 
    help_text = 'Full name of the person who changed the status'
 WHERE std_alert_type_id = 44 AND field_name = 'FROM_FULL_NAME';

UPDATE CSR.std_alert_type_param 
   SET description = 'Workflow status', 
    help_text = 'The current workflow status of the question',
    repeats = 0
 WHERE std_alert_type_id = 44 AND field_name = 'STATE_LABEL';


INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 5);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (48, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 4);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (49, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 4);

-- We use LIKE because Emil had some of these as en-gb
UPDATE CSR.default_alert_template_body
   SET subject = '<template>Question status has changed to <mergefield name="STATE_LABEL"/></template>',
    body_html = '<template>'||
        '<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
        '<p>The following questions have changed status to "<mergefield name="STATE_LABEL"/>" and now need your input:</p>'||
        '<ul>'||
            '<mergefield name="ITEMS"/>'||
        '</ul>'||
        '<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> for more information.</p>'||
    '</template>', 
    item_html = '<template><li><mergefield name="SECTION_TITLE"/> (from <mergefield name="FROM_FULL_NAME" />)</li></template>',
    lang = 'en'
 WHERE std_alert_type_id = 44
   AND lang LIKE 'en%'; 

UPDATE CSR.default_alert_template_body
   SET subject = '<template>Reminder about questions to be submitted</template>',
    body_html = '<template>'||
        '<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
        '<p>You''re receiving this email because there are questions awaiting your input that are due to be submitted shortly.</p>'||
        '<ul>'||
            '<mergefield name="ITEMS"/>'||
        '</ul>'||
        '<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> to submit these.</p>'||
    '</template>', 
    item_html = '<template><li><mergefield name="SECTION_TITLE"/> (<mergefield name="STATE_LABEL" /> - due <mergefield name="DUE_DTM" />)</li></template>',
    lang = 'en' 
 WHERE std_alert_type_id = 48
   AND lang LIKE 'en%'; 

UPDATE CSR.default_alert_template_body
   SET subject = '<template>Overdue questions that need to be submitted</template>',
    body_html = '<template>'||
        '<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
        '<p>You''re receiving this email because there are questions awaiting your input that are now passed their due date and need immediate action.</p>'||
        '<ul>'||
            '<mergefield name="ITEMS"/>'||
        '</ul>'||
        '<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> as soon as possible to submit these.</p>'||
    '</template>', 
    item_html = '<template><li><mergefield name="SECTION_TITLE"/> (<mergefield name="STATE_LABEL" /> - due <mergefield name="DUE_DTM" />)</li></template>',
    lang = 'en' 
 WHERE std_alert_type_id = 49
   AND lang LIKE 'en%';


INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (52, 'Corporate Reporter question submitted',
  'A user submits a question to the next user in the routing',
  'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (53, 'Corporate Reporter question returned',
  'A user returns a question to the previous user in the routing',
  'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

-- Text question route forward
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'HOST', 'Site host address', 'Address of the website', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'STATE_LABEL', 'Workflow status', 'The new workflow status of the question', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 1, 'DUE_DTM', 'Due date', 'Date when the question is due', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 1, 'FROM_FULL_NAME', 'From', 'Full name of the person who changed the status', 3);

-- Text question route return
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'HOST', 'Site host address', 'Address of the website', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'STATE_LABEL', 'Workflow status', 'The new workflow status of the question', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 1, 'DUE_DTM', 'Due date', 'Date when the question is due', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 1, 'FROM_FULL_NAME', 'From', 'Full name of the person who changed the status', 3);

DECLARE
    v_id NUMBER(10);
BEGIN
    SELECT MIN(default_alert_frame_id) INTO v_id FROM csr.default_alert_frame;
    INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (52, v_id, 'manual');
    INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (53, v_id, 'manual');
END;
/

INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (52, 'en',
        '<template>Questions have been submitted to you for attention</template>',
        '<template>'||
            '<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
            '<p>The following questions have been submitted to you and need your attention:</p>'||
            '<ul>'||
                '<mergefield name="ITEMS"/>'||
            '</ul>'||
            '<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> for more information.</p>'||
        '</template>', 
        '<template><li><mergefield name="SECTION_TITLE"/> (from <mergefield name="FROM_FULL_NAME" />)</li></template>'
        );
    
INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (53, 'en',
    '<template>Questions have been returned to you</template>',
    '<template>'||
        '<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
        '<p>The following questions have been returned to you and need your attention:</p>'||
        '<ul>'||
            '<mergefield name="ITEMS"/>'||
        '</ul>'||
        '<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> for more information.</p>'||
    '</template>', 
    '<template><li><mergefield name="SECTION_TITLE"/> (from <mergefield name="FROM_FULL_NAME" />)</li></template>'
    );


@..\csr_data_pkg
@..\section_root_body

@update_tail