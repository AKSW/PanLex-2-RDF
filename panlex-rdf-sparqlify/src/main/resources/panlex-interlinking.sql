CREATE TABLE IF NOT EXISTS links_dbpedia (
    ex bigint NOT NULL 
    -- REFERENCES ex(ex)
    ,
    uri text NOT NULL,
    UNIQUE(ex, uri)
);

-- Ignore duplicate links
CREATE RULE "rl_links_dbpedia_ignore" AS ON INSERT TO "links_dbpedia"
  WHERE EXISTS(SELECT 1 FROM links_dbpedia
                WHERE (ex, uri)=(NEW.ex, NEW.uri))
  DO INSTEAD NOTHING;

COMMENT ON COLUMN links_dbpedia.ex IS 'The expression id';
COMMENT ON COLUMN links_dbpedia.uri IS 'The DBpedia URI';

CREATE INDEX idx_links_dbpedia_ex ON links_dbpedia(ex);
CREATE INDEX idx_links_dbpedia_uri ON links_dbpedia(uri);
