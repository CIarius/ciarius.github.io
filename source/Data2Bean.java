import java.lang.reflect.*;
import java.sql.*;
import java.util.regex.*;
import mes.Database.*;
import mes.Employee.*;

public class Data2Bean{

	public static void main(String[] args){
		mes.Employee employee = new mes.Employee();
		employee.setId(1);
		get(employee);
	}

	public static String fieldname2Beanzname(String fieldName){
		// transform SQL field_name to Java bean FieldName
		Pattern pattern = Pattern.compile("\\b[a-z]");
		Matcher matcher = pattern.matcher(fieldName.replaceAll("_"," "));
		StringBuffer buffer = new StringBuffer();
		while ( matcher.find() ){
			matcher.appendReplacement(buffer, matcher.group().toUpperCase());
		}
		matcher.appendTail(buffer);
		return buffer.toString().replaceAll(" ", "");
	}

	public static void get(Object object){

		try{

			// object is a class named for a table, so the table name is the class name

			String tableName = object.getClass().getSimpleName().toLowerCase();

			// classes are derived from metadata so, like tables, have an id property

			Method method = object.getClass().getMethod("getId");
			int id = (int)method.invoke(object);

			// we can derive a SELECT statement from the table name and the record id

			String sql = String.format("SELECT * FROM %s WHERE id = %d;", tableName, id);

			// which query we can execute and obtain a result set from

			Connection connection = mes.Database.getConnection();
			Statement statement = connection.createStatement();
			ResultSet resultSet = statement.executeQuery(sql);

			// remembering to position the record set's cursor at the first record
			
			resultSet.next();

			// from the record set we can get the meta data and the column count

			ResultSetMetaData metadata = resultSet.getMetaData();
			int columnCount = metadata.getColumnCount();

			// and use these to loop through the results and invoke the setter for each field

			for ( int columnIndex = 1; columnIndex <= columnCount; columnIndex++ ){

				// extracting the column name and deriving the setter and getter names
				String columnName = metadata.getColumnName(columnIndex);
				String setterName = String.format("set%s", fieldname2Beanzname(columnName));
				String getterName = String.format("get%s", fieldname2Beanzname(columnName));

				// populating parameters, an array of Class objects, from the table class's property's type
				Class[] parameters = new Class[1];
				parameters[0] = object.getClass().getDeclaredField(fieldname2Beanzname(columnName)).getType();

				// invoking the public setter to populate the private property
				Method setter = object.getClass().getMethod(setterName, parameters);
				setter.invoke(object, resultSet.getObject(columnIndex));

				// testing that invoking the setter worked by invoking the corresponding getter
				Method getter = object.getClass().getMethod(getterName);
				System.out.println(String.format("%s=%s", columnName, getter.invoke(object)));

			}
			connection.close();
		}catch(Exception e){
			e.printStackTrace();
			System.out.println("CAUGHT: " + e.getMessage());
		}finally{
		}


	}

}