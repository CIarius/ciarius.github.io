# +-------------+--------+-------------------------------------------------------+
# | Date        | Author | Details                                               |
# +-------------+--------+-------------------------------------------------------+
# | 01-FEB-2019 | A.McC. | Original version.                                     |
# --------------------------------------------------------------------------------
#
# Synopsis
# --------
# This script is intended to interrogate an MS Outlook email account folder called
# ' Global Termination Report' for unread emails with the phrase 
# 'Global Termination Report' in the title. For any such email with an attachment 
# called 'Termination details 00000000.TXT' the attachment will be saved to 
# 'C:\temp'. The attachment, a tab delimited text file, contains a list of 
# employees from across all Bombardier sites whose employment has been terminated.
# The attachment will be opened in Excel and filtered on the site (column 13) to 
# determine if any terminations relate to the Belfast site. The employee number of 
# any Belfast employee whose employee has been terminated will be deleted from all
# of the Matrix site's MF_OPR file on which it is found. Upon completion the email 
# from which the attachment originated will be marked as having been read.
#

Add-Type -assembly "Microsoft.Office.Interop.Outlook"

$Outlook = New-Object -comobject Outlook.Application

$namespace = $Outlook.GetNameSpace("MAPI")

$inbox = $namespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderInbox)

$folder = $inbox.Folders.Item('Global Termination Report')

$unread = $folder.Items.Restrict('[UnRead] = True')

foreach ($email in $unread){

    if ( $email.Subject -imatch "Global Termination Report" ){

	    foreach ( $attachment in $email.attachments ){

		    if ( $attachment.filename -eq 'Termination details 00000000.TXT' ){

			    $attachment.saveasfile('C:\temp\' + $attachment.filename)

			    $Excel = New-Object -ComObject Excel.Application

			    $Excel.Visible = $true

			    $workbook = $Excel.Workbooks.Open('C:\temp\' + $attachment.filename)

                $worksheet = $workbook.Worksheets.Item(1)

                $usedrange = $worksheet.UsedRange

                $usedrange.AutoFilter(13, "Belfast")

                $rows = $worksheet.UsedRange.SpecialCells(12).Rows # 12 = $xlCellTypeVisible

                foreach( $row in $rows ){

                    $empID = $row.Cells.Item(1).Value()

                    if ( $empID.Length -lt 5 ){
                        $empID = $empID.ToString().PadLeft(5, '0') # 'cause it's a double
                    }

                    # connect to each Matrix site in turn and, using Connx as a ODBC broker to access the RMS data files, delete each terminated employeed from the MF_OPR table
                    # remembering that an employee may exist on none (they may be on FATS), one, or many of the MF_OPR tables across the multiple Matrix controlled factory sites

                    foreach ( $site in ("arpcnxliv", "nabcnxliv", "trmcnxliv", "mspcnxliv", "hawcnxliv", "duncnxliv", "wpucnxliv") ){

                        $conn = new-object System.Data.Odbc.OdbcConnection

                        $conn.connectionstring = "ODBC;server=redacted;dsn=iFactory;uid=" + $site + ";pwd=redacted"

                        $conn.open()

                        $sqlCommand = "DELETE FROM mf_opr WHERE operator_id = '" + $empID + "'"

                        #$sqlCommand = "SELECT * FROM mf_opr WHERE operator_id = '" + $empID + "'"

                        $cmd = New-object System.Data.Odbc.OdbcCommand($sqlCommand,$conn) | out-null

                        #$ds = New-Object system.Data.DataSet

                        #(New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($ds)

                        #if ( $ds.Tables.Count -gt 0 ){
                        #    $site + " - " + $ds.Tables[0].Item('OPERATOR_ID')
                        #}

                        $conn.Close()

                    }
                }

                $workbook.Close($false)

                $Excel.Quit()

                $email.UnRead = $false

            }

		}

	}

}