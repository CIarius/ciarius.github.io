import java.io.*;
import java.sql.*;
import java.util.*;
import java.util.regex.*;

public class Meta2Bean{

	public static String fieldname2Beanzname(String fieldName){
		// transform snake case to Pascal case
		Pattern pattern = Pattern.compile("\\b[a-z]");
		Matcher matcher = pattern.matcher(fieldName.replaceAll("_"," "));
		StringBuffer buffer = new StringBuffer();
		while ( matcher.find() ){
			matcher.appendReplacement(buffer, matcher.group().toUpperCase());
		}
		matcher.appendTail(buffer);
		return buffer.toString().replaceAll(" ", "");
	}

	public static void main(String[] args){

		// create bean from meta 

		String tableName = args[0];
		String className = tableName.substring(0, 1).toUpperCase() + tableName.substring(1); 	// PascalCased
		String fieldList = null;
		Connection conn  = null;
		Statement  stmt  = null;

		Properties properties = new Properties();
		String mysqlURL = null, username = null, password = null;

		try{
			// get the connection parameters from the config file
			properties.load(new FileInputStream("app.config"));
			mysqlURL = properties.getProperty("database");
			username = properties.getProperty("username");
			password = properties.getProperty("password");
		}catch(Exception e){
			System.out.println(e.getMessage());
		}
		
		try{

			// connect database using parameters from config file
			DriverManager.registerDriver(new com.mysql.jdbc.Driver());
			conn = DriverManager.getConnection(mysqlURL, username, password);
			stmt = conn.createStatement();

			// get a single record from tableName passed as command line argument
			String sql = String.format("SELECT * FROM %s LIMIT 1;", tableName);
			ResultSet rs = stmt.executeQuery(sql);

			// capture the recordset's accompanying metadata 
			ResultSetMetaData metadata = rs.getMetaData();
			int columnCount = metadata.getColumnCount();

			// writer for bean source file named tableName.java
			PrintWriter beanWriter = new PrintWriter(String.format("%s.java", tableName), "UTF-8");

			// every bean class is part of the mes package (by convention package names are always lowerclass)
			beanWriter.println("package mes;");

			// the class's required imports are the metadata column class names
			
			beanWriter.println();
			
			ArrayList<String> imports = new ArrayList<String>();

			for ( int columnIndex = 1; columnIndex <= columnCount; columnIndex++ ){
				if ( imports.indexOf(metadata.getColumnClassName(columnIndex)) == -1 )	// don't want dups
					imports.add(metadata.getColumnClassName(columnIndex));
			}

//			imports.add("java.io.Serializable");	// 'cause beans should be serializable

			for ( String i_port : imports ){
				beanWriter.println(String.format("import %s;", i_port));
			}

			// class declaration
			
			beanWriter.println();
//			beanWriter.println(String.format("public class %s implements Serializable{", tableName));
			beanWriter.println(String.format("public class %s {", tableName));
			beanWriter.println();
//			beanWriter.println("\tstatic final long serialVersionUID = 1L;\n");

			// one property per field named for the field, so if the field is date_of_birth DATE;
			// the corresponding property is going to be named private Date date_of_birth;
			
			// keeping the Java property names in line with the SQL schema field names
			// allows us to generate the bean from the schema, the HTML from the bean,
			// the SQL from the bean and thus we have a consistent nomenclature

			for ( int columnIndex = 1; columnIndex <= columnCount; columnIndex++ ){
				beanWriter.println(
					String.format("\tprotected %s %s = null;",
					metadata.getColumnClassName(columnIndex),
					metadata.getColumnName(columnIndex)
				));
			}

			beanWriter.println();

			// beans have a no-arg constructor named for the class (which is named for the table)

			beanWriter.println(String.format("\tpublic %s(){", tableName));
			beanWriter.println("\t}");

			beanWriter.println();

			// beans have an 'all' arg constructor named for the class (which is named for the table)

			beanWriter.println(String.format("\tpublic %s(", tableName));

			for ( int columnIndex = 1; columnIndex <= columnCount; columnIndex++ ){
				String columnName = metadata.getColumnName(columnIndex);
				String columnType = metadata.getColumnClassName(columnIndex);
				if ( columnIndex < columnCount ){
					beanWriter.println(String.format("\t\t%s %s,", columnType, columnName));
				}else{
					beanWriter.println(String.format("\t\t%s %s", columnType, columnName));
				}
			}

			beanWriter.println("\t){");
			beanWriter.println();
			beanWriter.println("\t\tsuper();");
			beanWriter.println();

			for ( int columnIndex = 1 ; columnIndex <= columnCount; columnIndex++ ){
				String columnName = metadata.getColumnName(columnIndex);
				beanWriter.println(String.format("\t\tthis.%s = %s;", columnName, columnName));
			}

			beanWriter.println("\t}");

			beanWriter.println();

			// every field has a corresponding getter and setter

			for ( int columnIndex = 1; columnIndex <= columnCount; columnIndex++ ){

				String columnName = metadata.getColumnName(columnIndex);
				String methodName = fieldname2Beanzname(columnName);
				String columnType = metadata.getColumnClassName(columnIndex);

				// setters are named for the property, so
				// if the property is Date date_of_birth;
				// the corresponding setter will be 
				// public void setDateOfBirth(Date date_of_birth);

				beanWriter.println();

				beanWriter.println(
					String.format("\tpublic void set_%s(%s %s){", columnName, columnType, columnName)
				);
				beanWriter.println(String.format("\t\tthis.%s = %s;", columnName, columnName));
				beanWriter.println("\t}");

				// getters are named for the property, so
				// if the property is Date date_of_birth;
				// the corresponding getter will be
				// public Date getDateOfBirth();

				beanWriter.println();
				
				beanWriter.println(String.format("\tpublic %s get_%s(){", columnType, columnName));
				beanWriter.println(String.format("\t\treturn this.%s;", columnName));
				beanWriter.println("\t}");

			}
/*
			// In a REST API the four CRUD operations correspond 
			// to: C=POST, R=GET, U=PUT, D=DELETE. We can implement
			// generic methods for these which, passed an instance,
			// use the class/property names and values to create and 
			// execute the corresponding SQL INSERT, UPDATE, SELECT,
			// or DELETE statement. This works because of the tight
			// binding of SQL metadata to class object to HTML id.

			// Get(id) will call a generic method which, given an
			// instance and an id, will SELECT the record id from
			// the table named for the instance, set the instance 
			// properties, and return a boolean expressing the outcome
			//
			// example usage
			//
			// Employee employee = new Employee();
			// employee.setId(1);
			// if ( employee.Get() ){
			// 	System.out.println("success!");
			// }else{
			// 	System.out.println("failure!");
			// }
			
			beanWriter.println();
			beanWriter.println("\tpublic boolean Get(){");
			beanWriter.println("\t\treturn mes.Database.Get(this);");
			beanWriter.println("\t}");

			// Put() will pass 'this' to a generic method which, 
			// given an object, will use property names and values 
			// to formulate and execute a SQL INSERT statement 
			// and return a boolean expression of the outcome
			//
			// example usage
			//
			// Employee employee = new Employee();
			// employee.setId(1);
			// if ( employee.Put() ){
			// 	System.out.println("success!");
			// }else{
			// 	System.out.println("failure!");
			// }

			beanWriter.println("");
			beanWriter.println("\tpublic Boolean Put(){");
			beanWriter.println("\t\treturn mes.Database.Put(this);");
			beanWriter.println("\t}");

			// Post() will pass 'this' to a generic method which, 
			// given an object, will use property names and values 
			// to formulate and execute a SQL UPDATE statement 
			// and return a boolean expression of the outcome
			//
			// example usage
			//
			// Employee employee = new Employee();
			// employee.setId(1);
			// if ( employee.Post() ){
			// 	System.out.println("success!");
			// }else{
			// 	System.out.println("failure!");
			// }

			beanWriter.println("");
			beanWriter.println("\tpublic Boolean Post(){");
			beanWriter.println("\t\treturn mes.Database.Post(this);");
			beanWriter.println("\t}");

			// Delete() will pass 'this' to a generic method which, 
			// given an object, will use property names and values 
			// to formulate and execute a SQL DELETE statement 
			// and return a boolean expression of the outcome
			//
			// example usage
			//
			// Employee employee = new Employee();
			// employee.setId(1);
			// if ( employee.Delete() ){
			// 	System.out.println("success!");
			// }else{
			// 	System.out.println("failure!");
			// }

			beanWriter.println("");
			beanWriter.println("\tpublic Boolean Delete(){");
			beanWriter.println("\t\treturn mes.Database.Delete(this);");
			beanWriter.println("\t}");
*/
			// close out the class definition

			beanWriter.println();

			beanWriter.println("}");

			beanWriter.close();

		}catch(Exception e){
			System.out.println(e.getMessage());
		}finally{
			try{
				stmt.close();	// always close statements and connections because we 
				conn.close();	// can't rely on Java garbage collection be be timely
			}catch(Exception e){
				System.out.println(e.getMessage());
			}
		}

	}

}