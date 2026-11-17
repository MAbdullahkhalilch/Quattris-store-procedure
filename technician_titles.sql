-- 1/3 technician_titles table + 9 titles. Run first.
-- Safe to re-run.

CREATE TABLE IF NOT EXISTS `technician_titles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT IGNORE INTO technician_titles (id, name) VALUES
(1,'Network/IT Engineer'),
(2,'Software'),
(3,'Network & Infrastructure'),
(4,'Desktop & End User Support'),
(5,'Server & Data Centre'),
(6,'AV & Collaboration'),
(7,'Cabling & Fibre'),
(8,'Wireless & Wi-Fi'),
(9,'Retail & POS Technology');

-- ---------------------------------------------------------------------
-- 2. title_skills (+ new rows in skills, looked up by NAME so ids can differ)

-- check: 9 rows
SELECT id, name FROM technician_titles ORDER BY id;
