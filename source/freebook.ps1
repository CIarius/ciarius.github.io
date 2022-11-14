# +-------------+--------+-------------------------------------------------------+
# | Date        | Author | Details                                               |
# +-------------+--------+-------------------------------------------------------+
# | 24-APR-2017 | A.McC. | Original version.                                     |
# --------------------------------------------------------------------------------
#
# Synopsis
# --------
# Packt publishing give away a free eBook each day. Yay! I set this up as a 
# scheduled task on my PC so it would do it for me regardless of whether I
# was around or not. Accurate at time of writing but site is subject to change.
#

$username = "someone@somewhere.something"
$password = 'likeidbethatstupid'

$ie = New-Object -com InternetExplorer.Application
$ie.Visible = $true
$ie.Navigate("https://www.packtpub.com/packt/offers/free-learning")

while($ie.busy){start-sleep 1}

$button = $ie.Document.getElementsByTagName("input") | where-object {$_.value -eq "Claim Your Free eBook"}
$button.click()

while($ie.busy){start-sleep 1}

$usernamefield = $ie.Document.getElementByID('email')
$usernamefield.value = $username

$usernamefield = $ie.Document.getElementByID('password')
$usernamefield.value = $password

$submitbutton = $ie.Document.getElementByID('edit-submit-1')
$submitbutton.click()

while($ie.busy){start-sleep 1}

$button = $ie.Document.getElementsByTagName("input") | where-object {$_.value -eq "Claim Your Free eBook"}
$button.click()

while($ie.busy){start-sleep 1}

$button = $ie.Document.getElementsByTagName("div") | where-object {$_.value -eq "Sign out"}
$button.click()

while($ie.busy){start-sleep 1}

$ie.Quit()