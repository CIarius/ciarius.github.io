package mes;

import java.io.*;
import java.lang.*;
import java.lang.reflect.*;
import java.sql.*;
import java.util.*;
import javax.servlet.*;

/*
 * below is command to compile mes/DatabaseAbstract.class 
 * javac -cp $CATALINA_HOME/lib/servlet-api.jar:/usr/share/java/mysql.jar:. -d . DatabaseAbstract.java
*/

public class DatabaseAbstract{

	// fields
	
	private String DB_DRIVER 	= null;
	private String DB_NAME		= null;
	private String DB_URL		= null;
	private String DB_USERNAME	= null;
	private String DB_PASSWORD	= null;

	// constructors

	public DatabaseAbstract(String DB_DRIVER, String DB_NAME, String DB_URL, String DB_USERNAME, String DB_PASSWORD){
		// manually populate fields
		try{
			this.DB_DRIVER    	= DB_DRIVER;
			this.DB_NAME	    	= DB_NAME;
			this.DB_URL		= DB_URL;
			this.DB_USERNAME  	= DB_USERNAME;
			this.DB_PASSWORD  	= DB_PASSWORD;
		}catch(Exception e){
			e.printStackTrace();
		}
	}

	public DatabaseAbstract(ServletConfig config){
		// populate fields from $CATALINA_BASE/webapps/<app>/WEB-INF/web.xml
		try{
			this.DB_DRIVER 		= config.getServletContext().getInitParameter("DB_DRIVER");
			this.DB_NAME 		= config.getServletContext().getInitParameter("DB_NAME");
			this.DB_URL 		= config.getServletContext().getInitParameter("DB_URL");
			this.DB_USERNAME 	= config.getServletContext().getInitParameter("DB_USERNAME");
			this.DB_PASSWORD 	= config.getServletContext().getInitParameter("DB_PASSWORD");
		}catch(Exception e){
			e.printStackTrace(System.err);
		}
	}

	public DatabaseAbstract(String filename){
		// populate fields from properties file filename
		try{
			Properties properties = new Properties();
			properties.load(new FileInputStream(filename));
			this.DB_DRIVER 		= properties.getProperty("DB_DRIVER");
			this.DB_NAME 		= properties.getProperty("DB_NAME");
			this.DB_URL 		= properties.getProperty("DB_URL");
			this.DB_USERNAME 	= properties.getProperty("DB_USERNAME");
			this.DB_PASSWORD 	= properties.getProperty("DB_PASSWORD");
		}catch(Exception e){
			e.printStackTrace(System.err);
		}
	}

	// methods

	public Connection getConnection() {

		// connect using the default username/password from the config source

		Connection connection = null;

		try{

			Class.forName(this.DB_DRIVER);

			connection = DriverManager.getConnection(this.DB_URL, this.DB_USERNAME, this.DB_PASSWORD);

		}catch(Exception e){
			e.printStackTrace(System.err);
		}

		return connection;

	}

	public Connection getConnection(String username, String password) {

		// connect using a given username/password

		Connection connection = null;

		try{

			Class.forName(this.DB_DRIVER);

			connection = DriverManager.getConnection(this.DB_URL, username, password);

		}catch(Exception e){
			e.printStackTrace(System.err);
		}

		return connection;

	}

	public  void select(Object bean){

		/*
		 * generic DAO cRud method
		 *
		 * given beans are named for tables, and methods and properties for columns, it is possible - given a bean 
		 * with the primary key property populated (via the corresponding setter) - to identify the primary key, 
		 * use that to get the primary key's value (by invoking the corresponding getter), use both to get the 
		 * record, and then populate the bean by invoking the corresponding setter for each column in the record
		 *
		 * or (in plain English) given a bean created from/aligned with a table's metadata we can...
		 *
		 * identify the table
		 * identify the primary key
		 * retrieve the primary key value
		 * retrieve the record with that key from the table
		 * populate the bean from the record
		 *
		*/

		Connection 		conn = null;
		Statement		stmt = null;
		ResultSet		rset = null;
		ResultSetMetaData	rsmd = null;

		try{
			
			conn = getConnection();
			
			stmt = conn.createStatement();

			Class[] args = new Class[1];	// getter/setter argument

			// identify the primary key

			String sql = String.format(
				"SELECT column_name " + 
				"FROM information_schema.key_column_usage " +
				"WHERE table_name = '%s' AND constraint_name = 'PRIMARY'",
				bean.getClass().getSimpleName()
			);

			rset = stmt.executeQuery(sql);

			rset.next();

			// retrieve the primary key

			Method getter = bean.getClass().getMethod(String.format("get_%s", rset.getString(1)));
			Object id = getter.invoke(bean);

			// retrieve the record
			
			sql = String.format(
				"SELECT id, forename FROM %s WHERE %s = '%s'", 
				bean.getClass().getSimpleName(),
				rset.getString(1),
				id
			);

			System.out.println(sql);

			rset = stmt.executeQuery(sql);

			rset.next();

			rsmd = rset.getMetaData();
			
			// populate the bean
			
			for ( int columnIndex = 1; columnIndex <= rsmd.getColumnCount(); columnIndex++ ){
				args[0] = rset.getObject(columnIndex).getClass();
				Method setter = bean.getClass().getMethod(
					String.format("set_%s", rsmd.getColumnName(columnIndex)), 
					args
				);
				setter.invoke(bean, rset.getObject(columnIndex));
			}

		}catch(Exception e){
			e.printStackTrace(System.err);
		}finally{

			try{
				rset.close();
			}catch(Exception e){
			}

			try{
				stmt.close();
			}catch(Exception e){
			}

			try{
				conn.close();
			}catch(Exception e){
			}

		}
	}

	public  void insert(Object bean){

		/*
		 * generic DAO Crud method
		 *
		 * given beans are named for tables, and methods and properties for columns, it is possible - given a bean 
		 * with all the property populated (via the corresponding setters) - to execute an insert statement
		 *
		 * or (in plain English) given a bean created from/aligned with a table's metadata we can...
		 *
		 * identify the primary key
		 * create a SQL INSERT prepared statement
		 * populate the prepared statement
		 * execute the SQL statement
		 * return the generated primary key object
		 *
		*/

		Connection 		conn = null;
		PreparedStatement	stmt = null;
		ResultSet		rset = null;
		ResultSet		keys = null;

		try{
			
			conn = getConnection();

			// identify the primary key

			String sql = String.format(
				"SELECT column_name " + 
				"FROM information_schema.key_column_usage " +
				"WHERE table_name = '%s' AND constraint_name = 'PRIMARY'",
				bean.getClass().getSimpleName()
			);

			rset = conn.createStatement().executeQuery(sql);

			rset.next();

			// create the SQL INSERT prepared statement
			
			Field[] fields = bean.getClass().getDeclaredFields();
			String names = "", values = "";
			for ( Field field : fields ){
				names += field.getName();
				values += "?";
				if ( java.util.Arrays.asList(fields).indexOf(field) != fields.length - 1 ){
					names  += ", ";
					values += ", ";
				}
			}

			sql = String.format(
				"INSERT INTO %s (%s) VALUES(%s)", 
				bean.getClass().getSimpleName(), names, values
			);

			// create a prepared statement that will return the primary key
			stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);

			// populate the prepared statment with values from the bean's fields
			for ( Field field : fields ){
				field.setAccessible(true);
				stmt.setObject(java.util.Arrays.asList(fields).indexOf(field)+1, field.get(bean));
			}

			// execute the statment and capture the generated key(s)
			
			int affectedRows = stmt.executeUpdate();

			keys = stmt.getGeneratedKeys();

			keys.next();

			// invoke the appropriate setter to populate the bean's primary key field with the generated key

			Method setter = bean.getClass().getMethod(
				String.format("set_%s", rset.getString(1)), 
				keys.getObject(1).getClass()
			);

			setter.invoke(bean, keys.getObject(1));

			// select the record to get the fully populated bean
			
			select(bean);


		}catch(Exception e){
			e.printStackTrace(System.err);
		}finally{

			try{
				keys.close();
			}catch(Exception e){
			}

			try{
				rset.close();
			}catch(Exception e){
			}

			try{
				stmt.close();
			}catch(Exception e){
			}

			try{
				conn.close();
			}catch(Exception e){
			}

		}

	}

	public  void update(Object bean){

		/*
		 * generic DAO crUd method
		 *
		 * given beans are named for tables, and methods and properties for columns, it is possible - given a bean 
		 * with all the property populated (via the corresponding setters) - to execute an update statement
		 *
		 * or (in plain English) given a bean created from/aligned with a table's metadata we can...
		 *
		 * identify the primary key
		 * retrieve the primary key
		 * create a SQL UPDATE statement
		 * execute the SQL statement
		 *
		*/

		Connection 		conn = null;
		Statement		stmt = null;
		ResultSet		rset = null;
		ResultSetMetaData	rsmd = null;

		try{
			
			conn = getConnection();
			
			stmt = conn.createStatement();

			Class[] args = new Class[1];	// getter/setter argument

			// identify the primary key

			String sql = String.format(
				"SELECT column_name " + 
				"FROM information_schema.key_column_usage " +
				"WHERE table_name = '%s' AND constraint_name = 'PRIMARY'",
				bean.getClass().getSimpleName()
			);

			rset = stmt.executeQuery(sql);

			rset.next();

			// retrieve the primary key

			Method getter = bean.getClass().getMethod(String.format("get_%s", rset.getString(1)));
			Object id = getter.invoke(bean);

			// create the SQL INSERT statement
			
			// UPDATE table SET field = value, field = value... WHERE primary key = value
			
			Field[] fields = bean.getClass().getDeclaredFields();
			String pairs = "";
			for ( Field field : fields ){
				field.setAccessible(true);
				switch( field.getType().getName() ){
					case "java.lang.String" :
						pairs += String.format("%s = '%s'", field.getName(), field.get(bean));
						break;
					default:
						pairs += String.format("%s = %s", field.getName(), field.get(bean));
				}
				if ( java.util.Arrays.asList(fields).indexOf(field) != fields.length - 1 ){
					pairs += ", ";
				}
			}

			sql = String.format(
				"UPDATE %s SET %s WHERE %s = '%s'", 
				bean.getClass().getSimpleName(), pairs, rset.getString(1), id
			);

			stmt.executeUpdate(sql);

			System.out.println(sql);

		}catch(Exception e){
			e.printStackTrace(System.err);
		}finally{

			try{
				rset.close();
			}catch(Exception e){
			}

			try{
				stmt.close();
			}catch(Exception e){
			}

			try{
				conn.close();
			}catch(Exception e){
			}

		}
	}

	public  void delete(Object bean){

		/*
		 * generic DAO crD method
		 *
		 * given beans are named for tables, and methods and properties for columns, it is possible - given a bean 
		 * with all the property populated (via the corresponding setters) - to execute a DELETE statement
		 *
		 * or (in plain English) given a bean created from/aligned with a table's metadata we can...
		 *
		 * identify the primary key
		 * retrived the primary key
		 * create a SQL DELETE statement
		 * execute the SQL statement
		 *
		*/

		Connection 		conn = null;
		Statement		stmt = null;
		ResultSet		rset = null;
		ResultSetMetaData	rsmd = null;

		try{
			
			conn = getConnection();
			
			stmt = conn.createStatement();

			Class[] args = new Class[1];	// getter/setter argument

			// identify the primary key

			String sql = String.format(
				"SELECT column_name " + 
				"FROM information_schema.key_column_usage " +
				"WHERE table_name = '%s' AND constraint_name = 'PRIMARY'",
				bean.getClass().getSimpleName()
			);

			rset = stmt.executeQuery(sql);

			rset.next();

			// retrieve the primary key

			Method getter = bean.getClass().getMethod(String.format("get_%s", rset.getString(1)));
			Object id = getter.invoke(bean);

			// create the SQL DELETE statement

			sql = String.format(
				"DELETE FROM %s WHERE %s = '%s'", 
				bean.getClass().getSimpleName(), rset.getString(1), id
			);

			stmt.executeUpdate(sql);

		}catch(Exception e){
			e.printStackTrace(System.err);
		}finally{

			try{
				rset.close();
			}catch(Exception e){
			}

			try{
				stmt.close();
			}catch(Exception e){
			}

			try{
				conn.close();
			}catch(Exception e){
			}

		}
	}

	public List<Object> selectAll(Object bean){

		/*
		 * generic DAO select all as list of beans  method
		 *
		 * loop through a table, convert each record to a bean, add the bean to a list, and return the list of beans
		 *
		 * identify table
		 * retrieve records
		 * loop records
		 * 	populate bean from record
		 * 	add bean to list
		 * return list 
		 *
		*/

		Connection 		conn = null;
		Statement		stmt = null;
		ResultSet		rset = null;
		ResultSetMetaData	rsmd = null;
		List<Object>		list = new ArrayList<Object>();

		try{

			System.out.println("selectEntire(" + bean.getClass().getSimpleName() + ")");
			
			conn = getConnection();
			
			stmt = conn.createStatement();

			Class[] args = new Class[1];	// getter/setter argument

			// retrieve the records
			
			String sql = String.format("SELECT * FROM %s", bean.getClass().getSimpleName());

			rset = stmt.executeQuery(sql);

			rsmd = rset.getMetaData();

			while ( rset.next() ){

				// create a new instance of the bean class

				bean = Class.forName(bean.getClass().getName()).newInstance();

				// populate the new bean instance
				
				for ( int columnIndex = 1; columnIndex <= rsmd.getColumnCount(); columnIndex++ ){
					// populate setter argument (like this in case column value is null)
					args[0] = Class.forName(rsmd.getColumnClassName(columnIndex));
					// identify the appropriate setter from its arguments
					Method setter = bean.getClass().getMethod(
						String.format("set_%s", rsmd.getColumnName(columnIndex)), 
						args
					);
					// invoke the setter, passing column value
					setter.invoke(bean, rset.getObject(columnIndex));
				}

				// add bean to list

				list.add(bean);

			}

		}catch(Exception e){
			e.printStackTrace(System.err);
		}finally{

			try{
				rset.close();
			}catch(Exception e){
			}

			try{
				stmt.close();
			}catch(Exception e){
			}

			try{
				conn.close();
			}catch(Exception e){
			}

		}

		return list;

	}

}