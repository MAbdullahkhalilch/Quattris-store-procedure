-- 3/3 update_technician procedure. Run third.
-- Safe to re-run.

DROP PROCEDURE IF EXISTS update_technician;

DELIMITER //

CREATE PROCEDURE update_technician(
    IN p_id BIGINT UNSIGNED,
    IN p_first_name VARCHAR(255), IN p_last_name VARCHAR(255), IN p_disability BOOLEAN,
    IN p_email VARCHAR(255), IN p_skype VARCHAR(255), IN p_profile_link TEXT,
    IN p_whats_app VARCHAR(255), IN p_phone VARCHAR(255), IN p_country_id INT, IN p_city_id INT,
    IN p_address TEXT, IN p_near_by_areas TEXT, IN p_work_permit TEXT,
    IN p_field_engineer_type VARCHAR(50), IN p_recruiter_id INT, IN p_title VARCHAR(255),
    IN p_employment_status_id INT, IN p_availability VARCHAR(255), IN p_currency_id INT,
    IN p_currency_rate VARCHAR(255), IN p_selected_skills JSON, IN p_selected_skillsets JSON,
    IN p_selected_certificates JSON, IN p_selected_toolkits JSON, IN p_selected_languages JSON,
    IN p_feedback TEXT, IN p_is_skills_for_reporting INT, IN p_is_skillset_for_reporting INT,
    IN p_is_certificates_for_reporting INT, IN p_is_toolkits_for_reporting INT,
    IN p_is_languages_for_reporting INT, IN p_latitude DECIMAL(10,8), IN p_longitude DECIMAL(11,8),
    IN p_created_by INT
)
BEGIN
    UPDATE technicians SET
        first_name = p_first_name, last_name = p_last_name, disability = p_disability,
        email = p_email, skype = NULLIF(p_skype, ''), profile_link = NULLIF(p_profile_link, ''),
        whats_app = p_whats_app, phone = p_phone, country_id = p_country_id, city_id = p_city_id,
        address = NULLIF(p_address, ''), near_by_areas = NULLIF(p_near_by_areas, ''),
        work_permit = NULLIF(p_work_permit, ''), field_engineer_type = p_field_engineer_type,
        recruiter_id = NULLIF(p_recruiter_id, 0), title = p_title,
        employment_status_id = p_employment_status_id, availability = p_availability,
        currency_rate = p_currency_id, rate = NULLIF(p_currency_rate, ''),
        is_skills_for_reporting = p_is_skills_for_reporting,
        is_skillsets_for_reporting = p_is_skillset_for_reporting,
        is_certificates_for_reporting = p_is_certificates_for_reporting,
        is_toolkits_for_reporting = p_is_toolkits_for_reporting,
        is_languages_for_reporting = p_is_languages_for_reporting,
        latitude = p_latitude, longitude = p_longitude, feedback = p_feedback
    WHERE id = p_id;

    DELETE FROM technician_skills       WHERE technician_id = p_id;
    DELETE FROM technician_skillsets    WHERE technician_id = p_id;
    DELETE FROM technician_certificates WHERE technician_id = p_id;
    DELETE FROM technician_toolkits     WHERE technician_id = p_id;
    DELETE FROM technician_languages    WHERE technician_id = p_id;

    IF COALESCE(JSON_LENGTH(p_selected_skills), 0) > 0 THEN
        INSERT INTO technician_skills (technician_id, skill_id, skill_level)
        SELECT p_id, Skill_ID, Skill_Value FROM JSON_TABLE(p_selected_skills, "$[*]"
            COLUMNS (Skill_ID INT PATH "$.id", Skill_Value VARCHAR(255) PATH "$.level")) AS s;
    END IF;
    IF COALESCE(JSON_LENGTH(p_selected_languages), 0) > 0 THEN
        INSERT INTO technician_languages (technician_id, language_id, language_level)
        SELECT p_id, Language_ID, Language_Level FROM JSON_TABLE(p_selected_languages, "$[*]"
            COLUMNS (Language_ID INT PATH "$.id", Language_Level VARCHAR(255) PATH "$.level")) AS l;
    END IF;
    IF COALESCE(JSON_LENGTH(p_selected_skillsets), 0) > 0 THEN
        INSERT INTO technician_skillsets (technician_id, skillset_id)
        SELECT p_id, Skillset_ID FROM JSON_TABLE(p_selected_skillsets, "$[*]"
            COLUMNS (Skillset_ID INT PATH "$.id")) AS ss;
    END IF;
    IF COALESCE(JSON_LENGTH(p_selected_toolkits), 0) > 0 THEN
        INSERT INTO technician_toolkits (technician_id, toolkit_id)
        SELECT p_id, Toolkit_ID FROM JSON_TABLE(p_selected_toolkits, "$[*]"
            COLUMNS (Toolkit_ID INT PATH "$.id")) AS t;
    END IF;
    IF COALESCE(JSON_LENGTH(p_selected_certificates), 0) > 0 THEN
        INSERT INTO technician_certificates (technician_id, certificate_id)
        SELECT p_id, Certificate_ID FROM JSON_TABLE(p_selected_certificates, "$[*]"
            COLUMNS (Certificate_ID INT PATH "$.id")) AS c;
    END IF;
END//

DELIMITER ;

-- check: 1 row
SHOW PROCEDURE STATUS WHERE Name = 'update_technician';
