<?php
session_start();
?>
<!DOCTYPE html>
<html>
<head>
<style>.error{color: red;}</style>
<title>Generic table CRUD screen</title>
</head>
<body>
<?php

	echo "Hello1";

	// read the application parameters from a text file into an associative array
	$parameters = array();
	foreach( file("parameters.txt") as $line ){
		list($key, $value) = explode("=", str_replace(array("\r", "\n"), "", $line));
		$parameters[$key] = $value;
	}

	// default the language to "en" if default language not supported
	$language = substr($_SERVER["HTTP_ACCEPT_LANGUAGE"], 0, 2);
	$supports = ["en", "es", "fr"];	// supported languages
	$language = in_array($language, $supports) ? $language : "en";

	// record id and table name come from either of GET or POST
	if ( empty($id) ){
		$id = empty($_GET["id"]) ? $_POST["id"] : $_GET["id"];
	}

	// tablename should be a consistent value so make it a session variable
	if ( empty($_SESSION["tablename"]) ){
		$_SESSION["tablename"] = empty($_GET["tablename"]) ? $_POST["tablename"] : $_GET["tablename"];
		// check it's populated because it's required
		if ( empty($_SESSION["tablename"]) ){
			die("Need to know which table to perform CRUD action on!");
		}
	}


	// open a connection to mySQL using $parameters
	$conn = new mysqli($parameters["servername"], $parameters["username"], $parameters["password"], $parameters["database"]);
	if ( $conn->connect_errno ){
		die("Connection failed : " . $conn->connect_errno);
	}

	if ( ! empty($_POST) ){

		// sanitise anything being POSTed in to thwart script injection attacks
		foreach( $_POST as $name => $value ){
			$_POST[$name] = htmlspecialchars($value);
		}

		var_dump($_POST);

		// it's either create or update
		if ( empty($_POST["id"]) ){
			foreach( $_POST as $name => $value ){
				$fields = sprintf("%s,%s", $fields, $name);
				$values = sprintf("%s,%s", $values, $value);
			}
			$sql = sprintf("INSERT INTO %s (%s) VALUES(%s);", $_SESSION["tablename"], $fields, $values);
		}else{
			foreach( $_POST as $name => $value ){
				$pairs  = sprintf("%s=%s,", $name, $value);
			}
			$sql = sprintf("UPDATE %s SET %s WHERE id = '%s';", $_SESSION["tablename"], $pairs, $_POST["id"]);
		}
/*
		if ( $conn->query($sql) === TRUE ){
		}else{
			die("Error in insert/update : " . $sql);
		}
*/
		//echo $sql;

		

	}

	// fetch the table metadata
	$sql = sprintf("
		SELECT information_schema.columns.column_name, data_type, referenced_table_schema, referenced_table_name, referenced_column_name, character_maximum_length, is_nullable, column_type 
		FROM information_schema.columns 
		LEFT OUTER JOIN information_schema.key_column_usage ON 
			information_schema.key_column_usage.table_schema = information_schema.columns.table_schema AND 
			information_schema.key_column_usage.table_name = information_schema.columns.table_name AND 
			information_schema.key_column_usage.column_name = information_schema.columns.column_name 
		WHERE 	information_schema.columns.table_schema = '%s' AND 
			information_schema.columns.table_name = '%s' AND 
			information_schema.columns.column_name <> 'id';", 
		$parameters["database"], $_SESSION["tablename"]);
	$metadata = $conn->query($sql);
	if ( $metadata->num_rows == 0 ){
		die("Unable to retrieve metadata for table " . $_SESSION["tablename"]);
	}

	// retrieve any language specific input field labels for the columns in database.table into an associative array of column_name=>label
	$sql = sprintf(
		"SELECT column_name, html_input_label FROM column_labels WHERE table_schema='%s' AND table_name='%s' AND language_code = '%s';",
		$parameters["database"], $_SESSION["tablename"], $language
	);
	$results = $conn->query($sql);
	while ( $row = $results->fetch_assoc() ){
		$labels[$row["column_name"]] = $row["html_input_label"];
	}

	printf("<h2>Create, Retrieve, Update, and Delete - %s</h2>", $_SESSION["tablename"]);

	echo "<p><span class='error'>* signifies a required field</span></p>";

	// retrieve the record identified by $id ( unless we're creating a new record in which case $id has no value )
	$sql = sprintf("SELECT * FROM %s WHERE id = %s;", $_SESSION["tablename"], $id);
	$data = $conn->query($sql);
	if ( $data->num_rows > 0 ){
		$record = $data->fetch_assoc();	// (field=>value,...)
		$data->free_result();
	}

	// loop back to self on post
	printf("<form action= '%s' method='post'>", $_SERVER['PHP_SELF']);

	// easier to hard code these fields as to word around them in the code
	printf("<input id='id' name='id' type='hidden' value='%s'>", $record["id"]);

	// loop through the metadata (each row is one column of $table)
	while ( $column = $metadata->fetch_assoc() ){

		if ( $column["IS_NULLABLE"] == "NO" ){
			$required = "required";
		}else{
			$required = "";
		}

		// convert each column's SQL datatype into an appropriate HTML input field type

		switch ( $column["DATA_TYPE"] ){
			case "datetime":
				$type = "date";
				break;
			case "int":
				$type = "number";
				break;
			case "varchar":
				$type = "text";
				break;
			default:
				$type = "text";
		}

		// labels either come from the column_labels table or default to the column name itself

		if ( ! empty($labels[$column["COLUMN_NAME"]]) ){
			printf("<label for='%s'>%s</label><br>", $column["COLUMN_NAME"], $labels[$column["COLUMN_NAME"]]);			
		}else{
			printf("<label for='%s'>%s</label><br>", $column["COLUMN_NAME"], $column["COLUMN_NAME"]);
		}

		// regardless of their data type (and to ensure referential integrity) foreign keys appear as a drop down list of appropriate values

		if ( ! empty($column["referenced_table_schema"]) ){

			// foreign key lookups are defined in the foreign_key_lookups table

			$sql = sprintf("
				SELECT * 
				FROM foreign_key_lookups 
				WHERE primary_table_schema = '%s' AND primary_table_name = '%s' AND primary_column_name = '%s';", 
				$parameters["database"], $_SESSION["tablename"], $column["COLUMN_NAME"]
			);

			$results = $conn->query($sql);

			if ( $results->num_rows > 0 ){

				$foreign_key_lookup = $results->fetch_assoc();

				$sql = sprintf(
					"SELECT %s.%s.%s AS option_value, %s.%s.%s AS option_inner FROM %s.%s;", 
					$foreign_key_lookup["foreign_table_schema"], $foreign_key_lookup["foreign_table_name"], $foreign_key_lookup["html_option_value_column"],
					$foreign_key_lookup["foreign_table_schema"], $foreign_key_lookup["foreign_table_name"], $foreign_key_lookup["html_option_inner_column"],
					$foreign_key_lookup["foreign_table_schema"], $foreign_key_lookup["foreign_table_name"]
				);

				$options = $conn->query($sql);

			}else{

				// if there are no lookups for schema.table.column default to using the foreign key itself as both value and inner

				$sql = sprintf(
					"SELECT %s AS option_value, '' AS option_inner FROM %s.%s", 
					$column["referenced_column_name"], $column["referenced_table_schema"], $column["referenced_table_name"]
				);

				$options = $conn->query($sql);

			}

			printf("<select id='%s' name='%s' value='%s'>", $column["COLUMN_NAME"], $column["COLUMN_NAME"], $record[$column["COLUMN_NAME"]]);

			while ( $option = $options->fetch_assoc() ){
				if ( $option["option_value"] == $record[$column["referenced_column_name"]] ){
					printf("<option value='%s' selected>%s</option>", $option["option_value"], $option["option_inner"]);
				}else{
					printf("<option value='%s'>%s</option>", $option["option_value"], $option["option_inner"]);
				}
			}

			echo "</select>";	

			$options->free_result();

		}elseif ( $column["DATA_TYPE"] == "enum" ){	// enumerated types appear as radio buttons
			// convert information_schema.column_type to an array
			$enums = str_getcsv(str_replace(["enum(",")"], ["",""], $column["COLUMN_TYPE"]), ",", "'");
			foreach ( $enums as $enum ){
				if ( $record[$column["COLUMN_NAME"]] === $enum ){
					$checked = "checked";
				}else{
					$checked = "";
				};
				printf("<input type='radio' id='%s' name='%s' %s value='%s' %s>", $enum, $column["COLUMN_NAME"], $required, $enum, $checked);
				printf("<label for='%s'>%s</label>", $enum, $enum);
			}
		}elseif( $column["DATA_TYPE"] == "datetime" ){
				$value = date_format(date_create($record[$column["COLUMN_NAME"]]), "Y-m-d");
				printf("<input type='%s' id='%s' name='%s' %s value='%s'>", $type, $column["COLUMN_NAME"], $column["COLUMN_NAME"], $required, $value);
		}else{
				$value = $record[$column["COLUMN_NAME"]];
				printf("<input type='%s' id='%s' name='%s' %s value='%s'>", $type, $column["COLUMN_NAME"], $column["COLUMN_NAME"], $required, $value);
		}

		if ( ! empty($required) ){
			echo "<span class='error'> * </span>";
		}

		echo "<br>";

	}

	echo "<input type='submit' value='submit'>";

	echo "</form>";

	$conn->close();

?>
</body>
</html>