SET default_tablespace = 'archive';
DROP TABLE IF EXISTS archive CASCADE;
DROP TYPE IF EXISTS severity;
DROP TYPE IF EXISTS restriction;
CREATE TYPE restriction AS ENUM ('public','need-to-know','private','default');
CREATE TYPE severity AS ENUM ('null','low','medium','high');

CREATE TABLE archive (
    id BIGSERIAL NOT NULL,
    uuid uuid NOT NULL,
    source uuid,
    guid uuid,
    format text, -- IODEF, MetaSharing, IRC, Email, etc...
    description text,
    restriction restriction default 'private',
    created timestamp with time zone DEFAULT NOW(),
    data text not null
);
SET default_tablespace = 'index';
ALTER TABLE archive ADD PRIMARY KEY (id);
ALTER TABLE archive ADD UNIQUE(uuid);
