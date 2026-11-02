DROP PROCEDURE IF EXISTS `getAllPartners`;

DELIMITER //

CREATE PROCEDURE `getAllPartners`(
	IN `pageno` INT,
	IN `pagesize` INT,
	IN `searchTerm` VARCHAR(255),
	IN `sortBy` VARCHAR(50),
	IN `sortOrder` VARCHAR(4),
	IN `statusFilter` VARCHAR(10),
	IN `serviceFilter` VARCHAR(20),
	IN `countryFilter` VARCHAR(20)
)
BEGIN
    -- page size can never be below 1 (avoids negative LIMIT errors)
    SET @pgsize = GREATEST(pagesize, 1);
    SET @offsets = (GREATEST(pageno, 1) - 1) * @pgsize;
    SET @searchTerm = CONCAT('%', searchTerm, '%');

    -- filters ('all' or empty = no filter)
    SET @statusFilter  = IF(statusFilter  IS NULL OR statusFilter  = '', 'all', statusFilter);
    SET @serviceFilter = IF(serviceFilter IS NULL OR serviceFilter = '', 'all', serviceFilter);
    SET @countryFilter = IF(countryFilter IS NULL OR countryFilter = '', 'all', countryFilter);

    SET @orderClause =
        CASE
            WHEN sortBy = 'company_contractor' THEN 'p.company_contractor'
            WHEN sortBy = 'main_contact' THEN 'p.main_contact'
            WHEN sortBy = 'email' THEN 'p.email'
            WHEN sortBy = 'country' THEN 'c2.name'
            WHEN sortBy = 'city' THEN 'c3.name'
            ELSE 'p.id'
        END;

    SET @orderDirection =
        CASE
            WHEN sortOrder = 'ASC' THEN 'ASC'
            ELSE 'DESC'
        END;

    SET @query = CONCAT('
        SELECT
            CEIL(COUNT(*) OVER () / @pgsize) AS totalPages,
            p.id,
            p.main_contact,
            p.company_contractor,
            p.email,
            p.website_link,
            p.whats_app,
            p.rate_id,
            p.partner_rate,
            p.additional_hour_rate,
            p.company_address,
            p.currency_id,
            p.services,
            p.countries_served,
            c2.name AS country,
            c2.id AS country_id,
            c3.name AS city,
            c3.id AS city_id,
            p.documents,
            cur.name AS currency_name,
            GROUP_CONCAT(DISTINCT c.name SEPARATOR ", ") AS countries_served_names,
            GROUP_CONCAT(DISTINCT s.name SEPARATOR ", ") AS services_names,
            p.phone,
            p.is_active
        FROM
            recruiters p
            LEFT JOIN countries c2 ON c2.id = p.country_id
            LEFT JOIN cities c3 ON c3.id = p.city_id
            LEFT JOIN currencies cur ON p.currency_id = cur.id
            LEFT JOIN countries c ON JSON_CONTAINS(p.countries_served, CONCAT(\'"\', c.id, \'"\'))
            LEFT JOIN services s ON JSON_CONTAINS(p.services, CONCAT(\'"\', s.id, \'"\'))
        WHERE
            p.deleted_at IS NULL
            AND (@statusFilter = \'all\' OR p.is_active = @statusFilter)
            AND (@countryFilter = \'all\' OR p.country_id = @countryFilter)
            AND (@serviceFilter = \'all\' OR JSON_CONTAINS(p.services, JSON_QUOTE(@serviceFilter)))
            ', IF(@searchTerm IS NOT NULL, 'AND (
					 p.company_contractor LIKE ? OR
                p.main_contact LIKE ? OR
                p.email LIKE ? OR
                c3.name LIKE ? OR
                c2.name LIKE ?
				)', ''), '
        GROUP BY
            p.id, p.main_contact, p.company_contractor, p.services, p.countries_served
        ORDER BY
            ', @orderClause, ' ', @orderDirection, '
        LIMIT ?, ?');

    PREPARE stmt FROM @query;
    EXECUTE stmt USING @searchTerm, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @offsets, @pgsize;
    DEALLOCATE PREPARE stmt;

END //

DELIMITER ;
