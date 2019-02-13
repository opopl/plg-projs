<?php
	$dir = getenv('PROJSDIR');

	$conffile = 

	if (isset($_GET['action'])) {
		 $action = $_GET['action'];

		 if ($action == 'listfiles') {
				listfiles($dir);
		 }
	}

	function listfiles($dir)
	{
		if ($handle = opendir($dir)) {
		    echo "Directory handle: $handle\n";
		    echo "Entries:\n";
	
				$i=0;
		
		    /* This is the correct way to loop over the directory. */
		    while (false !== ($entry = readdir($handle))) {
					 	echo "<br>$entry\n";
						$i++;
						if ($i==100) break;
		    }
		
		    closedir($handle);
		}
	}
?>
