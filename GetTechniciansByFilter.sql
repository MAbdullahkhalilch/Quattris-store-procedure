DROP PROCEDURE IF EXISTS `GetTechniciansByFilter`;

DELIMITER //

CREATE PROCEDURE `GetTechniciansByFilter`(
	IN `minlat` DECIMAL(10, 6),
	IN `maxlat` DECIMAL(10, 6),
	IN `minlng` DECIMAL(10, 6),
	IN `maxlng` DECIMAL(10, 6),
	IN `radius` INT,
	IN `center_lat` DECIMAL(10, 6),
	IN `center_lng` DECIMAL(10, 6),
	IN `type` INT,
	IN `ids` TEXT
)
BEGIN
    DECLARE tech_ids TEXT;

    SET SESSION group_concat_max_len = 100000;

    IF type = 1 THEN
        SELECT GROUP_CONCAT(DISTINCT technician_id)
        INTO tech_ids
        FROM technician_certificates
        WHERE FIND_IN_SET(certificate_id, ids) > 0;

	 ELSEIF type = 2 THEN
        SELECT GROUP_CONCAT(DISTINCT technician_id)
        INTO tech_ids
        FROM technician_languages
        WHERE FIND_IN_SET(language_id, ids) > 0;

    ELSEIF TYPE = 3 THEN
        SELECT GROUP_CONCAT(DISTINCT technician_id)
        INTO tech_ids
        FROM technician_skills
        WHERE FIND_IN_SET(skill_id, ids) > 0;

    ELSEIF TYPE = 4 THEN
        SELECT GROUP_CONCAT(DISTINCT technician_id)
        INTO tech_ids
        FROM technician_skillsets
        WHERE FIND_IN_SET(skillset_id, ids) > 0;

	 ELSEIF TYPE = 5 THEN
        SELECT GROUP_CONCAT(DISTINCT technician_id)
        INTO tech_ids
        FROM technician_toolkits
        WHERE FIND_IN_SET(toolkit_id, ids) > 0;

    END IF;

    SELECT DISTINCT
    t.id,
    t.first_name,
    t.last_name,
    t.disability,
    t.email,
    t.skype,
    t.profile_link,
    t.whats_app,
    t.phone,
    c2.id AS country_id,
    c2.name AS country_name,
    c1.id AS city_id,
    c1.name AS city_name,
    t.address,
    t.near_by_areas,

    -- Get the names of nearby cities
    (SELECT CONCAT('[', GROUP_CONCAT(name), ']')
 	 	FROM cities
 	 	WHERE FIND_IN_SET(id, REPLACE(REPLACE(t.near_by_areas, '[', ''), ']', '')))
 	 	AS near_by_areas_names,

    t.work_permit,
    t.field_engineer_type,
    t.title,
    t.employment_status_id,
    t.availability,
    c3.id AS currency_id,
    c3.code AS currency_name,
    t.rate,
    t.is_skills_for_reporting,
    t.is_skillsets_for_reporting,
    t.is_certificates_for_reporting,
    t.is_toolkits_for_reporting,
    t.is_languages_for_reporting,
    t.feedback,
    t.status,
    CAST(t.latitude AS DECIMAL(10, 6)) AS latitude,
    CAST(t.longitude AS DECIMAL(10, 6)) AS longitude

	 FROM technicians t
	 LEFT JOIN cities c1 ON t.city_id = c1.id
	 LEFT JOIN countries c2 ON t.country_id = c2.id
	 LEFT JOIN currencies c3 ON t.currency_rate = c3.id
	 WHERE
    	(minlat IS NULL OR maxlat IS NULL OR (t.latitude BETWEEN minlat AND maxlat))
    AND (minlng IS NULL OR maxlng IS NULL OR (t.longitude BETWEEN minlng AND maxlng))
    AND (
        type IS NULL
        OR FIND_IN_SET(t.id, tech_ids) > 0
    )
    AND (
        radius IS NULL OR radius <= 0 OR
        (6371 * ACOS(
            COS(RADIANS(center_lat)) * COS(RADIANS(t.latitude)) *
            COS(RADIANS(t.longitude) - RADIANS(center_lng)) +
            SIN(RADIANS(center_lat)) * SIN(RADIANS(t.latitude))
        )) <= radius
    )
	 ORDER BY t.id;

END //

DELIMITER ;
