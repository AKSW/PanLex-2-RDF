<?php
header('Content-type: text/plain');
$bz=bzopen(''.str_replace("_sl_","/",$_REQUEST['file']), "r") or die("File not found!");
echo(bzread($bz, 16000));
bzclose($bz);
