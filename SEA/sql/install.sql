CREATE TABLE IF NOT EXISTS sea_forensics_profiles (
    identifier VARCHAR(64) NOT NULL,
    blood_type VARCHAR(3) DEFAULT NULL,
    dna_hash VARCHAR(64) DEFAULT NULL,
    fingerprint_hash VARCHAR(64) DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (identifier)
);

CREATE TABLE IF NOT EXISTS sea_forensics_samples (
    id INT NOT NULL AUTO_INCREMENT,
    sample_type VARCHAR(16) NOT NULL,
    dna_hash VARCHAR(64) DEFAULT NULL,
    fingerprint_hash VARCHAR(64) DEFAULT NULL,
    blood_type VARCHAR(3) DEFAULT NULL,
    collected_by VARCHAR(64) NOT NULL,
    collected_from VARCHAR(64) DEFAULT NULL,
    collected_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id)
);
