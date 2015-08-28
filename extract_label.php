<?php
$json = json_decode(file_get_contents('php://stdin'));
echo $json->head->label, "\n";
