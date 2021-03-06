SET default_tablespace = 'index';
DROP TABLE IF EXISTS domain CASCADE;
CREATE TABLE domain (
    id BIGSERIAL PRIMARY KEY NOT NULL,
    uuid uuid REFERENCES archive(uuid) ON DELETE CASCADE NOT NULL,
    address text,
    md5 varchar(32),
    sha1 varchar(40),
    type VARCHAR(10),
    confidence REAL,
    source uuid NOT NULL,
    guid uuid,
    severity severity,
    restriction restriction not null default 'private',
    detecttime timestamp with time zone DEFAULT NOW(),
    CREATEd timestamp with time zone DEFAULT NOW(),
    UNIQUE (uuid,address)
);

CREATE TABLE domain_whitelist() INHERITS (domain);
ALTER TABLE domain_whitelist ADD PRIMARY KEY (id);
ALTER TABLE domain_whitelist ADD CONSTRAINT domain_whitelist_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_whitelist ADD UNIQUE(uuid,address);

CREATE TABLE domain_fastflux() INHERITS (domain);
ALTER TABLE domain_fastflux ADD PRIMARY KEY (id);
ALTER TABLE domain_fastflux ADD CONSTRAINT domain_fastflux_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_fastflux ADD UNIQUE(uuid,address);

CREATE TABLE domain_nameserver() INHERITS (domain);
ALTER TABLE domain_nameserver ADD PRIMARY KEY (id);
ALTER TABLE domain_nameserver ADD CONSTRAINT domain_nameserver_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_nameserver ADD UNIQUE(uuid,address);

CREATE TABLE domain_malware() INHERITS (domain);
ALTER TABLE domain_malware ADD PRIMARY KEY (id);
ALTER TABLE domain_malware ADD CONSTRAINT domain_malware_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_malware ADD UNIQUE(uuid,address);

CREATE TABLE domain_botnet() INHERITS (domain);
ALTER TABLE domain_botnet ADD PRIMARY KEY (id);
ALTER TABLE domain_botnet ADD CONSTRAINT domain_botnet_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_botnet ADD UNIQUE(uuid,address);

CREATE TABLE domain_passivedns() INHERITS (domain);
ALTER TABLE domain_passivedns ADD PRIMARY KEY (id);
ALTER TABLE domain_passivedns ADD CONSTRAINT domain_passivedns_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_passivedns ADD UNIQUE(uuid,address);

CREATE TABLE domain_search() INHERITS (domain);
ALTER TABLE domain_search ADD PRIMARY KEY (id);
ALTER TABLE domain_search ADD CONSTRAINT domain_search_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_search ADD UNIQUE(uuid,address);

CREATE TABLE domain_phishing() INHERITS (domain);
ALTER TABLE domain_phishing ADD PRIMARY KEY (id);
ALTER TABLE domain_phishing ADD CONSTRAINT domain_phishing_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_phishing ADD UNIQUE(uuid,address);

CREATE TABLE domain_suspicious() INHERITS (domain);
ALTER TABLE domain_suspicious ADD PRIMARY KEY (id);
ALTER TABLE domain_suspicious ADD CONSTRAINT domain_suspicious_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE domain_suspicious ADD UNIQUE(uuid,address);
