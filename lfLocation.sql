CREATE TABLE IF NOT EXISTS `rented_vehicles` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `plate` VARCHAR(10) NOT NULL,
    `rented_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `identifier` (`identifier`),
    INDEX `plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rental_history` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `model` VARCHAR(50) DEFAULT NULL,
    `plate` VARCHAR(10) DEFAULT NULL,
    `action` VARCHAR(20) DEFAULT NULL COMMENT 'rented, returned, deleted',
    `price` INT(11) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `identifier` (`identifier`),
    INDEX `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

