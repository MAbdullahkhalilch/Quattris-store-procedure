DROP PROCEDURE IF EXISTS `GetAllTicketByStatus`;
DELIMITER //
CREATE PROCEDURE `GetAllTicketByStatus`(
	IN `pageno` INT,
	IN `pagesize` INT,
	IN `searchTerm` VARCHAR(255),
	IN `sortBy` VARCHAR(50),
	IN `sortOrder` VARCHAR(4),
	IN `userId` INT,
	IN `startDate` DATE,
	IN `endDate` DATE,
	IN `statusCode` INT,
	IN `priorityFilter` VARCHAR(20)
)
BEGIN
	-- Calculate pagination offsets
    SET @offsets = (pageno - 1) * pagesize;
    SET @pgsize = pagesize;
    SET @userId = userId;

    -- Format search term
    SET @searchTerm = CONCAT('%', searchTerm, '%');

    -- Priority label search: Critical/High/Medium/Low match the user's label colour
    SET @priorityColor = CASE LOWER(TRIM(searchTerm))
        WHEN 'critical' THEN 'red'
        WHEN 'high' THEN 'orange'
        WHEN 'medium' THEN 'yellow'
        WHEN 'low' THEN 'blue'
        ELSE NULL
    END;

    -- Priority dropdown filter (red/orange/yellow/blue); empty = no filter
    SET @priorityFilterColor = NULLIF(TRIM(priorityFilter), '');

    -- Handle date parameters
    SET @startDate = IF(startDate IS NOT NULL, startDate, '1880-01-01');
    SET @endDate = IF(endDate IS NOT NULL, endDate, '2980-01-01');

    -- Determine the sort column based on input parameter sortBy
    SET @orderClause =
        CASE
            WHEN sortBy = 'ticket_ref_no' THEN 'ticket_ref_no'
            WHEN sortBy = 'client_name' THEN 'client_name'
            WHEN sortBy = 'ticket_execution_date' THEN 'ticket_execution_date'
            WHEN sortBy = 'schedule_time' THEN 'schedule_time'
            WHEN sortBy = 'pak_time' THEN 'pak_time'
            WHEN sortBy = 'technician_last_name' THEN 'technician_last_name'
            ELSE 't.id'  -- Default sort column is t.id
        END;

    -- Determine sort direction based on input parameter sortOrder
    SET @orderDirection =
        CASE
            WHEN sortOrder = 'ASC' THEN 'ASC'
            ELSE 'DESC'
        END;


	 -- ----------------- Query 1 (Fetch user ids for names) ------------------

    DROP TEMPORARY TABLE IF EXISTS temp_users;

    CREATE TEMPORARY TABLE temp_users (
        id INT NOT NULL PRIMARY KEY
    );

    SET @query1 = '
        INSERT IGNORE INTO temp_users (id)
        SELECT DISTINCT u.id
        FROM users u
        WHERE
            u.user_has_role IN (3, 4)
            AND (
                u.first_name LIKE ?
                OR u.last_name LIKE ?
                OR u.phone LIKE ?
                OR u.email LIKE ?
            )';

    PREPARE stmt1 FROM @query1;
    EXECUTE stmt1 USING @searchTerm, @searchTerm, @searchTerm, @searchTerm;
    DEALLOCATE PREPARE stmt1;


   -- ----------------- Query 2 (Fetch Ticket Details) ------------------

   DROP TEMPORARY TABLE IF EXISTS temp_tickets;

	CREATE TEMPORARY TABLE temp_tickets (
		id int NOT NULL AUTO_INCREMENT,
		ticket_ref_no varchar(255) DEFAULT NULL,
		ticket_status int DEFAULT NULL,
		ticket_deletion_status ENUM('0', '1', '2') DEFAULT '0',
		main_client varchar(255) DEFAULT NULL,
		end_client varchar(255) DEFAULT NULL,
		ticket_description text,
		ticket_execution_date date DEFAULT NULL,
		schedule_time time DEFAULT NULL,
		country varchar(255) DEFAULT NULL,
		city varchar(255) DEFAULT NULL,
		address text,
		fe_currency int DEFAULT NULL,
		fe_rate varchar(20) DEFAULT NULL,
		fe_cost_accommodation varchar(20) DEFAULT NULL,
		fe_travel_cost varchar(20) DEFAULT NULL,
		client_currency int DEFAULT NULL,
		client_rate varchar(20) DEFAULT NULL,
		default_client_rate varchar(20) DEFAULT NULL,
		client_material_accommodation_expenses varchar(20) DEFAULT NULL,
		client_travel_chargeable varchar(20) DEFAULT NULL,
		technician_id int DEFAULT NULL,
		sd_user_id text,
		assign_to text,
		fe_time_in time DEFAULT NULL,
		fe_time_out time DEFAULT NULL,
		total_time_on_site time DEFAULT NULL,
		pak_time datetime DEFAULT NULL,
		client_id int DEFAULT NULL,
		created_by int DEFAULT NULL,
		updated_by int DEFAULT NULL,
		is_pinned TINYINT(1) DEFAULT 0,
		border_color VARCHAR(20) DEFAULT NULL,

		-- Additional columns
		technician_first_name text,
		technician_last_name text,
		technician_title VARCHAR(100),
		technician_status VARCHAR(20),
		technician_availability text,
		technician_email text,
		technician_phone text,
		technician_whats_app text,
		technician_country_name VARCHAR(100),
		technician_city_name VARCHAR(100),
		technician_currency_name VARCHAR(20),
		client_name VARCHAR(100),
		end_client_name VARCHAR(100),
		main_client_name VARCHAR(100),
		country_name VARCHAR(100),
		fe_currency_name VARCHAR(20),
		currency_id INT,
		city_name VARCHAR(100),
		client_currency_name VARCHAR(100),
		created_by_name VARCHAR(100),
		created_by_last_name VARCHAR(100),
		updated_by_name VARCHAR(100),
		updated_by_last_name VARCHAR(100),
		project_id INT DEFAULT NULL,
		project_name VARCHAR(255) DEFAULT NULL,

		PRIMARY KEY (id),
		KEY updated_by (updated_by),
		KEY fe_currency (fe_currency),
		KEY technicians_id (technician_id) USING BTREE
	 );

	SET @query2 = CONCAT('
      INSERT INTO temp_tickets (
		id,
		ticket_ref_no,
		ticket_status,
		ticket_deletion_status,
		main_client,
		end_client,
		ticket_description,
		ticket_execution_date,
		schedule_time,
		country,
		city,
		address,
		fe_currency,
		fe_rate,
		fe_cost_accommodation,
		fe_travel_cost,
		client_currency,
		client_rate,
		client_material_accommodation_expenses,
		client_travel_chargeable,
		technician_id,
		sd_user_id,
		assign_to,
		fe_time_in,
		fe_time_out,
		total_time_on_site,
		pak_time,
		client_id,
		created_by,
		updated_by,
		is_pinned,
		border_color,
		technician_first_name,
		technician_last_name,
		technician_title,
		technician_status,
		technician_availability,
		technician_email,
		technician_phone,
		technician_whats_app,
		technician_country_name,
		technician_city_name,
		technician_currency_name,
		default_client_rate,
		client_name,
		main_client_name,
		end_client_name,
		country_name,
		city_name,
		fe_currency_name,
		client_currency_name,
		created_by_name,
		created_by_last_name,
		updated_by_name,
		updated_by_last_name,
		project_id,
		project_name
	)
    SELECT
		t.id,
		t.ticket_ref_no,
		t.ticket_status,
		t.ticket_deletion_status,
		t.main_client,
		t.end_client,
		t.ticket_description,
		t.ticket_execution_date,
		t.schedule_time,
		t.country,
		t.city,
		t.address,
		t.fe_currency,
		t.fe_rate,
		t.fe_cost_accommodation,
		t.fe_travel_cost,
		t.client_currency,
		t.client_rate,
		t.client_material_accommodation_expenses,
		t.client_travel_chargeable,
		t.technician_id,
		t.sd_user_id,
		t.assign_to,
		t.fe_time_in,
		t.fe_time_out,
		t.total_time_on_site,
		t.pak_time,
		t.client_id,
		t.created_by,
		t.updated_by,
		utp.is_pinned,
		COALESCE(utp.border_color, ''default_color'') AS border_color,

		tech.first_name AS technician_first_name,
		tech.last_name AS technician_last_name,
		tech.title AS technician_title,
		tech.status AS technician_status,
		tech.availability AS technician_availability,
		tech.email AS technician_email,
		tech.phone AS technician_phone,
		tech.whats_app AS technician_whats_app,
		techCountry.name AS technician_country_name,
		techCity.name AS technician_city_name,
		techCurrency.code AS technician_currency_name,

		c.client_rate AS default_client_rate,
		c.name AS client_name,
		mainClient.name AS main_client_name,
		endClient.name AS end_client_name,

		country.name AS country_name,
		city.name AS city_name,
		currency.code AS fe_currency_name,
		clientCurrency.name AS client_currency_name,
		u.first_name AS created_by_name,
		u.last_name AS created_by_last_name,
		u1.first_name AS updated_by_name,
		u1.last_name AS updated_by_last_name,
		t.project_id,
		proj.name AS project_name
    FROM tickets t
    LEFT JOIN technicians tech
        ON t.technician_id = tech.id
    LEFT JOIN new_clients_info c
        ON t.client_id = c.id
    LEFT JOIN new_clients_info endClient
        ON t.end_client = endClient.id
    LEFT JOIN new_clients_info mainClient
        ON t.main_client = mainClient.id
    LEFT JOIN countries country
        ON t.country = country.id
    LEFT JOIN cities city
        ON t.city = city.id
    LEFT JOIN currencies currency
        ON t.fe_currency = currency.id
    LEFT JOIN currencies clientCurrency
        ON t.client_currency = clientCurrency.id
    LEFT JOIN countries techCountry
        ON tech.country_id = techCountry.id
    LEFT JOIN cities techCity
        ON tech.city_id = techCity.id
    LEFT JOIN currencies techCurrency
        ON tech.currency_rate = techCurrency.id
    LEFT JOIN users u
        ON t.created_by = u.id
    LEFT JOIN users u1
        ON t.updated_by = u1.id
    LEFT JOIN projects proj
        ON t.project_id = proj.id
    LEFT JOIN user_ticket_preference utp
        ON utp.ticket_id = t.id
        AND utp.user_id = ?
    WHERE
        (t.sd_user_id IS NOT NULL OR t.assign_to IS NOT NULL OR t.technician_id IS NOT NULL)
        AND t.deleted_at IS NULL AND t.ticket_deletion_status != ''2''
        AND t.ticket_status = ', statusCode, '
        AND (
               t.ticket_ref_no LIKE ?
               OR c.name LIKE ?
               OR t.schedule_time LIKE ?
               OR t.ticket_execution_date LIKE ?
               OR t.pak_time LIKE ?
               OR tech.last_name LIKE ?
               OR CAST(utp.border_color AS BINARY) = CAST(@priorityColor AS BINARY)
               OR EXISTS (
						SELECT 1
						FROM temp_users tu
						WHERE
							REPLACE(REPLACE(t.sd_user_id, ''['', ''''), '']'', '''')
							REGEXP CONCAT(''(^|,)'', tu.id, ''(,|$)'')
						OR
							REPLACE(REPLACE(t.assign_to, ''['', ''''), '']'', '''')
							REGEXP CONCAT(''(^|,)'', tu.id, ''(,|$)'')
					)
           )',
        ' AND (@priorityFilterColor IS NULL OR CAST(utp.border_color AS BINARY) = CAST(@priorityFilterColor AS BINARY)) ',
        ' AND DATE(t.ticket_execution_date) >= ? ',
        ' AND DATE(t.ticket_execution_date) <= ? ',
        ' GROUP BY
            t.id, tech.first_name, tech.last_name, tech.title, tech.email, tech.phone,
            tech.whats_app, tech.status, tech.disability,
            c.name, endClient.name, mainClient.name, country.name, currency.code,
            c.currency_id, city.name, clientCurrency.name, t.ticket_ref_no,
            utp.border_color, utp.is_pinned, proj.name
        ORDER BY ', @orderClause, ' ', @orderDirection, '
           LIMIT ?, ?');

    PREPARE stmt2 FROM @query2;
    EXECUTE stmt2 USING @userId, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @startDate, @endDate, @offsets, @pgsize;
    DEALLOCATE PREPARE stmt2;

	 SELECT * from temp_tickets;

	 -- ---------------------- Query 3 (SD/IT names) ------------------------
    SET @queryNames = CONCAT('
    SELECT
        t.id,
        (SELECT GROUP_CONCAT(DISTINCT su.id ORDER BY su.id SEPARATOR ", ")
         FROM users su
         WHERE JSON_VALID(t.sd_user_id)
           AND JSON_LENGTH(t.sd_user_id) > 0
           AND JSON_CONTAINS(t.sd_user_id, CAST(su.id AS JSON))
           ) AS sd_user_ids,
        (SELECT GROUP_CONCAT(DISTINCT su.last_name ORDER BY su.last_name SEPARATOR ", ")
         FROM users su
         WHERE JSON_VALID(t.sd_user_id)
           AND JSON_LENGTH(t.sd_user_id) > 0
           AND JSON_CONTAINS(t.sd_user_id, CAST(su.id AS JSON))
           ) AS sd_user_names,
        (SELECT GROUP_CONCAT(DISTINCT au.id ORDER BY au.id SEPARATOR ", ")
         FROM users au
         WHERE JSON_VALID(t.assign_to)
           AND JSON_LENGTH(t.assign_to) > 0
           AND JSON_CONTAINS(t.assign_to, CAST(au.id AS JSON))
           ) AS assign_it_ids,
        (SELECT GROUP_CONCAT(DISTINCT au.last_name ORDER BY au.last_name SEPARATOR ", ")
         FROM users au
         WHERE JSON_VALID(t.assign_to)
           AND JSON_LENGTH(t.assign_to) > 0
           AND JSON_CONTAINS(t.assign_to, CAST(au.id AS JSON))
           ) AS assign_it_names

    FROM
        temp_tickets t
		  ');

    PREPARE stmtNames FROM @queryNames;
	 EXECUTE stmtNames;
    DEALLOCATE PREPARE stmtNames;

	-- ---------------------- Query 4 (Total Pages) ------------------------
	 SET @status = statusCode;

	 SET @countQuery = CONCAT('
	    SELECT ( COUNT(*) / @pgsize ) + 1 AS total_pages
			FROM tickets t
			LEFT JOIN new_clients_info c
        		ON t.client_id = c.id
        	LEFT JOIN technicians tech
        		ON t.technician_id = tech.id
        	LEFT JOIN user_ticket_preference utp
        		ON utp.ticket_id = t.id AND utp.user_id = @userId
			WHERE
				(t.sd_user_id IS NOT NULL OR t.assign_to IS NOT NULL OR t.technician_id IS NOT NULL)
				AND t.deleted_at IS NULL AND t.ticket_deletion_status != ''2''
				AND t.ticket_status = ?
				AND (
                t.ticket_ref_no LIKE ?
                OR c.name LIKE ?
                OR t.schedule_time LIKE ?
                OR t.ticket_execution_date LIKE ?
                OR t.pak_time LIKE ?
                OR tech.last_name LIKE ?
                OR CAST(utp.border_color AS BINARY) = CAST(@priorityColor AS BINARY)
                OR EXISTS (
						SELECT 1
						FROM temp_users tu
						WHERE
							REPLACE(REPLACE(t.sd_user_id, ''['', ''''), '']'', '''')
							REGEXP CONCAT(''(^|,)'', tu.id, ''(,|$)'')
						OR
							REPLACE(REPLACE(t.assign_to, ''['', ''''), '']'', '''')
							REGEXP CONCAT(''(^|,)'', tu.id, ''(,|$)'')
					)
                )',
				' AND (@priorityFilterColor IS NULL OR CAST(utp.border_color AS BINARY) = CAST(@priorityFilterColor AS BINARY)) ',
				' AND DATE(t.ticket_execution_date) >= ? ',
				' AND DATE(t.ticket_execution_date) <= ? '
			);

    PREPARE countStmt FROM @countQuery;
	 EXECUTE countStmt USING @status, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @startDate, @endDate;
    DEALLOCATE PREPARE countStmt;

	 -- ---------------------- Query 5 (Ticket Count) ------------------------
	 SET @statusCountQuery = CONCAT('
    SELECT s.id, s.code, COUNT(*) AS ticket_count
    FROM tickets t
    	JOIN status s ON s.id = t.ticket_status
    	LEFT JOIN new_clients_info c
    	  ON t.client_id = c.id
    	LEFT JOIN technicians tech
    	  ON t.technician_id = tech.id
    	LEFT JOIN user_ticket_preference utp
    	  ON utp.ticket_id = t.id AND utp.user_id = @userId
    WHERE
		(t.sd_user_id IS NOT NULL OR t.assign_to IS NOT NULL OR t.technician_id IS NOT NULL)
		AND t.deleted_at IS NULL AND t.ticket_deletion_status != ''2''
		AND (
              t.ticket_ref_no LIKE ?
              OR c.name LIKE ?
              OR t.schedule_time LIKE ?
              OR t.ticket_execution_date LIKE ?
              OR t.pak_time LIKE ?
              OR tech.last_name LIKE ?
              OR CAST(utp.border_color AS BINARY) = CAST(@priorityColor AS BINARY)
              OR EXISTS (
				SELECT 1
				FROM temp_users tu
				WHERE
					REPLACE(REPLACE(t.sd_user_id, ''['', ''''), '']'', '''')
					REGEXP CONCAT(''(^|,)'', tu.id, ''(,|$)'')
				OR
					REPLACE(REPLACE(t.assign_to, ''['', ''''), '']'', '''')
					REGEXP CONCAT(''(^|,)'', tu.id, ''(,|$)'')
			)
              )',
		' AND (@priorityFilterColor IS NULL OR CAST(utp.border_color AS BINARY) = CAST(@priorityFilterColor AS BINARY)) ',
		' AND DATE(t.ticket_execution_date) >= ? ',
		' AND DATE(t.ticket_execution_date) <= ? ',
		' GROUP BY s.id, s.code '
	);

	PREPARE statusCountStmt FROM @statusCountQuery;
	EXECUTE statusCountStmt USING @searchTerm, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @searchTerm, @startDate, @endDate;
	DEALLOCATE PREPARE statusCountStmt;

END//
DELIMITER ;
