SET default_tablespace = 'index';
DROP TABLE IF EXISTS email CASCADE;
CREATE TABLE email (
    id BIGSERIAL PRIMARY KEY NOT NULL,
    uuid uuid NOT NULL,
    address text,
    source uuid,
    guid uuid,
    confidence real,
    severity severity,
    restriction restriction not null default 'private',
    detecttime timestamp with time zone DEFAULT NOW(),
    created timestamp with time zone DEFAULT NOW(),
    UNIQUE (uuid)
);

CREATE TABLE email_search() INHERITS (email);
ALTER TABLE email_search ADD PRIMARY KEY (id);
-- ALTER TABLE email_search ADD CONSTRAINT email_search_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE email_search ADD UNIQUE(uuid);

CREATE TABLE email_phishing() INHERITS (email);
ALTER TABLE email_phishing ADD PRIMARY KEY (id);
-- ALTER TABLE email_phishing ADD CONSTRAINT email_phishing_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE email_phishing ADD UNIQUE(uuid);

CREATE TABLE email_registrant() INHERITS (email);
ALTER TABLE email_registrant ADD PRIMARY KEY (id);
-- ALTER TABLE email_registrant ADD CONSTRAINT email_registrant_uuid_fkey FOREIGN KEY (uuid) REFERENCES archive(uuid) ON DELETE CASCADE;
ALTER TABLE email_registrant ADD UNIQUE(uuid);
