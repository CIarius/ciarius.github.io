import java.io.*;
import java.net.URLEncoder;
import java.sql.*;
import java.util.HashMap;
import java.util.regex.*;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.ServletConfig;
import javax.sql.*;
import javax.sql.rowset.*;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerException;
import javax.xml.transform.stream.*;

public class ListView extends HttpServlet {

		private static class SearchFilter implements Predicate {

		private Pattern pattern;	// it's a regular expression

		public SearchFilter(String searchRegex){
			if ( searchRegex != null && !searchRegex.isEmpty() ){
				pattern = Pattern.compile(searchRegex);
			}
		}

		public boolean evaluate(RowSet rset){
			boolean result = false;
			try{
				// test each column to see if it's a match
				ResultSetMetaData rsmd = rset.getMetaData();
				for ( int index = 1; index <= rsmd.getColumnCount(); index++ ){	// not a zero based array
					String columnValue = rset.getString(index);
					if ( columnValue != null ){	// it's possible some columns will be null
						Matcher matcher = pattern.matcher(columnValue);
						if ( matcher.matches() )
							return true;	// only one column has to match for the row to be included
					}
				}
			}catch(Exception e){
				e.printStackTrace(System.err);
			};
			return false;	// no match, no include
		}

		// don't omit these method stubs

		public boolean evaluate(Object value, int column) throws SQLException{
			throw new UnsupportedOperationException("implementation pending...");
		}

		public boolean evaluate(Object value, String columnName) throws SQLException{
			throw new UnsupportedOperationException("implementation pending...");
		}

	}

	// 
	// generic list view class that displays all the records in DB_TABLENAME as 
	// a XML document for a XLS stylesheet to transform to HTML styled with CSS
	//
	// XML format is:
	//
	// <table>
	// 	<row>
	// 		<fieldname>fieldvalue</fieldname>
	// 		...
	// 	</row>
	// 	...
	// </table>
	//

	// global variables

	PrintWriter out = null;

	// application parameters defined in web.xml

	String DB_DRIVER    = null; 
	String DB_NAME	    = null;
	String DB_URL 	    = null;
	String DB_USERNAME  = null;
	String DB_PASSWORD  = null;

	// servlet parameters defined in web.xml
	
	String DB_TABLENAME = null;

	public void init() throws ServletException {

		// global variables

		// application parameters defined in web.xml
		DB_DRIVER   = getServletConfig().getServletContext().getInitParameter("DB_DRIVER");
		DB_NAME	    = getServletConfig().getServletContext().getInitParameter("DB_NAME");
		DB_URL 	    = getServletConfig().getServletContext().getInitParameter("DB_URL");
		DB_USERNAME = getServletConfig().getServletContext().getInitParameter("DB_USERNAME");
		DB_PASSWORD = getServletConfig().getServletContext().getInitParameter("DB_PASSWORD");

		// servlet parameters defined in web.xml
		DB_TABLENAME = getServletConfig().getInitParameter("DB_TABLENAME");

		try{
			Connection conn = DriverManager.getConnection(DB_URL, DB_USERNAME, DB_PASSWORD);
		}catch(Exception e){

		}

	}	

	private void substituteReferenced(HashMap<String,String> tuple){

		// foreign key relates to another table which unique key field we want to display

		Connection conn = null;	
		Statement  stmt = null;
		ResultSet  rset = null;
		String	   rslt = null;
		String     sql  = null;

		try{

			conn = DriverManager.getConnection(DB_URL, DB_USERNAME, DB_PASSWORD);

			// create a statement
			stmt = conn.createStatement();

			// given a table name and a column name return the corresponding foreign key lookup
			// by checking if the given table name and column name exists on INFORMATION_SCHEMA
			// database table KEY_COLUMN_USAGE

			sql =  "SELECT referenced_table_schema, referenced_table_name ";
			sql += "FROM information_schema.key_column_usage ";
			sql += "WHERE table_schema = '%s' "; 
			sql += "AND table_name = '%s' AND column_name = '%s' ";
			sql += "AND referenced_table_name IS NOT NULL ";
			sql += "AND referenced_column_name IS NOT NULL";

			sql = String.format(
				sql,
				tuple.get("schema"),
				tuple.get("table"),
				tuple.get("column")
			);

			rset = stmt.executeQuery(sql);

			if ( rset.next() ){

				// if schema/table/column is a foreign key we need to substitute reference table's unique column
				// but to do that we need to know the name of the unique column so we can obtain its value

				sql =  "SELECT constraint_name, table_schema, table_name ";
				sql += "FROM information_schema.table_constraints ";
				sql += "WHERE table_schema = '%s' ";
				sql += "AND table_name = '%s'";
				sql += "AND constraint_type = 'UNIQUE'";

				sql = String.format(
					sql, 
					rset.getString("referenced_table_schema"),
					rset.getString("referenced_table_name")
				);

				rset = stmt.executeQuery(sql);

				if ( rset.next() ){
				
					sql = String.format(
						"SELECT %s FROM %s.%s WHERE id = %s", 
						rset.getString("constraint_name"),
						rset.getString("table_schema"),
						rset.getString("table_name"),
					       	tuple.get("value")
					);

					rset = stmt.executeQuery(sql);

					int columnIndex = 1;

					if ( rset.next() ){
						// for schema read catalog, it's a JDBC/mySQL thing
						ResultSetMetaData rsmd = rset.getMetaData();
						tuple.replace("schema", rsmd.getCatalogName(columnIndex));
						tuple.replace("table", rsmd.getTableName(columnIndex));
						tuple.replace("column", rsmd.getColumnName(columnIndex));
						tuple.replace("type", rsmd.getColumnTypeName(columnIndex));
						tuple.replace("value", rset.getString(1));
					}

				}

			}
		}catch(Exception e){
			out.println("#1.1 " + e.getMessage());;
		}finally{
			try{
				if ( rset != null )
					rset.close();
			}catch(Exception e){
				out.println("#2.1 " + e.getMessage());;
			}
			try{
				if ( stmt != null )
					stmt.close();
			}catch(Exception e){
				out.println("#3.1 " + e.getMessage());;
			}
			try{
				if ( conn != null )
					conn.close();
			}catch(Exception e){
				out.println("#4.1 " + e.getMessage());;
			}
		}

	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

		Connection conn = null;
		Statement  stmt = null;
		ResultSet  rset = null;

		// servlet attribute(s)
		String USERNAME = (String)request.getSession().getAttribute("USERNAME");

		// initialise this global variable here because response is not available in init()
		out = response.getWriter();

		// XML transformed on the server is sent to client as HTML
		response.setContentType("text/html");

		try{

			// register the database driver class class to avoid 'No suitable driver found for...' errors
			Class.forName(DB_DRIVER);

			// assign global connection
			conn = DriverManager.getConnection(DB_URL, DB_USERNAME, DB_PASSWORD);

			// create a statement
			stmt = conn.createStatement();

			// redirect to login page if session variable USERNAME is missing or invalid

			String sql = String.format(
				"SELECT user FROM mysql.user WHERE user = '%s'", 
				USERNAME
			);

			rset = stmt.executeQuery(sql);

			if ( ! rset.next() ){
				String from = request.getRequestURI();
				if ( request.getQueryString() != null )
					from += "?" + request.getQueryString();
				response.sendRedirect("login.jsp?from=" + URLEncoder.encode(from, "UTF-8"));
			}

			// 
			// Determine which, if any, CREATE|SELECT|UPDATE|DELETE privileges USERNAME has on DB_TABLENAME.
			// MES uses the principle of least privilege, giving users only those their role(s) require(s).
			// To do this we need to create a role and give it necessary privilges on required table(s) and
			// then create a user and give the user the role(s) they require for their business function(s).
			//
			// CREATE ROLE 'rolename';
			// GRANT INSERT|SELECT|UPDATE|DELETE on database.table TO 'rolename';
			// CREATE USER 'username'[@'hostname'] IDENTIFIED BY 'password';
			// GRANT 'rolename' TO 'username'[@'hostname'];
			//
			// user needs a default role for authentication at login
			// SET DEFAULT ROLE 'rolename' FOR 'username'[@'hostname'];
			// 
			// !!!!!!!!!! don't forget to propagate the changes !!!!!!!!!!
			// FLUSH PRIVILEGES;
			//
			// see mysql.roles_mapping and mysql.tables_priv
			//

			// get USERNAME's privileges on DB_TABLENAME as an uppercased csv string
			sql =  "SELECT GROUP_CONCAT(UPPER(table_priv)) AS privileges ";
			sql += "FROM mysql.tables_priv ";
			sql += "WHERE db = '%s' AND table_name = '%s' AND user = '%s' ";
			sql += "OR user IN (SELECT role FROM mysql.roles_mapping WHERE user = '%s')";
			sql = String.format(sql, DB_NAME, DB_TABLENAME, USERNAME, USERNAME);

			rset = stmt.executeQuery(sql);

			if ( ! rset.next() ){
				out.println(String.format("<message>%s has no access to this data!</message>", USERNAME));
			}else{

				String rawXML = new String();

				// store the privileges from the previous query remembering it's not a zero based array

				String privileges = rset.getString(1);

				// fetch all the records from the given table and output them as XML as detailed above
				
				sql = String.format("SELECT * FROM %s.%s", DB_NAME, DB_TABLENAME);

				rset = stmt.executeQuery(sql);
/*
				// create a filtered result set
				FilteredRowSet frst = RowSetProvider.newFactory().createFilteredRowSet();

				// populate it with the unfiltered results
				frst.populate(rset);

				// if required create and apply a filter (filters utilise regular expressons)
				if ( request.getParameter("criteria") != null )
					frst.setFilter(new SearchFilter(request.getParameter("criteria")));
*/
				// dump any results as XML (format as described above)

				rawXML += "<table>";

				ResultSetMetaData rsmd = rset.getMetaData();

				while ( rset.next() ){

					rawXML += "<row>";

					for ( int index = 1; index <= rsmd.getColumnCount(); index++ ){

						// substitute schema, table, column, type, and value if column is a foreign key
						
						HashMap<String,String> tuple = new HashMap<String, String>();

						// for schema read catalog, it's a JDBC/mySQL thing
						tuple.put("schema", rsmd.getCatalogName(index));
						tuple.put("table", rsmd.getTableName(index));
						tuple.put("column", rsmd.getColumnName(index));
						tuple.put("type", rsmd.getColumnTypeName(index));
						tuple.put("value", rset.getString(index));

						// passing a (HashMap) object allows passing by reference
						substituteReferenced(tuple);

						rawXML += String.format(
							"<%s type=\"%s\">%s</%s>", 
							tuple.get("column"),
							tuple.get("type"),
							tuple.get("value"),
							tuple.get("column")
						);

					}

					// add placeholder for XSL to render link to UPDATE screen if USERNAME has privilege
					if ( privileges.contains("UPDATE") )
						rawXML += "<update></update>";

					// add placeholder for XSL to render link to DELETE screen if USERNAME has privilege
					if ( privileges.contains("DELETE") )
						rawXML += "<delete></delete>";

					// add placeholder for XLS to render link to SELECT screen to view record read-only
					rawXML += "<select></select>";

					rawXML += "</row>";

				}

				// add placeholder for XSL to render link to CREATE screen if USERNAME has privilege
				if ( privileges.contains("CREATE") )
					rawXML += "<create></create>";

				rawXML += "</table>";

				// transform XML to HTML using XSL

				StringReader reader = new StringReader(rawXML);
				TransformerFactory factory = TransformerFactory.newInstance();
				StreamSource xsl = new StreamSource(new File("webapps/MES/styles/listview.xsl"));
				Transformer transformer = factory.newTransformer(xsl);
				transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
				transformer.setOutputProperty(OutputKeys.INDENT, "yes");
				StreamResult result = new StreamResult(out);
				StreamSource xml = new StreamSource(new StringReader(rawXML));
				transformer.transform(xml, result);

			}
		}catch(Exception e){
			e.printStackTrace(System.err);
		}finally{
			try{
				if ( rset != null )
					rset.close();
			}catch(Exception e){
				out.println("#2 " + e.getMessage());
			}
			try{
				if ( stmt != null )
					stmt.close();
			}catch(Exception e){
				out.println("#3 " + e.getMessage());
			}
			try{
				if ( conn != null )
					conn.close();
			}catch(Exception e){
				out.println("#4 " + e.getMessage());
			}
		}

	}

	public void Destroy(){
	}

}