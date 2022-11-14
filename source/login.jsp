<!DOCTYPE html>
<html>
	<head>
		<title>Login</title>
		<%@ page import="java.util.*,java.sql.*,java.io.*" %>
	</head>
	<body>

		<% if ( session.getAttribute("MESSAGE") == null ) session.setAttribute("MESSAGE", ""); %>

		<form action="login.jsp" method="post">
			<table>
				<tr><td>Username</td><td><input type="text" name="username"/></td></tr>
				<tr><td>Password</td><td><input type="password" name="password"/></td></tr>
				<tr><td colspan="2"><input type="submit" value="login"/></td></tr>
			</table>
		</form>
		<span>
			<%
				out.println(session.getAttribute("MESSAGE")); 
			%>
		</span>

		<%

			if ( request.getMethod().equals("POST") ){

				try{
					String username = request.getParameter("username");
					String password = request.getParameter("password");

					// these <context-param> are defined in %CATALINA_BASE/webapps/<app>WEB-INF/web.xml

					String DB_DRIVER   = application.getInitParameter("DB_DRIVER");
					String DB_URL      = application.getInitParameter("DB_URL");
					String DB_USERNAME = application.getInitParameter("DB_USERNAME");
					String DB_PASSWORD = application.getInitParameter("DB_PASSWORD");

					// passwords are encrypted using a hashing algorithm and stored as strings,
					// so we encrypt the POSTed plain text and try to retrieve both it and the
					// POSTed username from the table mysql.user as a simple validity test.

					// register the driver class to prevent 'no suitable driver found...' errors
					Class.forName(DB_DRIVER);

					String sql = String.format("SELECT PASSWORD('%s') AS hashword FROM dual", password);

					Connection conn = DriverManager.getConnection(DB_URL+"mysql", DB_USERNAME, DB_PASSWORD);

					Statement stmt = conn.createStatement();

					ResultSet rs = stmt.executeQuery(sql);

					if ( rs.next() ){

						sql = String.format(
							"SELECT user FROM user WHERE user = '%s' AND password = '%s'", 
							username, rs.getString("hashword")
						);

						rs = stmt.executeQuery(sql);

						if ( rs.next() ){
							session.setAttribute("USERNAME", rs.getString("user"));
							String from = request.getParameter("from");
							if ( from != null )
								response.sendRedirect(from);
							else
								response.sendRedirect("index.html");
						}else{
							session.setAttribute("MESSAGE", "Invalid username and/or password!");
						}

					}else{
						session.setAttribute("MESSAGE", "Invalid username and/or password!");
					}
				}catch(Exception e){
					e.printStackTrace();
					out.println("#1 - " + e.getMessage());
				}
			}
		%>
	</body>
</html>