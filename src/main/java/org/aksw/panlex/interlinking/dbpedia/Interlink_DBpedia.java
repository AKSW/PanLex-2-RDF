package org.aksw.panlex.interlinking.dbpedia;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.sql.Connection;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.aksw.commons.jena.reader.NTripleIterator;
import org.aksw.commons.util.MapReader;
import org.aksw.commons.util.compress.MetaBZip2CompressorInputStream;
import org.apache.commons.collections15.BidiMap;
import org.apache.commons.collections15.bidimap.DualHashBidiMap;
import org.postgresql.jdbc2.optional.SimpleDataSource;

import com.google.common.base.Joiner;
import com.google.common.collect.HashMultimap;
import com.google.common.collect.Multimap;
import com.hp.hpl.jena.graph.Node;
import com.hp.hpl.jena.graph.Triple;
import com.ibm.icu.text.Normalizer;

class LangDataset {
	private String fileName;
	private String langCode;
	
	public LangDataset(String fileName, String langCode) {
		this.fileName = fileName;
		this.langCode = langCode;
	}

	public String getLangCode() {
		return langCode;
	}

	public void setLangCode(String langCode) {
		this.langCode = langCode;
	}

	public String getFileName() {
		return fileName;
	}

	public void setFileName(String fileName) {
		this.fileName = fileName;
	}
	
	public static LangDataset create(String fileName, String langCode) {
		LangDataset result = new LangDataset(fileName, langCode);
		return result;
	}

	@Override
	public String toString() {
		return "LangDataset [fileName=" + fileName + ", langCode=" + langCode
				+ "]";
	}
}

class Label {
	private String uri;
	private String original;
	private String normalized;
	public Label(String uri, String original, String normalized) {
		super();
		this.uri = uri;
		this.original = original;
		this.normalized = normalized;
	}
	public String getUri() {
		return uri;
	}
	public void setUri(String uri) {
		this.uri = uri;
	}

	public String getOriginal() {
		return original;
	}
	public void setOriginal(String original) {
		this.original = original;
	}
	public String getNormalized() {
		return normalized;
	}
	public void setNormalized(String normalized) {
		this.normalized = normalized;
	}

}

public class Interlink_DBpedia {

	public static String normalize(String raw) {
		String s = Normalizer.normalize(raw, Normalizer.NFKD);
		s = s.toLowerCase();
		s = s.replaceAll("(\\s|,|\\.|/|\\\\|\\(|\\)|'|\"|-)+", "");
		
		return s;
	}
	
	public static void main(String[] args)
		throws Exception
	{
		
		SimpleDataSource ds = new SimpleDataSource();
		ds.setServerName("localhost");
		ds.setDatabaseName("panlex");
		ds.setUser("postgres");
		ds.setPassword("postgres");

		Connection conn = ds.getConnection();
		
		//PrintStream out = System.out;
		
		
		Map<String, String> datasetToLang = MapReader.readFile(new File("src/main/resources/datasets.tsv"));
		List<LangDataset> fileList = new ArrayList<LangDataset>();
		String basePath = "var/cache/datasets/dbpedia/3.8/";
		for(Entry<String, String> entry : datasetToLang.entrySet()) {
			String name = entry.getKey();
			String lang = entry.getValue();
			
			LangDataset dataset = LangDataset.create(basePath + name, lang);
			fileList.add(dataset);			
		}	
		
		Map<String, String> tmp = MapReader.readFile(new File("src/main/resources/iso-639-mapping.tsv"));
		BidiMap<String, String> iso639_1_to_3 = new DualHashBidiMap<String, String>(tmp);
		
		//System.out.println(iso639_1_to_3);
		/*
		if(true) {
			return;
		}
		*/
		
		
		List<Label> batch = new ArrayList<Label>();
		
		for(LangDataset item : fileList) {
			String langCode = item.getLangCode();
		
			String lc3 = iso639_1_to_3.get(langCode);
			if(lc3 == null) {
				throw new RuntimeException("Language not mapped: " + langCode);
			}

			System.out.println("Processing " + item);
			
			
			String fileName = item.getFileName();
			File file = new File(fileName);

			String outFileName = "mappings-" + langCode + ".tsv";
			File outFile = new File(outFileName);
			PrintStream out = new PrintStream(outFile);
			
			
			InputStream in = new MetaBZip2CompressorInputStream(new FileInputStream(file));
			
			Iterator<Triple> it = new NTripleIterator(in, "", null);
			while(it.hasNext()) {
				Triple triple = it.next();
	
				String uri = triple.getSubject().getURI();
				Node node = triple.getObject();
				String labelStr = "" + node.getLiteralValue();
				
				String normLabelStr = normalize(labelStr);
				
				Label label = new Label(uri, labelStr, normLabelStr);
				
				batch.add(label);
				
				if(batch.size() >= 1000) {
					processBatch(out, conn, lc3, batch);
					batch.clear();
				}
				
				//System.out.println(normLabelStr);
			}
			
			processBatch(out, conn, lc3, batch);
			
			out.close();
		}
	}
	
	
	public static void processBatch(PrintStream out, Connection conn, String lc3, List<Label> batch)
		throws Exception
	{
		if(batch.isEmpty()) {
			return;
		}		
		
		Multimap<String, String> normToUri = HashMultimap.create();
		for(Label item : batch) {
			normToUri.put(item.getNormalized(), item.getUri());
		}
		
		List<String> normLabels = new ArrayList<String>();
		for(Label item : batch) {
			normLabels.add(item.getNormalized());
		}
		
		String setStr = "'" + Joiner.on("', '").join(normLabels) + "'";
		String queryStr = "SELECT ex, td FROM ex a JOIN lv b ON (b.lv = a.lv) WHERE b.lc IN ('" + lc3 + "') AND a.td IN (" + setStr + ")";
		

		//Inserte
		//System.out.println(queryStr);
		
		ResultSet rs = conn.createStatement().executeQuery(queryStr);
		
		while(rs.next()) {
			int ex = rs.getInt("ex");
			String td = rs.getString("td");
			
			Collection<String> uris = normToUri.get(td);
			for(String uri : uris ) {			
				out.println(ex + "\t" + uri);
			}
		}
		
		//List<Integer> ids = SqlUtils.executeList(conn, queryStr, Integer.class);
		
		
	}

}
