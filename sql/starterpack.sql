-- Run this once in your database.
-- Tracks which players have already claimed the package / vehicle.

CREATE TABLE IF NOT EXISTS `user_starterpack` (
    `identifier`       VARCHAR(60) NOT NULL,
    `package_claimed`  TINYINT(1)  NOT NULL DEFAULT 0,
    `vehicle_claimed`  TINYINT(1)  NOT NULL DEFAULT 0,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
