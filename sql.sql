

CREATE TABLE IF NOT EXISTS `bug_reports` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `player_id` varchar(50) DEFAULT NULL,
    `player_name` varchar(100) DEFAULT NULL,
    `title` varchar(255) NOT NULL,
    `category` varchar(50) NOT NULL,
    `description` text NOT NULL,
    `steps` text DEFAULT NULL,
    `priority` varchar(20) DEFAULT 'medium',
    `status` varchar(20) DEFAULT 'pending',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX `idx_player_id` ON `bug_reports` (`player_id`);
CREATE INDEX `idx_status` ON `bug_reports` (`status`);
CREATE INDEX `idx_priority` ON `bug_reports` (`priority`);
CREATE INDEX `idx_created_at` ON `bug_reports` (`created_at`);
