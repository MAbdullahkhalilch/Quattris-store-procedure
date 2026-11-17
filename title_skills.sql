-- 2/3 title_skills + new skills (run the WHOLE file in one go, temp table needs one session). Run second.
-- Safe to re-run.

CREATE TABLE IF NOT EXISTS `title_skills` (
  `title_id` int NOT NULL,
  `skill_id` int NOT NULL,
  PRIMARY KEY (`title_id`,`skill_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Network/IT Engineer (1) and Software (2) share the 7 current skills
-- (these ids already exist on the live DB: 1,2,3,4,6,7,82 - see check at the end)
INSERT IGNORE INTO title_skills (title_id, skill_id) VALUES
(1,1),(1,2),(1,3),(1,4),(1,6),(1,7),(1,82),
(2,1),(2,2),(2,3),(2,4),(2,6),(2,7),(2,82);

DROP TEMPORARY TABLE IF EXISTS tmp_title_skills;
CREATE TEMPORARY TABLE tmp_title_skills (
  title_id INT, name VARCHAR(100)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO tmp_title_skills (title_id, name) VALUES
(3,'Routers'),(3,'Switches'),(3,'Firewalls'),(3,'APs'),(3,'Rack & stack'),(3,'Patching'),(3,'Network troubleshooting'),(3,'Hardware replacement'),
(4,'Laptops'),(4,'Desktops'),(4,'Printers'),(4,'Peripherals'),(4,'Imaging'),(4,'Deskside support'),(4,'Migrations'),(4,'Break/fix'),
(5,'Servers'),(5,'Storage'),(5,'Rack & stack'),(5,'Component replacement'),(5,'Smart hands'),(5,'DC support'),(5,'Hardware troubleshooting'),
(6,'Displays'),(6,'Teams Rooms'),(6,'Zoom Rooms'),(6,'Cisco Webex'),(6,'Crestron'),(6,'Extron'),(6,'Poly'),(6,'Projectors'),(6,'Digital signage'),
(7,'Structured cabling'),(7,'Copper'),(7,'Fibre'),(7,'Termination'),(7,'Testing'),(7,'Tracing'),(7,'Splicing'),(7,'Patch panels'),
(8,'AP installation'),(8,'Wi-Fi troubleshooting'),(8,'Ekahau surveys'),(8,'Predictive/passive/active surveys'),(8,'Sidekick'),
(9,'POS'),(9,'Payment peripherals'),(9,'Scanners'),(9,'Printers'),(9,'Kiosks'),(9,'Digital signage'),(9,'Store technology');

-- add only the skills that do not exist yet
INSERT INTO skills (name, is_active)
SELECT DISTINCT t.name, 1 FROM tmp_title_skills t
WHERE NOT EXISTS (
  SELECT 1 FROM skills s
  WHERE s.name = t.name COLLATE utf8mb4_unicode_ci AND s.deleted_at IS NULL
);

-- link titles to skills using whatever ids the live DB gave them
INSERT IGNORE INTO title_skills (title_id, skill_id)
SELECT t.title_id, s.id FROM tmp_title_skills t
JOIN skills s ON s.name = t.name COLLATE utf8mb4_unicode_ci AND s.deleted_at IS NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_title_skills;

-- ---------------------------------------------------------------------
-- 3. update_technician procedure

-- check: 1:7, 2:7, 3:8, 4:8, 5:7, 6:9, 7:8, 8:5, 9:7
SELECT title_id, COUNT(*) AS skills FROM title_skills GROUP BY title_id ORDER BY title_id;
-- base skills must exist: 1,2,3,4,6,7,82
SELECT id, name FROM skills WHERE id IN (1,2,3,4,6,7,82) ORDER BY id;
