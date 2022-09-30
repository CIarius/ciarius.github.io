import java.io.StringReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class ListView {

	public ListView(HttpServletRequest request, HttpServletResponse response, String SQL) {
		
		Connection conn = null;
		Statement stmt = null;
		ResultSet rset = null;
		
		try{

			// CLASSPATH = \OT\src\main\webapp\WEB-INF\lib\ojdbc11.jar
			
			Class.forName("oracle.jdbc.driver.OracleDriver");

			// this references Oracle XE's sample database running locally in a Docker container
			// in a production environment connection properties would be read from a central properties file

			conn = DriverManager.getConnection("jdbc:oracle:thin:@//localhost:1521/xepdb1","ot","Orcl1234");

			stmt = conn.createStatement();
			
			// dates need to be in 00-00-0000 format so the XSL can centre these in their table cell
			stmt.executeQuery("ALTER SESSION SET nls_date_format='dd-mm-yyyy'");
			
			// do not put a ';' at the end of any SQL in a statement.executeQuery()
			rset = stmt.executeQuery(String.format("SELECT DBMS_XMLGEN.GETXML('%s') FROM dual", SQL));
			
			// DBMS_XMLGEN.GETXML returns a CLOB which we can transform into HTML using a XSL style sheet
			
			// position cursor at first record of the record set
			rset.next();	

			// call it what it is
			String rawXML = rset.getString(1);

			// load the style sheet from relative file webapp/styles/xsl/listview.xsl 
			Source xsl = new StreamSource(request.getServletContext().getResourceAsStream("styles/xsl/listview.xsl"));
			
			// create a new instance of TransformaerFactory 
			TransformerFactory factory = TransformerFactory.newInstance();
			
			// create a transformer that'll use the XSL loaded previously 
			Transformer transformer = factory.newTransformer(xsl);
			
			//transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
			//transformer.setOutputProperty(OutputKeys.INDENT, "yes");
			
			// direct the output of the transformer back to the client via the Servlet's response object
			StreamResult result = new StreamResult(response.getWriter());
			
			// convert the raw XML into a  
			StreamSource xml = new StreamSource(new StringReader(rawXML));
			
			// transform the XML to HTML and return to client browser 
			transformer.transform(xml, result);			
			
		}catch(Exception e){
			System.out.println(e);
		}finally {
			try {
				if ( rset != null )
					rset.close();
				if ( stmt != null )
					stmt.close();
				if ( conn != null )
					conn.close();
			}catch(Exception e) {
				System.out.println(e);
			}
		}	
	}

}
