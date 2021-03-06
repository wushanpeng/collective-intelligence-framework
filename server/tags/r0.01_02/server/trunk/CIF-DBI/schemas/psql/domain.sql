DROP TABLE IF EXISTS domain CASCADE;

CREATE TABLE domain (
    id BIGSERIAL PRIMARY KEY NOT NULL,
    uuid uuid REFERENCES message(uuid) ON DELETE CASCADE NOT NULL,
    description text,
    address text,
    type VARCHAR(10),
    rdata varchar(255),
    cidr inet,
    asn int,
    asn_desc text, 
    cc varchar(5),
    rir varchar(10),
    class VARCHAR(10),
    ttl int,
    whois text,
    impact VARCHAR(140),
    confidence REAL,
    source uuid NOT NULL,
    alternativeid text,
    alternativeid_restriction restriction not null default 'private',
    severity severity,
    restriction restriction not null default 'private',
    detecttime timestamp with time zone DEFAULT NOW(),
    created timestamp with time zone DEFAULT NOW(),
    UNIQUE (uuid)
);

create view v_domain as select address,rdata,type,ttl,impact,severity,detecttime,created from domain;

CREATE TABLE domain_whitelist() INHERITS (domain);
ALTER TABLE domain_whitelist ADD PRIMARY KEY (id);
ALTER TABLE domain_whitelist ADD CONSTRAINT whitelist_domain_uuid_fkey FOREIGN KEY (uuid) REFERENCES message(uuid) ON DELETE CASCADE;
ALTER TABLE domain_whitelist ADD UNIQUE(uuid);

CREATE TABLE domain_fastflux() INHERITS (domain);
ALTER TABLE domain_fastflux ADD PRIMARY KEY (id);
ALTER TABLE domain_fastflux ADD CONSTRAINT domain_fastflux_uuid_fkey FOREIGN KEY (uuid) REFERENCES message(uuid) ON DELETE CASCADE;
ALTER TABLE domain_fastflux ADD UNIQUE(uuid);

CREATE TABLE domain_nameserver() INHERITS (domain);
ALTER TABLE domain_nameserver ADD PRIMARY KEY (id);
ALTER TABLE domain_nameserver ADD CONSTRAINT domain_nameserver_uuid_fkey FOREIGN KEY (uuid) REFERENCES message(uuid) ON DELETE CASCADE;
ALTER TABLE domain_nameserver ADD UNIQUE(uuid);

CREATE TABLE domain_malware() INHERITS (domain);
ALTER TABLE domain_malware ADD PRIMARY KEY (id);
ALTER TABLE domain_malware ADD CONSTRAINT domain_malware_uuid_fkey FOREIGN KEY (uuid) REFERENCES message(uuid) ON DELETE CASCADE;
ALTER TABLE domain_malware ADD UNIQUE(uuid);

CREATE TABLE domain_botnet() INHERITS (domain);
ALTER TABLE domain_botnet ADD PRIMARY KEY (id);
ALTER TABLE domain_botnet ADD CONSTRAINT domain_botnet_uuid_fkey FOREIGN KEY (uuid) REFERENCES message(uuid) ON DELETE CASCADE;
ALTER TABLE domain_botnet ADD UNIQUE(uuid);

CREATE TABLE domain_passivedns() INHERITS (domain);
ALTER TABLE domain_passivedns ADD PRIMARY KEY (id);
ALTER TABLE domain_passivedns ADD CONSTRAINT domain_passivedns_uuid_fkey FOREIGN KEY (uuid) REFERENCES message(uuid) ON DELETE CASCADE;
ALTER TABLE domain_passivedns ADD UNIQUE(uuid);

CREATE TABLE domain_search() INHERITS (domain);
ALTER TABLE domain_search ADD PRIMARY KEY (id);
ALTER TABLE domain_search ADD CONSTRAINT domain_search_uuid_fkey FOREIGN KEY (uuid) REFERENCES message(uuid) ON DELETE CASCADE;
ALTER TABLE domain_search ADD UNIQUE(uuid);
