define version=2688
@update_header

DECLARE
    PROCEDURE add_param(
        in_alert_type_id        IN csr.std_alert_type.std_alert_type_id%TYPE,
        in_name                 IN csr.std_alert_type_param.field_name%TYPE,
        in_description          IN csr.std_alert_type_param.description%TYPE,
        in_help_text            IN csr.std_alert_type_param.help_text%TYPE,
        in_repeats              IN csr.std_alert_type_param.repeats%TYPE)
    AS
    BEGIN
        INSERT INTO csr.std_alert_type_param (std_alert_type_id, field_name, description, help_text, repeats, display_pos)
        VALUES (
            in_alert_type_id,
            in_name, 
            in_description,
            in_help_text,
            in_repeats,
            (SELECT MAX(display_pos) + 1 
               FROM csr.std_alert_type_param 
              WHERE std_alert_type_id = in_alert_type_id)
        );
    END;
    PROCEDURE add_regions_param(
        in_alert_type_id in csr.std_alert_type.std_alert_type_id%TYPE,
        in_repeats in csr.std_alert_type_param.repeats%TYPE)
    AS
    BEGIN
        add_param(
            in_alert_type_id, 
            'REGION_NAMES',
            'Region names',
            'A comma separated list of the regions included on the delegation.',
            in_repeats);
    END;
BEGIN
    -- CLEAN
    --DELETE FROM csr.std_alert_type_param 
    -- WHERE (field_name = 'REGION_DESCRIPTION' AND std_alert_type_id = 18)
    --    OR (field_name = 'REGION_NAMES'
    --            AND std_alert_type_id IN (
    --                5, 3, 7, 30, 39, 29, 58, 59, 
    --                2, 8, 68, 4, 62, 57
    --            )
    --        );

    add_regions_param(5, 1);   -- Delegation data reminder 
    add_regions_param(3, 1);   -- Delegation data overdue
    add_regions_param(7, 1);   -- Delegation terminated
    add_regions_param(30, 1);  -- Delegation state changed (batched)
    add_regions_param(39, 0);  -- Delegation data changed by other user.
    add_regions_param(29, 0);  -- Delegation data change request 
    add_regions_param(58, 0);  -- Delegation data change request approved 
    add_regions_param(59, 0);  -- Delegation data change request rejected 
    add_regions_param(2, 1);   -- New delegation
    add_regions_param(8, 1);   -- Delegation plan - forms updated
    add_regions_param(68, 1);  -- Delegation plan - new forms created
    add_regions_param(4, 0);   -- Delegation state changed 
    add_regions_param(62, 0);  -- Delegation edited
    add_regions_param(57, 0);  -- Delegation returned 

    -- Issue summary
    add_param(18, 'REGION_DESCRIPTION', 'Region', 'The region associated with the issue, if any.', 1); 
END;
/

@../delegation_pkg
@../delegation_body
@../sheet_body
@../issue_body

@update_tail
